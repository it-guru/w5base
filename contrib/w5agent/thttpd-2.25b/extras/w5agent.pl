#!/usr/bin/env perl
use strict;
use POSIX;
use IPC::SysV;
use w5agent;
use W5AgentModule;
use vars qw($AUTOLOAD);

$0="w5agent.pl";

BEGIN {
        *CORE::GLOBAL::hex = sub { printf("fifi hex\n"); };
    }

#sub AUTOLOAD {
#        my $program = $AUTOLOAD;
#        printf STDERR ("fifi AUTOLOAD $program\n");
#    }

w5agent::readConfigIPC();

my %MODULE;
my @MODLST;

loadModList();

while(1){
    verifyModuleProcesses(); 
    my $ppid=getppid();
    exit(-1) if ($ppid==1);
    sleep(10);
}
exit(0);


sub verifyModuleProcesses
{
   foreach my $mod (@MODLST){
      msg(DEBUG,"check module running of '$mod'");
      if (!defined($MODULE{$mod})){
         $MODULE{$mod}={};
      }
      my $ctl=$MODULE{$mod};
      if (defined($ctl->{pid})){
         waitpid($ctl->{pid},0);
      }
      if (!defined($ctl->{pid}) || (kill(0,$ctl->{pid})!=1)){
         if (defined($ctl->{pid})){
            msg(DEBUG,"restarting module $mod");
         }
         my $pid=fork() ;
         if (0==$pid){     # child
            $0="$mod\@w5agent.pl init";
            my $modobj;
            eval("use $mod;\$modobj=new $mod();");
            if (defined($modobj)){
               $0="$mod\@w5agent.pl Startup";
               if ($modobj->Startup()){
                  $0="$mod\@w5agent.pl MainLoop";
                  $modobj->MainLoop();
               }
            }
            else{
               print STDERR $@;
               exit(-1);
            }
            exit(0);
         }elsif ($pid>0){  # parent
            $ctl->{pid}=$pid;
         }else{
            msg(ERROR,"fail to fork module: $!");
            exit(-1);
         }
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

