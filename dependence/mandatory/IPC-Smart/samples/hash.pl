#!/usr/bin/env perl
use lib("../blib/lib","../blib/arch","./blib/lib","./blib/arch");
use IPC::Smart;
use Storable qw(freeze thaw);
use Data::Dumper;

my $share = new IPC::Smart(-size=>40);
if (!defined($share)){
   printf STDERR ("ERROR: can't create shared memory segement\n");
   exit(1);
}
printf("Parent Process (PID=$$) ready (share=$share)\n");
my $CHK='1234567890';
my $result = $share->store($CHK);
printf("... result (PID=$$) share->store = %s\n",$result);
my $result = $share->fetch;
printf("... result (PID=$$) share->fetch = %s\n",$result);

if (fork()==0){
   my $result = $share->store(freeze({name=>'Hartmut',vorname=>'Jo',pid=>$$}));
   printf("... result (PID=$$) share->store = %s  in PID=$$\n",$result);
   sleep(10);
   exit(0);
}
else{
   printf("Waiting...\n");
   sleep(1);
}
printf("... result (PID=$$)=%s\n",Dumper(thaw($share->fetch)));
for(my $c=0;$c<=10;$c++){
   printf("watched=%d\n",$share->watched);
   sleep(1);
}
exit(0);
