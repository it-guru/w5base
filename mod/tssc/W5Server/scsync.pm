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
         $self->CheckSyncJob("*");
         if ($forceSync>$forceSyncInterval){
            msg(DEBUG,"running scsync forceSync");
            $forceSync=0;
            #$self->CheckSyncJob("*");
         }
   #      while($self->CheckSyncJob()){}
      }
   }
}




sub CheckSyncJob
{
   my $self=shift;
   my $stateid=shift;
   my $wf=getModuleObject($self->Config,"base::workflow");
   my $wfop=$wf->Clone();
   printf STDERR ("W5Server now syncing data to sc ($self) wf=$wf\n");
   $wf->SetFilter({directlnkmode=>['w5base2extern','extern2w5base'],
                   directlnktype=>\'tssc::incident',
                   stateid=>$stateid});
   $wf->SetCurrentView(qw(id));
   my ($WfRec,$msg)=$wf->getFirst();
   if (defined($WfRec)){
      do{
         printf STDERR ("fifi pre Store\n");
         $wfop->nativProcess('extrefresh',{},$WfRec->{id});
         printf STDERR ("fifi post Store\n");
         ($WfRec,$msg)=$wf->getNext();
      } until(!defined($WfRec));
   }

   sleep(5);
   return(0);
}

sub reload
{
   my $self=shift;
printf STDERR ("reload $self\n");
   $self->{doCheckSyncJob}++;
}









1;


