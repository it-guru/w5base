#!/usr/bin/perl
use strict;

my $F=$ARGV[0];

if (! -f $F){
   die(sprintf("ERROR: File '%s' does not exists\n",$F));
}

printf("start file '%s'\n",$F);
