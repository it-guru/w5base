#!/usr/bin/perl
use strict;
use Data::Dumper;
use Date::Calc qw(Now);
use LWP::UserAgent;
use Data::Dumper;
use HTTP::Request::Common;
use HTTP::Cookies;
use HTML::Parser;
use FileHandle;
use XML::Parser;
use Getopt::Long;
use Config;
my ($klsnr,$help,$base,$loginuser,$loginpass,$verbose,$ua,$XMLrequest);
my %P=("help"=>\$help,"base=s"=>\$base,
       "webuser=s"=>\$loginuser,"webpass=s"=> \$loginpass,"klsnr=s"=>\$klsnr,
       "verbose+"=>\$verbose);
my $optresult=XGetOptions(\%P,\&Help,undef,undef,".BLTChecker");

sub ERROR() {return("ERROR")}
sub WARN()  {return("WARN")}
sub DEBUG() {return("DEBUG")}
sub INFO()  {return("INFO")}

sub Help
{
   print(<<EOF);
bltcheck [options] 
  --verbose
  --webuser   sets the loginname 
  --webpass   sets the login password 
  --base      set the base url
  --store     stores the given user and password
  --klsnr     KLS Testnumber
EOF
   exit(-1);
}

sub msg
{
   my $type=shift;
   my $msg=shift;
   my $format="\%-6s \%s\n";
   my $t=sprintf("%02d:%02d:%02d",Now());

   if ($type eq "ERROR" || $type eq "WARN"){
      foreach my $submsg (split(/\n/,$msg)){
         printf STDERR ($format,$type." ".$t.":",$submsg);
      }
   }
   else{
      foreach my $submsg (split(/\n/,$msg)){
         printf STDOUT ($format,$type." ".$t.":",$submsg) if ($Main::VERBOSE ||
                                                                $type eq "INFO");
      }
   }
   return();
}

sub checkXML
{
   my $data=shift;
   our $chkstr=shift;
   our @databack;
   my $parser = new XML::Parser(Handlers => {Start => \&handle_start,
                                             Char  => \&handle_char,
                                             End   => \&handle_end});
   $parser->parse($data);
   sub handle_start
   {
     my ($p,$tag,%attr)=@_;
   }
   sub handle_char
   {
     my ($p,$tag,%a)=@_;
     if (($chkstr->{val} eq "$tag" || $chkstr->{val} eq "") && 
         ($p->current_element() eq $chkstr->{attr} || $p->current_element() eq "")){
        push(@databack,$tag);
     }
   }
   sub handle_end
   {
     my ($p,$tag,%attr)=@_;
   }
   return(\@databack);
}

sub checkHTML
{
   my $data=shift;
   our $cks=shift;
   our $datab;
   my $parser=new HTML::Parser;
   $parser->handler(start  => \&handle_start,"self,text,attr");
   $parser->handler(text   => \&handle_start,"self,text");
   $parser->handler(end    => \&handle_end,"self,text");
   $parser->parse($data);

   sub handle_start
   {
     my ($p,$text,@attr)=@_;
      $text=~s/\r\n//g;
      if ($text=~m/^($cks)/){
          $text=~s/^.*'(.*)'.*$/$1/g;
          $text=~s/\\"/"/g;
          $text=~s/\\n//g;
          $datab=$text;
      }
   }
   sub handle_text
   {
     my ($p,$text)=@_;
   #  msg(INFO,$text,);
   }
   sub handle_end
   {
     my ($p,$text)=@_;
   #  msg(INFO,$text,);
   }
   return(\$datab);
}

sub initAgent 
{
  # Init UserAgent
  $ua=new LWP::UserAgent(env_proxy=>0);
  my $jar=HTTP::Cookies->new(file => "$ENV{HOME}/.cookies.txt");
  $ua->cookie_jar($jar);
  $ua->timeout(30);
  $ua->{LoginUser}=$loginuser;
  $ua->{LoginPass}=$loginpass;
  return(0);
}

sub webRequest
{
  # load XML request
  my $method=shift;
  my $url=shift;
  my $ct=shift;
  my $content=shift;
  my ($req);
  msg(DEBUG,"load XML request form");
  if (lc($method) eq "post"){
     $req=POST($url,Content=>$content);
  }elsif(lc($method) eq "get"){
     $req=GET($url,Content=>$content);
  }else{
     msg(ERROR,"method $method not defined");
     exit(1);
  }
  $req->content_type("$ct") if (defined($ct));
  my $response=$ua->request($req);
  msg(DEBUG,"response from XML request form response is $response");
  if ($response->code ne "200"){
     msg(ERROR,"fail to get XML request form - code was ".$response->message);
     exit(1); 
  }else{
     msg(INFO,"request to $url successful ".$response->message);
  }
  return($response->content());
}

