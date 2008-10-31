#!/usr/bin/env perl
use strict;
use POSIX;
use w5agent;

while(1){
    my $ppid=getppid();
    exit(-1) if ($ppid==1);
    printf STDERR ("fifi ich warte PERL5LIB=%s\n",$ENV{PERL5LIB});
    sleep(10);
}
exit(0);
