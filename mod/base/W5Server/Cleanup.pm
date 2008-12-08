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
         $self->CleanupWorkflows();
       #  $self->CleanupInlineAttachments(); tests are needed !!!
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

   $CleanupJobLog="<now-84d" if ($CleanupJobLog eq "");

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


sub CleanupInlineAttachments
{
   my $self=shift;
   my $inline=getModuleObject($self->getParent->Config,"base::filemgmt");
   my $CleanupInline=$self->getParent->Config->Param("CleanupInline");
   $CleanupInline="<now-84d" if ($CleanupInline eq "");

   $inline->SetFilter({srcsys=>\'W5Base::InlineAttach',
                       viewlast=>$CleanupInline});
   $inline->SetCurrentView(qw(ALL));
   $inline->SetCurrentOrder(qw(NONE));
   $inline->Limit(100000);

   my ($rec,$msg)=$inline->getFirst();
   if (defined($rec)){
      my $op=$inline->Clone();
      do{
         msg(INFO,"delete inline attachment $rec->{name} $rec->{fid}");
         $op->ValidatedDeleteRecord($rec);
         ($rec,$msg)=$inline->getNext();
      } until(!defined($rec));
   }
}

sub CleanupWorkflows
{
   my $self=shift;
   my $wf=getModuleObject($self->getParent->Config,"base::workflow");
   my $wfop=getModuleObject($self->getParent->Config,"base::workflow");
   my $CleanupWorkflow=$self->getParent->Config->Param("CleanupWorkflow");
   $CleanupWorkflow="<now-84d" if ($CleanupWorkflow eq "");



   foreach my $stateid (qw(10 16 17)){
      $wf->SetFilter({stateid=>\$stateid,
                      mdate=>$CleanupWorkflow});
      $wf->SetCurrentView(qw(id closedate stateid class));
      $wf->SetCurrentOrder(qw(NONE));
      $wf->Limit(100000);
      my $c=0;

      my ($rec,$msg)=$wf->getFirst();
      if (defined($rec)){
         do{
            msg(INFO,"process $rec->{id} class=$rec->{class}");
            if (1){
               if ($wfop->Action->StoreRecord($rec->{id},"wfautofinish",
                   {translation=>'base::workflowaction'},"",undef)){
                  my $closedate=$rec->{closedate};
                  $closedate=NowStamp("en") if ($closedate eq "");

                  $wfop->UpdateRecord({stateid=>21,closedate=>$closedate},
                                      {id=>\$rec->{id}});
                  $wfop->{DB}->do("update wfkey set wfstate='21',".
                                  "closedate='$closedate' ".
                                  "where id='$rec->{id}'");
                  $wfop->StoreUpdateDelta({id=>$rec->{id},
                                           stateid=>$rec->{stateid}},
                                          {id=>$rec->{id},
                                           stateid=>21});
               }
            }
            ($rec,$msg)=$wf->getNext();
         } until(!defined($rec));
      }
   }
   foreach my $stateid (qw(5)){
      $wf->SetFilter({stateid=>\$stateid});
      $wf->SetCurrentView(qw(ALL));
      $wf->SetCurrentOrder(qw(NONE));
      $wf->Limit(1000);

      my ($rec,$msg)=$wf->getFirst();
      if (defined($rec)){
         do{
            msg(INFO,"process $rec->{id} class=$rec->{class}");
            if (1){
               my $now=NowStamp("en");
               my $postponeduntil=$rec->{postponeduntil};
               $postponeduntil=$now if ($postponeduntil eq "");
               my $d=CalcDateDuration($now,$postponeduntil);
               if (1 || !defined($d) || $d->{totalseconds}<=0){
                  if ($wfop->Action->StoreRecord($rec->{id},"reactivate",
                      {translation=>'base::workflowaction'},"",undef)){
                     $wfop->Store($rec,{stateid=>4,postponeduntil=>undef});
                  }
               }
            }
            ($rec,$msg)=$wf->getNext();
         } until(!defined($rec));
      }
   }

}








1;


