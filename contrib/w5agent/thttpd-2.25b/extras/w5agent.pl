#!/usr/bin/env perl
use strict;
use POSIX;

while(1){
    my $ppid=getppid();
    exit(-1) if ($ppid==1);
    printf STDERR ("fifi ich warte\n");
    sleep(10);
}
exit(0);
