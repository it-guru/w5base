package base::W5Server::Cleanup;
use strict;
use kernel;
use kernel::date;
use kernel::W5Server;
use vars (qw(@ISA));
@ISA=qw(kernel::W5Server);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub process
{
   my $self=shift;
   my $CleanupTime=$self->getParent->Config->Param("CleanupTime");
   my ($h,$m)=$CleanupTime=~m/^(\d+):(\d+)/;

   $h=0  if ($h<0);
   $h=23 if ($h>23);
   $m=0  if ($m<0);
   $m=59 if ($m>59);

   my $nextrun;

   while(1){
      if (defined($nextrun) && $nextrun<=time()){
         $self->doCleanup();
         sleep(1);
      }
      my $current=time();
      my ($year,$month,$day,$hour,$min,$sec)=Time_to_Date("GMT",$current);
      if (Date_to_Time("GMT",$year,$month,$day,$h,$m,0)<=time()){
         ($year,$month,$day)=Add_Delta_YMD("GMT",$year,$month,$day,0,0,1);
      }
      $nextrun=Date_to_Time("GMT",$year,$month,$day,$h,$m,0);
      msg(DEBUG,"(%s) next cleanup at %04d-%02d-%02d %02d:%02d:%02d",
                 $self->Self,$year,$month,$day,$h,$m,0);
      my $sleep=$nextrun-$current;
      msg(DEBUG,"(%s) sleeping %d seconds",$self->Self,$sleep);
      sleep($sleep);
      
   }
}

sub doCleanup
{
   my $self=shift;

   my $CleanupJobLog=$self->getParent->Config->Param("CleanupJobLog");

   $CleanupJobLog="<now-35d" if ($CleanupJobLog eq "");

   msg(DEBUG,"(%s) Processing doCleanup",$self->Self);
   my $j=$self->getParent->getPersistentModuleObject("base::joblog");
   if (defined($j)){
      $j->SetFilter({'mdate'=>$CleanupJobLog});
      $j->SetCurrentView(qw(ALL));
      $j->ForeachFilteredRecord(sub{
                                     $j->ValidatedDeleteRecord($_);
                                });
   }
}







1;


