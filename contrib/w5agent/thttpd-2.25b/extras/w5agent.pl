#!/usr/bin/env perl
use strict;
use POSIX;
use IPC::SysV;
use w5agent;

$0="w5agent.pl";
w5agent::readConfigIPC();

my %MODULE;
my @MODLST;

loadModList();

while(1){
    verifyModuleProcesses(); 
    my $ppid=getppid();
    exit(-1) if ($ppid==1);
    printf STDERR ("fifi ich warte PERL5LIB=%s W5CFGIPCID=%d\n",$ENV{PERL5LIB},$ENV{W5CFGIPCID});
    sleep(10);
}
exit(0);


verifyModuleProcesses
{
   foreach my $mod (@MODLST){
      if (!defined($MODULE{$mod})){
         $MODULE{$mod}={};
      }
      my $ctl=$MODULE{$mod};
      if (!defined($ctl->{pid}) || (kill(0,$ctl->{pid})!=1)){
      }

   }


}


sub loadModList
{
   my $moddir=$w5agent::config{MODDIR};
   if ($moddir eq ""){
      msg(ERROR,"no MODDIR definition found");
      exit(-1);
   } 
   if (! -d $moddir){
      msg(ERROR,"can't open MODDIR '%s'",$moddir);
      exit(-1);
   }
   if (opendir(D,$moddir)){
      foreach my $mod (grep { !/^\./ } readdir(D)){
         my $modname=$mod;
         $modname=~s/\.pm$//;
         push(@MODLST,$modname);
      }
   }
   msg(DEBUG,"found modules: %s",join(", ",@MODLST));
}

