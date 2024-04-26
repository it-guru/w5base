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

   my $opmode=$self->getParent->Config->Param("W5BaseOperationMode");
   my $ro=0;
   if ($opmode eq "readonly"){
      $ro=1;
   }

   while(1){
      if ((defined($nextrun) && $nextrun<=time()) || $self->{doForceCleanup}){
         $self->{doForceCleanup}=0;
         if (!$ro){
            my $joblog=getModuleObject($self->getParent->Config,"base::joblog");
            my %jobrec=(name=>"base::W5Server::Cleanup.pm",
                        event=>"Cleanup.pm W5Server",
                        pid=>$$);
            my $jobid;
            if ($joblog->Ping()){
               $jobid=$joblog->ValidatedInsertRecord(\%jobrec);
            }

            $self->CleanupWasted();
            $self->doCleanup();
            $self->CleanupWorkflows();
            $self->CleanupHistory();
            msg(DEBUG,"Call CleanupLnkContactExp");
            my $bk=$joblog->W5ServerCall("rpcCallEvent","CleanupLnkContactExp");
            if ($jobid ne ""){
               if ($joblog->Ping()){
                  $joblog->ValidatedUpdateRecord({id=>$jobid},
                                                {exitcode=>"0",
                                                 exitmsg=>"done",
                                                 exitstate=>"ok"},
                                                {id=>\$jobid});
              }
            }
         }
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
      $self->FullContextReset();
      $sleep=60 if ($sleep>60);
      die('lost my parent W5Server process - not good') if (getppid()==1);
      my $targettime=time()+$sleep;
      do{
        #msg(DEBUG,"sleep ".time()." target=$targettime doForceCleanup $self->{doForceCleanup}");
        sleep(1);
      }while((time()<$targettime) && !$self->{doForceCleanup});
   }
}

sub doCleanup
{
   my $self=shift;

   my $CleanupJobLog=$self->getParent->Config->Param("CleanupJobLog");
   $CleanupJobLog="<now-84d" if ($CleanupJobLog eq "");
   msg(DEBUG,"(%s) Processing doCleanup base::joblog",$self->Self);
   my $j=getModuleObject($self->Config,"base::joblog");
   $j->BulkDeleteRecord({'mdate'=>$CleanupJobLog});

   my $CleanupInfoAbo=$self->getParent->Config->Param("CleanupInfoAbo");
   $CleanupInfoAbo="<now-56d" if ($CleanupInfoAbo eq "");
   msg(DEBUG,"(%s) Processing doCleanup base::infoabo",$self->Self);
   my $ia=getModuleObject($self->Config,"base::infoabo");
   $ia->BulkDeleteRecord({'expiration'=>$CleanupInfoAbo});

   my $CleanupUserLogon=$self->getParent->Config->Param("CleanupUserLogon");
   $CleanupUserLogon="<now-365d" if ($CleanupUserLogon eq "");
   msg(DEBUG,"(%s) Processing doCleanup base::userlogon",$self->Self);
   my $ul=getModuleObject($self->Config,"base::userlogon");
   $ul->BulkDeleteRecord({'logondate'=>$CleanupUserLogon});

   my $obj=getModuleObject($self->Config,"base::useraccount");
   $obj->CleanupUnunsedAPIKeys();
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

   my ($rec,$msg)=$inline->getFirst(unbuffered=>1);
   if (defined($rec)){
      my $op=$inline->Clone();
      do{
         msg(INFO,"delete inline attachment $rec->{name} $rec->{fid}");
         $op->ValidatedDeleteRecord($rec);
         ($rec,$msg)=$inline->getNext();
      } until(!defined($rec));
   }
}

