#!/usr/bin/env perl
use strict;
use POSIX;
use IPC::SysV;
use w5agent;
use Data::Dumper;


w5agent::readConfigIPC();

print Dumper(\%w5agent::config);

$0="w5agent.pl";
while(1){
    my $ppid=getppid();
    exit(-1) if ($ppid==1);
    printf STDERR ("fifi ich warte PERL5LIB=%s W5CFGIPCID=%d\n",$ENV{PERL5LIB},$ENV{W5CFGIPCID});
    sleep(10);
}
exit(0);