sub XGetOptions
{
   my $param=shift;
   my $help=shift;
   my $prestore=shift;
   my $defaults=shift;
   my $storefile=shift;
   my %param=@_;
   my $optresult;

   $storefile=XGetFQStoreFilename($storefile);
   my $store;
   $param->{store}=\$store;

   if (!($optresult=GetOptions(%$param))){
      if (defined($help)){
         &$help();
      }
      exit(1);
   }
   if (defined(${$param->{help}})){
      &$help();
      exit(0);
   }
   if (defined($prestore)){
      &$prestore($param);
   }
   my $sresult=XLoadStoreFile($storefile,$param);
   if ($sresult){
      printf STDERR ("ERROR: $!\n");
      exit(255);
   }
   if (!defined(${$param->{'webuser=s'}}) && !$param{noautologin}){
      my $u;
      while(1){
         printf("login user: ");
         $u=<STDIN>;
         $u=~s/\s*$//;
         last if ($u ne "");
      }
      ${$param->{'webuser=s'}}=$u;
   }
   if (!defined(${$param->{'webpass=s'}}) && !$param{noautologin}){
      my $p="";
      system("stty -echo 2>/dev/null");
      $SIG{INT}=sub{ system("stty echo 2>/dev/null");print("\n");exit(1)};
      while(1){
         printf("password: ");
         $p=<STDIN>;
         $p=~s/\s*$//;
         printf("\n");
         last if ($p ne "");
      }
      system("stty echo 2>/dev/null");
      $SIG{INT}='default';
      ${$param->{'webpass=s'}}=$p;
   }
   if (${$param->{store}}){
      my $sresult=XSaveStoreFile($storefile,$param);
      if ($sresult){
         printf STDERR ("ERROR: $!\n");
         exit(255);
      }
   }
   if (defined($defaults)){
      &$defaults($param);
   }
   if (defined($param->{'verbose+'}) &&
       ref($param->{'verbose+'}) eq "SCALAR" &&
       ${$param->{'verbose+'}}>0){
      $Main::VERBOSE=1;
      msg(INFO,"using parameters:");
      foreach my $p (sort(keys(%$param))){
         my $pname=$p;
         $pname=~s/=.*$//;
         $pname=~s/\+.*$//;
         msg(INFO,sprintf("%8s = '%s'",$pname,${$param->{$p}}));
      }
      msg(INFO,"-----------------");
   }
   return($optresult);
}

sub XGetFQStoreFilename
{
   my $storefile=shift;
   my $home;
   $storefile=".W5API" if ($storefile eq "");
   if ($Config{'osname'} eq "MSWin32"){
      $home=$ENV{'HOMEPATH'};
   }else{
      $home=$ENV{'HOME'};
   }
   if (!($storefile=~m/^\//) &&
       !($storefile=~m/\\/)){ # finding the home directory
      if ($home eq ""){
         eval('
            while(my @pline=getpwent()){
               if ($pline[1]==$< && $pline[7] ne ""){
                  $home=$pline[7];
                  last;
               }
            }
            endpwent();
         ');
      }
      if ($home ne ""){
         $storefile=$home."/".$storefile;
      }
   }
   $storefile=$ENV{'HOMEDRIVE'}.$storefile if ($Config{'osname'} eq "MSWin32");
   return($storefile);
}

sub XLoadStoreFile
{
   my $storefile=shift;
   my $param=shift;

   if (open(F,"<".$storefile)){

      while(my $l=<F>){
         $l=~s/\s*$//;
         if (my ($var,$val)=$l=~m/^(\S+)\t(.*)$/){
            if (exists($param->{$var})){
               if (!(${$param->{store}}) || $var eq "webuser=s" ||
                   $var eq "webpass=s"){
                  if (!defined(${$param->{$var}})){
                     ${$param->{$var}}=unpack("u*",$val);
                  }
               }
            }
         }
      }
      close(F);
   }
   return(0);
}

sub XSaveStoreFile
{
   my $storefile=shift;
   my $param=shift;

   if (open(F,">".$storefile)){
      foreach my $p (keys(%$param)){
         next if ($p=~m/^verbose.*/);
         next if ($p=~m/^help$/);
         next if ($p=~m/^store$/);
         if (defined(${$param->{$p}})){
            my $pstring=pack("u*",${$param->{$p}});
            $pstring=~s/\n//g;
            printf F ("%s\t%s\n",$p,$pstring);
         }
      }
      close(F);
   }
   else{
      return($?);
   }
   return(0);
}


sub KlsCheck
{
   my $wreq=webRequest("GET",$base."link_start_kls1.do");
   $XMLrequest=checkHTML($wreq,"var text='<.xml version");
   my $nr=checkXML(${$XMLrequest},{attr=>"bom_cc:Adress-ID"});
   if ($klsnr ne ""){
      ${$XMLrequest}=~s/$nr->[0]/$klsnr/g;
      $nr->[0]=$klsnr;
   }
   msg(INFO,"KLS Check with number ".$nr->[0]);
   webRequest("POST",$base."service.do",
              "application/x-www-form-urlencoded",
              [XMLString_Input=>${$XMLrequest}]);
   my $r=webRequest("GET",$base."start/xml.jsp");
   my $a=checkXML($r,{attr=>"kls:K_INFO",val=>"IAL-Kommunikation ist ok!"});
   if ($a->[1] eq "IAL-Kommunikation ist ok!"){
      msg(INFO,"KLS Check successful");
   }
}

# main 
initAgent();
KlsCheck();



# add user and password to useragent namespace
package LWP::UserAgent;
sub get_basic_credentials
{
   my ($self,$realm, $uri, $isproxy )=@_;
   return($self->{LoginUser},$self->{LoginPass});
}

1;
