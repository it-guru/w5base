package itil::W5Server::Cleanup;
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
            my %jobrec=(name=>"itil::W5Server::Cleanup.pm",
                        event=>"Cleanup.pm W5Server",
                        pid=>$$);
            my $jobid;
            if ($joblog->Ping()){
               $jobid=$joblog->ValidatedInsertRecord(\%jobrec);
            }
            $joblog->W5ServerCall("rpcCallEvent","ITIL_Cleanup");
            $self->CleanupIPEntries();
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
      sleep($sleep);
   }
}



sub CleanupIPEntries
{
   my $self=shift;

   my $ip=getModuleObject($self->Config,"itil::ipaddress");
   my $sys=getModuleObject($self->Config,"itil::system");
   my $itcl=getModuleObject($self->Config,"itil::itcloudarea");
   my $itclustsvc=getModuleObject($self->Config,"itil::lnkitclustsvc");

   $ip->SetFilter({ciactive=>\'0',cistatusid=>"<6"});
   my @ipl=$ip->getHashList(qw(ALL));
   msg(DEBUG,"start CleanupIPEntries");

   foreach my $iprec (@ipl){
      $ip->ResetFilter();
      msg(DEBUG,"cleanup ip $iprec->{name}");
      if ($iprec->{systemid} ne ""){ # validate system
         $sys->ResetFilter();
         $sys->SetFilter({id=>\$iprec->{systemid}});
         my ($sysrec,$msg)=$sys->getOnlyFirst(qw(id cistatusid mdate));
         if (!defined($sysrec)){  # cleanup invalid ip records
            msg(DEBUG,"delete $iprec->{name} with id $iprec->{id}");
            $ip->BulkDeleteRecord({id=>\$iprec->{id}});
         }
         else{
            my $d=CalcDateDuration($sysrec->{mdate},NowStamp("en")); 
            msg(DEBUG,"set ip $iprec->{name} to disposted of waste");
            if ($d->{totaldays}>6){
               $ip->ValidatedUpdateRecord($iprec,{cistatusid=>6},
                                          {id=>\$iprec->{id}});
            }
         }
      }
      elsif ($iprec->{itclustsvcid} ne ""){ # validate ClusterService
         $itclustsvc->ResetFilter();
         $itclustsvc->SetFilter({id=>\$iprec->{itclustsvcid}});
         my ($itclrec,$msg)=$itclustsvc->getOnlyFirst(qw(id itclustcistatusid 
                                                         mdate));
         if (!defined($itclrec)){  # cleanup invalid ip records
            msg(DEBUG,"delete $iprec->{name} with id $iprec->{id}");
            $ip->BulkDeleteRecord({id=>\$iprec->{id}});
         }
         else{
            #my $d=CalcDateDuration($itclrec->{mdate},NowStamp("en")); 
            #msg(DEBUG,"set ip $iprec->{name} to disposted of waste");
            #if ($d->{totaldays}>6){
            #  mdate check geht da nicht, da nicht in itclustsvc verfuegbar
               $ip->ValidatedUpdateRecord($iprec,{cistatusid=>6},
                                          {id=>\$iprec->{id}});
            #}
         }
      }
      elsif ($iprec->{itcloudareaid} ne ""){ # validate CloudArea
         $itcl->ResetFilter();
         $itcl->SetFilter({id=>\$iprec->{itcloudareaid}});
         my ($itclrec,$msg)=$itcl->getOnlyFirst(qw(id cistatusid mdate));
         if (!defined($itclrec)){  # cleanup invalid ip records
            msg(DEBUG,"delete $iprec->{name} with id $iprec->{id}");
            $ip->BulkDeleteRecord({id=>\$iprec->{id}});
         }
         else{
            my $d=CalcDateDuration($itclrec->{mdate},NowStamp("en")); 
            msg(DEBUG,"set ip $iprec->{name} to disposted of waste");
            if ($d->{totaldays}>6){
               $ip->ValidatedUpdateRecord($iprec,{cistatusid=>6},
                                          {id=>\$iprec->{id}});
            }
         }
      }
   }
   return(0);
}


sub reload
{
   my $self=shift;
   $self->{doForceCleanup}++;
}










1;


