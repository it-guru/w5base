package tssm::lib::io;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
use strict;
use kernel;
use kernel::date;
use Digest::MD5 qw(md5_base64);
use base 'Exporter';
our @EXPORT;
our @EXPORT_OK;

use constant {
    TABpref => 'DH_',
    SELpref => 'S_'
};

@EXPORT=qw(TABpref SELpref MandantenRestriction);
@EXPORT_OK=qw(identifyW5UserFromGroup identifyW5UserFromOperator);


sub MandantenRestriction
{
   my @l=qw(
      10001000.000600 10001000.001100 10001000.002200 10001000.004300
      10001000.004900 10001000.005100 10001000.008300 10001000.008400
      10001000.009000 10001000.900000 10001000.900400 10001002.999900
      20002053.000200 20002545.000300 20002657.000000 20002659.000000
      20002660.000000 20002661.000000 20002662.000000 20002663.000000
      20002664.000000 30003015.000100 30003015.000200 30003015.000400
      30003909.000000 40004232.000000 40004613.000200 40004787.000000
      40004800.000100 50005000.000900 50005000.001000 50005300.000100
      50005300.005000 80008012.000000 80008999.000000 90009998.000100
      10001000.000000 10001000.000200 10001000.000300 10001000.000400
      10001000.000500 10001000.001500 10001000.001800 10001000.003400
      10001000.004200 10001000.004400 10001000.004500 10001000.004600
      10001000.004700 10001000.005800 10001000.005900 10001000.006200
      10001000.006300 10001000.006400 10001000.006500 10001000.007000
      10001000.007400 10001000.007500 10001000.007600 10001000.007700
      10001000.007800 10001000.007900 10001000.008100 10001000.008200
      10001000.104300 10001000.900300 10001000.900500 10001001.900100
      10001002.000000 10001010.000000 30003863.000000 30003863.000100
      30003863.000200 30003863.000300 30003863.000400 30003863.000500
      40004787.900100 40004787.900200 40004787.900300 40004787.900400
      80008120.000000 80008120.000100 80008120.000200 
      80008120.000800
      10001000.000100
      10001000.004800 10001000.007200 20002549.000000 30003743.000000
      20002514.000000 30003486.000000 30003070.000000 20002053.004200
      30003635.000100 30003594.000100 20002532.000000 30003799.000000
      30003002.000300 90009999.000000 40004666.000000 20002278.000000
      40004787.899500 40004787.899600 40004787.899700 40004787.899800
      40004787.899900 40004787.902100 50005592.000000 40004762.000000
      20002640.000000 10001000.008900 20002556.000000 20002541.000000
      30003798.000000 30003792.000000 30003792.000100 30003792.000200
      30003792.000300 30003792.000400 30003792.000500 30003792.000600
      30003792.000700 30003773.000000 40004787.894900
      20002316.000000 30003173.000000 40004787.899100
      90009999.111100 90009999.000000 50005619.000000
      50005579.000000 50005864.000000 30003501.000000 10001000.010100
      40004787.897200
      40004799.000000
      40004787.900700 40004787.900800 40004787.900900 40004787.901100
      40004787.901200 40004787.901300 40004787.901400 40004787.901600
      40004787.901700 40004787.901800 40004787.901900 40004787.902600
      40004739.000000
  );
  return(@l);
}





sub InitScImportEnviroment
{
   my $self=shift;

   $self->{user}=getModuleObject($self->Config,"base::user");
   $self->{appl}=getModuleObject($self->Config,"itil::appl");
   $self->{wf}=getModuleObject($self->Config,"base::workflow");
}



sub ProcessServiceManagerRecord
{
   my $self=shift;
   my $selfname=shift;
   my $rec=shift;
   my $obj=shift;
   my $wf=$self->{wf};

   #msg(DEBUG,"chm=%s",Dumper($rec));
   my ($wfstorerec,$updateto,$relations);
   if (defined($rec->{changenumber})){
      ($wfstorerec,$updateto,$relations)=
         $self->mkChangeStoreRec($rec,$wf,$selfname,$obj);
   }
   if (defined($rec->{problemnumber})){
      ($wfstorerec,$updateto)=$self->mkProblemStoreRec($rec,$wf,$selfname,$obj);
   }
   if (defined($rec->{incidentnumber})){
      ($wfstorerec,$updateto)=$self->mkIncidentStoreRec($rec,$wf,$selfname,$obj);
   }
   if (defined($wfstorerec)){
      # create new
      my $chkname=$wfstorerec->{name};
      $chkname=trim(rmNonLatin1($wfstorerec->{name}));
      if ($chkname eq ""){ # siehe WF:13397595390001
         return;
      }
      #######################################################################
      # Buggi Timestamp handling for SM9 rotz
      $wfstorerec->{eventstart}=undef if ($wfstorerec->{eventstart}=~
                                          m/^4000-01-01 /);
      $wfstorerec->{eventend}=undef if ($wfstorerec->{eventend}=~
                                          m/^4000-01-01 /);
      if (!defined($wfstorerec->{eventstart}) &&
          defined($wfstorerec->{eventend})){
         $wfstorerec->{eventstart}=$wfstorerec->{eventend}
      }
      
      my $eventend=$wfstorerec->{eventend};
      my $eventstart=$wfstorerec->{eventstart};
      if ($eventend ne "" && $eventstart ne ""){
         my $duration=CalcDateDuration($eventstart,$eventend);
         if ($duration->{totalseconds}<0){ 
            $wfstorerec->{eventstart}=$wfstorerec->{eventend};
            # this fix sets the start to the end, if end is bevor start.
            # (this handles data junk from SM9)
         }
      }
      #######################################################################
      if (!defined($updateto) || $updateto eq ""){
         msg(DEBUG,"PROCESS: try to create new workflow entry");
         if (my $id=$wf->Store(undef,$wfstorerec)){
            msg(DEBUG,"workflow id=%s created",$id);
            #$self->CreateOrUpdateRelations($id,$relations); # not working
            # since 06/2015
         }
         else{
            msg(ERROR,"failed to create workflow :".$wfstorerec->{srcid});
         }
      }
      else{
         msg(DEBUG,"PROCESS: update workflow entry '$updateto'");
         $wf->SetFilter({id=>\$updateto});
         $wf->SetCurrentView(qw(ALL));
         $wf->ForeachFilteredRecord(sub{
            msg(DEBUG,"PROCESS: du update to '$updateto'");
            my $oldrec=$_;
            $wf->ValidatedUpdateRecord($oldrec,$wfstorerec,{id=>\$updateto});
            #$self->CreateOrUpdateRelations($updateto,$relations); # not
            # workin since 06/2015
         });
      }
   }
   else{
      msg(DEBUG,"no wfstorerec created");
   }
}

