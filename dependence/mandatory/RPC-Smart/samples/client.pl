#!/usr/bin/env perl
use lib("../lib","./lib",
        "../blib/lib","../blib/arch","./blib/lib","./blib/arch");
use RPC::Smart::Client;
use Data::Dumper;
use strict;

my $MyClient=new RPC::Smart::Client();

$MyClient->Connect();
my $method=shift(@ARGV);
my $res=$MyClient->Call($method,{ARGV=>[@ARGV]});
printf("%s",Dumper($res));
