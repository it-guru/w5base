package TS::W5Server::Cleanup;
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
      if ((defined($nextrun) && $nextrun<=time()) || $self->{doForceCleanup}){
         $self->{doForceCleanup}=0;
         $self->CleanupWorkflows();
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
      $sleep=60 if ($sleep>60);
      die('lost my parent W5Server process - not good') if (getppid()==1);
      sleep($sleep);
      
   }
}

sub CleanupWorkflows
{
   my $self=shift;
   my $wf=getModuleObject($self->getParent->Config,"base::workflow");
   my $wfop=getModuleObject($self->getParent->Config,"base::workflow");



   $wf->SetFilter({class=>['itil::workflow::change','itil::workflow::incident'],
                   mdate=>"<now-365d"});
   $wf->SetCurrentView(qw(ALL));
   $wf->SetCurrentOrder(qw(NONE));
   $wf->Limit(10000);
   my $c=0;

   my ($rec,$msg)=$wf->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         msg(INFO,"process $rec->{id} class=$rec->{class}");
         $wfop->ValidatedDeleteRecord($rec);
         ($rec,$msg)=$wf->getNext();
      } until(!defined($rec));
   }
}

sub reload
{
   my $self=shift;
   $self->{doForceCleanup}++;
}










1;