sub mkProblemStoreRec
{
   my $self=shift;
   my $rec=shift;
   my $wf=shift;
   my $selfname=shift;
   my $obj=shift;
   my $updateto;
   my $oldclass;
   my %wfrec=(srcsys=>$selfname);
   my $app=$self->getParent();
   $wf->SetFilter({srcsys=>\$selfname,srcid=>\$rec->{problemnumber}});
   my @oldrec=$wf->getHashList("id","class","stateid","step");
   if ($#oldrec==0){
      $updateto=$oldrec[0]->{id};
      $oldclass=$oldrec[0]->{class};
   }

   $wfrec{srcid}=$rec->{problemnumber};
   $wfrec{name}=$rec->{name};
   $wfrec{detaildescription}=$rec->{description};
   $wfrec{problemsolution}=$rec->{solution};
   $wfrec{stateid}=1;
   $wfrec{stateid}=21 if (lc($rec->{status}) eq "closed");
   $wfrec{additional}={
      ServiceManagerProblemNumber=>$rec->{problemnumber},
      ServiceManagerState=>$rec->{status},
      ServiceManagerAssignedTo=>$rec->{assignedto},
      ServiceManagerTriggeredBy=>$rec->{triggeredby},
      ServiceManagerHomeAssignment=>$rec->{homeassignment},
      ServiceManagerUrgency=>$rec->{urgency},
      ServiceManagerPriority=>$rec->{priority},
      ServiceManagerImpact=>$rec->{impact},
      ServiceManagerSysModTime=>$rec->{sysmodtime},
      ServiceManagerSoftwareID=>$rec->{softwareid},
      ServiceManagerCreator=>$rec->{creator},
   };
   if (($rec->{priority}=~m/^\d+$/) &&
       $rec->{priority}>0 && $rec->{priority}<10){
      $wfrec{prio}=int($rec->{priority});
   }
   if (!($rec->{devicename}=~m/^\s*$/)){
      $wfrec{additional}->{ServiceManagerDeviceName}=$rec->{devicename};
   }
   if (!($rec->{deviceid}=~m/^\s*$/)){
      $wfrec{additional}->{ServiceManagerDeviceID}=$rec->{deviceid};
   }

   $wfrec{eventstart}=$rec->{createtime};
   $wfrec{eventend}=$rec->{closetime};
   $wfrec{mdate}=$rec->{sysmodtime};
   $wfrec{createdate}=$rec->{createtime};
   $wfrec{closedate}=$rec->{closetime};
   $wfrec{openuser}=undef;
   $wfrec{openusername}=undef;
   if ($rec->{creator}=~m/^[a-z0-9_-]{1,8}$/i){
      $wfrec{openusername}="wiw/".lc($rec->{creator});
      $self->{user}->SetFilter({posix=>\$rec->{creator}});
      my $userid=$self->{user}->getVal("userid");
      $wfrec{openuser}=$userid if (defined($userid));
   }
   my ($system,$systemid,
       $anames,$aids,$primanames,$primaids,
       $contrnames,$contrids,$contrmods,$mandator,$mandatorid,
       $costcenter,$customername,$responseteam,$businessteam,
       $truecustomerprio)=
               $self->extractAffectedApplication($rec);
   $wfrec{affectedsystemid}=$systemid;
   $wfrec{affectedsystem}=$system;
   $wfrec{affectedapplicationid}=$aids;
   $wfrec{affectedapplication}=$anames;
   $wfrec{affectedcontractid}=$contrids;
   $wfrec{customercontractmod}=$contrmods;
   $wfrec{affectedcontract}=$contrnames;
   $wfrec{involvedresponseteam}=$responseteam;
   $wfrec{involvedbusinessteam}=$businessteam;
   $wfrec{involvedcustomer}=$customername;
   $wfrec{involvedcostcenter}=$costcenter;
   $wfrec{mandator}=$mandator;
   $wfrec{mandatorid}=$mandatorid;
   $wfrec{class}=$oldclass;
   if (defined($updateto) && $#{$aids}!=-1 && 
       $oldclass eq "itil::workflow::problem"){
      $wf->UpdateRecord({class=>'TS::workflow::problem'},
                        {id=>$updateto});
      #printf STDERR ("WARN: class changed on id $updateto\n");
      $wfrec{class}='TS::workflow::problem';
      $oldclass='TS::workflow::problem';
   }
   if (!defined($updateto)){
      if ($#{$aids}!=-1){
         $wfrec{class}='TS::workflow::problem';
      }
      else{
         $wfrec{class}='itil::workflow::problem';
         $wfrec{stateid}=21;           # non AL DTAG is automaticly finished
      }
   }
   if (!defined($updateto)){
      $wfrec{openuser}=undef;
      my $posix=lc($rec->{requestedby});
      $wfrec{openusername}="wiw/$posix";
      $self->{user}->ResetFilter();
      $self->{user}->SetFilter({posix=>\$posix});
      my $userid=$self->{user}->getVal("userid");
      $wfrec{openuser}=$userid if (defined($userid));
      $wfrec{step}='itil::workflow::problem::extauthority';
   }
   $wfrec{srcload}=$self->detectSrcLoad($rec->{sysmodtime},
                                        $rec->{problemnumber},$rec);
   return(\%wfrec,$updateto);
}