sub CleanupWasted
{
   my $self=shift;
   my $CleanupWasted=$self->getParent->Config->Param("CleanupWasted");
   $CleanupWasted="<now-2Y" if ($CleanupWasted eq "");

   my @objlist=$self->getParent->globalObjectList();
   foreach my $obj (@objlist){
      my $o;
      eval('$o=getModuleObject($self->getParent->Config,$obj);');
      msg(DEBUG,"check for CleanupWasted $obj as '$o' instance");
      #if (!defined($o)){
      #   die("ERROR: can not create object $obj");
      #}
      if (defined($o) && $o->can("prepareToWasted")){
         my $idobj=$o->IdField();
         my $mdatefld=$o->getField("mdate");
         my $cistatusfld=$o->getField("cistatusid");
         if (defined($idobj) && defined($mdatefld) && defined($cistatusfld) &&
             $o->SelfAsParentObject() eq $obj){
            my $idname=$idobj->Name();
            my $uCleanupWasted=$CleanupWasted;
            if ($obj eq "base::user"){    # justified on person related data
               $uCleanupWasted="<now-1Y"; # the privacy forces a limit of
            }                             # 1 year is forced for storing 
                                          # old person related informations
            msg(DEBUG,"start CleanupWasted on $obj with mdate=$uCleanupWasted");
            $o->SetFilter({cistatusid=>\'6',mdate=>$uCleanupWasted});
            $o->SetCurrentView(qw(ALL));
            $o->SetCurrentOrder(qw(NONE));
            $o->Limit(10000);
            my ($rec,$msg)=$o->getFirst(unbuffered=>1);
            if (defined($rec)){
               my $op=$o->Clone();
               do{
                  if ($rec->{$idname} ne ""){
                     my $newrec={cistatusid=>7};
                     if ($op->prepareToWasted($rec,$newrec)){
                        $op->ValidatedUpdateRecord($rec,$newrec,{
                           $idname=>\$rec->{$idname}
                        });
                     }
                  }
                  ($rec,$msg)=$o->getNext();
               } until(!defined($rec));
            }
            $o->ResetFilter();
            $o->SetFilter({cistatusid=>\'7',mdate=>"<now-1Y"});
            #
            # TODO : Hartes Löschen aus der Datenbank. Da hab ich
            #        noch Angst davor!
            #
         }
      }
   }
}

sub CleanupHistory
{
   my $self=shift;
   my $hist=getModuleObject($self->getParent->Config,"base::history");
   my $CleanupHistory=$self->getParent->Config->Param("CleanupHistory");
   $CleanupHistory="<now-1095d" if ($CleanupHistory eq "");

   $hist->SetFilter({cdate=>$CleanupHistory});
   $hist->SetCurrentView(qw(ALL));
   $hist->SetCurrentOrder(qw(NONE));
   $hist->Limit(100000);

   my ($rec,$msg)=$hist->getFirst(unbuffered=>1);
   if (defined($rec)){
      my $op=$hist->Clone();
      do{
         msg(INFO,"delete history $rec->{id}");
         $op->ValidatedDeleteRecord($rec);
         ($rec,$msg)=$hist->getNext();
      } until(!defined($rec));
   }
}

sub CleanupWorkflows
{
   my $self=shift;
   my $wf=getModuleObject($self->getParent->Config,"base::workflow");
   my $wfop=getModuleObject($self->getParent->Config,"base::workflow");
   my $CleanupWorkflow=$self->getParent->Config->Param("AutoFinishWorkflow");
   $CleanupWorkflow="<now-84d" if ($CleanupWorkflow eq "");



   foreach my $stateid (qw(10 16 17)){
      $wf->SetFilter({stateid=>\$stateid,
                      mdate=>$CleanupWorkflow});
      $wf->SetCurrentView(qw(id closedate stateid class));
      $wf->SetCurrentOrder(qw(NONE));
      $wf->Limit(100000);
      my $c=0;

      my ($rec,$msg)=$wf->getFirst(unbuffered=>1);
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
                  $wf->SendRemoteEvent("upd",$rec,{stateid=>21,
                                                   closedate=>$closedate});
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

      my ($rec,$msg)=$wf->getFirst(unbuffered=>1);
      if (defined($rec)){
         do{
            msg(INFO,"process $rec->{id} class=$rec->{class}");
            if (1){
               my $now=NowStamp("en");
               my $postponeduntil=$rec->{postponeduntil};
               $postponeduntil=$now if ($postponeduntil eq "");
               my $d=CalcDateDuration($now,$postponeduntil);
               if (!defined($d) || $d->{totalseconds}<=0){
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

sub reload
{
   my $self=shift;
   msg(DEBUG," got reload");
   $self->{doForceCleanup}++;
}










1;


