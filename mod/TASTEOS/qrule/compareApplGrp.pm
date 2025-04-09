package TASTEOS::qrule::compareApplGrp;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This quality rule compares a W5Base ApplicationGroup to a TasteOS 
system (which is a application in W5Base spelling).

=head3 IMPORTS

- name of cluster

=head3 HINTS

Sync to TasteOS

[de:]

Syncronisation der Anwendungsgruppen in Darwin mit den "Systemen"
in TasteOS.

=cut
#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2020  Hartmut Vogler (it@guru.de)
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
use vars qw(@ISA);
use kernel;
use kernel::QRule;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return(["itil::applgrp"]);
}

   sub insNewTSOSmac
   {
      my $dataobj=shift;
      my $tsosmac=shift;
      my $opladdobj=shift;
      my $rec=shift;
      my $nrec=shift;
      my $lrec=shift;
      my $ladd=shift;

      my $newid=$tsosmac->ValidatedInsertRecord($nrec);
      if ($newid ne ""){
         if (!exists($ladd->{$lrec->{systemid}}) ||
             !exists($ladd->{$lrec->{systemid}}->{additional})){
            my %add=(TasteOS_MachineID=>$newid);
            $opladdobj->ValidatedInsertRecord({
               systemid=>$lrec->{systemid},
               applgrpid=>$lrec->{applgrpid},
               additional=>\%add
            });
         }
         else{
            my %add=%{$ladd->{$lrec->{systemid}}->{additional}};
            my $oldTasteOS_MachineID=$add{TasteOS_MachineID};
            if (ref($oldTasteOS_MachineID) eq "ARRAY"){
               $oldTasteOS_MachineID=$oldTasteOS_MachineID->[0];
            }
            my $newTasteOS_MachineID=$newid;
            if ($oldTasteOS_MachineID ne "" &&
                $newTasteOS_MachineID ne $oldTasteOS_MachineID){
               $tsosmac->Log(WARN,"backlog",
                        "TasteOS stored MachineID='$oldTasteOS_MachineID' ".
                        "changed to new '$newTasteOS_MachineID'");
            }
            $add{TasteOS_MachineID}=$newid;
            $opladdobj->ValidatedUpdateRecord(
               $ladd->{$lrec->{systemid}},
               {additional=>\%add},
               {id=>$ladd->{$lrec->{systemid}}->{id}}
            );
         }
      }
      return($newid);
   }

   sub insNewTSOSsys
   {
      my $dataobj=shift;
      my $tsossys=shift;
      my $rec=shift;
      my $nrec=shift;

      my $newid=$tsossys->ValidatedInsertRecord($nrec);
#      printf STDERR ("create new SystemID=$newid\n");
      if ($newid ne ""){
         my %add=%{$rec->{additional}};
         $add{TasteOS_SystemID}=$newid;
         my $bk=$dataobj->ValidatedUpdateRecord(
            $rec,{additional=>\%add},
            {id=>$rec->{id}}
         );
         #printf STDERR ("update system $rec->{id} bk=$bk\n");
      }
      return($newid);
   }

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=shift;

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;
   my %contact;

   return(0,undef) if ($rec->{cistatusid}<3);
   return(undef)   if ($rec->{applgrpid} eq "");
   

   my $opmode=$dataobj->Config->Param("W5BaseOperationMode");
   if ($opmode eq "test"){
      return(undef,{qmsg=>'no sync on w5base testenv allowed'});
   }

   if (($opmode ne "prod" && $opmode ne "online") && ( 0
       && !in_array($rec->{id},["15954048670047"])
       )){
      return(undef,{qmsg=>'on noneprod only individual selected id'});
   }

   my $tsossys=getModuleObject($dataobj->Config,"TASTEOS::tsossystem");
   my $tsossysacl=getModuleObject($dataobj->Config,"TASTEOS::tsossystemacl");
   my $tsosmac=getModuleObject($dataobj->Config,"TASTEOS::tsosmachine");

   if ($tsossys->isSuspended() || $tsossysacl->isSuspended() ||
       $tsosmac->isSuspended()){
      return(undef,{
         qmsg=>'TasteOS is blacklisted/suspended/maintained'
      });
   }

   if (!$tsossys->Ping()){   # ping on one object is sufficient 
      return(undef,{
         qmsg=>'TasteOS not available'
      });
   }

   msg(INFO,"start loading getUnassignedMachinesRec");
   my $uarec=$tsossys->getUnassignedMachinesRec();
   if (!defined($uarec)){
      return(undef,{
         qmsg=>'TasteOS UnassignedMachines record can not be loaded'
      });
   }
   my %uaMachines;  # needed for check, if there is a "late Agent installation"
   foreach my $uamrec (@{$uarec->{machines}}){
      $uaMachines{$uamrec->{machineNumber}}=$uamrec;
   }

   my $appl=getModuleObject($dataobj->Config,"itil::appl");
   $appl->SetFilter({
      applgrpid=>\$rec->{id},
      cistatusid=>[4]
   });
   my @a=$appl->getHashList(qw(tsmid tsm2id applmgrid contacts));
   foreach my $arec (@a){
      foreach my $fld (qw(tsmid tsm2id applmgrid)){
         if ($arec->{$fld} ne ""){
            $contact{$arec->{$fld}}={};
         }
      }
      foreach my $crec (@{$arec->{contacts}}){
         my $roles=$crec->{roles};
         $roles=[$roles] if (ref($roles) ne "ARRAY");
         if ($crec->{target} eq "base::user" &&
             in_array($roles,"applmgr2")){
            $contact{$crec->{targetid}}={};
         }
      }
   }
   if (keys(%contact)){
      my $user=getModuleObject($dataobj->Config,"base::user");
      $user->SetFilter({cistatusid=>[4],userid=>[keys(%contact)]});
      foreach my $urec ($user->getHashList(qw(email userid))){
         $contact{$urec->{userid}}=$urec;
      }
   }


   my $lobj=getModuleObject($dataobj->Config,"itil::lnkapplsystem");

   $lobj->SetFilter(
      {
         applgrpid=>\$rec->{id},
         systemcistatusid=>[4],
         applcistatusid=>[4]
      }
   );

   my @l=$lobj->getHashList(qw(systemid applgrpid applid id reltyp
                               systemsystemid systemsrcsys systemsrcid
                               isembedded isnetswitch shortdesc));

   @l=grep({
      ($_->{isembedded} eq "0" && $_->{isnetswitch} eq "0")
   } @l);

   my %ul;
   foreach my $lrec (@l){
      $ul{$lrec->{applgrpid}."-".$lrec->{systemid}}=$lrec;
   }
   @l=values(%ul);

   my @systemid;
   map({push(@systemid,$_->{systemid});} @l);

   #printf STDERR ("l=%s\n",Dumper(\@l));
   #printf STDERR ("n=%d\n",$#l+1);
   #printf STDERR ("systemid=%s\n",join(",",@systemid));

   my $laddobj=getModuleObject($dataobj->Config,"itil::addlnkapplgrpsystem");
   $laddobj->SetFilter({ applgrpid=>\$rec->{id} });
   my $opladdobj=$laddobj->Clone();
   $laddobj->SetCurrentView(qw(systemid system applgrpid applgrp 
                               additional id));
   my $ladd=$laddobj->getHashIndexed(qw(systemid));

   foreach my $systemid (keys(%{$ladd->{systemid}})){
       my $TSOSmachineid;
       if (in_array(\@systemid,$systemid)){
          if (exists($ladd->{systemid}->{$systemid})){
             my $laddent=$ladd->{systemid}->{$systemid};
             $TSOSmachineid=$laddent->{additional}->{TasteOS_MachineID}->[0];
          }
          if ($TSOSmachineid ne ""){
             $ladd->{TasteOS_MachineID}->{$TSOSmachineid}=
                $ladd->{systemid}->{$systemid};
          }
       }
       else{
          #
          # drop addlnkapplgrpsystem record (no relation between applgrp
          # and logical system
          #
          if (exists($ladd->{systemid}->{$systemid}) &&
              $ladd->{systemid}->{$systemid} ne ""){
             my $oldrec=$ladd->{systemid}->{$systemid};
             my $opladdobj=$laddobj->Clone();
             $opladdobj->ValidatedDeleteRecord(
                {id=>\$oldrec->{id}}
             );
          }
          delete($ladd->{systemid}->{$systemid});
       }
   }

   my $expLevelIdMap={
      'CNDTAG'  =>10018,
      'Backend' =>10019,
      'Internet'=>10017,
   };

   my $w5sys=getModuleObject($dataobj->Config,"TS::system");
   if ($#systemid!=-1){
      $w5sys->SetFilter({id=>\@systemid});
      my @w5rec=$w5sys->getHashList(qw(id name 
                                       effexposurelevel 
                                       autoexposurelevel 
                                       exposurelevel));
      foreach my $rec (@w5rec){
         foreach my $v (qw(effexposurelevel)){
            
            $ladd->{systemid}->{$rec->{id}}->{$v}=$rec->{$v};
            if (exists($expLevelIdMap->{$rec->{$v}})){
               $ladd->{systemid}->{$rec->{id}}->{riskCategoryId}=
                   $expLevelIdMap->{$rec->{$v}};
            }
         }
      }
   }
   #printf STDERR ("addl=%s\n",Dumper($ladd));
  # printf STDERR Dumper(\@l);

   $tsossys->ResetFilter();
   $tsossys->SetFilter({ictoNumber=>$rec->{applgrpid}});
   $tsossys->SetCurrentView(qw(id ictoNumber machines));
   my $curSys=$tsossys->getHashIndexed(qw(ictoNumber id));
   # printf STDERR ("curSys getHashIndexed=%s\n",Dumper($curSys));

   if ($rec->{cistatusid}>5){
      if (keys(%{$curSys->{id}})){
         my @qmsg;
         foreach my $id (keys(%{$curSys->{id}})){
            push(@qmsg,"drop TasteOS system: ".$id);
            $tsossys->ValidatedDeleteRecord({id=>$id});
            if ($tsossys->LastMsg()){
               push(@qmsg,($tsossys->LastMsg()));
            }
         }
         return(0,{qmsg=>\@qmsg});
      }
      return(undef,undef);
   }

   my $dd=Dumper($rec->{additional});

   my $TSOSsystemid=$rec->{additional}->{TasteOS_SystemID}->[0];

   msg(INFO,"try to system record for TSOSsystemid=$TSOSsystemid");
   if ($TSOSsystemid ne ""){
      $tsossys->ResetFilter();
      $tsossys->SetFilter({id=>$TSOSsystemid}); # check if systemid still exists
      my ($srec,$msg)=$tsossys->getOnlyFirst(qw(id name));
      if (!defined($srec)){
         $tsossys->Log(WARN,"backlog",
                            "stored systemid $TSOSsystemid does not ".
                            "exists in TasteOS");
         $TSOSsystemid=undef;
      }
   }

   my @delList;
   my @idl;
   if (ref($curSys->{ictoNumber}->{$rec->{applgrpid}}) eq "ARRAY"){
      @idl=map({$_->{id}} @{$curSys->{ictoNumber}->{$rec->{applgrpid}}});
   }
   else{
      if (ref($curSys->{ictoNumber}) eq "HASH"){
         @idl=$curSys->{ictoNumber}->{$rec->{applgrpid}}->{id};
      }
   }
   if ($#idl!=-1){
      if ($TSOSsystemid ne "" &&
          in_array(\@idl,$TSOSsystemid)){  # cleanup andere ICTOs
         push(@delList,grep(!/^$TSOSsystemid$/,@idl));
      }
      else{
         @delList=@idl;
         $TSOSsystemid=undef;
      }
   }
   foreach my $id (@delList){  # cleanup old system records (not stored local)
      if ($id ne ""){
         $tsossys->Log(WARN,"backlog",
                            "drop systemid $id in TasteOS");
         $tsossys->ValidatedDeleteRecord({id=>$id});
      }
   }

   my $tsossysrec={
      name=>$rec->{fullname},
      ictoNumber=>$rec->{applgrpid},
      description=>NowStamp("en")
   };


   if ($TSOSsystemid eq ""){
      $TSOSsystemid=insNewTSOSsys($dataobj,$tsossys,$rec,$tsossysrec);
   }
   else{
      my $bk=$tsossys->ValidatedUpdateRecord(
         {},$tsossysrec,
      {id=>$TSOSsystemid});
      $tsossys->ResetFilter();
      $tsossys->SetFilter({id=>$TSOSsystemid});
      my ($srec,$msg)=$tsossys->getOnlyFirst(qw(ALL));

      if (defined($srec)){
         my @delList;
         foreach my $mrec (@{$srec->{machines}}){
            if (!exists($ladd->{TasteOS_MachineID}->{$mrec->{id}})){
               push(@delList,$mrec->{id});
               push(@qmsg,"drop MachineID $mrec->{id} for ".
                          "systemname $mrec->{name}");
            }
            else{
               my $machineNumber=$mrec->{machineNumber};
               if ($machineNumber ne "" && 
                   exists($uaMachines{$machineNumber})){
                  $tsosmac->ValidatedDeleteRecord({id=>$mrec->{id}});
                  $tsosmac->Log(WARN,"backlog",
                           "TasteOS: droped MachineID=$mrec->{id} ".
                           "because new Agent in UnassignedMachines ".
                           "for $machineNumber");
                  # in follow processes, the machine will be new
                  # inserted - and as followup, moved from 
                  # UnassignedMachines to the current TasteOS-System
               }
            }
         }
         #printf STDERR "delList=".Dumper(\@delList);
         foreach my $machineid (@delList){
            $tsosmac->ResetFilter();
            $tsosmac->ValidatedDeleteRecord({id=>$machineid});
            $tsosmac->Log(WARN,"backlog",
                     "TasteOS: ".
                     "normaly drop MachineID '$machineid' because it ".
                     "does not exists in ICTO anymore");
         }
      }
   }
   #printf STDERR ("fifi upd TSOSsystemid=$TSOSsystemid\n");
   #printf STDERR ("current SysList in ICTO=%s\n",Dumper(\@l));


   if ($TSOSsystemid ne ""){
       
      foreach my $lrec (@l){
         my $TSOSmachineid;
         if (exists($ladd->{systemid}->{$lrec->{systemid}}) &&
             exists($ladd->{systemid}->{$lrec->{systemid}}->{additional})){
            my $laddent=$ladd->{systemid}->{$lrec->{systemid}};
            $TSOSmachineid=$laddent->{additional}->{TasteOS_MachineID}->[0];
         }
         my $tsosmacrec={
            name=>$lrec->{system},
            systemid=>$TSOSsystemid,
            description=>$lrec->{shortdesc}
         };
         if (exists($ladd->{systemid}->{$lrec->{systemid}}) &&
             exists($ladd->{systemid}->{$lrec->{systemid}}->{riskCategoryId})){
            my $laddent=$ladd->{systemid}->{$lrec->{systemid}};
            $tsosmacrec->{riskCategoryId}=$laddent->{riskCategoryId};
         }


         my $machineNumber;

         {
            my $systemsrcid=$lrec->{systemsrcid};
            $systemsrcid=$lrec->{systemid} if ($systemsrcid eq "");
      
            my $systemsrcsys=$lrec->{systemsrcsys};
            $systemsrcsys="w5base" if ($systemsrcsys eq "");

            $machineNumber=$systemsrcid;
            $machineNumber=$systemsrcsys.":".$machineNumber;
         }
         if ($machineNumber){
            $tsosmacrec->{machineNumber}=$machineNumber;
         }
         {
            my $SystemName=$lrec->{system};
            my ($mrec,$msg);
           
            #################################################################
            # Check if in w5base stored TSOSmachineid still exists in TasteOS
            # (in some cases, records were deleted in TasteOS)
            #
            msg(INFO,"check if known MachineID '$TSOSmachineid' for ".
                     "SystemName=$SystemName still exists");
           
            if ($TSOSmachineid ne ""){ 
               $tsosmac->ResetFilter();
               $tsosmac->SetFilter({id=>$TSOSmachineid});
               ($mrec,$msg)=$tsosmac->getOnlyFirst(qw(id name systemid 
                                                         description
                                                         riskCategoryId));
               if (!defined($mrec)){
                  $tsosmac->Log(WARN,"backlog",
                           "TasteOS: ".
                           "MachineID '$TSOSmachineid' ".
                           "(SystemName=$SystemName) ".
                           "lost in TasteOS");
                  $TSOSmachineid=undef;
               }
            }
            #################################################################
            if ($TSOSmachineid eq ""){
               $tsosmacrec->{salt}=$tsosmacrec->{machineNumber};
               $tsosmacrec->{salt}.=":" if ($tsosmacrec->{salt} ne "" &&
                                            $tsosmacrec->{systemid} ne "");
               $tsosmacrec->{salt}.=$tsosmacrec->{systemid};
               my $newid=insNewTSOSmac($dataobj, $tsosmac,$opladdobj,
                                       $rec,$tsosmacrec,$lrec,
                                       $ladd->{systemid});
               return(undef,undef) if ($newid eq ""); 
               push(@qmsg,"add MachineID $newid for ".
                          "systemname $tsosmacrec->{name}");
            }
            else{
               if ($mrec->{systemid} ne $tsosmacrec->{systemid} ||
                   $mrec->{machineNumber}  ne $tsosmacrec->{machineNumber} ||
                   $mrec->{description}  ne $tsosmacrec->{description} ||
                   $mrec->{riskCategoryId}  ne $tsosmacrec->{riskCategoryId} ||
                   $mrec->{name}     ne $tsosmacrec->{name}){
                  my $bk=$tsosmac->ValidatedUpdateRecord(
                     {},$tsosmacrec,
                     {id=>$TSOSmachineid
                  });
               }
            }
            #################################################################
         }

      }

      if (1 || in_array($rec->{applgrpid},["ICTO-20324"])){
         my @email=sort(map({$_->{email}} values(%contact)));
         msg(INFO,sprintf("set acl of TasteOS system $TSOSsystemid to %s\n",
               join(",",@email)));
         if ($#email!=-1){
            foreach my $email (@email){
               if ($email ne ""){
                  my $bk=$tsossysacl->ValidatedInsertRecord({
                     systemid=>$TSOSsystemid,
                     email=>$email,
                     readwrite=>1
                  });
                  msg(INFO,"insert of $email = $bk");
               }
            }
         }
      }
   }

   $tsossys->ResetFilter();
   $tsossys->SetFilter({name=>'!"Default System"',ictoNumber=>\""});
   my @l=$tsossys->getHashList(qw(ALL));
   foreach my $delsys (@l){
       next if ($delsys->{name} eq "Unassigned Machines");
       $tsossys->ResetFilter();
       $tsossys->ValidatedDeleteRecord({id=>$delsys->{id}});
   }

   $tsossys->ResetFilter();
   $tsossys->SetFilter({name=>\"Default System",ictoNumber=>\""});
   my ($defrec,$msg)=$tsossys->getOnlyFirst(qw(id name machines));
   if (defined($defrec)){
      if (ref($defrec->{machines}) eq "ARRAY"){
         foreach my $mrec (@{$defrec->{machines}}){
            $tsosmac->ResetFilter();
            $tsosmac->ValidatedDeleteRecord({id=>$mrec->{id}});
            $tsosmac->Log(WARN,"backlog",
                     "TasteOS: ".
                     "cleanup MachineID '$mrec->{id}' from 'Default System' ".
                     "(SystemName=$mrec->{name}) ");
         }
      }
   }

   my @result=$self->HandleQRuleResults("TasteOS",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);

   return(@result);
}



1;
