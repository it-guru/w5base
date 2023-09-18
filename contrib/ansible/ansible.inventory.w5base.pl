#!/usr/bin/perl
use lib qw(/opt/w5base2/lib /opt/w5base/lib);
use strict;                   
use W5Base::API;
use W5Kernel;
use JSON;

use Data::Dumper;

my $DefaultBase="https://w5base.net/w5base/auth/";
my ($help,$verbose,$loginuser,$loginpass,$quiet,$base,$lang,$xapi,$appl,$list);
my %P=("help"=>\$help,"base=s"=>\$base,"lang=s"=>\$lang,
       "webuser=s"=>\$loginuser,"webpass=s"=> \$loginpass,
       "X-API-Key=s"=>\$loginpass,
       "list"=>\$list,
       "verbose+"=>\$verbose,
       "application=s"=>\$appl);
my $optresult=XGetOptions(\%P,\&Help,undef,undef,".ansi.inventory.w5base");
my $ansiCacheFile=XGetFQStoreFilename(".ansi.inventory.w5base.cache.json");
my $ansiCacheLock=XGetFQStoreFilename(".ansi.inventory.w5base.cache.lock");

#######################################################################
# create connection config
#
my $apidebug=$verbose>=3 ? 1 : 0;
my $Config=createConfig($base,$loginuser,$loginpass,$lang,$apidebug);
if (!defined($Config)){
   msg(ERROR,"base or username/password is not valid");exit(1);
}
else{
   msg(DEBUG,"create of config ok");
}
msg(DEBUG,"verbose=$verbose");


my $flt=$appl;
if ($flt eq ""){
   msg(ERROR,"no filter specified");exit(3);
}
if (!$list){
   msg(INFO,"flt='$flt'");
}

if (my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
          $atime,$mtime,$ctime,$blksize,$blocks) = stat($ansiCacheLock)){
   if (time()-$mtime>60){ # remove stale lock
      unlink($ansiCacheLock);
   }
}



my $CacheAge;
my $asyncRefresh=0;

if ($list){
   if (-f $ansiCacheFile){
      my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
          $atime,$mtime,$ctime,$blksize,$blocks) = stat($ansiCacheFile);
      $CacheAge=time()-$mtime;
      if ($CacheAge>10 && $CacheAge<300 && !-f $ansiCacheLock){
         #printf STDERR ("Cache gets async refresh\n");
         open(F,">$ansiCacheLock") && close(F);
         $asyncRefresh=1;
      }
      if ($CacheAge<300){  # Cache Aging
         #printf STDERR ("Cache is fresher then 300 sec\n");
         if (open(F,"<$ansiCacheFile")){
            while(my $l=<F>){
               print $l;
            }
            close(F);
            if (!$asyncRefresh){
               exit(0);
            }
         }
      }
   }
}

if ($asyncRefresh){
   printf STDERR ("Split Cache prozess for async refresh\n");
   my $pid=fork();
   if ($pid==0){ 
      $SIG{INT}='IGNORE';
      $SIG{CHLD}='IGNORE';
      $SIG{HUP}='IGNORE';
      close(STDERR);
      close(STDOUT);
   }
   else{  # in parent
      $SIG{CHLD}='IGNORE';
      exit(0);
   }
}



#######################################################################
# load ModuleObject
#
my $objectname="itil::system";
my $sysobj=getModuleObject($Config,$objectname);
if (!defined($sysobj)){
   msg(ERROR,"can't load object $objectname");exit(2);
}
else{
   msg(DEBUG,"create of ModuleObject $sysobj ok");
}


#######################################################################
# do search
#

my %ansi;

$ansi{_meta}={
  hostvars=>{

  }
};


$sysobj->SetFilter({applications=>$flt,cistatusid=>4});
my $st=0;
my $blk=50;
my @l;
do{
   $sysobj->Limit($st+$blk,$st);
   my @dVars=qw(isprod istest isdevel iseducation isapprovtest isreference
                iscbreakdown 
                isapplserver isworkstation isinfrastruct isprinter isbackupsrv
                isdatabasesrv iswebserver ismailserver isnetswitch 
                isterminalsrv isnas isloadbalacer isclusternode isembedded
                fsystemalias kwords
                shortdesc);
   if (@l=$sysobj->getHashList(qw(name id ipaddresses applications),@dVars)){
      if ($#l==-1){
         msg(INFO,"no data found in $objectname matching fullname=$flt");
         exit(2);
      }
      else{
         foreach my $rec (@l){
             if (!$list){
                printf("%s\n -id=%s\n\n",UTF8toLatin1($rec->{name}),
                   UTF8toLatin1($rec->{id}));
             }
             $ansi{_meta}->{hostvars}->{$rec->{name}}->{W5BaseID}=$rec->{id};
             foreach my $dVar (@dVars){
                $ansi{_meta}->{hostvars}->{$rec->{name}}->{$dVar}=$rec->{$dVar};
             }
             if (ref($rec->{applications}) eq "SubListRecordArray"){
                my $l=$rec->{applications}->{record};
                $l=[$l] if (ref($l) ne "ARRAY");
                foreach my $arec (@$l){
                   my $appname=$arec->{appl};
                   $appname=~s/[^a-z0-9]/_/gi;
                   if (!exists($ansi{$appname})){
                      $ansi{$appname}={hosts=>[]};
                   }
                   if (!in_array($ansi{$appname}->{hosts},$rec->{name})){
                      push(@{$ansi{$appname}->{hosts}},$rec->{name});
                   }
                }
             }
         }
      }
   }
   $st+=$blk;
}while($#l==$blk-1);

if ($list){
   my $json=new JSON();
   $json->utf8(1);
   $json->pretty(1);

   if (!$asyncRefresh){
      print $json->encode(\%ansi);
   }
   if (open(F,">$ansiCacheFile")){
      print F $json->encode(\%ansi);
      close(F);
      unlink($ansiCacheLock);
   }
}

$sysobj->dieOnERROR();
exit(0);

#######################################################################
sub Help
{
   print(<<EOF);
$RealScript [options] FullnameFilter

   --verbose display more details of operation process
   --quiet   only errors would be displayed
   --base    base url of filemgmt (default: $DefaultBase)

   --webuser username
   --webpass password
   --store   stores the parameters (not help,verbose and store)
   --help    show this help

EOF
}
#######################################################################
exit(255);
