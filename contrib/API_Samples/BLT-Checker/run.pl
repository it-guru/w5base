#!/usr/bin/perl
use lib qw(/opt/w5base2/lib /opt/w5base/lib);
use strict;
use W5Base::API;
use Data::Dumper;
use LWP::UserAgent;
use Data::Dumper;
use HTTP::Request::Common;
use HTTP::Cookies;
use HTML::Parser;
use FileHandle;

my ($help,$base,$loginuser,$loginpass,$verbose);

my %P=("help"=>\$help,"base=s"=>\$base,
       "webuser=s"=>\$loginuser,"webpass=s"=> \$loginpass,
       "verbose+"=>\$verbose);
my $optresult=XGetOptions(\%P,\&Help,undef,undef,".BLTChecker");


printf STDERR ("fifi help=$help\n");
printf STDERR ("fifi loginuser=$loginuser\n");
printf STDERR ("fifi loginpass=$loginpass\n");
printf STDERR ("fifi verbose=$verbose\n");
printf STDERR ("fifi base=$base\n");

sub Help
{
   printf("... hier kommt die Hilfe hin\n");
   exit(-1);
}



######################################################################
#
# Init UserAgent
#
my $ua=new LWP::UserAgent(env_proxy=>1);
my $jar=HTTP::Cookies->new(file => "$ENV{HOME}/.cookies.txt");
$ua->cookie_jar($jar);

$ua->timeout(60);
$ua->{LoginUser}=$loginuser;
$ua->{LoginPass}=$loginpass;


######################################################################
#
# Process login
#
msg(DEBUG,"LWP:UserAgent = $ua");

msg(INFO,"process login to service");
my $response=$ua->request(GET($base));

msg(DEBUG,"response from login request is $response");

if ($response->code ne "200"){
   msg(ERROR,"fail to get loginurl - code was ".$response->message);
   exit(1); 
}
#printf("result=%s\n",$response->content);

msg(INFO,"load XML request form");
my $response=$ua->request(GET($base."link_start_kls1.do"));
#my $response=$ua->request(GET($base."start/xml.jsp"));

msg(DEBUG,"response from XML request form response is $response");

if ($response->code ne "200"){
   msg(ERROR,"fail to get XML request form - code was ".$response->message);
   exit(1); 
}

msg(INFO,"process XML Request");
my $XMLrequest=<<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<bom:InlandsadresseLesen_Request xmlns:bom_cc="http://bom.telekom.de/cc" xmlns:bom="http://bom.telekom.de/svc">
 <Adresse>
  <bom_cc:Adress-ID>16229167</bom_cc:Adress-ID>
 </Adresse>
</bom:InlandsadresseLesen_Request>
EOF


my $req=POST($base."service.do",
             Content_Type=>'application/x-www-form-urlencoded',
             Content=>[XMLString_Input=>$XMLrequest]);

my $response=$ua->request($req);
msg(DEBUG,"response from XML request is $response");

if ($response->code ne "200"){
   msg(ERROR,"fail to get XML request response - code was ".$response->message);
   exit(1); 
}

#printf("result=%s\n",$response->content);


msg(INFO,"load XML response");
my $response=$ua->request(GET($base."start/xml.jsp"));
#my $response=$ua->request(GET($base."start/xml.jsp"));

msg(DEBUG,"response from XML response is $response");

if ($response->code ne "200"){
   msg(ERROR,"fail to get XML respnse- code was ".$response->message);
   exit(1); 
}

printf("result=%s\n",$response->content);

#eval('$html->parse($response->content);');
#if ($@ ne ""){
#   printf STDERR ("%s\n",$@);
#   printf STDERR ("ERROR: parsing loginurl=$loginurl\n");
#   exit(1); 
#}  

package LWP::UserAgent;

sub get_basic_credentials
{
   my ($self,$realm, $uri, $isproxy )=@_;
   return($self->{LoginUser},$self->{LoginPass});
}
