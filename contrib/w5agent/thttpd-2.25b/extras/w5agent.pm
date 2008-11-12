# This is the w5agent kernel
package w5agent;
use W5AgentModule;
use strict;


sub readConfigIPC
{
   my %config=();
   my $buff;
   shmread($ENV{W5CFGIPCID}, $buff, 0, 4096) || die "$!";
   substr($buff, index($buff, "\0")) = '';
   eval($buff);
   if ($@ eq ""){
      %w5agent::config=%config;
   }
   else{
      msg(ERROR,"can't load config from IPC shared memory");
      exit(-1);
   }
   msg(DEBUG,"config:\n%s",Dumper("w5agent::config",\%config));
}


1;
