package itil::W5Server::CustContractCrono;
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
   my $CronoTime="22:00";
   my ($h,$m)=$CronoTime=~m/^(\d+):(\d+)/;


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
      if ((defined($nextrun) && $nextrun<=time()) || $self->{doForce}){
         $self->{doForce}=0;
         
         if (!$ro){
            my $joblog=getModuleObject($self->getParent->Config,"base::joblog");
            my %jobrec=(name=>"CustContractCrono.pm",
                        event=>"CustContractCrono.pm W5Server Start",
                        pid=>$$);
            my $jobid=$joblog->ValidatedInsertRecord(\%jobrec);

            $self->doCrono();
            if ($jobid ne ""){
               $joblog->ValidatedUpdateRecord({id=>$jobid},
                                             {exitcode=>"0",
                                              exitmsg=>"done",
                                              exitstate=>"OK"},
                                             {id=>\$jobid});
            }
         }
         sleep(1);
      }
      my $current=time();
      my ($year,$month,$day,$hour,$min,$sec)=Time_to_Date("GMT",$current);
      if (Date_to_Time("GMT",$year,$month,$day,$h,$m,0)<=time()){
         ($year,$month,$day)=Add_Delta_YMD("GMT",$year,$month,$day,0,0,1);
      }
      $nextrun=Date_to_Time("GMT",$year,$month,$day,$h,$m,0);
      msg(DEBUG,"(%s) next wakeup at %04d-%02d-%02d %02d:%02d:%02d",
                 $self->Self,$year,$month,$day,$h,$m,0);
      my $sleep=$nextrun-$current;
      msg(DEBUG,"(%s) sleeping %d seconds",$self->Self,$sleep);
      $self->FullContextReset();
      $sleep=60 if ($sleep>60);
      die('lost my parent W5Server process - not good') if (getppid()==1);
      sleep($sleep);
   }
}

sub doCrono
{
   my $self=shift;

   msg(DEBUG,"ok - start customer contract crono");

   my ($year,$month,$day,$hour,$min,$sec)=Time_to_Date("GMT",time());
   my $m=sprintf("%04d/%02d",$year,$month);
   my $mk=sprintf("(%02d/%04d)",$month,$year);


   my $wf=getModuleObject($self->Config,"base::workflow");

   $wf->SetFilter({eventend=>"$mk",isdeleted=>0});
   $wf->SetCurrentView(qw(class id affectedcontractid));
   $wf->SetCurrentOrder(qw(NONE));
   my %wfstat=();
   my %wfstatkeys=();

   my ($wfrec,$msg)=$wf->getFirst(unbuffered=>1);
   if (defined($wfrec)){
      do{
         my $contractid=$wfrec->{affectedcontractid};
         $contractid=[$contractid] if (ref($contractid) ne "ARRAY");
         foreach my $cid (@{$contractid}){
            if ($wfrec->{class}=~m/::change$/){
               $wfstat{$cid}->{TotalChangeWorkflowCount}++;
            }
            elsif ($wfrec->{class}=~m/::incident$/){
               $wfstat{$cid}->{TotalIncidentWorkflowCount}++;
            }
            elsif ($wfrec->{class}=~m/::problem$/){
               $wfstat{$cid}->{TotalProblemWorkflowCount}++;
            }
            foreach my $k (keys(%{$wfstat{$cid}})){
               $wfstatkeys{$k}++;
            }
         }
         my $d=Dumper($wfrec);
         ($wfrec,$msg)=$wf->getNext();
      } until(!defined($wfrec));
   }


   my $out=getModuleObject($self->Config,"itil::custcontractcrono");
   my $in=getModuleObject($self->Config,"itil::custcontract");
   my $sys=getModuleObject($self->Config,"itil::lnkapplsystem");
   my $swi=getModuleObject($self->Config,"itil::swinstance");
   $in->SetFilter({cistatusid=>\'4'});

   $in->SetCurrentView(qw(name fullname id applications));

   my ($rec,$msg)=$in->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         if (1){
            my %add=(activeApplications=>0);
            my %appl=();
            my %applid=();
            foreach my $appl (@{$rec->{applications}}){
               $add{activeApplications}++;
               $appl{$appl->{appl}}++;
               $applid{$appl->{applid}}++;
            }
            if (keys(%applid)){
               $sys->ResetFilter();
               $sys->SetFilter({applid=>[keys(%applid)],
                                systemcistatusid=>\'4'});
               my $syscount=0;
               my $logicalcpucount=0;
               foreach my $sysrec ($sys->getHashList(qw(id logicalcpucount))){
                  $syscount++;
                  $logicalcpucount+=$sysrec->{logicalcpucount};
               }
               $add{activeLogicalSystemCount}=$syscount;
               $add{activeLogicalCPUCount}=$logicalcpucount;
             
               $swi->ResetFilter();
               $swi->SetFilter({applid=>[keys(%applid)],
                                cistatusid=>\'4'});
               my $swinstancecount=0;
               my $dbcount=0;
               foreach my $irec ($swi->getHashList(qw(id swnature))){
                  $swinstancecount++;
                  if ($irec->{nature}=~
                      m/(mysql|mssql|oracle db|informix|postgres)/i){
                     $dbcount++;
                  }
               }
               $add{totalActiveInstances}=$swinstancecount;
               $add{activeDatabaseInstances}=$dbcount;
            }

            foreach my $k (keys(%wfstatkeys)){
               $add{$k}=$wfstat{$rec->{id}}->{$k};
            }

            my $reportkeyfilter={custcontractid=>\$rec->{id},month=>\$m};
            if (keys(%applid)<=0){
               $out->BulkDeleteRecord($reportkeyfilter); 
            }
            else{
               $out->ValidatedInsertOrUpdateRecord({
                     custcontractid=>$rec->{id},
                     name=>$rec->{name},
                     fullname=>$rec->{fullname},
                     applications=>join(", ",sort(keys(%appl))),
                     month=>$m,
                     additional=>\%add
                     },$reportkeyfilter);
            }
         }
         ($rec,$msg)=$in->getNext();
      } until(!defined($rec));
   }




   
}

sub reload
{
   my $self=shift;
   $self->{doForce}++;
}










1;


