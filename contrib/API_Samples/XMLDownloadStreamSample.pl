#!/usr/bin/env perl
use strict;
use LWP::Simple;
use XML::DOM;
use CGI;
use W5Base::API;


#
# Paramter Handling
#
my $DefaultBase="https://w5base.net/w5base/auth/";
my ($help,$verbose,$loginuser,$loginpass,$quiet,$base,$lang);
my %P=("help"=>\$help,"base=s"=>\$base,"lang=s"=>\$lang,
       "webuser=s"=>\$loginuser,"webpass=s"=> \$loginpass,
       "verbose+"=>\$verbose);
my $optresult=XGetOptions(\%P,\&Help,undef,undef,".XMLDownloadStreamSample");


my $url=$base."/base/MyW5Base/Result";
my $user=$loginuser;
my $pass=$loginpass;
my @view=qw(id class name stateid eventstart eventend
            affectedapplication affectedapplicationid
            wffields.eventmode
            wffields.eventdesciption
            wffields.eventstatclass);

# 
# build query parameter object
# 
my $cgi=new CGI({
                 MIRRORDAYS    =>1,
                 FormatAs      =>'XMLV01',
                 MyW5BaseSUBMOD=>'itil::MyW5Base::openeventinfo',
                 CurrentView   =>'('.join(",",@view).')'
                });

#
# build request and useragent object
#
my $ua=new LWP::UserAgent();
my $req=new HTTP::Request(GET=>$url.'?'.$cgi->query_string());
$req->authorization_basic($user,$pass);

#
# build XML Stream parser
#
my $xmlparser=new XML::Parser(
   Handlers=>{
      Start   => sub{
         my ($expat,$e)=@_;
         if ($e eq "record"){
            $expat->{curRecord}={};
            $expat->{curElement}=undef;
         }
         else{
            $expat->{curElement}=$e;
         }
      },
      Char =>sub{
         my ($expat,$str)=@_;
         if (defined($expat->{curRecord}) && 
             defined($expat->{curElement})){
            $expat->{curRecord}->{$expat->{curElement}}.=$str;
         }
      },
      End     => sub{
         my ($expat,$e)=@_;
         if ($e eq "record"){
            processRecord($expat->{curRecord});
            $expat->{curRecord}=undef; 
         }
      }
   });

#
# run request and process incomming data
#
my $blk;
my $res = $ua->request($req);
$xmlparser->parse($res->content);


sub Help
{
   printf("Help()\n");

}


#
# processing one single record
#
sub processRecord
{
   my $rec=shift;
   foreach my $k (keys(%$rec)){
      $rec->{$k}=~s/^\s*//;
      $rec->{$k}=~s/\s*$//;
      $rec->{$k}=~s/\n/ /g;
      printf("%-25s:%s\n",$k,$rec->{$k});
   }
   printf("--\n");
}


exit(0);
