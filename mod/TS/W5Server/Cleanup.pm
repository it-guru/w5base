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
   my $nextrun;

   my $opmode=$self->getParent->Config->Param("W5BaseOperationMode");
   my $ro=0;
   if ($opmode eq "readonly"){
      $ro=1;
   }

   while(1){
      if ((defined($nextrun) && $nextrun<=time()) || $self->{doForceCleanup}){
         $self->{doForceCleanup}=0;
         if (!$ro){
            $self->CleanupWorkflows();
         }
         sleep(1);
      }
      my $current=time();
      $nextrun=$current+40;
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


   return if (!defined($wf) || !defined($wfop));

   msg(DEBUG,"(%s) start cleanup",$self->Self);
   $wf->SetFilter({class=>[qw(
      itil::workflow::change itil::workflow::incident   itil::workflow::problem
      TS::workflow::change   TS::workflow::incident     TS::workflow::problem
      AL_TCom::workflow::change 
      AL_TCom::workflow::incident   
      AL_TCom::workflow::problem
      AL_TCom::workflow::P800   AL_TCom::workflow::P800special
      AL_TCom::workflow::riskmgmt)]
   });
   $wf->SetCurrentView(qw(ALL));
   $wf->SetCurrentOrder(qw(mdate));
   $wf->Limit(100);
   my $c=0;

   my ($rec,$msg)=$wf->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         msg(INFO,"process $rec->{id} class=$rec->{class}");
         $wfop->ValidatedDeleteRecord($rec);
         ($rec,$msg)=$wf->getNext();
      } until(!defined($rec));
   }
   msg(DEBUG,"(%s) end cleanup",$self->Self);
}

sub reload
{
   my $self=shift;
   $self->{doForceCleanup}++;
}










1;


