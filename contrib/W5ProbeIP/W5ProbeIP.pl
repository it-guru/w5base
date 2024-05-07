#!/usr/bin/perl
use strict;
use CGI qw/:standard -oldstyle_urls/;
use Data::Dumper;
use JSON;
use URI;
use IO::Socket::INET;
use Time::HiRes;

package SSLTEST;
no strict;

%ssl2ciphers = (
	'DES-CBC3-MD5' => '3DES 168 bits, RSA Auth, MD5 MAC, RSA Kx',
	'DES-CBC-MD5' => 'DES 56 bits, RSA Auth, MD5 MAC, RSA Kx',
	'EXP-RC2-CBC-MD5' => 'RC2 40 bits, RSA Auth, MD5 MAC, RSA 512 Kx',
	'RC2-CBC-MD5' => 'RC2 128 bits, RSA Auth, MD5 MAC, RSA Kx',
	'EXP-RC4-MD5' => 'RC4 40 bits, RSA Auth, MD5 MAC, RSA 512 Kx',
	'RC4-MD5' => 'RC4 128 bits, RSA Auth, MD5 MAC, RSA Kx'
);



%ssl3ciphers = (
	'ECDHE-RSA-AES256-SHA' => 'AES 256 bits, RSA Auth, SHA1 MAC, ECDH Kx',
	'ECDHE-ECDSA-AES256-SHA' => 'AES 256 bits, ECDSA Auth, SHA1 MAC, ECDH Kx',
	'SRP-DSS-AES-256-CBC-SHA' => 'AES 256 bits, DSS Auth, SHA1 MAC, SRP Kx',
	'SRP-RSA-AES-256-CBC-SHA' => 'AES 256 bits, RSA Auth, SHA1 MAC, SRP Kx',
	'SRP-AES-256-CBC-SHA' => 'AES 256 bits, SRP Auth, SHA1 MAC, SRP Kx',
	'DHE-RSA-AES256-SHA' => 'AES 256 bits, RSA Auth, SHA1 MAC, DH Kx',
	'DHE-DSS-AES256-SHA' => 'AES 256 bits, DSS Auth, SHA1 MAC, DH Kx',
	'DHE-RSA-CAMELLIA256-SHA' => 'Camellia 256 bits, RSA Auth, SHA1 MAC, DH Kx',
	'DHE-DSS-CAMELLIA256-SHA' => 'Camellia 256 bits, DSS Auth, SHA1 MAC, DH Kx',
	'AECDH-AES256-SHA' => 'AES 256 bits, Null Auth, SHA1 MAC, ECDH Kx',
	'ADH-AES256-SHA' => 'AES 256 bits, Null Auth, SHA1 MAC, DH Kx',
	'ADH-CAMELLIA256-SHA' => 'Camellia 256 bits, Null Auth, SHA1 MAC, DH Kx',
	'ECDH-RSA-AES256-SHA' => 'AES 256 bits, ECDH Auth, SHA1 MAC, ECDH/RSA Kx',
	'ECDH-ECDSA-AES256-SHA' => 'AES 256 bits, ECDH Auth, SHA1 MAC, ECDH/ECDSA Kx',
	'AES256-SHA' => 'AES 256 bits, RSA Auth, SHA1 MAC, RSA Kx',
	'CAMELLIA256-SHA' => 'Camellia 256 bits, RSA Auth, SHA1 MAC, RSA Kx',
	'PSK-AES256-CBC-SHA' => 'AES 256 bits, PSK Auth, SHA1 MAC, PSK Kx',
	'ECDHE-RSA-DES-CBC3-SHA' => '3DES 168 bits, RSA Auth, SHA1 MAC, ECDH Kx',
	'ECDHE-ECDSA-DES-CBC3-SHA' => '3DES 168 bits, ECDSA Auth, SHA1 MAC, ECDH Kx',
	'SRP-DSS-3DES-EDE-CBC-SHA' => '3DES 168 bits, DSS Auth, SHA1 MAC, SRP Kx',
	'SRP-RSA-3DES-EDE-CBC-SHA' => '3DES 168 bits, RSA Auth, SHA1 MAC, SRP Kx',
	'SRP-3DES-EDE-CBC-SHA' => '3DES 168 bits, SRP Auth, SHA1 MAC, SRP Kx',
	'EDH-RSA-DES-CBC3-SHA' => '3DES 168 bits, RSA Auth, SHA1 MAC, DH Kx',
	'EDH-DSS-DES-CBC3-SHA' => '3DES 168 bits, DSS Auth, SHA1 MAC, DH Kx',
	'AECDH-DES-CBC3-SHA' => '3DES 168 bits, Null Auth, SHA1 MAC, ECDH Kx',
	'ADH-DES-CBC3-SHA' => '3DES 168 bits, Null Auth, SHA1 MAC, DH Kx',
	'ECDH-RSA-DES-CBC3-SHA' => '3DES 168 bits, ECDH Auth, SHA1 MAC, ECDH/RSA Kx',
	'ECDH-ECDSA-DES-CBC3-SHA' => '3DES 168 bits, ECDH Auth, SHA1 MAC, ECDH/ECDSA Kx',
	'DES-CBC3-SHA' => '3DES 168 bits, RSA Auth, SHA1 MAC, RSA Kx',
	'PSK-3DES-EDE-CBC-SHA' => '3DES 168 bits, PSK Auth, SHA1 MAC, PSK Kx',
	'ECDHE-RSA-AES128-SHA' => 'AES 128 bits, RSA Auth, SHA1 MAC, ECDH Kx',
	'ECDHE-ECDSA-AES128-SHA' => 'AES 128 bits, ECDSA Auth, SHA1 MAC, ECDH Kx',
	'SRP-DSS-AES-128-CBC-SHA' => 'AES 128 bits, DSS Auth, SHA1 MAC, SRP Kx',
	'SRP-RSA-AES-128-CBC-SHA' => 'AES 128 bits, RSA Auth, SHA1 MAC, SRP Kx',
	'SRP-AES-128-CBC-SHA' => 'AES 128 bits, SRP Auth, SHA1 MAC, SRP Kx',
	'DHE-RSA-AES128-SHA' => 'AES 128 bits, RSA Auth, SHA1 MAC, DH Kx',
	'DHE-DSS-AES128-SHA' => 'AES 128 bits, DSS Auth, SHA1 MAC, DH Kx',
	'DHE-RSA-SEED-SHA' => 'SEED 128 bits, RSA Auth, SHA1 MAC, DH Kx',
	'DHE-DSS-SEED-SHA' => 'SEED 128 bits, DSS Auth, SHA1 MAC, DH Kx',
	'DHE-RSA-CAMELLIA128-SHA' => 'Camellia 128 bits, RSA Auth, SHA1 MAC, DH Kx',
	'DHE-DSS-CAMELLIA128-SHA' => 'Camellia 128 bits, DSS Auth, SHA1 MAC, DH Kx',
	'AECDH-AES128-SHA' => 'AES 128 bits, Null Auth, SHA1 MAC, ECDH Kx',
	'ADH-AES128-SHA' => 'AES 128 bits, Null Auth, SHA1 MAC, DH Kx',
	'ADH-SEED-SHA' => 'SEED 128 bits, Null Auth, SHA1 MAC, DH Kx',
	'ADH-CAMELLIA128-SHA' => 'Camellia 128 bits, Null Auth, SHA1 MAC, DH Kx',
	'ECDH-RSA-AES128-SHA' => 'AES 128 bits, ECDH Auth, SHA1 MAC, ECDH/RSA Kx',
	'ECDH-ECDSA-AES128-SHA' => 'AES 128 bits, ECDH Auth, SHA1 MAC, ECDH/ECDSA Kx',
	'AES128-SHA' => 'AES 128 bits, RSA Auth, SHA1 MAC, RSA Kx',
	'SEED-SHA' => 'SEED 128 bits, RSA Auth, SHA1 MAC, RSA Kx',
	'CAMELLIA128-SHA' => 'Camellia 128 bits, RSA Auth, SHA1 MAC, RSA Kx',
	'PSK-AES128-CBC-SHA' => 'AES 128 bits, PSK Auth, SHA1 MAC, PSK Kx',
	'ECDHE-RSA-RC4-SHA' => 'RC4 128 bits, RSA Auth, SHA1 MAC, ECDH Kx',
	'ECDHE-ECDSA-RC4-SHA' => 'RC4 128 bits, ECDSA Auth, SHA1 MAC, ECDH Kx',
	'AECDH-RC4-SHA' => 'RC4 128 bits, Null Auth, SHA1 MAC, ECDH Kx',
	'ADH-RC4-MD5' => 'RC4 128 bits, Null Auth, MD5 MAC, DH Kx',
	'ECDH-RSA-RC4-SHA' => 'RC4 128 bits, ECDH Auth, SHA1 MAC, ECDH/RSA Kx',
	'ECDH-ECDSA-RC4-SHA' => 'RC4 128 bits, ECDH Auth, SHA1 MAC, ECDH/ECDSA Kx',
	'RC4-SHA' => 'RC4 128 bits, RSA Auth, SHA1 MAC, RSA Kx',
	'RC4-MD5' => 'RC4 128 bits, RSA Auth, MD5 MAC, RSA Kx',
	'PSK-RC4-SHA' => 'RC4 128 bits, PSK Auth, SHA1 MAC, PSK Kx',
	'EDH-RSA-DES-CBC-SHA' => 'DES 56 bits, RSA Auth, SHA1 MAC, DH Kx',
	'EDH-DSS-DES-CBC-SHA' => 'DES 56 bits, DSS Auth, SHA1 MAC, DH Kx',
	'ADH-DES-CBC-SHA' => 'DES 56 bits, Null Auth, SHA1 MAC, DH Kx',
	'DES-CBC-SHA' => 'DES 56 bits, RSA Auth, SHA1 MAC, RSA Kx',
	'EXP-EDH-RSA-DES-CBC-SHA' => 'DES 40 bits, RSA Auth, SHA1 MAC, DH(512) Kx',
	'EXP-EDH-DSS-DES-CBC-SHA' => 'DES 40 bits, DSS Auth, SHA1 MAC, DH(512) Kx',
	'EXP-ADH-DES-CBC-SHA' => 'DES 40 bits, Null Auth, SHA1 MAC, DH(512) Kx',
	'EXP-DES-CBC-SHA' => 'DES 40 bits, RSA Auth, SHA1 MAC, RSA(512) Kx',
	'EXP-RC2-CBC-MD5' => 'RC2 40 bits, RSA Auth, MD5 MAC, RSA(512) Kx',
	'EXP-ADH-RC4-MD5' => 'RC4 40 bits, Null Auth, MD5 MAC, DH(512) Kx',
	'EXP-RC4-MD5' => 'RC4 40 bits, RSA Auth, MD5 MAC, RSA(512) Kx',
	'ECDHE-RSA-NULL-SHA' => 'Null, RSA Auth, SHA1 MAC, ECDH Kx',
	'ECDHE-ECDSA-NULL-SHA' => 'Null, ECDSA Auth, SHA1 MAC, ECDH Kx',
	'AECDH-NULL-SHA' => 'Null, Null Auth, SHA1 MAC, ECDH Kx',
	'ECDH-RSA-NULL-SHA' => 'Null, ECDH Auth, SHA1 MAC, ECDH/RSA Kx',
	'ECDH-ECDSA-NULL-SHA' => 'Null, ECDH Auth, SHA1 MAC, ECDH/ECDSA Kx',
	'NULL-SHA' => 'Null, RSA Auth, SHA1 MAC, RSA Kx',
	'NULL-MD5' => 'Null, RSA Auth, MD5 MAC, RSA Kx'
);


