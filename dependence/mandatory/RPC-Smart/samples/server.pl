#!/usr/bin/env perl
use lib("../blib/lib","../blib/arch","./blib/lib","./blib/arch");
package MyServer;
use strict;
use vars qw(@ISA);
use RPC::Smart::Server;
use Data::Dumper;

@ISA=qw(RPC::Smart::Server);


sub rpcAsyncFunc
{
   my $self=shift;

   $self->async(sub {
      printf STDERR ("SLEEP($$): start\n");
      sleep(6);
      printf STDERR ("SLEEP($$): ende\n");
      return({MyAsyncVar=>'Hans',exitcode=>0});
   });
}

sub rpcSyncFunc
{
   my $self=shift;

   printf STDERR ("sync SLEEP($$): start\n%s",Dumper(\@_));
   sleep(5);
   printf STDERR ("sync SLEEP($$): ende\n");
   return({MySyncVar=>'Fritz',a=>[qw(ich bin ein array)],exitcode=>0});
}

sub rpcMulti
{
   my $self=shift;
   my $param=shift;
   my $mux=shift;
   my $io=shift;

   printf STDERR ("rpcMulti:%s\n",Dumper($param));
   my $opresult="hä?";
   if (ref($param->{'ARGV'}) eq "ARRAY"){
      $opresult=1;
      map({$opresult=$opresult*$_} @{$param->{ARGV}});
   }
   return({opresult=>$opresult,exitcode=>0});
}

sub configure_hook
{
   my $self=shift;
   $self->max_async(5);
}

package main;

#$0='MyServer';
MyServer->run();


