package tssc::W5Server::scsync;
use strict;
use kernel;
use kernel::W5Server;
use SC::Customer::TSystems;

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
   my $forceSyncInterval=7200;
   #my $forceSyncInterval=5;
   my $forceSync=0;
   while(1){
      printf STDERR ("W5Server process ($self)\n");
      sleep(1);
      $forceSync++;
      if ($self->{doCheckSyncJob} || $forceSync>$forceSyncInterval){
         $self->{doCheckSyncJob}=0;
         if ($forceSync>$forceSyncInterval){
            msg(DEBUG,"running scsync forceSync");
            $forceSync=0;
            $self->returnSync();
         }
         while($self->CheckSyncJob()){}
      }
   }
}




sub returnSync
{
   my $self=shift;
   my $wf=getModuleObject($self->Config,"base::workflow");
   my $wfop=$wf->Clone();
   printf STDERR ("W5Server now syncing data to sc ($self) wf=$wf\n");
   $wf->SetFilter({step=>"tssc::workflow::sc*",
                   stateid=>6});
   $wf->SetCurrentView(qw(id 
                          wffields.scworkflowid wffields.screqlastsync mdate));
   $wf->SetCurrentOrder(qw(mdaterev));
   my ($WfRec,$msg)=$wf->getFirst();
   if (defined($WfRec)){
      do{
         $WfRec->{action}="screfresh";
         $wfop->nativProcess("screfresh",{},$WfRec->{id});
         ($WfRec,$msg)=$wf->getNext();
      } until(!defined($WfRec));
   }
   sleep(5);
   return(0);
}

sub CheckSyncJob
{
   my $self=shift;
   my $wf=getModuleObject($self->Config,"base::workflow");
   my $wfop=$wf->Clone();
   printf STDERR ("W5Server now syncing data to sc ($self) wf=$wf\n");
   $wf->SetFilter({step=>"tssc::workflow::screq::Wait4SC*"});
   $wf->SetCurrentView(qw(ALL));
   my ($WfRec,$msg)=$wf->getFirst();
   if (defined($WfRec)){
      do{
         my $okstep=$WfRec->{class};
         $okstep.="::SCworking";
         $wfop->Store($WfRec,{stateid=>3,
                              step=>$okstep});
         ($WfRec,$msg)=$wf->getNext();
      } until(!defined($WfRec));
   }

 


   sleep(5);
   return(0);
}

sub reload
{
   my $self=shift;
   $self->{doCheckSyncJob}++;
}









1;


