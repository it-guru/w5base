#!/usr/bin/perl
use strict;
use CGI qw/:standard/;
use Data::Dumper;
use JSON;
use URI;
use IO::Socket::INET;
use Time::HiRes;


my $q=new CGI();

if (request_method() eq "POST"){
   ProbeIP();
}
else{
   if ($q->param("url") eq ""){
      $q->param("url"=>$ENV{SCRIPT_URI});
   }
   ShowForm();
}
exit(0);


sub ProbeIP()
{
   print $q->header(
      -type=>'application/json',
      -expires=>'+10s',
      -charset=>'utf-8'
   );
   my $r={};

   my $uri=new URI($q->param("url"));
   my $scheme=$uri->scheme();
   if (ref($uri) ne "URI::_foreign"){
      $uri->path("");
      $r->{url}=$uri->as_string();
      $r->{target}={
         schema=>$scheme,
         host=>$uri->host(),
         port=>$uri->port()
      }
   }
   else{
      my $name=$uri;
      my $befhost=qr{\@}; # character before the host
      $befhost=qr{://} if (index($name,'@')==-1);

      my ($host,$port)=$name=~m/$befhost([^:\/]+)(?:\:(\d+))?/;
      $r->{target}={
         schema=>$scheme,
         host=>$host
      };
      if ($port eq ""){
         $port="22" if ($scheme eq "sftp");
         $port="22" if ($scheme eq "ssh");
         $port="22" if ($scheme eq "scp");
      }

      if ($port ne ""){
         $r->{target}->{port}=$port;
      }

   }
   my $t1=Time::HiRes::time();
   my @operation=$q->param("operation");
   do_DNSRESOLV($r) if (grep(/^DNSRESOLV$/,@operation));
   do_SSLCERT($r)   if (grep(/^SSLCERT$/,@operation));
   do_REVDNS($r)    if (grep(/^REVDNS$/,@operation));
   do_IPCONNECT($r) if (grep(/^IPCONNECT$/,@operation));
   foreach my $k (keys(%$r)){
      if (ref($r->{$k}) eq "HASH"){
         if (exists($r->{$k}->{exitcode}) && 
             $r->{$k}->{exitcode} ne "0"){
            if ($r->{exitcode}<$r->{$k}->{exitcode}){
               $r->{exitcode}=$r->{$k}->{exitcode};
            }
         }
      }
   }
   if (!exists($r->{exitcode})){
      $r->{exitcode}=0;
   }
   my $t2=Time::HiRes::time();
   $r->{duration}=$t2-$t1;

   print to_json($r,{ 
      utf8=>1, 
      pretty=>1 
   });
}

sub do_DNSRESOLV
{
   my $r=shift;

   $r->{operation}->{DNSRESOLV}=1;

   my $host=$r->{target}->{host};

   $r->{dnsresolver}=resolv2ip($host);
}


sub resolv2ip
{
   my $host=shift;

   my $r={};

   my $k=$host;

   if (exists($W5ProbeIP::resolvip::Cache{$k})){
      return($W5ProbeIP::resolvip::Cache{$k});
   }


   my @okt=unpack("C4",pack("C4",split(/\./,$host)));
   @okt=grep({ $_>=0 and $_< 256 } @okt);
   my $parsed=join('.',unpack("C4",pack("C4",split(/\./,$host))));
   if ($parsed eq $host){ # is already v4 address
      $r->{ipaddress}=[$host];
      $r->{exitcode}=0;
   }
   elsif ($host=~m/^[:a-f0-9]+$/){ # is already v6 address
      $r->{ipaddress}=[$host];
      $r->{exitcode}=0;
   }
   else{
      my $res;
      eval('
         use Net::DNS;
         $res=Net::DNS::Resolver->new();
      ');
      if ($@ ne ""){
         $r->{errorcode}=100;
         $r->{error}=$@;
      }
      else{
         my @ipaddress;
         my $query=$res->search($host);
         if ($query){
            foreach my $rr ($query->answer) {
               next unless($rr->type eq "A");
               push(@ipaddress,$rr->address);
            }
            $r->{exitcode}=0;
            $r->{ipaddress}=\@ipaddress;
         }
         elsif ($res->errorstring eq "NXDOMAIN" ||
                $res->errorstring eq "NOERROR"){
            $r->{error}="invalid dns name";
            $r->{exitcode}=100;
         }
         else{
            $r->{error}="dns query failed";
            $r->{exitcode}=1;
            return(undef);
         }
      }
   }
   $W5ProbeIP::resolvip::Cache{$k}=$r;

   return($r);
}

sub do_SSLCERT
{
   my $r=shift;

   $r->{operation}->{SSLCERT}=1;

   my $host=$r->{target}->{host};
   my $port=$r->{target}->{port};

   eval('use IO::Socket::SSL;');
   eval('use Net::SSLeay;');
   eval('use IO::Socket::INET;');
   eval('use IO::Socket::INET6;');
   eval('use DateTime;');
   eval('use Date::Parse;');

   if (!canTcpConnect($host,$port)){
      push(@{$r->{sslcert}->{log}},
          sprintf("Step0: generic tcp connect check %s:%s",$host,$port));
      $r->{sslcert}->{error}="can not tcp connect to $host:$port";
      $r->{sslcert}->{exitcode}=1;
      return;
   }

   push(@{$r->{sslcert}->{log}},
       sprintf("Step1: try to connect to %s:%s SSLv23",$host,$port));
   $ENV{"HTTPS_VERSION"}="3";



   my $sock = IO::Socket::SSL->new(PeerAddr=>"$host:$port",
                                   SSL_version=>'SSLv23',
                                   SSL_verify_mode=>'SSL_VERIFY_NONE',
                                   Timeout=>5,
                                   SSL_session_cache_size=>0);
   if (!defined($sock)){
      push(@{$r->{sslcert}->{log}},
          sprintf("->result=%s",IO::Socket::SSL->errstr()));
   }
   if (!defined($sock)){
      push(@{$r->{sslcert}->{log}},
          sprintf("Step2: try to connect to %s:%s SSLv2",$host,$port));
      $sock = IO::Socket::SSL->new(PeerAddr=>"$host:$port",
                                   SSL_version=>'SSLv2',
                                   SSL_verify_mode=>'SSL_VERIFY_NONE',
                                   Timeout=>5,
                                   SSL_session_cache_size=>0);
      if (!defined($sock)){
         push(@{$r->{sslcert}->{log}},
             sprintf("->result=%s",IO::Socket::SSL->errstr()));
      }
   }
   if (!defined($sock)){
      push(@{$r->{sslcert}->{log}},
          sprintf("Step3: try to connect to %s:%s SSLv3",$host,$port));
      $sock = IO::Socket::SSL->new(PeerAddr=>"$host:$port",
                                   SSL_version=>'SSLv3',
                                   SSL_verify_mode=>'SSL_VERIFY_NONE',
                                   Timeout=>5,
                                   SSL_session_cache_size=>0);
      if (!defined($sock)){
         push(@{$r->{sslcert}->{log}},
             sprintf("->result=%s",IO::Socket::SSL->errstr()));
      }
   }
   if (defined($sock)){
      my $cert = $sock->peer_certificate();
      if (1){
         my $certdump;
         eval('$certdump=$sock->dump_peer_certificate();');
         $r->{sslcert}->{ssl_certdump}=$certdump if ($@ eq "");
     
         my $version;
         eval('$version = $sock->get_sslversion();');
         $r->{sslcert}->{ssl_version}=$version if ($@ eq "");
     
         my $cipher;
         eval('$cipher=$sock->get_cipher();');
         $r->{sslcert}->{ssl_cipher}=$cipher if ($@ eq "");
      }
      my ($begin_date,$expire_date)=();


      if ($cert){
         my $expire_date_asn1=Net::SSLeay::X509_get_notAfter($cert);
         my $expireDate=Net::SSLeay::P_ASN1_UTCTIME_put2string(
                        $expire_date_asn1);
         ### $expire_date_str
         my $begin_date_asn1 =Net::SSLeay::X509_get_notBefore($cert);
         my $beginDate=Net::SSLeay::P_ASN1_UTCTIME_put2string($begin_date_asn1);
         $r->{sslcert}->{ssl_cert_begin}="".
             DateTime->from_epoch(epoch=>str2time($beginDate));
         $r->{sslcert}->{ssl_cert_end}="".
             DateTime->from_epoch(epoch=>str2time($expireDate));
    
         my $certserial;
         eval('$certserial=Net::SSLeay::X509_get_serialNumber($cert);');
         $r->{sslcert}->{ssl_cert_serialno}=
            Net::SSLeay::P_ASN1_INTEGER_get_hex($certserial) if ($@ eq "");
         if (main->can("Net::SSLeay::P_X509_get_signature_alg")){
            my $cert_signature_algo;
            eval('$cert_signature_algo=
               Net::SSLeay::OBJ_obj2txt(
                  Net::SSLeay::P_X509_get_signature_alg($cert)
               );
            ');
            if ($@ eq ""){
               $r->{sslcert}->{ssl_cert_signature_algo}=$cert_signature_algo;
            }
         }
      }
      $r->{sslcert}->{exitcode}=0;
   }
   else{
      $r->{sslcert}->{exitcode}=1;
   }
}

sub do_REVDNS
{
   my $r=shift;

   $r->{operation}->{REVDNS}=1;

   my $host=$r->{target}->{host};

   my $dns=resolv2ip($host);

   if ($dns->{exitcode}==0 &&
       ref($dns->{ipaddress}) eq "ARRAY"){
      my $res;
      eval('
         use Net::DNS;
         $res=Net::DNS::Resolver->new();
      ');
      if ($@ ne ""){
         $r->{errorcode}=100;
         $r->{error}=$@;
      }
      else{
         $r->{revdns}->{names}=[];
         my @ipl=@{$dns->{ipaddress}};
         my @names=();
         foreach my $ip (@ipl){
            my $query=$res->query($ip,"PTR");
            if ($query){
               foreach my $rr ($query->answer) {
                  next unless($rr->type eq "PTR");
                  push(@names,$rr->rdatastr);
               }
            }
         }
         push(@{$r->{revdns}->{names}},@names)
      }
   }
}

sub do_IPCONNECT
{
   my $r=shift;

   $r->{operation}->{IPCONNECT}=1;
   my $t1=Time::HiRes::time();
   my $res=canTcpConnect($r->{target}->{host},$r->{target}->{port});
   my $t2=Time::HiRes::time();
   if ($res){
      $r->{ipconnect}->{open}=1;
      $r->{ipconnect}->{time}=$t2-$t1;
   }
   else{
      $r->{ipconnect}->{open}=0;
   }
   if ($ENV{W5ProbeIP_SourceIP} ne ""){
      $r->{ipconnect}->{sourceip}=$ENV{W5ProbeIP_SourceIP};
   }
}

sub canTcpConnect
{
   my ($host,$port)=@_;

   my $k=$host.":".$port;

   if (exists($W5ProbeIP::canTcpConnect::Cache{$k})){
      return($W5ProbeIP::canTcpConnect::Cache{$k});
   }

   my $sock = IO::Socket::INET->new(
      PeerAddr => $host,PeerPort => $port,
      Proto => "tcp",
      Timeout => 5 
   );
   if (defined($sock)){
      if ($ENV{W5ProbeIP_SourceIP} eq ""){
         $ENV{W5ProbeIP_SourceIP}=$sock->sockhost();
      }
      $sock->close();
      $W5ProbeIP::canTcpConnect::Cache{$k}=1;
      return(1);
   }
   $W5ProbeIP::canTcpConnect::Cache{$k}=0;
   return(0);
}



sub ShowForm()
{
   my $e=Dumper(\%ENV);
   $e=~s/^\$VAR1/ENV/;

   print $q->header().
   $q->start_html('W5ProbeIP').

   "<div style='width:100%'>".
   h1({
      -style=>'Color: blue;'
   },'W5ProbeIP').

   $q->start_form(
      -method=>'POST',
      -target=>'OUT'
   ).

   $q->textfield(-name=>'url',
      -value=>'',
      -size=>50,
      -maxlength=>80
   ).

   $q->checkbox_group(
      -name=>'operation',
      -values=>['SSLCERT','DNSRESOLV','REVDNS','IPCONNECT'],
      -columns=>4
   ).

   $q->submit(
      -name=>'do',
      -value=>'analyse URL'
   ).
   $q->end_form().
   "<iframe name=OUT style='width:100%;height:300px'></iframe>".
   '</div>'.
   "<div style='height:200px;overflow:scroll'>"."<xmp>".$e."</xmp>"."</div>".
   

   $q->end_html();
}