%tlsv12ciphers = (
	'ECDHE-RSA-AES256-GCM-SHA384' => 'AESGCM 256 bits, RSA Auth, AEAD MAC, ECDH Kx',
	'ECDHE-ECDSA-AES256-GCM-SHA384' => 'AESGCM 256 bits, ECDSA Auth, AEAD MAC, ECDH Kx',
	'ECDHE-RSA-AES256-SHA384' => 'AES 256 bits, RSA Auth, SHA384 MAC, ECDH Kx',
	'ECDHE-ECDSA-AES256-SHA384' => 'AES 256 bits, ECDSA Auth, SHA384 MAC, ECDH Kx',
	'DHE-DSS-AES256-GCM-SHA384' => 'AESGCM 256 bits, DSS Auth, AEAD MAC, DH Kx',
	'DHE-RSA-AES256-GCM-SHA384' => 'AESGCM 256 bits, RSA Auth, AEAD MAC, DH Kx',
	'DHE-RSA-AES256-SHA256' => 'AES 256 bits, RSA Auth, SHA256 MAC, DH Kx',
	'DHE-DSS-AES256-SHA256' => 'AES 256 bits, DSS Auth, SHA256 MAC, DH Kx',
	'ADH-AES256-GCM-SHA384' => 'AESGCM 256 bits, Null Auth, AEAD MAC, DH Kx',
	'ADH-AES256-SHA256' => 'AES 256 bits, Null Auth, SHA256 MAC, DH Kx',
	'ECDH-RSA-AES256-GCM-SHA384' => 'AESGCM 256 bits, ECDH Auth, AEAD MAC, ECDH/RSA Kx',
	'ECDH-ECDSA-AES256-GCM-SHA384' => 'AESGCM 256 bits, ECDH Auth, AEAD MAC, ECDH/ECDSA Kx',
	'ECDH-RSA-AES256-SHA384' => 'AES 256 bits, ECDH Auth, SHA384 MAC, ECDH/RSA Kx',
	'ECDH-ECDSA-AES256-SHA384' => 'AES 256 bits, ECDH Auth, SHA384 MAC, ECDH/ECDSA Kx',
	'AES256-GCM-SHA384' => 'AESGCM 256 bits, RSA Auth, AEAD MAC, RSA Kx',
	'AES256-SHA256' => 'AES 256 bits, RSA Auth, SHA256 MAC, RSA Kx',
	'ECDHE-RSA-AES128-GCM-SHA256' => 'AESGCM 128 bits, RSA Auth, AEAD MAC, ECDH Kx',
	'ECDHE-ECDSA-AES128-GCM-SHA256' => 'AESGCM 128 bits, ECDSA Auth, AEAD MAC, ECDH Kx',
	'ECDHE-RSA-AES128-SHA256' => 'AES 128 bits, RSA Auth, SHA256 MAC, ECDH Kx',
	'ECDHE-ECDSA-AES128-SHA256' => 'AES 128 bits, ECDSA Auth, SHA256 MAC, ECDH Kx',
	'DHE-DSS-AES128-GCM-SHA256' => 'AESGCM 128 bits, DSS Auth, AEAD MAC, DH Kx',
	'DHE-RSA-AES128-GCM-SHA256' => 'AESGCM 128 bits, RSA Auth, AEAD MAC, DH Kx',
	'DHE-RSA-AES128-SHA256' => 'AES 128 bits, RSA Auth, SHA256 MAC, DH Kx',
	'DHE-DSS-AES128-SHA256' => 'AES 128 bits, DSS Auth, SHA256 MAC, DH Kx',
	'ADH-AES128-GCM-SHA256' => 'AESGCM 128 bits, Null Auth, AEAD MAC, DH Kx',
	'ADH-AES128-SHA256' => 'AES 128 bits, Null Auth, SHA256 MAC, DH Kx',
	'ECDH-RSA-AES128-GCM-SHA256' => 'AESGCM 128 bits, ECDH Auth, AEAD MAC, ECDH/RSA Kx',
	'ECDH-ECDSA-AES128-GCM-SHA256' => 'AESGCM 128 bits, ECDH Auth, AEAD MAC, ECDH/ECDSA Kx',
	'ECDH-RSA-AES128-SHA256' => 'AES 128 bits, ECDH Auth, SHA256 MAC, ECDH/RSA Kx',
	'ECDH-ECDSA-AES128-SHA256' => 'AES 128 bits, ECDH Auth, SHA256 MAC, ECDH/ECDSA Kx',
	'AES128-GCM-SHA256' => 'AESGCM 128 bits, RSA Auth, AEAD MAC, RSA Kx',
	'AES128-SHA256' => 'AES 128 bits, RSA Auth, SHA256 MAC, RSA Kx',
	'NULL-SHA256' => 'Null, RSA Auth, SHA256 MAC, RSA Kx'
);


# add the list of ssl3 ciphers to the tlsv1.2 list
while ( ($k,$v) = each(%ssl3ciphers) ) {
    $tlsv12ciphers{$k} = $v;
}

package main;


my $r={};
my $t1;
my $q=new CGI();
my @CERTBuffer;
my $ScriptTimeout=60;

if (request_method() eq "POST"){
   ProbeIP();
}
else{
   if ($q->param("url") eq ""){
      $q->param("url"=>$ENV{SCRIPT_URI});
   }
   if ($q->param("operation") eq ""){
      $q->param(-name=>"operation",
                -value=>['DNSRESOLV']);
   }
   ShowForm();
}
exit(0);


sub outputResults
{
   foreach my $k (keys(%$r)){
      if (ref($r->{$k}) eq "HASH"){
         if (exists($r->{$k}->{exitcode}) && 
             $r->{$k}->{exitcode} ne "0"){
            if ($r->{exitcode}<$r->{$k}->{exitcode}){
               $r->{exitcode}=$r->{$k}->{exitcode};
               if (defined($r->{$k}->{exitmsg})){
                  $r->{exitmsg}=$r->{$k}->{exitmsg};
               }
            }
         }
      }
   }
   if (!exists($r->{exitcode})){
      $r->{exitcode}=0;
   }
   my $t2=Time::HiRes::time();
   $r->{startunixtime}=$t1;

   my $uri=$ENV{SCRIPT_URI};
   $uri=~s/\?.*$//;
   if (lc($ENV{HTTP_FRONT_END_HTTPS}) eq "on"){
      $uri=~s/^http:/https:/;
   }

   my $requesturl=new CGI({});
   $requesturl->param(-name=>'submit',-value=>'1');
   $requesturl->param(-name=>'url',-value=>$q->param("url"));
   my @operation=$q->param("operation");
   $requesturl->param(-name=>'operation',-value=>\@operation);

   $r->{requesturl}=$uri.'?'.$requesturl->query_string();

   $r->{endunixtime}=$t2;
   $r->{duration}=$t2-$t1;

   print to_json($r,{ 
      utf8=>1, 
      pretty=>1 
   });
}