sub mkChangeStoreRec
{
   my $self=shift;
   my $rec=shift;
   my $wf=shift;
   my $selfname=shift;
   my $obj=shift;
   my $updateto;
   my $oldclass;
   my %wfrec=(srcsys=>$selfname);
   my $app=$self->getParent();
   $wf->ResetFilter();
   $wf->SetFilter({srcsys=>\$selfname,srcid=>\$rec->{changenumber}});
   my @oldrec=$wf->getHashList("id","class","step",
                               "stateid","headref");
   msg(DEBUG,"found on oldsearch %s",Dumper(\@oldrec));
   if ($#oldrec==0){
      $updateto=$oldrec[0]->{id};
      $oldclass=$oldrec[0]->{class};
   }
   my $ServiceManagerTaskCount="?";
   my $tasks=$rec->{tasks};

   if (ref($tasks) eq "ARRAY"){
      $ServiceManagerTaskCount=$#{$tasks}+1;
   }

   $wfrec{srcid}=$rec->{changenumber};
   $wfrec{name}=$rec->{name};
   $wfrec{changedescription}=$rec->{description};
   #$wfrec{changedescription}=~s/^-{10}description via Interface//;

   $wfrec{stateid}=8; # init
   if (lc($rec->{status}) eq 'open') {
      $wfrec{stateid}=1  if ($rec->{phase}=~m/^30/);
      $wfrec{stateid}=2  if ($rec->{phase}=~m/^40/);
      $wfrec{stateid}=4  if ($rec->{phase}=~m/^50/);
      $wfrec{stateid}=18 if ($rec->{phase}=~m/^60/);
   }
   $wfrec{stateid}=17 if (lc($rec->{status}) eq "closed");

   my $chmmgr_pending;

   if ($wfrec{stateid}==2) {
      if (($#oldrec==0 && $oldrec[0]->{stateid}==1) ||
          $#oldrec==-1                              ||
          !defined($oldrec[0]->{headref}->{approvalphaseentry})) {
         $wfrec{approvalphaseentry}=$rec->{sysmodtime};
      }

      # pending approvals of TelIT Changemanager
      my @chm2approve=grep(/^TIT\..*\.CHM/,map({$_->{groupname}}
                                               @{$rec->{approvalsreq}}));
      $chmmgr_pending=join(', ',@chm2approve);
   }

   $wfrec{additional}={
      ServiceManagerChangeNumber=>$rec->{changenumber},
      ServiceManagerCategory=>$rec->{category},
      ServiceManagerState=>$rec->{status},
      ServiceManagerPhase=>$rec->{phase},
      ServiceManagerApprovalState=>$rec->{approvalstatus},
      ServiceManagerRequestedBy=>$rec->{requestedby},
      ServiceManagerAssignedTo=>$rec->{assignedto},
      ServiceManagerChmMgr=>$rec->{chmmgrgrp},
      ServiceManagerTaskCount=>$ServiceManagerTaskCount,
      ServiceManagerProject=>$rec->{project},
      ServiceManagerType=>$rec->{type},
      ServiceManagerRisk=>$rec->{risk},
      ServiceManagerUrgency=>$rec->{urgency},
      ServiceManagerComplexity=>$rec->{complexity},
      ServiceManagerCriticality=>$rec->{criticality},
      ServiceManagerImpact=>$rec->{impact},
      ServiceManagerWorkStart=>$rec->{workstart},
      ServiceManagerWorkEnd=>$rec->{workend},
      ServiceManagerWorkDuration=>$rec->{workduration},
      ServiceManagerSysModTime=>$rec->{sysmodtime}
   };
   msg(DEBUG,"===========================:");
   my $relations;
   my $relationupd=0;
   my $relationupd=1;

   #
   #
   #  Anscheinend über die SM9 Oberfläche nicht mehr ausfüllbar bzw. notwendig
   #if ($rec->{exsrcid} ne ""){
   #   $wfrec{additional}->{ServiceManagerExternChangeID}=$rec->{exsrcid};
   #   msg(DEBUG,"ServiceManager ExternChangeID:".$rec->{exsrcid});
   #}
   #if ($#oldrec==0){
   #   if ($oldrec[0]->{additional}->{ServiceManagerExternChangeID}->[0] ne
   #       $rec->{exsrcid}){
   #      $relationupd++;
   #   }
   #}
   #else{
   #   $relationupd++;
   #}
   #if ($relationupd){
   #   if (my ($dstwfid)=$rec->{srcid}=~m/W5B:(\d{10,18})/){
   #      $relations=[{dstwfid=>$dstwfid,
   #                   name=>'commission',
   #                   translation=>'itil::workflow::change'}];
   #   }
   #}

   if (defined($chmmgr_pending)) {
      $wfrec{additional}->{ServiceManagerChmTITPending}=$chmmgr_pending;
   }
   if ($wfrec{additional}->{ServiceManagerClosedBy} ne
       $rec->{closedby}){
      $wfrec{additional}->{ServiceManagerClosedBy}=$rec->{closedby};
   }
   if ($wfrec{additional}->{ServiceManagerCloseCode} ne
       $rec->{closecode}){
      $wfrec{additional}->{ServiceManagerCloseCode}=$rec->{closecode};
   }
   if ($wfrec{additional}->{ServiceManagerResolveTime} ne
       $rec->{resolvetime}){
      $wfrec{additional}->{ServiceManagerResolveTime}=$rec->{resolvetime};
   }
   if ($wfrec{additional}->{ServiceManagerResolvedBy} ne
       $rec->{resolvedby}){
      $wfrec{additional}->{ServiceManagerResolvedBy}=$rec->{resolvedby};
   }

   $wfrec{owner}=undef;
   if (!($rec->{implementor}=~m/^\s*$/)){
      $wfrec{additional}->{ServiceManagerImplementor}=$rec->{implementor};
      my $implementor=lc($rec->{implementor});
      $self->{user}->ResetFilter();
      $self->{user}->SetFilter({posix=>\$implementor});
      my $userid=$self->{user}->getVal("userid");
      if (defined($userid)){
         $wfrec{owner}=$userid;
      }
   }
   if (!($rec->{coordinatorposix}=~m/^\s*$/)){
      my $chmmgr=lc($rec->{coordinatorposix});
      $self->{user}->ResetFilter();
      $self->{user}->SetFilter({posix=>\$chmmgr});
      my ($urec,$msg)=$self->{user}->getOnlyFirst(qw(userid fullname));
      if (defined($urec)){
         $wfrec{changemanager}=$urec->{fullname};
         $wfrec{changemanagerid}=$urec->{userid};
      }
      else{
         $wfrec{changemanagerid}=undef;
         $wfrec{changemanager}=$rec->{coordinatorname};
      }
   }


   if (!($rec->{coordinator}=~m/^\s*$/)){
      $wfrec{additional}->{ServiceManagerCoordinator}=$rec->{coordinator};
   }
   if (!($rec->{resources}=~m/^\s*$/)){
      $wfrec{additional}->{ServiceManagerResources}=$rec->{resources};
   }
   $wfrec{eventstart}=$rec->{plannedstart};
   $wfrec{eventend}=$rec->{plannedend};

   my @viewgroups=$obj->isViewValid($rec);
   if (in_array(\@viewgroups,"close") ||
       $rec->{taskstatus} eq "all tasks closed"){
      if ($rec->{workstart} ne ""){
         $wfrec{eventstart}=$rec->{workstart};
      }
      if ($rec->{workend} ne ""){
         $wfrec{eventend}=$rec->{workend};
      }
   }

   $wfrec{mdate}=$rec->{sysmodtime};
   $wfrec{createdate}=$rec->{createtime};
   $wfrec{closedate}=$rec->{closetime};
   if (!($rec->{closecode}=~m/^\s*$/)){
      $wfrec{additional}->{ServiceManagerCloseCode}=$rec->{closecode};
   }

   # approval check for I-Network (TSM hat zugestimmt)
   my %approver=();
   foreach my $agrp (split(/\s/,$rec->{addgrp})){
      my $g=trim($agrp);
      $approver{$g}=1 if ($g ne "");
   }
   if (ref($rec->{approved}) eq "ARRAY"){
      foreach my $a (@{$rec->{approved}}){
         foreach my $agrp (split(/\s/,$a->{name})){
            $approver{$agrp}=1 if ($agrp ne "");
         }
      }
   }


   $wfrec{changefallback}=$rec->{fallback};
   my ($system,$systemid,
       $anames,$aids,$primanames,$primaids,
       $contrnames,$contrids,$contrmods,$mandator,$mandatorid,
       $costcenter,$customername,$responseteam,$businessteam,
       $truecustomerprio)=
               $self->extractAffectedApplication($rec);

   if (ref($aids) eq "ARRAY" && $#{$aids}!=-1){
      if ($rec->{project} ne "" && !($rec->{project}=~m/\s/) &&
          length($rec->{project})>=3){
         my $pr=getModuleObject($self->Config(),"base::projectroom");
         $pr->SetFilter({name=>\$rec->{project},
                         cistatusid=>[2,3,4]});
         my ($prrec,$msg)=$pr->getOnlyFirst(qw(id name));
         if (defined($prrec) && $prrec->{name} ne ""){
            $wfrec{affectedproject}=$prrec->{name};
            $wfrec{affectedprojectid}=$prrec->{id};
         }
         else{
            $wfrec{affectedproject}=[];
            $wfrec{affectedprojectid}=[];
         }
      }
      else{
         $wfrec{affectedproject}=[];
         $wfrec{affectedprojectid}=[];
      }
   }
   if ($rec->{srcsys} eq "CSC"  &&      # prevent double load of changes
       $rec->{srcid} ne ""){
      $systemid=[];
      $system=[];
      $aids=[];
      $anames=[];
      $primaids=[];
      $primanames=[];
      $contrids=[];
      $contrmods=[];
      $contrnames=[];
      $responseteam=[];
      $businessteam=[];
      $costcenter=[];
      $customername=[];
      $wfrec{affectedproject}=["SCC->SM9 Interface"];
   }
   else{
      if (!exists($wfrec{affectedproject})){
         $wfrec{affectedproject}=undef;
      }
   }

   $wfrec{affectedsystemid}=$systemid;
   $wfrec{affectedsystem}=$system;
   $wfrec{affectedapplicationid}=$aids;
   $wfrec{affectedapplication}=$anames;
   $wfrec{primaffectedapplicationid}=$primaids;
   $wfrec{primaffectedapplication}=$primanames;
   $wfrec{affectedcontractid}=$contrids;
   $wfrec{customercontractmod}=$contrmods;
   $wfrec{affectedcontract}=$contrnames;
   $wfrec{involvedresponseteam}=$responseteam;
   $wfrec{involvedbusinessteam}=$businessteam;
   $wfrec{involvedcustomer}=$customername;
   $wfrec{involvedcostcenter}=$costcenter;
   $wfrec{mandator}=$mandator;
   $wfrec{mandatorid}=$mandatorid;
   $wfrec{truecustomerprio}=$truecustomerprio;
   $wfrec{class}=$oldclass;

   { # essential build name;stateid;applications;start;end
     my $essentialdata=$wfrec{name}."|";
     my $applnames=$wfrec{affectedapplication};
     $applnames=[$applnames] if (!ref($applnames));
     $essentialdata.="[".$wfrec{stateid}."]";
     $essentialdata.="[".join(";",@$applnames)."]";
     $essentialdata.="[".$rec->{plannedstart}."]";
     $essentialdata.="[".$rec->{plannedend}."]";
     $wfrec{essentialdatahash}=md5_base64($essentialdata);
   }

   { # rescheduled build name;start;end;description;validation
     my $rescheduled=$wfrec{name}."|";
     $rescheduled.="[".$rec->{plannedstart}."]";
     $rescheduled.="[".$rec->{plannedend}."]";
     $rescheduled.="[".$rec->{description}."]";
     $rescheduled.="[".$rec->{validation}."]";
     $wfrec{rescheduledatahash}=md5_base64($rescheduled);
   }


   # mz 19.07.17
   # try to simplify the classification of workflow class/step
   # has to be monitored for a while
   # previous version is commented below

   $wfrec{class}='TS::workflow::change';

   if (defined($updateto)) {
      # for compatibility with older Workflows
      if ($oldclass ne $wfrec{class}) {
         $wf->UpdateRecord({class=>$wfrec{class}},
                           {id=>$updateto});
         $wfrec{step} ='TS::workflow::change::extauthority';
         $oldclass=$wfrec{class};
      }
      if ($oldrec[0]->{step} eq 'itil::workflow::change::extauthority') {
         $wfrec{step}='TS::workflow::change::extauthority';
      }
   }

   if (!defined($updateto)){
      $wfrec{openuser}=undef;
      my $posix=lc($rec->{requestedby});
      $wfrec{openusername}="wiw/$posix";
      $self->{user}->ResetFilter();
      $self->{user}->SetFilter({posix=>\$posix});
      my $userid=$self->{user}->getVal("userid");
      if (defined($userid)){
         $wfrec{openuser}=$userid;
         $wfrec{openusername}="wiw/$posix";
      }

      $wfrec{step}='TS::workflow::change::extauthority';
   }

    my $ws=$rec->{workstart};
    my $we=$rec->{workend};
    my $wt=0;
    if ((my ($wsY,$wsM,$wsD,$wsh,$wsm,$wss)=$ws=~
           m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/) &&
        (my ($weY,$weM,$weD,$weh,$wem,$wes)=$we=~
           m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/)){
       my ($dd,$dh,$dm,$ds);
       eval('($dd,$dh,$dm,$ds)=Delta_DHMS("CET",
                                          $wsY,$wsM,$wsD,$wsh,$wsm,$wss,
                                          $weY,$weM,$weD,$weh,$wem,$wes);
            ');
       if (defined($dd) && defined($dh) && defined($dm)){
          $wt=$dd*24*60+$dh*60+$dm;
       }
    }

   # previous version
#
#   if (defined($updateto) && $#{$aids}!=-1) {
#      if ($oldclass eq "itil::workflow::change" ||
#          !($oldrec[0]->{step}=~m/^TS::/)) {
#         $wf->UpdateRecord({class=>'TS::workflow::change'},
#                           {id=>$updateto});
#         $wfrec{class}='TS::workflow::change';
#         $wfrec{step} ='TS::workflow::change::extauthority';
#         $oldclass='TS::workflow::change';
#      }
#   }
#
#   # for compatibility with older Workflow step
#   if ($oldrec[0]->{step} eq 'itil::workflow::change::extauthority') {
#      if ($oldclass eq 'TS::workflow::change' && $#{$aids}!=-1) {
#         $wfrec{step}='TS::workflow::change::extauthority';
#      }
#      else {
#         $wf->UpdateRecord({class=>'itil::workflow::change'},
#                           {id=>$updateto});
#         $wfrec{class}='itil::workflow::change';
#         $wfrec{step}='itil::workflow::change::main';
#         $oldclass='itil::workflow::change';
#      }
#   }
#
#   if (!defined($updateto)){
#      if ($#{$aids}!=-1){
#         $wfrec{class}='TS::workflow::change';
#      }
#      else{
#         $wfrec{class}='itil::workflow::change';
#         $wfrec{stateid}=21;           # non AL DTAG is automaticly finished
#      }
#   }
#   if (!defined($updateto)){
#      $wfrec{openuser}=undef;
#      my $posix=lc($rec->{requestedby});
#      $wfrec{openusername}="wiw/$posix";
#      $self->{user}->ResetFilter();
#      $self->{user}->SetFilter({posix=>\$posix});
#      my $userid=$self->{user}->getVal("userid");
#      if (defined($userid)){
#         $wfrec{openuser}=$userid;
#         $wfrec{openusername}="wiw/$posix";
#      }
#      if ($wfrec{class}=~m/^TS::/) {
#         $wfrec{step}='TS::workflow::change::extauthority';
#      }
#      else {
#         $wfrec{step}='itil::workflow::change::main';
#      }
#   }
#   if ($wfrec{class}=~m/^TS::/){
#       my $ws=$rec->{workstart};
#       my $we=$rec->{workend};
#       my $wt=0;
#       if ((my ($wsY,$wsM,$wsD,$wsh,$wsm,$wss)=$ws=~
#              m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/) &&
#           (my ($weY,$weM,$weD,$weh,$wem,$wes)=$we=~
#              m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/)){
#          my ($dd,$dh,$dm,$ds);
#          eval('($dd,$dh,$dm,$ds)=Delta_DHMS("CET",
#                                             $wsY,$wsM,$wsD,$wsh,$wsm,$wss,
#                                             $weY,$weM,$weD,$weh,$wem,$wes);
#               ');
#          if (defined($dd) && defined($dh) && defined($dm)){
#             $wt=$dd*24*60+$dh*60+$dm;
#          }
#       }
#   }

   $wfrec{srcload}=$self->detectSrcLoad($rec->{sysmodtime},
                                        $rec->{changenumber},$rec);
   return(\%wfrec,$updateto,$relations);
}

sub detectSrcLoad
{
   my $self=shift;
   my $reqstamp=shift;
   my $id=shift;
   my $rec=shift;

   my $d=CalcDateDuration($reqstamp,NowStamp("en"));
   if (defined($d) && $d->{totalseconds}<0){
      msg(ERROR,"desired srcload timestamp for $id is in the ".
                "future '$reqstamp'");
      $reqstamp=NowStamp("en");
   }
   return($reqstamp);
}

sub mkIncidentStoreRec
{
   my $self=shift;
   my $rec=shift;
   my $wf=shift;
   my $selfname=shift;
   my $obj=shift;
   my $updateto;
   my $oldclass;
   my %wfrec=(srcsys=>$selfname);
   my $app=$self->getParent();
   $wf->SetFilter({srcsys=>\$selfname,srcid=>\$rec->{incidentnumber}});
   my @oldrec=$wf->getHashList("id","class","step");
   if ($#oldrec==0){
      $updateto=$oldrec[0]->{id};
      $oldclass=$oldrec[0]->{class};
   }

   $wfrec{srcid}=$rec->{incidentnumber};
   $wfrec{name}=$rec->{name};
   $wfrec{incidentdescription}=$rec->{action};
   $wfrec{incidentresolution}=$rec->{resolution};
   $wfrec{stateid}=1;
   $wfrec{stateid}=17 if ($rec->{status} eq "closed");
   $wfrec{additional}={
      ServiceManagerIncidentNumber=>$rec->{incidentnumber},
      ServiceManagerState=>$rec->{status},
      ServiceManagerReason=>$rec->{reason},
      ServiceManagerPriority=>$rec->{priority},
      ServiceManagerHomeAssignment=>$rec->{hassignment},
      ServiceManagerInitialAssignment=>$rec->{iassignment},
      ServiceManagerResolvedAssignment=>$rec->{rassignment},
      ServiceManagerSysModTime=>$rec->{sysmodtime},
      ServiceManagerReportedBy=>$rec->{reportedby},
      ServiceManagerInvolvedAssignment=>$rec->{involvedassignment},
      ServiceManagerSoftwareID=>$rec->{softwareid},
      ServiceManagerDowntimeStart=>$rec->{downtimestart},
      ServiceManagerDowntimeEnd=>$rec->{downtimeend},
   };
   if (($rec->{priority}=~m/^\d+$/) &&
       $rec->{priority}>0 && $rec->{priority}<10){
      $wfrec{prio}=int($rec->{priority});
   }
   if (!($rec->{devicename}=~m/^\s*$/)){
      $wfrec{additional}->{ServiceManagerDeviceName}=$rec->{devicename};
   }
   if (!($rec->{deviceid}=~m/^\s*$/)){
      $wfrec{additional}->{ServiceManagerDeviceID}=$rec->{deviceid};
   }
   if (!($rec->{causecode}=~m/^\s*$/)){
      $wfrec{additional}->{ServiceManagerCauseCode}=$rec->{causecode};
   }
   if (!($rec->{workstart}=~m/^\s*$/)){
      $wfrec{additional}->{ServiceManagerWorkStart}=$rec->{workstart};
   }
   if (!($rec->{workend}=~m/^\s*$/)){
      $wfrec{additional}->{ServiceManagerWorkEnd}=$rec->{workend};
   }
   $wfrec{eventstart}=$rec->{downtimestart};
   my $downtimeend=$rec->{downtimeend};
   $downtimeend=$rec->{downtimestart} if (!defined($downtimeend) ||
                                          $downtimeend eq "");
   $wfrec{eventend}=$downtimeend;
   $wfrec{mdate}=$rec->{sysmodtime};
   $wfrec{createdate}=$rec->{opentime};
   $wfrec{closedate}=$rec->{closetime};

   $wfrec{openuser}=undef;
   $wfrec{openusername}=undef;
   if ($rec->{reportedby}=~m/^[a-z0-9_-]{1,8}$/i){
      $wfrec{openusername}="wiw/".lc($rec->{reportedby});
      $self->{user}->SetFilter({posix=>\$rec->{reportedby}});
      my $userid=$self->{user}->getVal("userid");
      $wfrec{openuser}=$userid if (defined($userid));
   }

   my ($system,$systemid,
       $anames,$aids,$primanames,$primaids,
       $contrnames,$contrids,$contrmods,$mandator,$mandatorid,
       $costcenter,$customername,$responseteam,$businessteam)=
                        $self->extractAffectedApplication($rec);



   if ($rec->{srcsys} eq "SC-GER"  &&      # prevent double load of changes
       $rec->{srcid} ne "" &&
       $rec->{openedby}=~m/\.backbone\./){
      $systemid=[];
      $system=[];
      $aids=[];
      $anames=[];
      $contrids=[];
      $contrmods=[];
      $contrnames=[];
      $responseteam=[];
      $businessteam=[];
      $costcenter=[];
      $customername=[];
      $wfrec{affectedproject}=["SCC->SM9 Interface"];
   }
   else{
      if (!exists($wfrec{affectedproject})){
         $wfrec{affectedproject}=undef;
      }
   }

   $wfrec{affectedsystemid}=$systemid;
   $wfrec{affectedsystem}=$system;
   $wfrec{affectedapplicationid}=$aids;
   $wfrec{affectedapplication}=$anames;
   $wfrec{affectedcontractid}=$contrids;
   $wfrec{customercontractmod}=$contrmods;
   $wfrec{affectedcontract}=$contrnames;
   $wfrec{involvedresponseteam}=$responseteam;
   $wfrec{involvedbusinessteam}=$businessteam;
   $wfrec{involvedcustomer}=$customername;
   $wfrec{involvedcostcenter}=$costcenter;
   $wfrec{mandator}=$mandator;
   $wfrec{mandatorid}=$mandatorid;

   if (defined($updateto) && $#{$aids}!=-1 &&
       $oldclass eq "itil::workflow::incident"){
      $wf->UpdateRecord({class=>'TS::workflow::incident'},
                        {id=>$updateto});
      #printf STDERR ("WARN: class incidentd on id $updateto\n");
      $oldclass='TS::workflow::incident';
   }
   if (!defined($updateto)){
      if ($#{$aids}!=-1){
         $wfrec{class}='TS::workflow::incident';
      }
      else{
         $wfrec{class}='itil::workflow::incident';
      }
      $wfrec{step}='itil::workflow::incident::extauthority';
   }
   if ($oldclass eq "itil::workflow::incident" ||
       (defined($wfrec{class}) && 
        ($wfrec{class}=~m/itil::workflow::incident/))){
      $wfrec{stateid}=21;           # non AL DTAG is automaticly finished
      # sollte jetzt auch mit sofort beenden funktionieren
   }
   if (!defined($oldrec[0]) || !($oldrec[0]->{step}=~m/::postreflection$/)){
       my $ws=$rec->{workstart};
       my $we=$rec->{workend};
       my $wt=0;
       if ((my ($wsY,$wsM,$wsD,$wsh,$wsm,$wss)=$ws=~
              m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/) &&
           (my ($weY,$weM,$weD,$weh,$wem,$wes)=$we=~
              m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/)){
          my ($dd,$dh,$dm,$ds);
          eval('($dd,$dh,$dm,$ds)=Delta_DHMS("CET",$wsY,$wsM,$wsD,$wsh,$wsm,$wss,
                                             $weY,$weM,$weD,$weh,$wem,$wes);
               ');
          if (defined($dd) && defined($dh) && defined($dm)){
             $wt=$dd*24*60+$dh*60+$dm;
          }
       }
       if ($#{$aids}!=-1){ 
          $wfrec{tcomcodrelevant}="yes";
       }
       else{
          $wfrec{tcomcodrelevant}="no";
       }
       $wfrec{tcomcodcause}="appl.base.base";
       $wfrec{tcomworktime}=$wt;
       if ($rec->{resolution} ne ""){
          $wfrec{tcomcodcomments}=$rec->{resolution};
       }
   }

   $wfrec{srcload}=$self->detectSrcLoad($rec->{sysmodtime},
                                        $rec->{incidentnumber},$rec);
   return(\%wfrec,$updateto);
}


sub extractAffectedApplication
{
   my $self=shift;
   my $rec=shift;
   my @mandator=();
   my @mandatorid=();
   my @system=();
   my @systemid=();
   my %system=();
   my %systemid=();
   my @custcontract=();
   my @custcontractid=();
   my @custcontractmod=();
   my @applna=();
   my @applid=();
   my @primapplna=();
   my @primapplid=();
   my @costcenter=();
   my @responseteam=();
   my @businessteam=();
   my @customername=();
   my %costcenter=();
   my %responseteam=();
   my %businessteam=();
   my %customername=();
   my $truecustomerprio;


   msg(DEBUG,"createtime = %s",$rec->{createtime});
   my $tbreaktime1;   # modified handling since breaktime1
   my $breaktime1="2009-10-05 00:00:00";
   if (exists($rec->{changenumber}) && $rec->{createtime} ne ""){
      my $d=CalcDateDuration($breaktime1,$rec->{createtime});
      $tbreaktime1=$d->{totalminutes};
   }
   my $tbreaktime2;  
   my $breaktime2="2011-01-01 00:00:00";
   if (exists($rec->{changenumber}) && $rec->{createtime} ne ""){
      my $d=CalcDateDuration($breaktime2,$rec->{createtime});
      $tbreaktime2=$d->{totalminutes};
   }
   my @chksystemid;
   my @chkapplid;
   my @chkprimapplid;
   #  pass 1 : softwareid
   my @l1;

   if (defined($rec->{custapplication})){
      push(@l1,split(/[,\s;]+/,$rec->{custapplication}));
   }

   my @l2;

   
   if (defined($rec->{relations}) && ref($rec->{relations} )eq "ARRAY"){
      foreach my $r (@{$rec->{relations}}){
         if ($r->{dstobj} eq "tsacinv::appl"){
            push(@chkapplid,$r->{dstid});
            msg(DEBUG,"add %s by entry in relations table",$r->{dst});
         }
         if ($r->{dstobj} eq "tsacinv::system"){
            push(@chksystemid,$r->{dstid});
         }
      }
   }
   if ($#chkprimapplid==-1){
      @chkprimapplid=@chkapplid;
   }
   #   removing empty ApplicationIDs
   @chkprimapplid=grep(!/^$/,@chkprimapplid);
   @chkapplid=grep(!/^$/,@chkapplid);

   #   pass 3 : affacted Softare
   my @l3;

   #  pass 4 : make all unique with ignoring case
   my %u=();
   map({$u{lc($_)}=$_;} @l1,@l2,@l3);
   my @applna=grep(!/^\s*$/,sort(values(%u)));
   my @applna=grep(!/\>/,@applna);
   my @applna=grep(!/\</,@applna);
   my @applna=grep(!/!/,@applna);
   my @applna=grep(!/\*/,@applna);
   my @applna=grep(!/\?/,@applna);
   my @applna=grep(!/^\s*$/,@applna);
   msg(DEBUG,"pass4 validate aglist=%s",join(",",@applna));


   #  pass 5 : validate against W5Base
   my $appl=$self->getPersistentModuleObject("W5BaseAppl","itil::appl");
   my @l;
   if ($#applna!=-1){
      my $flt=join(" ",map({'"'.$_.'"'} @applna));
      $appl->ResetFilter();
      $appl->SetFilter({name=>$flt});
      @l=$appl->getHashList(qw(id name custcontracts customerprio
                               mandator mandatorid customer 
                               businessteam responseteam conumber));
      @applid=sort(map({$_->{id}} @l));
      @applna=sort(map({$_->{name}} @l));
      map({ if (defined($_->{customerprio}) && $_->{customerprio}>0){
               if (!defined($truecustomerprio) || 
                   $truecustomerprio>$_->{customerprio}){
                  $truecustomerprio=$_->{customerprio};
               }
            }
          } @l);
   }
   my $novalidappl=0;
   $novalidappl=1 if ($#applid==-1);
   msg(DEBUG,"pass5 validate aglist=%s",join(",",@applid));
   msg(DEBUG,"pre deviceid chkapplid=%s",join(",",@chkapplid));
   msg(DEBUG,"pre deviceid chkprimapplid=%s",join(",",@chkprimapplid));

   my $dev;
   if (exists($rec->{devicename})){ # for incident and problem TODO
      $dev=$rec->{devicename};
   }
   if (my ($applid)=$dev=~m/^.*\(((APPLGER|APPL|GER)\d+)\)$/){
      msg(DEBUG,"ApplicationID from deviceid field=%s",$applid);
      push(@chkapplid,$applid);
   }

   msg(DEBUG,"post deviceid chkapplid=%s",join(",",@chkapplid));
   if ($#chkapplid!=-1){
      $appl->ResetFilter();
      $appl->SetFilter({applid=>\@chkapplid});
      my @l1=$appl->getHashList(qw(id applid name custcontracts 
                               mandator mandatorid customer 
                               businessteam responseteam conumber));
      if ($#l1!=-1){
         push(@l,@l1);
         foreach my $arec (@l1){
            push(@applid,$arec->{id})   if (!in_array(\@applid,$arec->{id}));
            push(@applna,$arec->{name}) if (!in_array(\@applna,$arec->{name}));
            if (in_array(\@chkprimapplid,$arec->{applid})){
               if (!in_array(\@primapplna,$arec->{name})){
                  push(@primapplna,$arec->{name});
               }
               if (!in_array(\@primapplid,$arec->{id})){
                  push(@primapplid,$arec->{id});
               }
            }
         }
      }
   }
   else{
      my @dev=split(/[,;]+/,$dev);
      if ($#chksystemid==-1){
         for(my $c=0;$c<=$#dev;$c++){
            my $dev=$dev[$c];
            if (my ($name,$itemid)=$dev=~m/^(.*)\s+\((.+)\)$/){
               if ($itemid=~m/^S/){
                  $dev[$c]=lc($name);
               }
               else{
                  $dev[$c]=$name;
               }
               push(@dev,$itemid);
            }
         }
      }
      @dev=grep(!/\</,@dev);
      @dev=grep(!/\>/,@dev);
      @dev=grep(!/!/,@dev);
      @dev=grep(!/\*/,@dev);
      @dev=grep(!/\?/,@dev);
      @dev=grep(!/^\s*$/,@dev);
      msg(DEBUG,"no application entries - try to found '%s'",join(",",@dev));
    
      if ($#dev!=-1){
         my $sys=$self->getPersistentModuleObject("W5BaseSys",
                                                  "itil::system");
         $sys->SetFilter([{name=>\@dev},{systemid=>\@dev}]);
         my @sl=$sys->getHashList(qw(id name applications)); 
         my %applid=();
         my %applna=();
         msg(DEBUG,"found %d system entries",scalar($#sl)+1);
         foreach my $s (@sl){
            $system{$s->{name}}=1;
            $systemid{$s->{id}}=1;
            if ($novalidappl){
               if (ref($s->{applications}) eq "ARRAY"){
                  foreach my $a (@{$s->{applications}}){
                     if ($a->{appl} ne "" && $a->{applid} ne "" &&
                         $a->{applcistatusid}<=4){
                        $applid{$a->{applid}}=1; 
                        $applna{$a->{appl}}=1; 
                     }
                  }
               }
            }
         }
         msg(DEBUG,"after systemcheck system=%s",join(",",keys(%system)));
         msg(DEBUG,"after systemcheck systemid=%s",join(",",keys(%systemid)));
         if ($novalidappl){
            @primapplid=@applid=sort(keys(%applid));
            @primapplna=@applna=sort(keys(%applna));

            $appl->SetFilter({id=>\@applid}); # reread the application table
            @l=$appl->getHashList(qw(id name custcontracts customer 
                                     businessteam responseteam conumber
                                     mandator mandatorid));
         }
      }
   }
   msg(DEBUG,"after systemcheck aglist=%s",join(",",@applna));
   if ($#chksystemid!=-1){
      my $sys=$self->getPersistentModuleObject("W5BaseSys",
                                               "itil::system");
      $sys->SetFilter({systemid=>\@chksystemid,cistatusid=>"<=4"});
      my @sl=$sys->getHashList(qw(id name)); 
      foreach my $s (@sl){
         $system{$s->{name}}=1;
         $systemid{$s->{id}}=1;
      }
   }
   msg(DEBUG,"after chksystemid system=%s",join(",",keys(%system)));
   msg(DEBUG,"after chksystemid systemid=%s",join(",",keys(%systemid)));
   my %mandator=();
   my %mandatorid=();
   my %custcontractid=();
   my %custcontractmod=();
   my %custcontract=();
   foreach my $rec (@l){
      if (ref($rec->{custcontracts}) eq "ARRAY"){
         foreach my $contr (@{$rec->{custcontracts}}){
            $custcontractid{$contr->{custcontractid}}=1;
            $custcontract{$contr->{custcontract}}=1;
         }
      }
      if ($rec->{mandator} ne ""){
         $mandator{$rec->{mandator}}=1;
      }
      if ($rec->{mandatorid} ne ""){
         $mandatorid{$rec->{mandatorid}}=1;
      }
      $costcenter{$rec->{conumber}}=1;
      $customername{$rec->{customer}}=1;
      $responseteam{$rec->{responseteam}}=1;
      $businessteam{$rec->{businessteam}}=1;
   }
   if (keys(%custcontractid)){
      my $cmod=$self->getPersistentModuleObject("W5BaseCustMod",
                                               "finance::custcontractmod");
      $cmod->SetFilter({contractid=>[keys(%custcontractid)]});
      my @sl=$cmod->getHashList(qw(rawname)); 
      foreach my $s (@sl){
         $custcontractmod{$s->{rawname}}=1;
      }
   }
   @custcontract=sort(keys(%custcontract));
   @custcontractid=sort(keys(%custcontractid));
   @custcontractmod=sort(keys(%custcontractmod));
   @mandator=sort(keys(%mandator));
   @mandatorid=sort(keys(%mandatorid));
   @costcenter=grep(!/^\s*$/,sort(keys(%costcenter)));
   @customername=grep(!/^\s*$/,sort(keys(%customername)));
   @responseteam=grep(!/^\s*$/,sort(keys(%responseteam)));
   @businessteam=grep(!/^\s*$/,sort(keys(%businessteam)));
   @system=grep(!/^\s*$/,sort(keys(%system)));
   @systemid=grep(!/^\s*$/,sort(keys(%systemid)));

   if ($#mandatorid==-1){
      @mandatorid=(-99);
      @mandator=("none");
   }
   msg(DEBUG,"result aglist  =%s",join(",",@applna));
   msg(DEBUG,"result mandator=%s",join(",",@mandator));
   

   # $rec->{softwareid}
   # $rec->{software} =>array
   # $rec->{description} 

#print STDERR ("applid=@applid\n");
#print STDERR ("applna=@applna\n");

   return(\@system,\@systemid,
          \@applna,\@applid,
          \@primapplna,\@primapplid,
          \@custcontract,\@custcontractid,\@custcontractmod,
          \@mandator,\@mandatorid,\@costcenter,\@customername,
          \@responseteam,\@businessteam,$truecustomerprio);
}


sub identifyW5UserFromGroup
{
   my $self=shift;
   my $name=shift;

   my $lnk=getModuleObject($self->Config,'tssm::lnkusergroup');
   $lnk->SetFilter({lgroup=>\$name});

   return(-1) if (!$lnk->Ping());

   my @operator=map {$_->{luser}} @{$lnk->getHashList(qw(luser))};

   my $userobj=getModuleObject($self->Config,'base::user');
   $userobj->SetFilter({posix=>\@operator});
 
   my @user=map {$_->{userid}} @{$userobj->getHashList(qw(userid))};

   return(@user) if(wantarray());
   return(\@user);
}


sub identifyW5UserFromOperator
{
   my $self=shift;
   my $name=shift;

   my $userobj=getModuleObject($self->Config,'base::user');
   $userobj->SetFilter({posix=>\$name});
 
   my ($user,$msg)=$userobj->getOnlyFirst(qw(userid));

   return($user->{userid});
}


sub getAMObjDecode
{
   my $depend=shift;

   return(
          "decode($depend,".
               "'application','tsacinv::appl',".
               "'computer','tsacinv::system',".
               "'networkcomponents','tsacinv::system',".
               "'generic','tsacinv::asset',".
               "'runningsoftware','tsacinv::swinstance',".
               "NULL)"
       );
}




1;
