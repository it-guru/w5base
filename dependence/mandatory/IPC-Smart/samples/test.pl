#!/usr/bin/env perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use lib("../blib/lib","../blib/arch","./blib/lib","./blib/arch");
use IPC::Smart;

######################### End of black magic.

# If a semaphore or shared memory segment already uses this
# key, all tests will fail
$KEY = 192; 

$num++;
my $share = new IPC::Smart(-size=>40,-nolocking=>1);
print (defined $share ? "ok $num\n" : "not ok $num\n");
printf("Waiting... PID=$$ share=$share\n");
my $k=<STDIN>;
my $CHK='1234567890'.'1234567890'.'1234567890';
my $result = $share->store($CHK);
printf("... result share->store = %s\n",$result);
my $k=<STDIN>;
my $result = $share->fetch;
printf("... result share->fetch = %s\n",$result);
my $k=<STDIN>;

if (fork()==0){
   my $result = $share->store($CHK."-vom Task $$ -".$CHK);
   printf("... result share->store = %s  in PID=$$\n",$result);
   sleep(10);
   exit(0);
}
else{
   printf("Waiting...\n");
   sleep(1);
}

my $result = $share->fetch;
printf("... result share->fetch = %s  in $$\n",$result);
my $k=<STDIN>;

exit(0);

# Store value
#$num++;
#my $result = $share->store('maurice');
#print (defined $result ? "ok $num\n" : "not ok $num\n");
#
## Retrieve value
#$num++;
#print ($result eq 'maurice' ? "ok $num\n" : "not ok $num\n");
#
## Fragmented store
#$num++;
#my $result = $share->store( "X" x 200 );
#print (defined $result ? "ok $num\n" : "not ok $num\n");
#
## Check number of segments
#$num++;
#print ($share->num_segments == 3 ? "ok $num\n" : "not ok $num\n");
#
## Fragmented fetch
#$num++;
#my $result = $share->fetch;
#print ($result eq 'X' x 200 ? "ok $num\n" : "not ok $num\n");
#
#$num++;
#$share->store( 0 );
#my $pid = fork;
#defined $pid or die $!;
#if ($pid == 0) {
#  $share->destroy( 0 );
#  for(1..1000) {
#    $share->lock( LOCK_EX ) or die $!;
#    $val = $share->fetch;
#    $share->store( ++$val ) or die $!;
#    $share->unlock or die $!;
#  }
#  exit;
#} else {
#  for(1..1000) {
#    $share->lock( LOCK_EX) or die $!;
#    $val = $share->fetch;
#    $share->store( ++$val ) or die $!;
#    $share->unlock or die $!;
#  } 
#  wait;
#
#  $val = $share->fetch;
#  print ($val == 2000 ? "ok $num\n" : "not ok $num\n");
#}