sub ProbeIP()
{
   $|=1;
   print $q->header(
      -type=>'application/json',
      -expires=>'+10s',
      -charset=>'utf-8'
   );

   my $url=$q->param("url");
   $url=~s/^["'\s]*//g;
   $url=~s/["'\s]*$//g;
   my $uri=new URI($url);
   $SIG{ALRM}=sub{
      outputResults();
      die("W5ProbeIP timeout for $uri after $ScriptTimeout seconds");
   };
   alarm($ScriptTimeout);

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
   $t1=Time::HiRes::time();
   my @operation;
   if ($q->can("multi_param")){
      @operation=$q->multi_param("operation");
   }
   else{
      @operation=$q->param("operation");
   }
   do_DNSRESOLV($r)    if (grep(/^DNSRESOLV$/,@operation));
   do_SSLCERT($r)      if (grep(/^SSLCERT$/,@operation));
   do_SSLCIPHERS($r)   if (grep(/^SSLCIPHERS$/,@operation));
   do_REVDNS($r)       if (grep(/^REVDNS$/,@operation));
   do_IPCONNECT($r)    if (grep(/^IPCONNECT$/,@operation));
   outputResults();
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

   my @oktstr=split(/\./,$host);
   my $oktpacked;
   my $parsed;
   if ($#oktstr==3){
      eval('$oktpacked=pack("C4",@oktstr);');
   }
   my @okt;
   if ($@ eq "" && defined($oktpacked)){
      $oktpacked=unpack("C4",$oktpacked);
      @okt=grep({ $_>=0 and $_< 256 } @okt);
      $parsed=join('.',unpack("C4",pack("C4",split(/\./,$host))));
   }
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
            $r->{exitcode}=101;
         }
         else{
            $r->{error}="dns query failed";
            $r->{exitcode}=102;
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


   foreach my $mod (qw( IO::Socket::SSL Net::SSLeay IO::Socket::INET 
                        IO::Socket::INET6
                        DateTime HTTP::Date Date::Parse)){
      eval("use $mod;");
      if ($@ ne ""){
         printf STDERR ("W5ProbeIO: fail to load $mod for do_SSLCERT\n");
         $r->{sslcert}->{error}="W5ProbeIP Installation problem - missing ".
                                "module $mod";
         $r->{sslcert}->{exitcode}=1;
         return();
      }
      my $v;
      eval("\$v=\$${mod}::VERSION;");
      push(@{$r->{sslcert}->{log}},"use module $mod in version $v");
   }

   sub unpackCert
   {
      my $cert=shift;
      my $sslcert={};

      my $expire_date_asn1=Net::SSLeay::X509_get_notAfter($cert);
      my $expireDate=Net::SSLeay::P_ASN1_UTCTIME_put2string(
                     $expire_date_asn1);
      ### $expire_date_str
      my $begin_date_asn1 =Net::SSLeay::X509_get_notBefore($cert);
      my $beginDate=Net::SSLeay::P_ASN1_UTCTIME_put2string($begin_date_asn1);
      $sslcert->{ssl_cert_begin}="".
          DateTime->from_epoch(epoch=>str2time($beginDate));
      $sslcert->{ssl_cert_end}="".
          DateTime->from_epoch(epoch=>str2time($expireDate));
    
      my $pkey=Net::SSLeay::X509_get_pubkey($cert);
      my $bits = Net::SSLeay::EVP_PKEY_bits($pkey);
      $sslcert->{ssl_cert_bits}=$bits;

      my $certserial;
      eval('$certserial=Net::SSLeay::X509_get_serialNumber($cert);');

      $sslcert->{ssl_cert_serialno}=
         Net::SSLeay::P_ASN1_INTEGER_get_hex($certserial) if ($@ eq "");

      my $certificate_type;
      my @certificate_type;
      eval('$certificate_type = Net::SSLeay::X509_certificate_type($cert);');

      foreach my $bitname (qw(EVP_PKS_DSA EVP_PKS_EC EVP_PKS_RSA
                              EVP_PKT_ENC EVP_PKT_EXCH EVP_PKT_EXP 
                              EVP_PKT_SIGN EVP_PK_DH EVP_PK_DSA 
                              EVP_PK_EC EVP_PK_RSA)){
          my $chk;
          eval("\$chk=\$certificate_type & &Net::SSLeay::$bitname");
          if ($chk){
             push(@certificate_type,$bitname);
          }
      }
      $sslcert->{ssl_cert_type}=\@certificate_type;
      if (grep(/PK_RSA/,@certificate_type)){
         $sslcert->{ssl_cert_pk_type}="RSA".$sslcert->{ssl_cert_bits};
      }
      if (grep(/PK_DSA/,@certificate_type)){
         $sslcert->{ssl_cert_pk_type}="DSA".$sslcert->{ssl_cert_bits};
      }
      if (grep(/PK_DH/,@certificate_type)){
         $sslcert->{ssl_cert_pk_type}="DH".$sslcert->{ssl_cert_bits};
      }
      if (grep(/PK_EC/,@certificate_type)){
         $sslcert->{ssl_cert_pk_type}="EC".$sslcert->{ssl_cert_bits};
      }

      my $issuerdn;
      eval('$issuerdn=Net::SSLeay::X509_NAME_print_ex('.
                      'Net::SSLeay::X509_get_issuer_name($cert),'.
                      'Net::SSLeay::XN_FLAG_DN_REV);');
      if ($@ eq ""){
         $sslcert->{ssl_cert_issuerdn}=$issuerdn;
         # Bugfix some formating errors in Net::SSLeay lib
         $sslcert->{ssl_cert_issuerdn}=~s#/street=#, street=#g;
         $sslcert->{ssl_cert_issuerdn}=~s#/postalCode=#, postalCode=#g;
      }


      if (main->can("Net::SSLeay::P_X509_get_signature_alg")){
         my $cert_signature_algo;
         eval('$cert_signature_algo=
            Net::SSLeay::OBJ_obj2txt(
               Net::SSLeay::P_X509_get_signature_alg($cert)
            );
         ');
         if ($@ eq ""){
            $sslcert->{ssl_cert_signature_algo}=$cert_signature_algo;
         }
      }
      return($sslcert);
   }

   sub preConnectReadServerCerts
   {
      my ($ok,$ctx_store,$certname,$error,$cert,$depth) = @_;
      my $sslcert=unpackCert($cert);
      $sslcert->{name}=$certname;
      push(@CERTBuffer,$sslcert);
      return(1);
   }

   if (!canTcpConnect($host,$port)){
      push(@{$r->{sslcert}->{log}},
          sprintf("Step0: generic tcp connect check %s:%s",$host,$port));
      $r->{sslcert}->{error}="can not tcp connect to $host:$port";
      $r->{sslcert}->{exitcode}=51;
      return;
   }

   #push(@{$r->{sslcert}->{log}},
   #    sprintf("Step1: try to connect to %s:%s SSLv23",$host,$port));

   $r->{sslcert}->{exitcode}=199;
   $r->{sslcert}->{exitmsg}="connect timeout after $ScriptTimeout seconds";
   @CERTBuffer=();

   my $step=0;

   if (!defined($sock) && $#CERTBuffer==-1){
      $step++;
      push(@{$r->{sslcert}->{log}},
          sprintf("Step${step}: try to connect to %s:%s auto",$host,$port));
      eval('$sock = IO::Socket::SSL->new(
         PeerAddr=>"$host:$port",
         SSL_verify_mode=>SSL_VERIFY_PEER,
         Timeout=>10,
         SSL_verify_callback=>\&preConnectReadServerCerts,
         SSL_session_cache_size=>0
      );');
      if ($@ ne ""){
         printf STDERR ("W5ProbeIP IO::Socket::SSL->new step${step} = $@\n");
      }
      if (!defined($sock)){
         push(@{$r->{sslcert}->{log}},
             sprintf("->result=%s",IO::Socket::SSL->errstr()));
      }
   }

   if (!defined($sock) && $#CERTBuffer==-1){
      $step++;
      push(@{$r->{sslcert}->{log}},
          sprintf("Step${step}: try to connect to %s:%s SSLv3",$host,$port));
      $ENV{"HTTPS_VERSION"}="3";
      eval('$sock = IO::Socket::SSL->new(
         PeerAddr=>"$host:$port",
         SSL_version=>"SSLv3",
         SSL_verify_mode=>SSL_VERIFY_PEER,
         Timeout=>10,
         SSL_verify_callback=>\&preConnectReadServerCerts,
         SSL_session_cache_size=>0
      );');
      if ($@ ne ""){
         printf STDERR ("W5ProbeIP IO::Socket::SSL->new step${step} = $@\n");
      }
      delete($ENV{"HTTPS_VERSION"});
      if (!defined($sock)){
         push(@{$r->{sslcert}->{log}},
             sprintf("->result=%s",IO::Socket::SSL->errstr()));
      }
   }


   if (!defined($sock) && $#CERTBuffer==-1){
      $step++;
      push(@{$r->{sslcert}->{log}},
          sprintf("Step${step}: try to connect to %s:%s TLSv12",$host,$port));
      eval('$sock = IO::Socket::SSL->new(
         PeerAddr=>"$host:$port",
         SSL_verify_mode=>SSL_VERIFY_PEER,
         Timeout=>5,
         SSL_version=>"TLSv12",
         SSL_verify_callback=>\&preConnectReadServerCerts,
         SSL_session_cache_size=>0
      );');
      if ($@ ne ""){
         printf STDERR ("W5ProbeIP IO::Socket::SSL->new step${step} = $@\n");
      }
      if (!defined($sock)){
         push(@{$r->{sslcert}->{log}},
             sprintf("->result=%s",IO::Socket::SSL->errstr()));
      }
   }


   if (!defined($sock) && $#CERTBuffer==-1){
      $step++;
      push(@{$r->{sslcert}->{log}},
          sprintf("Step${step}: try to connect to %s:%s TLSv11",$host,$port));
      eval('$sock = IO::Socket::SSL->new(
         PeerAddr=>"$host:$port",
         SSL_version=>"TLSv11",
         SSL_verify_mode=>SSL_VERIFY_PEER,
         Timeout=>10,
         SSL_verify_callback=>\&preConnectReadServerCerts,
         SSL_session_cache_size=>0
      );');
      if ($@ ne ""){
         printf STDERR ("W5ProbeIP IO::Socket::SSL->new step${step} = $@\n");
      }
      if (!defined($sock)){
         push(@{$r->{sslcert}->{log}},
             sprintf("->result=%s",IO::Socket::SSL->errstr()));
      }
   }


   if (!defined($sock) && $#CERTBuffer==-1){
      $step++;
      push(@{$r->{sslcert}->{log}},
          sprintf("Step${step}: try to connect to %s:%s SSLv2",$host,$port));
      eval('$sock = IO::Socket::SSL->new(
         PeerAddr=>"$host:$port",
         SSL_version=>"SSLv2",
         SSL_verify_mode=>SSL_VERIFY_PEER,
         SSL_verify_callback=>\&preConnectReadServerCerts,
         Timeout=>10,
         SSL_session_cache_size=>0
      );');
      if ($@ ne ""){
         printf STDERR ("W5ProbeIP IO::Socket::SSL->new step${step} = $@\n");
      }
      if (!defined($sock) && $#CERTBuffer==-1){
         push(@{$r->{sslcert}->{log}},
             sprintf("->result=%s",IO::Socket::SSL->errstr()));
      }
   }

   if (!defined($sock) && $#CERTBuffer==-1){
      $step++;
      push(@{$r->{sslcert}->{log}},
          sprintf("Step${step}: try to connect to %s:%s SSLv23",$host,$port));
      eval('my $sock = IO::Socket::SSL->new(
         PeerAddr=>"$host:$port",
         SSL_version=>"SSLv23",
         SSL_verify_mode=>SSL_VERIFY_PEER,
         Timeout=>10,
         SSL_verify_callback=>\&preConnectReadServerCerts,
         SSL_session_cache_size=>0
      );');
      if ($@ ne ""){
         printf STDERR ("W5ProbeIP IO::Socket::SSL->new step${step} = $@\n");
      }
      if (!defined($sock) && $#CERTBuffer==-1){
         push(@{$r->{sslcert}->{log}},
             sprintf("->result=%s",IO::Socket::SSL->errstr()));
      }
   }




   delete($r->{sslcert}->{exitcode}); # remove timeout flag
   delete($r->{sslcert}->{exitmsg});
   if (defined($sock)){
      my $cert = $sock->peer_certificate();
      if ($cert){
         my $C=unpackCert($cert);
         if (ref($C) eq "HASH"){
            foreach my $k (keys(%$C)){
               $r->{sslcert}->{$k}=$C->{$k};
            }
         }
      }
      if (1){
         my $certdump;
         if (!$sock->can("dump_peer_certificate")){
            push(@{$r->{sslcert}->{log}},
             "missing dump_peer_certificate in $sock to get cert details");
         }
         else{
            eval('$certdump=$sock->dump_peer_certificate();');
            $r->{sslcert}->{ssl_certdump}=$certdump if ($@ eq "");
         }
     
         my $version;
         if (!$sock->can("get_sslversion")){   # IO::Socket::SSL 1.964 needed!
            push(@{$r->{sslcert}->{log}},
             "missing get_sslversion in $sock to get cert details");
         }
         else{
            eval('$version = $sock->get_sslversion();');
            $r->{sslcert}->{ssl_version}=$version if ($@ eq "");
         }
     
         my $cipher;
         if (!$sock->can("get_cipher")){
            push(@{$r->{sslcert}->{log}},
             "missing get_cipher in $sock to get cert details");
         }
         else{
            eval('$cipher=$sock->get_cipher();');
            $r->{sslcert}->{ssl_cipher}=$cipher if ($@ eq "");
         }
      }

      if ($#CERTBuffer!=-1){
         $r->{sslcert}->{certtree}=\@CERTBuffer;
      }
      $r->{sslcert}->{method}="socket_peer_certifcate";
      $r->{sslcert}->{exitcode}=0;
   }
   elsif ($#CERTBuffer!=-1){
      $r->{sslcert}={%{$CERTBuffer[$#CERTBuffer]}};
      $r->{sslcert}->{certtree}=\@CERTBuffer;
      $r->{sslcert}->{method}="pre_verify_callback";
      $r->{sslcert}->{exitcode}=0;
   }
   else{
      $r->{sslcert}->{exitcode}=201;
   }
}

sub ciphertests
{
	my $success = 0;
	my $fail = 0;
	my $host = shift;
	my $port = shift;
	my $sversion = shift;
	my $hashref = shift;
	my $r = shift;
	my %hash = %$hashref;
   my $timeout=2;
	foreach my $hk (sort keys %hash) {
		#if ($verbose > 1) { print "Attempting connection to $host:$port using $_[0] $hk...\n"; }
                my $sslsocket;
		eval(' $sslsocket = IO::Socket::SSL->new(
			PeerAddr => $host,
			PeerPort => $port,
			Proto => "tcp",
			SSL_verify_mode => SSL_VERIFY_NONE,
			Timeout => $timeout, 
			SSL_version => $sversion, 
			SSL_cipher_list => $hk
		);');
		if ($sslsocket) {
         push(@{$r->{sslciphers}->{enabled}},"$sversion:".$hk);
		$sslsocket->close();
		} else {
         push(@{$r->{sslciphers}->{disabled}},"$sversion:".$hk);
		}
	}
}

sub do_SSLCIPHERS
{
   my $r=shift;

   my $host=$r->{target}->{host};
   my $port=$r->{target}->{port};

   $r->{operation}->{SSLCIPHERS}=1;

   eval('use IO::Socket::SSL qw(SSL_VERIFY_NONE);');
   eval('use Net::SSLeay;');
   eval('use IO::Socket::INET;');
   eval('use IO::Socket::INET6;');

   if (!canTcpConnect($host,$port)){
      push(@{$r->{sslcert}->{log}},
          sprintf("Step0: generic tcp connect check %s:%s",$host,$port));
      $r->{sslciphers}->{error}="can not tcp connect to $host:$port";
      $r->{sslciphers}->{exitcode}=199;
      return;
   }
   my $sock;
   eval('
      $sock = IO::Socket::SSL->new(   # first try a simple SSL Connect
      PeerAddr=>"$host:$port",
      SSL_verify_mode=>SSL_VERIFY_NONE,
      Timeout=>3,
      SSL_session_cache_size=>0
   );');
   if (defined($sock)){
      close($sock);
      $r->{sslciphers}->{sslconnect}=1;
      ciphertests($host,$port,'SSLv2', \%SSLTEST::ssl2ciphers,$r);
      ciphertests($host,$port,'SSLv3', \%SSLTEST::ssl3ciphers,$r);
      ciphertests($host,$port,'TLSv1', \%SSLTEST::ssl3ciphers,$r);
      ciphertests($host,$port,'TLSv11', \%SSLTEST::ssl3ciphers,$r);
      ciphertests($host,$port,'TLSv12', \%SSLTEST::tlsv12ciphers,$r);
   }
   else{
      $r->{sslciphers}->{sslconnect}=0;
   }

   $r->{sslciphers}->{exitcode}=0;
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
      $r->{ipconnect}->{exitcode}=0;
   }
   else{
      $r->{ipconnect}->{open}=0;
      $r->{ipconnect}->{exitcode}=51;
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
      Timeout => 15 
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
   $e="";
   my %formparam=(
      -method=>'POST',
      -target=>'OUT'
   );

   my %htmlparam=(
      -title => 'W5ProbeIP'
   );

   if ($q->param("submit") ne ""){
      $htmlparam{'-onLoad'}='document.forms[0].submit();';
   }

   print $q->header().
   $q->start_html(%htmlparam).

   "<div style='width:100%'>".
   h1({
      -style=>'Color: blue;'
   },'W5ProbeIP').
   h3({
      -style=>'Color: black;'
   },'ClientIP:'.$ENV{REMOTE_ADDR}).


   $q->start_form(%formparam).

   $q->textfield(-name=>'url',
      -value=>'',
      -size=>50,
      -maxlength=>256
   ).

   $q->checkbox_group(
      -name=>'operation',
      -values=>['SSLCERT','DNSRESOLV','REVDNS','IPCONNECT','SSLCIPHERS'],
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



package SSLTEST;
no strict;

#!/usr/bin/perl
# Originally based on Cryptonark by Chris Mahns, techstacks.com
# Written by Stephen Bradshaw, www.thegreycorner.com
# Visit the blog to see if a newer version of the tool has been released

# ToDo: Renegotiation checks, certificate checks.  May or may not decide to do this....
# PCI - no MD5 certs, no SGC certs, organisation (not domain) cert validation, revocation checking for each cert in chain, no insecure renegotiation, >1024 bit RSA/DSA keys in certs
# ISM - no insecure renegotiation, preference for SHA-2 certs, no MD5 certs


# History:
# Changes 0.1 - 0.1.1 : Minor bug fix and cosmetic changes
# Changes 0.1.1 - 0.1.2: More minor cosmetic changes, 
# Changes 0.1.2 - 0.2: More cosmetic changes, Windows Support, improved greppable output, Help text re OpenSSL, helpful errors for missing modules
# Changes 0.2 - 0.3: Added check to confirm listening service on host:port before running SSL tests, and added checks for friendly https cipher denials
# Changes 0.3 - 0.4: Minor bugfix with list command, all SSL2 ciphers now not listed as supported under pci
# Changes 0.4 - 0.5: Updated PCI and ISM supported ciphers, added TLVv1.1 and TLSv1.2 support, refreshed cipher list, disabled default certificate verification, updated help, added optional ISM checks

$version = "0.5";

#Copyright (c) 2010, Stephen Bradshaw
#All rights reserved.

#Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

#    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
#    * Neither the name of the organization nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Check that IO::Socket::SSL module is installed, explain what to do if not
if (not eval("require IO::Socket::SSL;")){
	noiosockethelp();
	die($noiosockethelp);
}

use Net::SSLeay;
use IO::Socket::INET;
use Getopt::Long;
Getopt::Long::Configure ("bundling");

# Separator values for cipher listing output
$gsep = "   ";
$sep = ", ";

# Search strings used to determine which ciphers are compliant with various standards, ISM 2014, PCI DSS 3.0
# ISM Must rules: No SSL, no renegotiation if secure renegotiation is unavailable, no anonymous DH, no MD5, no *DES, use AES
# ISM Should rules: Use current TLS, AES–GCM for symmetric encryption, use TLS imp w/ secure renegotiation, use ephemeral DH for key establishment over RSA and static DH, SHA-2 certs, SHA-2 MAC then SHA-1
# PCI: No SSL, crypto w/ >112 bits such as AES, 3DES, RSA, ECC, ElGamal, nothing below TLS 1.1 (depending on interpretation), No RC4, No MD5, effectively no TLSv1.0
$ismstring = 'NULL|^ADH-|DES-CBC-|MD5|RC|CAMELLIA|SEED|-DES-|SRP|PSK|AECDH-'; # Regex = No NULL cipher, No Null Auth, No single DES, No MD5, No RC ciphers, No Camellia, No Seed, No single DES, No SRP, No PSK, No Null auth
$pcistring = '^NULL|^ADH-|DES-CBC-|^EXP-|-DES-|MD5|AECDH-|RC4-'; # Regex = No NULL cipher, No Null Auth, No single DES, No Export encryption, No single DES, No MD5, No null auth, No RC4
$ismoptstring = 'SHA$|AES[0-9]{3}-S|^AES|^ECDH-'; # Regex = No SHA1, No non GCM AES, No non ephemeral DH *2 (these strings filter ciphers from openssl cipher spec 'kEECDH:kEDH')
$optviolation = 0;

# print this at end if an optional condition was violated and in verbose mode
$ismoptionalexpl = "Supported cipher list caused a conflict with an ISM should condition. These can include:\n";
$ismoptionalexpl .= "* Use of current version (1.2) of TLS\n* Use of AES-GCM where available\n* Ephemeral DH for key establishment over RSA and static DH\n* SHA2 MAC where available";


# search strings to find to detect friendly "update your browser" responses
$friendlystring = '^HTTP/1.1 401 Unauthorized';
$friendlydetected = 0;

GetOptions('h|help' => \$help, 'v|verbose+' => \$verbose, 'r|ssl2' => \$ssl2, 's|ssl3' => \$ssl3, 't|tls1' => \$tls1, 'b|tls11' => \$tls11, 'c|tls12' => \$tls12,  'x|timeout=i' => \$timeout, 'i|ism' => \$ism, 'p|pci' => \$pci, 'g|grep' => \$grep, 'l|list' => \$list, 'f|friend' => \$friend, 'n|nohelp' => \$nohelp, 'z|vercert' => \$vcert);

# Check which OS we are running on, use appropriate terminal colouring module
if ($^O =~ m/MSWin/) {
	if (not $grep) {
		# Win32::Console::ANSI is not commonly installed on Windows, so lets check for it and provide a workaround
		if (not eval("require Win32::Console::ANSI;")) { 
			die("Module Win32::Console::ANSI not found to support coloured terminal output.\nEither install this using your perl package manager, or enable greppable\noutput using the -g|--grep switch.\n\n");
		}		
	}
} else { # Assuming that all other OS'es support Term::ANSIColor properly - Linux does, others.... dunno
	use Term::ANSIColor qw(:constants);
}



if ($grep) { $sep = ";" }

# supported ssl2 and 3 and tls ciphers and a description (modified from output of command "openssl ciphers -v 'ALL:eNULL'")
%ssl2ciphers = (
	'DES-CBC3-MD5' => '3DES 168 bits, RSA Auth, MD5 MAC, RSA Kx',
	'DES-CBC-MD5' => 'DES 56 bits, RSA Auth, MD5 MAC, RSA Kx',
	'EXP-RC2-CBC-MD5' => 'RC2 40 bits, RSA Auth, MD5 MAC, RSA 512 Kx',
	'RC2-CBC-MD5' => 'RC2 128 bits, RSA Auth, MD5 MAC, RSA Kx',
	'EXP-RC4-MD5' => 'RC4 40 bits, RSA Auth, MD5 MAC, RSA 512 Kx',
	'RC4-MD5' => 'RC4 128 bits, RSA Auth, MD5 MAC, RSA Kx'
);



%ssl3ciphers = (
	'ECDHE-RSA-AES256-SHA' => 'AES 256 bits, RSA Auth, SHA1 MAC, ECDH Kx',
	'ECDHE-ECDSA-AES256-SHA' => 'AES 256 bits, ECDSA Auth, SHA1 MAC, ECDH Kx',
	'SRP-DSS-AES-256-CBC-SHA' => 'AES 256 bits, DSS Auth, SHA1 MAC, SRP Kx',
	'SRP-RSA-AES-256-CBC-SHA' => 'AES 256 bits, RSA Auth, SHA1 MAC, SRP Kx',
	'SRP-AES-256-CBC-SHA' => 'AES 256 bits, SRP Auth, SHA1 MAC, SRP Kx',
	'DHE-RSA-AES256-SHA' => 'AES 256 bits, RSA Auth, SHA1 MAC, DH Kx',
	'DHE-DSS-AES256-SHA' => 'AES 256 bits, DSS Auth, SHA1 MAC, DH Kx',
	'DHE-RSA-CAMELLIA256-SHA' => 'Camellia 256 bits, RSA Auth, SHA1 MAC, DH Kx',
	'DHE-DSS-CAMELLIA256-SHA' => 'Camellia 256 bits, DSS Auth, SHA1 MAC, DH Kx',
	'AECDH-AES256-SHA' => 'AES 256 bits, Null Auth, SHA1 MAC, ECDH Kx',
	'ADH-AES256-SHA' => 'AES 256 bits, Null Auth, SHA1 MAC, DH Kx',
	'ADH-CAMELLIA256-SHA' => 'Camellia 256 bits, Null Auth, SHA1 MAC, DH Kx',
	'ECDH-RSA-AES256-SHA' => 'AES 256 bits, ECDH Auth, SHA1 MAC, ECDH/RSA Kx',
	'ECDH-ECDSA-AES256-SHA' => 'AES 256 bits, ECDH Auth, SHA1 MAC, ECDH/ECDSA Kx',
	'AES256-SHA' => 'AES 256 bits, RSA Auth, SHA1 MAC, RSA Kx',
	'CAMELLIA256-SHA' => 'Camellia 256 bits, RSA Auth, SHA1 MAC, RSA Kx',
	'PSK-AES256-CBC-SHA' => 'AES 256 bits, PSK Auth, SHA1 MAC, PSK Kx',
	'ECDHE-RSA-DES-CBC3-SHA' => '3DES 168 bits, RSA Auth, SHA1 MAC, ECDH Kx',
	'ECDHE-ECDSA-DES-CBC3-SHA' => '3DES 168 bits, ECDSA Auth, SHA1 MAC, ECDH Kx',
	'SRP-DSS-3DES-EDE-CBC-SHA' => '3DES 168 bits, DSS Auth, SHA1 MAC, SRP Kx',
	'SRP-RSA-3DES-EDE-CBC-SHA' => '3DES 168 bits, RSA Auth, SHA1 MAC, SRP Kx',
	'SRP-3DES-EDE-CBC-SHA' => '3DES 168 bits, SRP Auth, SHA1 MAC, SRP Kx',
	'EDH-RSA-DES-CBC3-SHA' => '3DES 168 bits, RSA Auth, SHA1 MAC, DH Kx',
	'EDH-DSS-DES-CBC3-SHA' => '3DES 168 bits, DSS Auth, SHA1 MAC, DH Kx',
	'AECDH-DES-CBC3-SHA' => '3DES 168 bits, Null Auth, SHA1 MAC, ECDH Kx',
	'ADH-DES-CBC3-SHA' => '3DES 168 bits, Null Auth, SHA1 MAC, DH Kx',
	'ECDH-RSA-DES-CBC3-SHA' => '3DES 168 bits, ECDH Auth, SHA1 MAC, ECDH/RSA Kx',
	'ECDH-ECDSA-DES-CBC3-SHA' => '3DES 168 bits, ECDH Auth, SHA1 MAC, ECDH/ECDSA Kx',
	'DES-CBC3-SHA' => '3DES 168 bits, RSA Auth, SHA1 MAC, RSA Kx',
	'PSK-3DES-EDE-CBC-SHA' => '3DES 168 bits, PSK Auth, SHA1 MAC, PSK Kx',
	'ECDHE-RSA-AES128-SHA' => 'AES 128 bits, RSA Auth, SHA1 MAC, ECDH Kx',
	'ECDHE-ECDSA-AES128-SHA' => 'AES 128 bits, ECDSA Auth, SHA1 MAC, ECDH Kx',
	'SRP-DSS-AES-128-CBC-SHA' => 'AES 128 bits, DSS Auth, SHA1 MAC, SRP Kx',
	'SRP-RSA-AES-128-CBC-SHA' => 'AES 128 bits, RSA Auth, SHA1 MAC, SRP Kx',
	'SRP-AES-128-CBC-SHA' => 'AES 128 bits, SRP Auth, SHA1 MAC, SRP Kx',
	'DHE-RSA-AES128-SHA' => 'AES 128 bits, RSA Auth, SHA1 MAC, DH Kx',
	'DHE-DSS-AES128-SHA' => 'AES 128 bits, DSS Auth, SHA1 MAC, DH Kx',
	'DHE-RSA-SEED-SHA' => 'SEED 128 bits, RSA Auth, SHA1 MAC, DH Kx',
	'DHE-DSS-SEED-SHA' => 'SEED 128 bits, DSS Auth, SHA1 MAC, DH Kx',
	'DHE-RSA-CAMELLIA128-SHA' => 'Camellia 128 bits, RSA Auth, SHA1 MAC, DH Kx',
	'DHE-DSS-CAMELLIA128-SHA' => 'Camellia 128 bits, DSS Auth, SHA1 MAC, DH Kx',
	'AECDH-AES128-SHA' => 'AES 128 bits, Null Auth, SHA1 MAC, ECDH Kx',
	'ADH-AES128-SHA' => 'AES 128 bits, Null Auth, SHA1 MAC, DH Kx',
	'ADH-SEED-SHA' => 'SEED 128 bits, Null Auth, SHA1 MAC, DH Kx',
	'ADH-CAMELLIA128-SHA' => 'Camellia 128 bits, Null Auth, SHA1 MAC, DH Kx',
	'ECDH-RSA-AES128-SHA' => 'AES 128 bits, ECDH Auth, SHA1 MAC, ECDH/RSA Kx',
	'ECDH-ECDSA-AES128-SHA' => 'AES 128 bits, ECDH Auth, SHA1 MAC, ECDH/ECDSA Kx',
	'AES128-SHA' => 'AES 128 bits, RSA Auth, SHA1 MAC, RSA Kx',
	'SEED-SHA' => 'SEED 128 bits, RSA Auth, SHA1 MAC, RSA Kx',
	'CAMELLIA128-SHA' => 'Camellia 128 bits, RSA Auth, SHA1 MAC, RSA Kx',
	'PSK-AES128-CBC-SHA' => 'AES 128 bits, PSK Auth, SHA1 MAC, PSK Kx',
	'ECDHE-RSA-RC4-SHA' => 'RC4 128 bits, RSA Auth, SHA1 MAC, ECDH Kx',
	'ECDHE-ECDSA-RC4-SHA' => 'RC4 128 bits, ECDSA Auth, SHA1 MAC, ECDH Kx',
	'AECDH-RC4-SHA' => 'RC4 128 bits, Null Auth, SHA1 MAC, ECDH Kx',
	'ADH-RC4-MD5' => 'RC4 128 bits, Null Auth, MD5 MAC, DH Kx',
	'ECDH-RSA-RC4-SHA' => 'RC4 128 bits, ECDH Auth, SHA1 MAC, ECDH/RSA Kx',
	'ECDH-ECDSA-RC4-SHA' => 'RC4 128 bits, ECDH Auth, SHA1 MAC, ECDH/ECDSA Kx',
	'RC4-SHA' => 'RC4 128 bits, RSA Auth, SHA1 MAC, RSA Kx',
	'RC4-MD5' => 'RC4 128 bits, RSA Auth, MD5 MAC, RSA Kx',
	'PSK-RC4-SHA' => 'RC4 128 bits, PSK Auth, SHA1 MAC, PSK Kx',
	'EDH-RSA-DES-CBC-SHA' => 'DES 56 bits, RSA Auth, SHA1 MAC, DH Kx',
	'EDH-DSS-DES-CBC-SHA' => 'DES 56 bits, DSS Auth, SHA1 MAC, DH Kx',
	'ADH-DES-CBC-SHA' => 'DES 56 bits, Null Auth, SHA1 MAC, DH Kx',
	'DES-CBC-SHA' => 'DES 56 bits, RSA Auth, SHA1 MAC, RSA Kx',
	'EXP-EDH-RSA-DES-CBC-SHA' => 'DES 40 bits, RSA Auth, SHA1 MAC, DH(512) Kx',
	'EXP-EDH-DSS-DES-CBC-SHA' => 'DES 40 bits, DSS Auth, SHA1 MAC, DH(512) Kx',
	'EXP-ADH-DES-CBC-SHA' => 'DES 40 bits, Null Auth, SHA1 MAC, DH(512) Kx',
	'EXP-DES-CBC-SHA' => 'DES 40 bits, RSA Auth, SHA1 MAC, RSA(512) Kx',
	'EXP-RC2-CBC-MD5' => 'RC2 40 bits, RSA Auth, MD5 MAC, RSA(512) Kx',
	'EXP-ADH-RC4-MD5' => 'RC4 40 bits, Null Auth, MD5 MAC, DH(512) Kx',
	'EXP-RC4-MD5' => 'RC4 40 bits, RSA Auth, MD5 MAC, RSA(512) Kx',
	'ECDHE-RSA-NULL-SHA' => 'Null, RSA Auth, SHA1 MAC, ECDH Kx',
	'ECDHE-ECDSA-NULL-SHA' => 'Null, ECDSA Auth, SHA1 MAC, ECDH Kx',
	'AECDH-NULL-SHA' => 'Null, Null Auth, SHA1 MAC, ECDH Kx',
	'ECDH-RSA-NULL-SHA' => 'Null, ECDH Auth, SHA1 MAC, ECDH/RSA Kx',
	'ECDH-ECDSA-NULL-SHA' => 'Null, ECDH Auth, SHA1 MAC, ECDH/ECDSA Kx',
	'NULL-SHA' => 'Null, RSA Auth, SHA1 MAC, RSA Kx',
	'NULL-MD5' => 'Null, RSA Auth, MD5 MAC, RSA Kx'
);


%tlsv12ciphers = (
	'ECDHE-RSA-AES256-GCM-SHA384' => 'AESGCM 256 bits, RSA Auth, AEAD MAC, ECDH Kx',
	'ECDHE-ECDSA-AES256-GCM-SHA384' => 'AESGCM 256 bits, ECDSA Auth, AEAD MAC, ECDH Kx',
	'ECDHE-RSA-AES256-SHA384' => 'AES 256 bits, RSA Auth, SHA384 MAC, ECDH Kx',
	'ECDHE-ECDSA-AES256-SHA384' => 'AES 256 bits, ECDSA Auth, SHA384 MAC, ECDH Kx',
	'DHE-DSS-AES256-GCM-SHA384' => 'AESGCM 256 bits, DSS Auth, AEAD MAC, DH Kx',
	'DHE-RSA-AES256-GCM-SHA384' => 'AESGCM 256 bits, RSA Auth, AEAD MAC, DH Kx',
	'DHE-RSA-AES256-SHA256' => 'AES 256 bits, RSA Auth, SHA256 MAC, DH Kx',
	'DHE-DSS-AES256-SHA256' => 'AES 256 bits, DSS Auth, SHA256 MAC, DH Kx',
	'ADH-AES256-GCM-SHA384' => 'AESGCM 256 bits, Null Auth, AEAD MAC, DH Kx',
	'ADH-AES256-SHA256' => 'AES 256 bits, Null Auth, SHA256 MAC, DH Kx',
	'ECDH-RSA-AES256-GCM-SHA384' => 'AESGCM 256 bits, ECDH Auth, AEAD MAC, ECDH/RSA Kx',
	'ECDH-ECDSA-AES256-GCM-SHA384' => 'AESGCM 256 bits, ECDH Auth, AEAD MAC, ECDH/ECDSA Kx',
	'ECDH-RSA-AES256-SHA384' => 'AES 256 bits, ECDH Auth, SHA384 MAC, ECDH/RSA Kx',
	'ECDH-ECDSA-AES256-SHA384' => 'AES 256 bits, ECDH Auth, SHA384 MAC, ECDH/ECDSA Kx',
	'AES256-GCM-SHA384' => 'AESGCM 256 bits, RSA Auth, AEAD MAC, RSA Kx',
	'AES256-SHA256' => 'AES 256 bits, RSA Auth, SHA256 MAC, RSA Kx',
	'ECDHE-RSA-AES128-GCM-SHA256' => 'AESGCM 128 bits, RSA Auth, AEAD MAC, ECDH Kx',
	'ECDHE-ECDSA-AES128-GCM-SHA256' => 'AESGCM 128 bits, ECDSA Auth, AEAD MAC, ECDH Kx',
	'ECDHE-RSA-AES128-SHA256' => 'AES 128 bits, RSA Auth, SHA256 MAC, ECDH Kx',
	'ECDHE-ECDSA-AES128-SHA256' => 'AES 128 bits, ECDSA Auth, SHA256 MAC, ECDH Kx',
	'DHE-DSS-AES128-GCM-SHA256' => 'AESGCM 128 bits, DSS Auth, AEAD MAC, DH Kx',
	'DHE-RSA-AES128-GCM-SHA256' => 'AESGCM 128 bits, RSA Auth, AEAD MAC, DH Kx',
	'DHE-RSA-AES128-SHA256' => 'AES 128 bits, RSA Auth, SHA256 MAC, DH Kx',
	'DHE-DSS-AES128-SHA256' => 'AES 128 bits, DSS Auth, SHA256 MAC, DH Kx',
	'ADH-AES128-GCM-SHA256' => 'AESGCM 128 bits, Null Auth, AEAD MAC, DH Kx',
	'ADH-AES128-SHA256' => 'AES 128 bits, Null Auth, SHA256 MAC, DH Kx',
	'ECDH-RSA-AES128-GCM-SHA256' => 'AESGCM 128 bits, ECDH Auth, AEAD MAC, ECDH/RSA Kx',
	'ECDH-ECDSA-AES128-GCM-SHA256' => 'AESGCM 128 bits, ECDH Auth, AEAD MAC, ECDH/ECDSA Kx',
	'ECDH-RSA-AES128-SHA256' => 'AES 128 bits, ECDH Auth, SHA256 MAC, ECDH/RSA Kx',
	'ECDH-ECDSA-AES128-SHA256' => 'AES 128 bits, ECDH Auth, SHA256 MAC, ECDH/ECDSA Kx',
	'AES128-GCM-SHA256' => 'AESGCM 128 bits, RSA Auth, AEAD MAC, RSA Kx',
	'AES128-SHA256' => 'AES 128 bits, RSA Auth, SHA256 MAC, RSA Kx',
	'NULL-SHA256' => 'Null, RSA Auth, SHA256 MAC, RSA Kx'
);


# add the list of ssl3 ciphers to the tlsv1.2 list
while ( ($k,$v) = each(%ssl3ciphers) ) {
    $tlsv12ciphers{$k} = $v;
}




# Choose the appropriate check string based on selected compliance standard
if ($pci && $ism) {
	print "Both ISM and PCI-DSS standards selected, defaulting to more restrictive standard of ISM.\n";
	$checkstring = $ismstring;
	$checkoptstring = $ismoptstring;
} elsif ($ism) {
	$checkstring = $ismstring;
	$checkoptstring = $ismoptstring;
} elsif ($pci) {
	$checkstring = $pcistring;
} else { # Default to ISM standard if none specified
	$checkstring = $ismstring;
	$checkoptstring = $ismoptstring;
}

# If list option specified, just print out the ciphers and exit
if ($list) {
	$hostport = "";
	if ( (!$ssl2) && (!$ssl3) && (!$tls1) && (!$tls11) && (!$tls12) ) {
		print "SSLv2 Ciphers Supported...\n";
		foreach $hk (sort keys %ssl2ciphers) { checkcompliance($hk, $ssl2ciphers{$hk}, "SSLv2") }		
		print "SSLv3 Ciphers Supported...\n";
		foreach $hk (sort keys %ssl3ciphers) { checkcompliance($hk, $ssl3ciphers{$hk}, "SSLv3") }
		print "TLSv1 Ciphers Supported...\n";
		foreach $hk (sort keys %ssl3ciphers) { checkcompliance($hk, $ssl3ciphers{$hk}, "TLSv1") }
		print "TLSv1.1 Ciphers Supported...\n";
		foreach $hk (sort keys %ssl3ciphers) { checkcompliance($hk, $ssl3ciphers{$hk}, "TLSv11") }
		print "TLSv1.2 Ciphers Supported...\n";		
		foreach $hk (sort keys %tlsv12ciphers) { checkcompliance($hk, $tlsv12ciphers{$hk}, "TLSv12") }
	} else {
		if ($ssl2) { 
			print "SSLv2 Ciphers Supported...\n";
			foreach $hk (sort keys %ssl2ciphers) { checkcompliance($hk, $ssl2ciphers{$hk}, "SSLv2") }
		}
		if ($ssl3) {
			print "SSLv3 Ciphers Supported...\n";
			foreach $hk (sort keys %ssl3ciphers) { checkcompliance($hk, $ssl3ciphers{$hk}, "SSLv3") }
		}
		if ($tls1) {
			print "TLSv1 Ciphers Supported...\n";
			foreach $hk (sort keys %ssl3ciphers) { checkcompliance($hk, $ssl3ciphers{$hk}, "TLSv1") }
		}
		if ($tls11) {
			print "TLSv1.1 Ciphers Supported...\n";
			foreach $hk (sort keys %ssl3ciphers) { checkcompliance($hk, $ssl3ciphers{$hk}, "TLSv11") }
		}
		if ($tls12) {
			print "TLSv1.2 Ciphers Supported...\n";
			foreach $hk (sort keys %tlsv12ciphers) { checkcompliance($hk, $tlsv12ciphers{$hk}, "TLSv12") }
		}
	}
	exit;
}	
	

if ( !$ARGV[1] || $help ) {
	help();
}

$host = $ARGV[0];
$port = $ARGV[1];

if (!$timeout) { 
	$timeout = 4; # Default timeout of 4 seconds for connections
}

# HTTP request to send to server to check for friendly SSL errors
$httprequest = "GET / HTTP/1.1\r\nHost: $host\r\nConnection: close\r\n\r\n";

# Check if there is something listening on $host:$port
IO::Socket::INET->new(
	PeerAddr => $host,
	PeerPort => $port,
	Proto => 'tcp',
	Timeout => $timeout
) || die("Can't make a connection to $host:$port.\nAre you sure you specified the host and port correctly?\n\n");


if ($grep) { 
	print "Status(Compliant,Non-compliant,Disabled);Hostname:Port;SSL-Protocol;Cipher-Name;Cipher-Description\n"; 
	$hostport = "$host:$port$sep";
}

# Run the appropriate SSL tests
if ( (!$ssl2) && (!$ssl3) && (!$tls1) && (!$tls11) && (!$tls12) ) { # If no protocols specified, run all tests
	ciphertests('SSLv2', \%ssl2ciphers);
	ciphertests('SSLv3', \%ssl3ciphers);
	ciphertests('TLSv1', \%ssl3ciphers);
	ciphertests('TLSv11', \%ssl3ciphers);
	ciphertests('TLSv12', \%tlsv12ciphers);
} else {
	if ($ssl2) { ciphertests('SSLv2', \%ssl2ciphers); }
	if ($ssl3) { ciphertests('SSLv3', \%ssl3ciphers); }
	if ($tls1) { ciphertests('TLSv1', \%ssl3ciphers); }
	if ($tls11) { ciphertests('TLSv11', \%ssl3ciphers); }	
	if ($tls12) { ciphertests('TLSv12', \%tlsv12ciphers); }	
}


if ($optviolation && $verbose > 0)
{
	print $ismoptionalexpl;
}

# Called on event of a successful SSL connection from ciphertests(), used to determine compliant status of supported ciphers
sub checkcompliance{	
	if ( (! $friend) && (! $list) ){
		$socket = $_[3];    
		print $socket $httprequest;    
		$response = "";
		while (<$socket>) {
      			$response .= $_;
    		}
		if ($verbose > 2) {
			$n = "=" x 40;
			print "\n$n\nHTTP Request:\n$n\n$httprequest$n\nHTTP Response:\n$n\n$response\n$n\n\n";
		}
		if ($response =~ m/($friendlystring)/) {
			unsupported($_[0], $_[1], $_[2]);
			$friendlydetected = 1;
			return;
		}
	}
	if ( ($_[0] =~ /($checkstring)/) || ($_[2] eq 'SSLv2') || ($_[2] eq 'SSLv3') || ($_[2] eq 'TLSv1' && $pci) ) {
		if ($grep) {
			$description = $_[1];
			$description =~ s/( bits, |, )/,/g; # Shorten cipher description for greppable output
			print "N" . $sep . $hostport . $_[2] . $sep . $_[0] . $sep . $description . "\n";
		} elsif ($^O =~ m/MSWin/) {
			print "\e[1;31m" . $gsep . $_[0] . $sep . $_[1] . "\e[0m\n";
		} else {
			print RED, $gsep . $_[0] . $sep . $_[1] . "\n", RESET;
		}
	} elsif ( ($_[0] =~ /($checkoptstring)/) || ($_[2] eq 'TLSv1' && $ism) || ($_[2] eq 'TLSv11' && $ism) ) {
		$optviolation = 1;
		if ($grep) {
			$description = $_[1];
			$description =~ s/( bits, |, )/,/g;
			print "P" . $sep . $hostport . $_[2] . $sep . $_[0] . $sep . $description . "\n";
		} elsif ($^O =~ m/MSWin/) {
			print "\e[1;33m" . $gsep . $_[0] . $sep . $_[1] . "\e[0m\n";
		} else {
			print YELLOW, $gsep . $_[0] . $sep . $_[1] . "\n", RESET;
		}	
	} else {
		if ($grep) {
			$description = $_[1];
			$description =~ s/( bits, |, )/,/g;
			print "C" . $sep . $hostport . $_[2] . $sep . $_[0] . $sep . $description . "\n";
		} elsif ($^O =~ m/MSWin/) {
			print "\e[1;32m" . $gsep . $_[0] . $sep . $_[1] . "\e[0m\n";
		} else {
			print GREEN, $gsep . $_[0] . $sep . $_[1] . "\n", RESET;
		}
	}
	

}

# prints out text in red
sub rPrint {
	if ($^O =~ m/MSWin/) {
		print "\e[1;31m" . $_[0] . "\e[0m\n";
	} else {
		print RED, "$_[0]\n", RESET;
	}
}

# Called on event of a SSL connection error from ciphertests(), used for verbose output of unsupported ciphers
sub unsupported{
	if ($verbose) {		
		if ($grep) {
			$description = $_[1];
			$description =~ s/( bits, |, )/,/g;			
			print "D" . $sep . $hostport . $_[2] . $sep . $_[0] . $sep . $description . "\n";
		} elsif ($^O =~ m/MSWin32/) {
			print "\e[1;34m" . $gsep . $_[0] . $sep . $_[1] . " (Disabled)\e[0m\n";
		} else {
			print BLUE, $gsep . $_[0] . $sep . $_[1] . " (Disabled)\n", RESET;
		}
	}
}



if ( ($friendlydetected) && (! $nohelp)){
	friendlyerror();
}


# Help


sub friendlyerror {
	print STDERR <<FRIENDLYHELPTEXT;

One or more friendly SSL error messages were detected during the cipher 
testing process.  These will allow an SSL connection only for the purpose 
of providing a friendly error message to the client to update their browser
to a newer version.  The process used by this tool to detect these errors is
a little simplistic and potentially prone to errors, so if you see this
message I suggest you run the test with the triple verbose mode (-vvv) 
enabled to see the HTTP response from the server that has triggered this 
detection.  If you think that the detection is a false negative you can 
disable the check using the -f switch, and you can also inform the author of
this tool about the issue so this feature can be improved.

If you like the friendly option, and don't want to see this error message any 
more you can also prevent it from displaying in future by using the -n 
option.

See the help for more information. 
FRIENDLYHELPTEXT
}



sub noiosockethelp {
	$noiosockethelp = <<IOHELPTEXT;
It appears your Perl install does not include the IO::Socket::SSL module, 
which is required for this tool to work.

If you are running ActivePerl on Windows, this module, as well as the
dependant Net::SSLeay do not exist in the ActiveState Repositories, so 
you will need to go to a third party repository appropriate for your 
particular version of Perl.  The uwinnipeg repository is a good source,
just add it from the suggested list in the PPM Preferences window, or 
visit the following URL as a jumping off point to find the correct
repository for your version of perl (the below link is for perl 5.10
but there are links there for perl versions 5.6, 5.8 and 5.12):

http://cpan.uwinnipeg.ca/PPMPackages/10xx/

Don't forget to install "IO-Socket-SSL" AND "Net-SSLeay", and while you're 
there you may as well also install "Win32-Console-ANSI" to get coloured
terminal output (although it is possible to do without this if you use
greppable output).

If running perl on Linux, you can install the needed modules from CPAN.

In both cases you will also require OpenSSL on your system, and the version
of OpenSSL you use may effect your ability to connect to particular systems.
I have had good results with OpenSSL versions 0.9.8g and below but your 
mileage may vary.  Binary versions of OpenSSL for Windows can be obtained
from here, version 0.9.8e is suggested:

http://code.google.com/p/openssl-for-windows/ 

Stick the ssleay32.dll and libeay32.dll files in your path.

For Linux just use your distributions package management system or grab and 
install OpenSSL from source.
IOHELPTEXT
}


sub help {
	print <<HELPTEXT;
ssltest $version
Stephen Bradshaw, www.thegreycorner.com

Tests the provided SSL host to determine supported SSL/TLS protocols and
ciphers.  


USAGE:

$0 [options] host port
$0 [--pci|--ssl2|--ssl3|--tls1|--tls11|--tls12] --list


OPTIONS:

  -v|--verbose  Verbosity level. Use once to also list tested 
                ciphers that are not enabled on the target host.
                Use twice to also show when host connection 
                attempts are made.  Use three times to also show
                the output of HTTP responses from the server
                (used to detect friendly SSL messages - see the
                help for the -f switch below for more info). Its
                a good idea to turn on verbosity if you are
                getting unexpected results at any time.

  -r|--ssl2     Performs cipher tests for the sslv2 protocol.
                Default is all protocols (ssl2, ssl3, tls1, 
                tls11, tls12).

  -s|--ssl3     Performs cipher tests for the sslv3 protocol.
                Default is all protocols (ssl2, ssl3, tls1, 
                tls11, tls12).
                
  -t|--tls1     Performs cipher tests for the tlsv1 protocol.
                Default is all protocols (ssl2, ssl3, tls1, 
                tls11, tls12).
                
  -b|--tls11    Performs cipher tests for the tlsv1.1 protocol.
                Default is all protocols (ssl2, ssl3, tls1, 
                tls11, tls12).
                
  -c|--tls12    Performs cipher tests for the tlsv1.2 protocol.
                Default is all protocols (ssl2, ssl3, tls1, 
                tls11, tls12).

  -x|--timeout	Sets timeout value in seconds for connections.  
                Default 4.  Lower value for hosts that may not 
                properly close connections when an unsupported 
                protocol request is attempted.  Raise value for 
                slow links/hosts.

  -i|--ism      Marks enabled ciphers that are compliant with the 
                DSD ISMs mandatory 'Must' standards for use as an
                AACP (ISM 2014).  Default compliance standard used
                (as opposed to PCI).

  -p|--pci      Marks enabled ciphers that are compliant with 
                PCI-DSS standards.  Provided as an alternate 
                compliance standard to the DSD ISM.

  -g|--grep     Outputs in a semicolon ";" separated greppable 
                format, adds text for compliance status.  Use 
                when you need to write output to a text file and 
                you want compliance status to be included in 
                text format instead of just being represented by 
                terminal colour.  Fields ouput are Status;
                Hostname:Port;SSL-Protocol;Cipher-Name;
                Cipher-Description.  Compliance status will be one
                of C (Compliant), N (Non-compliant) or D (Disabled
                - only in verbose mode).

  -l|--list     Lists ciphers checked by this tool and exits, 
                with output colour coded to indicate compliance 
                status with the selected standard (pci or ism).  
                Host and port values do not need to be provided 
                when using this option, as no host connection is 
                made.  Purely informational, so you can see what
                ciphers are tested for, and which are deemed to be
                compliant with the various standards.

  -f|--friend   Disables checks for "friendly" SSL errors. 
                These checks are enabled by default, and will
                essentially try and detect any sites that allow an 
                SSL connection just so that they can tell you to
                get a newer browser.  At the moment this test is
                done very crudely by checking for a HTTP 1.1 401
                Unauthorised message in response to a GET request.
                This is quite possibly prone to false negatives, so
                the tool will warn you if such a detection has 
                occurred and will suggest that you run the test
                again in triple verbose mode to see the HTTP response
                from the server.  If the response does not appear
                to suggest that SSL is only supported for the 
                purpose of a warning the user to upgrade their 
                browser, you can run the test again with this
                switch to disable the friendly check.
                
  -n|--nohelp   Disables the display of helpful (but potentially 
                unwanted) messages, such as the warning about the 
                friendly SSL detection.
                
  -z|--vercert  Enables verification of certificates.  Otherwise,
                peer certificate verification is disabled.


If one or more protocol/s (SSLV2, SSLV3, TLSV1, TLSv11, TLSv12) are not 
specifically enabled, tests for all protocols will be performed.  If you 
know that a host does not support certain protocols (or does not properly 
close connection attempts made using particular protocols) you can only 
include tests for the protocols you are interested in to speed up the test.
If no compliance standard is specifically enabled, or if more than one 
is selected the default is to use the DSD ISM.

This tool is dependant on using OpenSSL to make SSL connections, and since 
OpenSSL sometimes changes the format of SSL requests in different versions
of the software, if you are having problems getting a connection to a
particular host you may be able to resolve them by using a later (or
earlier) version of OpenSSL.  On Windows you will be using the OpenSSL dll 
files, which are named ssleay32.dll and libeay32.dll and are probably in 
your path.  Check the version of these dll files to determine the OpenSSL 
version.  The binary versions of the dll files that the author uses with 
this tool can be obtained from:
http://code.google.com/p/openssl-for-windows/.

On Linux you will be using libssl, and you can check the version using your
systems package management software.

Some newer versions of OpenSSL and Net::SSLeay disable support for SSLv2 
which is needed to perform the SSLv2 checks - the checks will return false 
negatives if this is the case.  See the following for information on how 
to resolve this on Ubuntu, modifying as needed if you have a newer Ubuntu
version than 13.04

http://www.techstacks.com/howto/enable-sslv2-and-tlsv12-in-openssl-101c-on-ubuntu-1304.html
http://www.techstacks.com/howto/enable-sslv2-methods-in-netssleay.html

If on 64 bit architecture, you may also need to modify your deb files to 
change dependancies for libc6-amd64 to libc6 before installing.  Extract
the deb files, modify the DEBIAN/control file and rebuild the deb using 
'dpkg-deb --build <folder_name>'


EXAMPLES:

$0 -vvrsi test.example.com 443

Performs testing on host test.example.com port 443, using the sslv3 protocol
(-s), and sslv2 protocol (-r), matches responses against the cipher 
requirements in the ISM (-i) and provides double verbose output (-vv) where 
ciphers unsupported by the destination host and connection attempts are printed
to screen.

$0 --list 

Provides a list of all ciphers supported by the tool, colour coded to indicate 
which ones are considered to be compliant with the ISM.  Add the --pci switch 
to colour code listed ciphers for PCI compliance instead, or supply the --ssl2,
--ssl3 or --tls1 switches to only list ciphers appropriate to those protocols.


HELPTEXT
exit;
}



package main;

