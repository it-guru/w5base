#!/usr/bin/env perl
use lib("../lib","./lib",
        "../blib/lib","../blib/arch","./blib/lib","./blib/arch");
use RPC::Smart::Client;
use Data::Dumper;
use strict;

my $MyClient=new RPC::Smart::Client();

$MyClient->Connect();

my $res=$MyClient->Call("rpcSyncFunc",{v1=>"Hallo",v2=>"Wert"});

printf("direct result:\n%s",Dumper($res));
