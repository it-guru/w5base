#!/usr/bin/perl
use FindBin qw($Bin);
use File::Find;
use strict;
printf("Start Prozessing at $Bin from STDIN\n");

my $configdir=$Bin."/../conf";

my $OUTSTREAM;
my $MODE;

while(my $line=<>){
   $line=~s/\s*$//;
   if (my ($pid,$pnam)=$line=~m/^BEGIN:\s+projectroom\s+(\d+)\s+(.*)\s*$/){
      printf("Starting %s\n",$pid);
      if (! -d "$Bin/../projects/$pid"){
         system("svnadmin create '$Bin/../projects/$pid'");
      }
      symlink($pid,"$Bin/../projects/$pnam");
      $MODE="projectroom";
      open($OUTSTREAM,">$configdir/project.d/$pid");
   }
   elsif ($line=~m/^BEGIN:\s+groups/){
      $MODE="groups";
   }
   elsif($line=~m/^END:/){
      $MODE=undef;
      if (defined($OUTSTREAM)){
         close($OUTSTREAM);
         $OUTSTREAM=undef;
      }
   }
   else{
      if ($MODE eq "projectroom" && defined($OUTSTREAM)){
         printf $OUTSTREAM ("%s\n",$line);
      }
      if ($MODE eq "groups"){
         if (my ($grpname)=$line=~m/^(GRP\d+)\s=/){
            open($OUTSTREAM,">$configdir/group.d/$grpname");
            printf $OUTSTREAM ("%s\n",$line);
            close($OUTSTREAM);
         }
      }
   }
   printf(":%s\n",$line);
}
if (defined($OUTSTREAM)){
   close($OUTSTREAM);
}
my ($PROJECT,$GROUP,$ACCESS);
open($PROJECT,">$configdir/project");
open($GROUP,">$configdir/group");
printf $GROUP ("[groups]\n");
find({
        wanted=>sub {
           if (-f $File::Find::name && -r $File::Find::name && !($_=~m/^\./)){
              my $fout;
              $fout=$GROUP   if ($File::Find::dir=~m/group\.d$/);
              $fout=$PROJECT if ($File::Find::dir=~m/project\.d$/);
              if (defined($fout)){
                 if (open(F,"<$File::Find::name")){
                    while(my $l=<F>){print $fout $l;}
                    close(F);
                 }
              }
           }
        },
     },"$configdir/group.d","$configdir/project.d");
close($GROUP);
close($PROJECT);

open($PROJECT,"<$configdir/project");
open($GROUP,"<$configdir/group");
open($ACCESS,">$configdir/access.new");
while(my $l=<$GROUP>){print $ACCESS $l;}
print $ACCESS ("\n\n");
while(my $l=<$PROJECT>){print $ACCESS $l;}
close($ACCESS);
close($GROUP);
close($PROJECT);
rename("$configdir/access.new","$configdir/access");

printf("End Prozessing at $Bin from STDIN\n");
exit(0);
