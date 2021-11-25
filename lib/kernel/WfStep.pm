package kernel::WfStep;
#  W5Base Framework
#  Copyright (C) 2002  Hartmut Vogler (hartmut.vogler@epost.de)
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
#
use vars qw(@ISA);
use strict;
use kernel;
use kernel::Operator;
use kernel::Wf;

@ISA=qw(kernel::Operator kernel::Wf);

sub new
{
   my $type=shift;
   my $parent=shift;
   my $self=bless({@_},$type);

   $self->setParent($parent);
   return($self);
}

sub Config
{
   my $self=shift;
   return($self->getParent()->Config);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my @WorkflowStep=Query->Param("WorkflowStep");
   my %b=();
   if ($#WorkflowStep>0){
      %b=(PrevStep=>$self->T('previous Step'),
          NextStep=>$self->T('next Step'));
   }
   else{
      %b=(NextStep=>$self->T('next Step'));
   }
   if (defined($WfRec->{id})){
      $b{BreakWorkflow}=$self->T('break Workflow');
   }
   return(%b);
}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   return($self->getParent->getWorkHeight($WfRec,$actions));
}


sub ProcessNext
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;
   return($self->Process($action,$WfRec,$actions));
}

sub ProcessPrev
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;
   return($self->Process($action,$WfRec,$actions));
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   $self->LastMsg(ERROR,"%s is no storeable step",$self->Self());
   return(0);
}


sub preValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   msg(DEBUG,"default preValidate handler in WfStep");

   return(1);
}

sub StoreRecord
{
   my $self=shift;
   my $WfRec=shift;
   my $new=shift;

   if (defined($WfRec)){
      my $id=$WfRec->{id};
      #if ($self->Validate($WfRec,$new)){
         return($self->getParent->getParent->ValidatedUpdateRecord($WfRec,$new,
                                                                   {id=>$id}));
      #}
      #else{
      #   if (!($self->LastMsg())){
      #      $self->LastMsg(ERROR,"StoreRecord->Validate unknown error");
      #   }
      #   return(undef);
      #}
   } 
   my $newincurrent=0;
   if (!defined($new->{class}) && !defined(Query->Param("id"))){
      $newincurrent=1;
   }
   $new->{class}=$self->getParent->Self() if (!defined($new->{class}));
   $new->{step}=$self->Self()             if (!defined($new->{step}));
   my $bk=$self->getParent->getParent->ValidatedInsertRecord($new);
   if ($newincurrent){
      Query->Param("id"=>$bk);
   } 
   return($bk);
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   msg(DEBUG,"default FinishWrite Handler in $self");
}


sub PostProcess
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;
   my %param=@_;
   my $aobj=$self->getParent->getParent->Action();
   my $workflowname=$self->getParent->getWorkflowMailName();

   if ($action eq "SaveStep.wfw5event"){
      my %newparam=(mode=>'EVENT:',
                    workflowname=>$WfRec->{name},
                    addtarget=>$param{addtarget},
                    addcctarget=>$param{addcctarget});
      $aobj->NotifyForward($WfRec->{id},
                           $param{fwdtarget},
                           $param{fwdtargetid},
                           $param{fwdtargetname},
                           $param{note},%newparam);
   }
   elsif ($action eq "SaveStep.wffollowup"){
      my %newparam=(mode=>'FOLLOWUP:',
                    workflowname=>$WfRec->{name},
                    addtarget=>$param{addtarget},
                    addcctarget=>$param{addcctarget},
                    sendercc=>1);
      my $userid=$self->getParent->getParent->getCurrentUserId();
      if (!($param{fwdtarget} eq "base::user" &&
            $param{fwdtargetid} eq $userid)){
         $aobj->NotifyForward($WfRec->{id},
                              $param{fwdtarget},
                              $param{fwdtargetid},
                              $param{fwdtargetname},
                              $param{note},%newparam);
      }
      else{
         #printf STDERR ("fifi no SaveStep.wffollowup message - user is sender\n");
      }
   }
   if ($action eq "SaveStep.wfforward" ||
       $action eq "SaveStep.wfreprocess"){
      $aobj->NotifyForward($WfRec->{id},
                           $param{fwdtarget},
                           $param{fwdtargetid},
                           $param{fwdtargetname},
                           $param{note},
                           workflowname=>$workflowname,
                           sendercc=>1);
   }
   if ($action eq "SaveStep.wfinquiry"){
      $aobj->NotifyForward($WfRec->{id},
                           $param{fwdtarget},
                           $param{fwdtargetid},
                           $param{fwdtargetname},
                           $param{note},
                           mode=>'INQUIRY:',
                           sendercc=>1);
   }
   if ($action eq "SaveStep.wfdefer"){
      my $userid=$WfRec->{initiatorid};
      if ($userid eq ""){
         $userid=$WfRec->{openuser};
      }
      if ($userid ne ""){
         my %newparam=(mode=>'DEFER:',
                       workflowname=>$WfRec->{name},
                       sendercc=>1);
         my $note=$param{note};
         if ($note=~m/^\s*$/){
            $note.=$self->T("The workflow started by you, has been defered ".
                            "with no comments.");
         }
         $aobj->NotifyForward($WfRec->{id},"base::user",$userid,"WF-Initiator",
                              $note,%newparam);
      }
   }

   if ($action=~m/^SaveStep\..*$/){
      Query->Delete("WorkflowStep");
      Query->Delete("note");
      Query->Delete("Formated_note");
      Query->Delete("Formated_effort");
   }


   return(undef);           # return isn't matter
}


sub nativProcess
{
   my $self=shift;
   my $op=shift;
   my $h=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $userid=$self->getParent->getParent->getCurrentUserId();


   if ($op eq "wfw5event"){
      my $note=$h->{note};
      $note=trim($note);
      my %param=(note=>$note,
                 addtarget=>[],
                 addcctarget=>[],
                 additional=>{},
                 fwdtarget=>$WfRec->{fwdtarget},
                 fwdtargetid=>$WfRec->{fwdtargetid});

      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"wfw5event",
          {translation=>'base::workflow::request',
           additional=>$param{additional}},$param{note})){
         $self->PostProcess("SaveStep.".$op,$WfRec,$actions,%param);
         return(1);
      }
      return(0);
   }
   elsif ($op eq "wffollowup"){
      my $note=$h->{note};
      if ($note=~m/^\s*$/  || length($note)<10){
         $self->LastMsg(ERROR,"empty or to short notes are not allowed");
         return(0);
      }
      $note=trim($note);
      my %param=(note=>$note,
                 addtarget=>[],
                 addcctarget=>[],
                 additional=>{},
                 fwdtarget=>$WfRec->{fwdtarget},
                 fwdtargetid=>$WfRec->{fwdtargetid});

      $self->getParent->getFollowupTargetUserids($WfRec,\%param);

      if ($self->getParent->handleFollowupExtended($WfRec,$h,\%param)){
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wffollowup",
             {translation=>'base::workflow::request',
              additional=>$param{additional}},$param{note})){
            $self->PostProcess("SaveStep.".$op,$WfRec,$actions,%param);
            return(1);
         }
      }
      else{
         if (!$self->LastMsg()){
            $self->LastMsg(ERROR,"unknown error in handleFollowupExtended");
         }
      }
      return(0);
   }
   elsif ($op eq "wfschedule"){
#printf STDERR ("WfRec=%s\n",Dumper($WfRec));
#printf STDERR ("h=%s\n",Dumper($h));
      my $autocopymode=$h->{autocopymode};
      my $oprec={autocopymode=>$autocopymode,
                 fwdtarget=>undef,
                 fwdtargetid=>undef,
                 fwddebtarget=>undef,
                 fwddebtargetid=>undef};
      if ($WfRec->{autocopymode} ne $autocopymode){
         $oprec->{autocopydate}=undef;
      }
      $self->StoreRecord($WfRec,$oprec);
      return(0);
   }
   elsif ($op eq "wfhardtake"){
      my $userid=$self->getParent->getParent->getCurrentUserId();
      if ($WfRec->{fwdtarget} eq "base::user"){
         my %newparam=(mode=>'TAKEOVER:',
                       workflowname=>$WfRec->{name},
                       sendercc=>1);
         my $msg=$self->T("TakeOverMailMsg");
         $self->getParent->getParent->Action->NotifyForward($WfRec->{id},
                              $WfRec->{fwdtarget},
                              $WfRec->{fwdtargetid},
                              "",$msg,%newparam);
      }
      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"wftakeover",
          {translation=>'kernel::WfStep'},undef,undef)){
         my $oprec={fwdtarget=>'base::user',
                    fwdtargetid=>$userid,
                    stateid=>4,
                    owner=>$userid,
                    fwddebtarget=>undef,
                    fwddebtargetid=>undef};
         if ($self->StoreRecord($WfRec,$oprec)){
            $self->PostProcess("SaveStep.".$op,$WfRec,$actions);
         }
      }
      return(0);
   }
   elsif($op eq "wfaccept"){
      if ($self->StoreRecord($WfRec,{stateid=>3,
                                     eventend=>undef,
                                     closedate=>undef,
                                     fwdtarget=>'base::user',
                                     fwdtargetid=>$userid,
                                     fwddebtarget=>undef,
                                     fwddebtargetid=>undef})){
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wfaccept",
             {translation=>'kernel::WfStep'},"",undef)){
            $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
            $self->PostProcess("SaveStep.".$op,$WfRec,$actions);
            return(1);
         }
      }
      return(0);
   }
   elsif($op eq "wfreject"){
      my $note=$h->{note};
      my $effort=$h->{effort};
      if ($note=~m/^\s*$/ || length($note)<10){
         $self->LastMsg(ERROR,"empty or to short notes are not allowed");
         return(0);
      }
      $note=trim($note);
      $effort=undef if (!($effort=~m/^\d+$/));

      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"wfreject",
          {translation=>'base::workflow::request'},$note,$effort)){
         my $openuserid=$WfRec->{openuser};
         $self->StoreRecord($WfRec,{stateid=>24,fwdtargetid=>$openuserid,
                                                fwdtarget=>'base::user',
                                                eventend=>NowStamp("en"),
                                                fwddebtarget=>undef,
                                                fwddebtargetid=>undef});

         $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
         $self->PostProcess("SaveStep".".".$op,$WfRec,$actions,
                            note=>$note,
                            fwdtarget=>'base::user',
                            fwdtargetid=>$openuserid,
                            fwdtargetname=>"Requestor");
         return(1);
      }
      return(0);
   }
   elsif ($op eq "wfinquiry"){
      my $action=$op;
      my $note=Query->Param("note");
      $note=trim($note);
   
      my $inquiryrequest="inquiryrequest"; 
      my $fobj=$self->getParent->getField($inquiryrequest);
     # my $f=defined($newrec->{$inquiryrequest}) ?
     #       $newrec->{$inquiryrequest} :
     #       Query->Param("Formated_$inquiryrequest");
      my $f=Query->Param("Formated_$inquiryrequest");

      my $new1;
      if ($new1=$fobj->Validate($WfRec,{$inquiryrequest=>$f})){
         if (!defined($new1->{"${inquiryrequest}id"}) ||
             $new1->{"${inquiryrequest}id"}==0){
            if ($self->LastMsg()==0){
               $self->LastMsg(ERROR,"invalid inquiry target");
            }
            return(0);
         }
      }
      else{
         return(0);
      }
      if ($self->getParent->getParent->getCurrentUserId()==
          $new1->{"${inquiryrequest}id"}){
         $self->LastMsg(ERROR,"you could'nt inquiry by your self");
         return(0);
      }
      if ($note=~m/^\s*$/ ||
          length($note)<10){
         $self->LastMsg(ERROR,"you need to specified a descriptive note");
         return(0);
      }

      my $inquiryrequestname=Query->Param("Formated_inquiryrequest");
      my $info="\@:".$inquiryrequestname;
      $info.="\n".$note;
      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"wfinquiry",
          {translation=>'base::workflow::request',
           additional=>{
                         approvereqtarget=>'base::user',
                         approvereqtargetid=>$new1->{"${inquiryrequest}id"}
                       }},$info,undef)){
         my $openuserid=$WfRec->{openuser};
         if ($self->getParent->getParent->AddToWorkspace($WfRec->{id},
                            "base::user",$new1->{"${inquiryrequest}id"})){
            if ($self->StoreRecord($WfRec,{stateid=>11})){
               Query->Delete("OP");
               #
               # Mail versenden - Genehmigungsanforderung
               #
               $self->PostProcess("SaveStep.".$op,$WfRec,$actions,
                              note=>$note,
                              fwdtarget=>'base::user',
                              fwdtargetid=>$new1->{"${inquiryrequest}id"},
                              fwdtargetname=>$inquiryrequestname);
               return(1);
            }
         }
      }
      return(0);
   }

   elsif ($op eq "wfaddnote" || $op eq "wfaddsnote" || $op eq "wfaddlnote"){
      my $note=$h->{note};
      if ($note=~m/^\s*$/  || length($note)<10){
         $self->LastMsg(ERROR,"empty or to short notes are not allowed");
         return(0);
      }
      $note=trim($note);
      my $oprec={};
      my $inquiryreset=0;
      if (grep(/^iscurrent$/,@{$actions})){ # state "in bearbeitung" darf
         $oprec->{stateid}=4;               # nur gesetzt werden, wenn
         $oprec->{postponeduntil}=undef;    # wf aktuell an mich zugewiesen
      }                                     # u. Rückstellung wird entfernt.
      else{
         if ($WfRec->{stateid}==11){
            $oprec->{stateid}=2;
            $inquiryreset=1;
            $oprec->{postponeduntil}=undef;
         }
      }
      my $effort=$h->{effort};
      my $intiatornotify=$h->{intiatornotify};
      $intiatornotify=1 if ($intiatornotify ne "" &&
                            $intiatornotify ne "0");
      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"wfaddnote",
          {translation=>'base::workflow::request',
           intiatornotify=>$intiatornotify},$note,$effort)){
         my @emailto;

         if ($intiatornotify ne "" && defined($WfRec->{initiatorid}) &&
             $WfRec->{initiatorid} ne ""){
            my $user=getModuleObject($self->Config,"base::user");
            $user->SetFilter({userid=>\$WfRec->{initiatorid}});
            my ($urec,$msg)=$user->getOnlyFirst(qw(email));
            if ($urec->{email} ne ""){
               push(@emailto,$urec->{email});
            }
         }
         if (!grep(/^iscurrent$/,@{$actions})){ #  adder is not current
            if ($WfRec->{fwdtarget} eq "base::user"){  # the current forward
                                                       # needs info about add
               my $user=getModuleObject($self->Config,"base::user");
               $user->SetFilter({userid=>\$WfRec->{fwdtargetid}});
               my ($urec,$msg)=$user->getOnlyFirst(qw(email));
               if ($urec->{email} ne ""){
                  if (!in_array(\@emailto,$urec->{email})){
                     push(@emailto,$urec->{email});
                  }
               }
            }
         }
         if ($#emailto!=-1){
            $self->sendMail($WfRec,emailtext=>$note,emailto=>\@emailto); 
         }

         if ($inquiryreset){
            $self->sendMail($WfRec,emailtext=>$note); 
         }
         $self->StoreRecord($WfRec,$oprec);
         $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
         $self->PostProcess("SaveStep.".$op,$WfRec,$actions);
         Query->Delete("note");
         Query->Delete("intiatornotify");
         return(1);
      }
      return(0);
   }
   else{
      if ($self->getParent->can("nativProcess")){
         return($self->getParent->nativProcess($op,$h,$WfRec,$actions));
      }
   }


   return(0);
}




sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "PrevStep"){
      my @WorkflowStep=Query->Param("WorkflowStep");
      pop(@WorkflowStep);
      Query->Param("WorkflowStep"=>\@WorkflowStep);
      $self->PostProcess($action,$WfRec,$actions);
      return(0);
   }
   elsif ($action eq "NextStep"){
      my $nextstep=$self->getParent->getNextStep($self->Self(),$WfRec); 
      if (!defined($nextstep)){
         $self->getParent->LastMsg(ERROR,"no next step defined in '%s'",
                                   $self->Self());
         return(0);
      }
      my @WorkflowStep=Query->Param("WorkflowStep");
      push(@WorkflowStep,$nextstep);
      Query->Param("WorkflowStep"=>\@WorkflowStep);
      $self->PostProcess($action,$WfRec,$actions);
      return(0);
   }
   elsif($action eq "SaveStep"){
      my $op=Query->Param("OP");
      if ($action ne "" && !grep(/^$op$/,@{$actions})){
         $self->LastMsg(ERROR,"invalid or disallowed action '$action.$op' ".
                              "requested");
         return(0);
      }
      if ($op eq "wfaddnote" || $op eq "wfaddsnote"){
         my $note=Query->Param("note");
         my $effort=Query->Param("Formated_effort");
         my $intiatornotify=Query->Param("intiatornotify");
         my $h={};
         $h->{note}=$note                     if ($note ne "");
         $h->{effort}=$effort                 if ($effort ne "");
         $h->{intiatornotify}=$intiatornotify if ($intiatornotify ne "");
         return($self->nativProcess($op,$h,$WfRec,$actions));
      }
      elsif ($op eq "wfforward" || $op eq "wfreprocess"){ #default forwarding
         my $note=Query->Param("note");
         my ($target,$fwdtarget,$fwdtargetid,$fwddebtarget, 
             $fwddebtargetid,@wsref,$fwdtargetname);
         $note=trim($note);

         my $fobj=$self->getParent->getField("fwdtargetname");
         my $h=$self->getWriteRequestHash("web");
         my $newrec;
         if (!defined($h->{isdefaultforward}) &&
             defined($self->getParent->getField("isdefaultforward"))){
            $h->{isdefaultforward}=0;
         }
         if ($self->getParent->can("getDefaultContractor") &&
             lc($h->{fwdtargetname}) eq "\@default"){
            ($target,$fwdtarget,$fwdtargetid,$fwddebtarget,
                $fwddebtargetid,@wsref)=
                $self->getParent->getDefaultContractor($WfRec,$actions,$action);
            if ($fwdtarget ne "" && $fwdtargetid ne ""){
               $newrec->{fwdtarget}=$fwdtarget;
               $newrec->{fwdtargetid}=$fwdtargetid;
               $fwdtargetname=$target;
            }
         }
         else{
            if ($newrec=$fobj->Validate($WfRec,$h)){
               if (!defined($newrec->{fwdtarget}) ||
                   !defined($newrec->{fwdtargetid} ||
                   $newrec->{fwdtargetid}==0)){
                  if ($self->LastMsg()==0){
                     $self->LastMsg(ERROR,"invalid forwarding target");
                  }
                  return(0);
               }
               if ($newrec->{fwdtarget} eq "base::user"){
                  # check against distribution contacts
                  my $user=getModuleObject($self->Config,"base::user");
                  $user->SetFilter({userid=>\$newrec->{fwdtargetid}});
                  my ($urec,$msg)=$user->getOnlyFirst(qw(usertyp));
                  if (!defined($urec) || 
                      ($urec->{usertyp} ne "user" &&
                       $urec->{usertyp} ne "service")){
                     $self->LastMsg(ERROR,
                                    "selected forward user is not allowed");
                     return(0);
                  }
               }
            }
            else{
               return(0);
            }
            if ($newrec=$fobj->Validate($WfRec,$h)){
               if (!defined($newrec->{fwdtarget}) ||
                   !defined($newrec->{fwdtargetid} ||
                   $newrec->{fwdtargetid}==0)){
                  if ($self->LastMsg()==0){
                     $self->LastMsg(ERROR,"invalid forwarding target");
                  }
                  return(0);
               }
               if ($newrec->{fwdtarget} eq "base::user"){
                  # check against distribution contacts
                  my $user=getModuleObject($self->Config,"base::user");
                  $user->SetFilter({userid=>\$newrec->{fwdtargetid}});
                  my ($urec,$msg)=$user->getOnlyFirst(qw(usertyp));
                  if (!defined($urec) || 
                      ($urec->{usertyp} ne "user" &&
                       $urec->{usertyp} ne "service")){
                     $self->LastMsg(ERROR,"selected forward user is not allowed");
                     return(0);
                  }
               }
            }
            else{
               return(0);
            }
            $fwdtargetname=Query->Param("Formated_fwdtargetname");
         }

         if ($self->StoreRecord($WfRec,{stateid=>2,
                                        eventend=>undef,
                                        closedate=>undef,
                                        fwdtarget=>$newrec->{fwdtarget},
                                        fwdtargetid=>$newrec->{fwdtargetid},
                                        fwddebtarget=>$fwddebtarget,
                                        fwddebtargetid=>$fwddebtargetid })){
            if ($self->getParent->getParent->Action->StoreRecord(
                $WfRec->{id},"wfforward",
                {translation=>'base::workflow::request'},$fwdtargetname."\n".
                                                         $note,undef)){
               my $openuserid=$WfRec->{openuser};
               $self->getParent->getParent->CleanupWorkspace($WfRec->{id});

               my $id=$WfRec->{id};
               if ($#wsref!=-1){
                  while(my $target=shift(@wsref)){
                     my $targetid=shift(@wsref);
                     last if ($targetid eq "" || $target eq "");
                     $self->getParent->getParent->AddToWorkspace($id,
                                                          $target,$targetid);
                  }
               }

               $self->PostProcess($action.".".$op,$WfRec,$actions,
                                  note=>$note,
                                  fwdtarget=>$newrec->{fwdtarget},
                                  fwdtargetid=>$newrec->{fwdtargetid},
                                  fwdtargetname=>$fwdtargetname);
               Query->Delete("OP");
               return(1);
            }
         }
         return(0);
      }
      elsif ($op eq "wfdefer"){
         my $app=$self->getParent->getParent;
         my $note=Query->Param("note");
         if ($note=~m/^\s*$/  || length($note)<10){
            $self->LastMsg(ERROR,"empty or to short notes are not allowed");
            return(0);
         }
         $note=trim($note);
         my $oprec={};
         $oprec->{stateid}=5;
         my $postponeduntil=Query->Param("Formated_postponeduntil");
         $oprec->{postponeduntil}=$app->ExpandTimeExpression($postponeduntil);
         if ($oprec->{postponeduntil} ne ""){
            my $from=$WfRec->{eventstart};
            my $d1=CalcDateDuration(NowStamp("en"),$oprec->{postponeduntil});
            my $d2=CalcDateDuration($from,$oprec->{postponeduntil});
            if ($self->getParent->ValidatePostpone(
                   $WfRec,$oprec->{postponeduntil},$d1,$d2)){
               if ($app->Action->StoreRecord($WfRec->{id},"wfdefer",
                   {translation=>'base::workflow::request'},$note)){
                  $self->StoreRecord($WfRec,$oprec);
                  $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
                  $self->PostProcess($action.".".$op,$WfRec,$actions,
                                     note=>$note);
                  Query->Delete("note");
                  Query->Delete("OP");
                  return(1);
               }
               if ($app->LastMsg()==0){
                  $app->LastMsg(ERROR,
                                "store postponeduntil action record failed");
               }
            }
            else{
               if ($app->LastMsg()==0){
                  $app->LastMsg(ERROR,"postponeduntil rejected");
               }
               return(undef);
            }
         }
         else{
            $app->LastMsg(ERROR,"invalid postponeduntil specifed");
         }
         return(0);
      }
      elsif ($op eq "wfmailsend"){    # default mailsending handling
          
         my $emailto=Query->Param("emailto");
         my $shortnote=Query->Param("emailmsg");

         $shortnote=trim($shortnote);
         if (length($shortnote)<10){
            $self->LastMsg(ERROR,"empty or not descriptive messages ".
                                 "are not allowed");
            return(0);
         }
         my $note=$shortnote;
         if ($ENV{SCRIPT_URI} ne ""){
            my $baseurl=$ENV{SCRIPT_URI};
            $baseurl=~s#/(auth|public)/.*$##;
            my $jobbaseurl=$self->Config->Param("EventJobBaseUrl");
            if ($jobbaseurl ne ""){
               $jobbaseurl=~s#/$##;
               $baseurl=$jobbaseurl;
            }
            my $url=$baseurl;
            if (lc($ENV{HTTP_FRONT_END_HTTPS}) eq "on"){
               $url=~s/^http:/https:/i;
            }
            $url.="/auth/base/workflow/ById/".$WfRec->{id};
            $note.="\n\n\n".$self->T("Workflow Link").":\n";
            $note.=$url;
            $note.="\n\n";
         }
         my $wf=$self->getParent->getParent();
         my $subject=$WfRec->{name};
         my $from='no_reply@w5base.net';
         my @to=();
         my $UserCache=$self->Cache->{User}->{Cache};
         if ($emailto=~m/^\s*$/){
            $self->LastMsg(ERROR,"no email address specified");
            return(0);
         }
         my %adr=(emailto=>$emailto);
         if (defined($UserCache->{$ENV{REMOTE_USER}})){
            $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
         }
         if (defined($UserCache->{email}) &&
             $UserCache->{email} ne ""){
            $adr{emailcc}=$UserCache->{email};
         }
         if (my $id=$wf->Store(undef,{
                 class    =>'base::workflow::mailsend',
                 step     =>'base::workflow::mailsend::dataload',
                 name     =>$subject,%adr,
                 emailtext=>$note,
                })){
            my %d=(step=>'base::workflow::mailsend::waitforspool');
            if ($wf->Store($id,%d)){
               $self->getParent->getParent->Action->StoreRecord(
                   $WfRec->{id},"wfmailsend",
                   {translation=>'kernel::WfStep'},"\@:".
                                 $emailto."\n\n".$shortnote);
               $self->PostProcess($action.".".$op,$WfRec,$actions,
                                  note=>$shortnote);
               Query->Delete("OP");
               Query->Delete("emailto");
               Query->Delete("emailmsg");
            }
            return(1);
         }
      }
      else{
         my $h=$self->getWriteRequestHash("web");
         return($self->nativProcess($op,$h,$WfRec,$actions));
      }


   }
   return(0);
}

sub sendMail
{
   my $self=shift;
   my $WfRec=shift;
   my %param=@_;
   my %m;

   $m{name}=trim($param{subject});
   $m{emailtext}=trim($param{emailtext});
   if (ref($param{emailto}) eq "ARRAY"){
      $m{emailto}=$param{emailto};
   }
   else{
      $m{emailto}=trim($param{emailto});
   }
   if ($param{emailto} eq ""){
      my $fwdtarget=$WfRec->{fwdtarget};
      my $fwdtargetid=$WfRec->{fwdtargetid};
      my @to;
      if ($fwdtarget eq "base::user"){
         my $u=getModuleObject($self->Config,"base::user");
         $u->SetFilter(userid=>\$fwdtargetid);
         my ($rec,$msg)=$u->getOnlyFirst(qw(email));
         if (defined($rec)){
            push(@to,$rec->{email});
         }
      }
      if ($fwdtarget eq "base::grp"){
         my $grp=$self->{grp};
         if (!defined($grp)){
            $grp=getModuleObject($self->Config,"base::grp");
            $self->{grp}=$grp;
         }
         $grp->ResetFilter();
         if ($fwdtargetid ne ""){
            $grp->SetFilter(grpid=>\$fwdtargetid);
         }
         my @acl=$grp->getHashList(qw(grpid users));
         my %u=();
         foreach my $grprec (@acl){
            if (defined($grprec->{users}) && ref($grprec->{users}) eq "ARRAY"){
               foreach my $usr (@{$grprec->{users}}){
                  $u{$usr->{email}}=1;
               }
            }
         }
         @to=keys(%u);
      }
      $m{emailto}=\@to;
   }

   if ($ENV{SCRIPT_URI} ne ""){
      my $baseurl=$ENV{SCRIPT_URI};
      $baseurl=~s#/(auth|public)/.*$##;
      my $url=$baseurl;
      if (lc($ENV{HTTP_FRONT_END_HTTPS}) eq "on"){
         $url=~s/^http:/https:/i;
      }
      $url.="/auth/base/workflow/ById/".$WfRec->{id};
      $m{emailtext}.="\n\n\n".$self->T("Workflow Link").":\n";
      $m{emailtext}.=$url;
      $m{emailtext}.="\n\n";
   }
   my $wf=$self->getParent->getParent->Clone();
   if (!defined($m{name})){
      $m{name}="Info: ".$WfRec->{name};
   }
   $m{emailfrom}='no_reply@w5base.net';
   my @to=();
   my $UserCache=$self->Cache->{User}->{Cache};
   if ($m{emailto}=~m/^\s*$/){
      $self->LastMsg(ERROR,"no email address specified");
      return(0);
   }
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   if (defined($UserCache->{email}) &&
       $UserCache->{email} ne ""){
      $m{emailfrom}=$UserCache->{email};
      if (!defined($m{emailfrom})){
         $m{emailcc}=$UserCache->{email};
      }
   }
   $m{class}='base::workflow::mailsend';
   $m{step}='base::workflow::mailsend::dataload';
   if (my $id=$wf->Store(undef,\%m)){
      my %d=(step=>'base::workflow::mailsend::waitforspool');
      if ($wf->Store($id,%d)){
         return(1);
      }
      return(0);
   }
   return(0);
}


sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $divset="";
   my $selopt="";

   my $wsheight=$self->getWorkHeight($WfRec);
   $wsheight="200" if ($wsheight=~m/%/);
   $wsheight=~s/px//g;


   my $defo=$self->generateWorkspacePages($WfRec,$actions,\$divset,\$selopt,
                                          $wsheight);   
   my $oldop=Query->Param("OP");
   if (!defined($oldop) || $oldop eq "" || !grep(/^$oldop$/,@{$actions})){
      if (length($defo)<30 && ($defo=~m/^[a-z0-9]+$/i)){
         $oldop=$defo;
      }
   }
   my $templ;
   if ($divset eq ""){
      return("<table width=\"100%\"><tr><td>&nbsp;</td></tr></table>");
   }
   my $pa=$self->getParent->T("possible action");
   my $tabheight=$wsheight-30;
   $tabheight=30 if ($tabheight<30);  # ensure, that tabheigh is not negativ
   $templ=<<EOF;
<table width="100%" height="$tabheight" border=0 cellspacing=0 cellpadding=1>
<tr height=1%><td width=1% nowrap>&nbsp;$pa &nbsp;</td>
<td><select id=OP name=OP style="width:100%">$selopt</select></td></tr>
<tr><td colspan=3 valign=top>$divset</td></tr>
</table>
<script language="JavaScript">
function fineSwitch(s)
{
   var sa=document.forms[0].elements['SaveStep'];
   if (s.value=="nop"){
      if (sa){
         sa.disabled=true;
      }
   }
   else{
      if (sa){
         sa.disabled=false;
      }
   }
}
function InitDivs()
{
   var s=document.getElementById("OP");
   divSwitcher(s,"$oldop",fineSwitch);
}
addEvent(window,"load",InitDivs);
//InitDivs();
//window.setTimeout(InitDivs,1000);   // ensure to disable button (mozilla bug)
</script>
EOF

   return($templ);
}



sub generateWorkspacePages
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $divset=shift;
   my $selopt=shift;
   my $height=shift;
   my $tr="base::workflow::actions";
   my $class="display:none;visibility:hidden";

   if (grep(/^wfforward$/,@$actions)){
      $$selopt.="<option value=\"wfforward\">".
                $self->getParent->T("wfforward",$tr).
                "</option>\n";
      my $note=Query->Param("note");

      my $d="<table width=\"100%\" border=0 cellspacing=0 cellpadding=0><tr>".
         "<td colspan=2><textarea name=note ".
         "style=\"width:100%;resize:none;height:100px\">".
         quoteHtml($note)."</textarea></td></tr>";
      $d.="<tr><td width=1% nowrap>".
          $self->getParent->T("forward to","base::workflow::request").
          ":&nbsp;</td>".
          "<td>\%fwdtargetname(detail)\%".
          "</td>";
      $d.="</tr></table>";
      $$divset.="<div id=OPwfforward class=\"$class\">$d</div>";
   }
   if (grep(/^wfschedule$/,@$actions)){
      my @t=(''       =>$self->getParent->T("no automatic scheduling"),
             'month'  =>$self->getParent->T("monthly"),
            # 'week'   =>$self->getParent->T("weekly")
            );
      my $s="<select name=Formated_autocopymode style=\"width:280px\">";
      my $oldval=Query->Param("Formated_autocopymode");
      while(defined(my $min=shift(@t))){
         my $l=shift(@t);
         $s.="<option value=\"$min\"";
         $s.=" selected" if ($min eq $oldval);
         $s.=">$l</option>";
      }
      $s.="</select>";

      $$selopt.="<option value=\"wfschedule\">".
                $self->getParent->T("wfschedule",$tr).
                "</option>\n";
      my $d="<table width=\"100%\" border=0 cellspacing=0 cellpadding=4><tr>".
         "<td colspan=2><br>Automaticly scheduling will copy this worklow in a selectable interval. After copy process, the new workflow will be activated automaticly. The result of the operation will be mailed to the creator of this workflow. ATTENSION: This function is Test!!!".
         "<br><br></td></tr>";
      $d.="<tr><td width=1% nowrap>".
          "select scheduling intervall:</td>".
          "<td>".$s."</td>";
      $d.="</tr></table>";
      $$divset.="<div id=OPwfschedule class=\"$class\">$d</div>";
   }
   if (grep(/^nop$/,@$actions)){  # put nop NO-Operation at the begin of list
      $$selopt="<option value=\"nop\" class=\"$class\">".
                $self->getParent->T("nop",$tr).
                "</option>\n".$$selopt;
      if ($height>100){
         $$divset="<div id=OPnop style=\"margin:15px\"><br>".
                   $self->getParent->T("The current workflow isn't forwared ".
                   "to you. At now there is no action nessasary.",$tr)."</div>".
                   $$divset;
      }
      else{
         my $initial=0;
         if ($ENV{HTTP_REFERER}=~m#/base/workflow/New$#){
            $initial++;
         }
         my $localdiv="<div id=OPnop style=\"margin:15px\">";
         if ($initial){
            $localdiv.=$self->getParent->T("INITIALMSG000",$tr);
         }
         $localdiv.="</div>";
         $$divset=$localdiv.$$divset;
      }
   }
   if (grep(/^wfreject$/,@$actions)){
      my $note=Query->Param("note");
      $$selopt.="<option value=\"wfreject\">".
                $self->getParent->T("wfreject",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfreject class=\"$class\"><textarea name=note ".
                "style=\"width:100%;height:110px\">".
                unHtml($note)."</textarea></div>";
   }
   if (grep(/^wfmailsend$/,@$actions)){
      my $wfheadid=$WfRec->{id};
      my $userid=$self->getParent->getParent->getCurrentUserId();
      $$selopt.="<option value=\"wfmailsend\">".
                $self->getParent->T("wfmailsend",$tr).
                "</option>\n";
      my $onclick="openwin(\"externalMailHandler?".
                   "id=$wfheadid&parent=base::workflow&mode=simple\",".
                   "\"_blank\",".
                   "\"height=400,width=600,toolbar=no,status=no,".
                   "resizable=yes,scrollbars=no\")";
      my @m;
      if (defined($WfRec->{openuser}) && $WfRec->{openuser}=~m/^\d+$/ &&
          $WfRec->{openuser} ne $userid){
         push(@m,$self->getParent->T("to opener")); 
         push(@m,{to=>"base::user($WfRec->{openuser})"});
      }
      if (defined($WfRec->{initiatorid}) && $WfRec->{initiatorid}=~m/^\d+$/ &&
          $WfRec->{initiatorid} ne $userid){
         push(@m,$self->getParent->T("to initiator")); 
         push(@m,{to=>"base::user($WfRec->{initiatorid})"});
      }
      if (defined($WfRec->{owner}) && $WfRec->{owner}=~m/^\d+$/ &&
          $WfRec->{owner} ne $userid){
         push(@m,$self->getParent->T("to current owner")); 
         push(@m,{to=>"base::user($WfRec->{owner})"});
      }
      if (defined($WfRec->{fwdtargetid}) && $WfRec->{fwdtargetid}=~m/^\d+$/ &&
          !($WfRec->{fwdtarget} eq "base::user" && $WfRec->{fwdtargetid} eq $userid)){
         push(@m,$self->getParent->T("to current forward")); 
         push(@m,{to=>"$WfRec->{fwdtarget}($WfRec->{fwdtargetid})"});
      }
      if (defined($WfRec->{initiatorgroupid}) && 
          $WfRec->{initiatorgroupid}=~m/^\d+$/){
         push(@m,$self->getParent->T("to initiator group")); 
         push(@m,{to=>"base::grp($WfRec->{initiatorgroupid})"});
      }
#      if (defined($WfRec->{initiatorgroupid}) && 
#          $WfRec->{initiatorgroupid}=~m/^\d+$/){
#         push(@m,$self->getParent->T("to all related")); 
#         push(@m,{to=>"AllRelated_base::workflow($WfRec->{id})"});
#      }

      sub Hash2Onclick
      {
         my $param=shift;
         my $p=kernel::cgi::Hash2QueryString($param);
         
         return("openwin(\"externalMailHandler?$p\",".
                      "\"_blank\",".
                      "\"height=400,width=600,toolbar=no,status=no,".
                      "resizable=yes,scrollbars=no\")");
      }
      my $d="<table width=\"100%\" border=0 cellspacing=0 cellpadding=0>";
      #if ($#m!=-1){
         my $param={}; 
         $param->{parent}="base::workflow";
         $param->{mode}="workflowrepeat($wfheadid)";
         $param->{id}=$wfheadid;
         $onclick=Hash2Onclick($param);
         $onclick=~s/%/\\%/g;
         $d.="<tr><td width=40% valign=top><span onclick=$onclick>".
             "<div style=\"cursor:pointer;cursor:hand;".
             "margin:2px;font-size:9px;margin-right:20px\">".
             $self->getParent->T("This action sends a E-Mail with automaticly ".
                             "dokumentation in the workflow log").
             "</div></span></td><td>";
         $d.="<table border=0>";
         my $col=0;
         while(my $label=shift(@m)){
            my $param=shift(@m);
            $param->{parent}="base::workflow";
            $param->{mode}="simple";
            $param->{id}=$wfheadid;
            $onclick=Hash2Onclick($param);
            $onclick=~s/%/\\%/g;
            $d.="<tr>" if ($col==0);
            $d.="<td valign=center width=1%>".
                "<span class=sublink onclick=$onclick>".
                "<img style=\"margin-left:4px\" ".
                "src=\"../../../public/base/load/minimail.gif\">".
                "</span></td>";
            $d.="<td valign=center nowrap>".
                "<span class=sublink onclick=$onclick>".$label."</span></td>";
            $col++;
            if ($col==3){
               $d.="</tr>";
               $col=0;
            }
         }
         $d.="</tr>" if ($col==1 || $col==2);
         $d.="</table>";
         $d.="</td></tr>";
      #}


      $d.="<tr>".
         "<td colspan=2>".
      #   "<table width=\"100%\" cellspacing=0 cellpadding=0><tr>".
      #   "<td nowrap width=1%>".
      #   $self->getParent->T("to").": &nbsp;</td><td>".
      #   "<input type=text name=emailto style=\"width:100%\">".
      #   "</td></tr></table></td></tr>".
      #   "<tr>".
      #   "<td colspan=2><textarea name=emailmsg ".
      #   "style=\"width:100%;height:50px\">".
      #   "</textarea>";
         "</td></tr>";
      $d.="</table>";
      $$divset.="<div id=OPwfmailsend class=\"$class\">$d</div>";
   }
   if (grep(/^wfhardtake$/,@$actions)){
      $$selopt.="<option value=\"wfhardtake\">".
                $self->getParent->T("wfhardtake",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfhardtake class=\"$class\">".
                "<div style=\"padding:10px\">".
                $self->getParent->T("wftakemessage",$tr).
                "</div>".
                "</div>";
   }
   if (grep(/^wfaddnote$/,@$actions)){
      $$selopt.="<option value=\"wfaddnote\">".
                $self->getParent->T("wfaddnote",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfaddnote class=\"$class\">".
                $self->getDefaultNoteDiv($WfRec,$actions).
                "</div>";
   }
   if (grep(/^wfinquiry$/,@$actions)){
      $$selopt.="<option value=\"wfinquiry\">".
                $self->getParent->T("wfinquiry",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfinquiry class=\"$class\">".
                "<table width=\"100%\" border=0 cellspacing=0 cellpadding=1>".
                "<tr><td width=1% nowrap>&nbsp;%inquiryrequest(label)% ".
                ":&nbsp;</td>".
                "<td>\%inquiryrequest(detail)\%".
                "</td></tr>".
                "</table>".
                $self->getDefaultNoteDiv($WfRec,$actions,mode=>'inquiry',
                                                         height=>80).
                "</div>";
   }
   if (grep(/^wfaddsnote$/,@$actions)){
      $$selopt.="<option value=\"wfaddsnote\">".
                $self->getParent->T("wfaddsnote",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfaddsnote class=\"$class\">".
                $self->getDefaultNoteDiv($WfRec,$actions,mode=>'simple').
                "</div>";
   }
   if (grep(/^wfaddlnote$/,@$actions)){
      $$selopt.="<option value=\"wfaddlnote\">".
                $self->getParent->T("wfaddlnote",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfaddlnote class=\"$class\">".
                $self->getDefaultNoteDiv($WfRec,$actions,mode=>'local').
                "</div>";
   }
   if (grep(/^wfdefer$/,@$actions)){
      $$selopt.="<option value=\"wfdefer\">".
                $self->getParent->T("wfdefer",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfdefer class=\"$class\">".
                $self->getDefaultNoteDiv($WfRec,$actions,mode=>"defer").
                "</div>";
   }
   if (grep(/^wfstartnew$/,@$actions)){
      my @l=$self->getParent->getPosibleWorkflowDerivations($WfRec,$actions);
      if ($#l>-1){
         $$selopt.="<option value=\"wfstartnew\">".
                   $self->getParent->T("wfstartnew",$tr).
                   "</option>\n";
         my $d="<div id='wfstartnewContainer' unselectable=\"on\" ".
               "style=\"height:90px;border-style:solid;".
               "-moz-user-select:none;khtml-user-select: none;".
               "border-color:gray;xborder-width:1px;overflow:auto;".
               "padding:5px\" class=\"noselect\">";
         $d.="<script language=JavaScript>";
         $d.="function markDerivateWorkflowLine(o){";
         $d.=" var blk=document.getElementById('wfstartnewContainer');";
         $d.=" for(var count=0;count<blk.childNodes.length; count++){";
         $d.="   if (blk.childNodes[count].tagName=='DIV' && ";
         $d.="      blk.childNodes[count].className=='DerivateWorkflowActiv'){";
         $d.="     blk.childNodes[count].className='DerivateWorkflowInActiv';";
         $d.="   }";
         $d.=" }";
         $d.=" var v=document.getElementById('doDerivateWorkflow');";
         $d.=" v.value=o.id;";
         $d.=" o.className='DerivateWorkflowActiv'";
         $d.="}";
         $d.="</script>";
         foreach my $derivRec (@l){
            $d.="<div id=\"$derivRec->{name}\" ".
                "class=DerivateWorkflowInActiv ".
                "style=\"cursor:pointer\"  ".
                "onclick=\"markDerivateWorkflowLine(this);\" ".
                "ondblclick=\"markDerivateWorkflowLine(this);".
                "derivateWorkflow();\">";
            if (!defined($derivRec->{icon})){
               $derivRec->{icon}='../../base/load/MyW5Base-NewWf.jpg';
            }
            my $i="<img border=0 style=\"padding:2px\" ".
                  "src=\"$derivRec->{icon}\" width=30 height=30>";
            $d.="<div style=\"float:left;width:34px;height:34px\">$i</div>".
                "<div style=\"float:left;height:34px;".
                "padding-top:5px;padding-left:5px;cursor:pointer\">".
                $derivRec->{label}."</div>";
            $d.="<div style='clear:both'></div>";
            $d.="</div>";
         }
         $d.="\n<input type=hidden ".
             "id=doDerivateWorkflow name=doDerivateWorkflow>";
         $d.="\n</div>\n";
         $$divset.="<div id=OPwfstartnew class=\"$class\">".
                   "<div style=\"padding:5px\">".$d.
                   "</div>".
                   "</div>";
      }
   }

}

sub generateStoredWorkspace
{
   my $self=shift;
   my @steplist=@_;

   my $step=pop(@steplist);
   if (defined($step)){
      my $StepObj=$self->getParent->getStepObject($self->Config,$step);
      return($StepObj->generateStoredWorkspace(@steplist));
   }
   return("");
}

#sub getFieldObjsByView
#{
#   my $self=shift;
#   return($self->getParent->getFieldObjsByView(@_));
#}

#sub getClassFieldList
#{
#   my $self=shift;
#   return($self->getParent->getClassFieldList(@_));
#}

sub getWriteRequestHash
{
   my $self=shift;

   return($self->getParent->getParent->getWriteRequestHash(@_));
}


sub getField
{
   my $self=shift;

   return($self->getParent->getField(@_));
}

sub getNextStep
{
   my $self=shift;
   return($self->getParent->getNextStep($self->Self,@_)) if ($#_<=0);
   return($self->getParent->getNextStep(@_));
}

sub ValidActionCheck
{
   my $self=shift;
   return($self->getParent->ValidActionCheck(@_));
}


sub getDefaultNoteDiv
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my %param=@_;
   my $mode=$param{mode};
   $mode="addnote" if ($mode eq "");
   my $name=$param{name};
   $name="note" if ($name eq "");

   my $userid=$self->getParent->getParent->getCurrentUserId();
   my $initiatorid=$WfRec->{initiatorid};
   my $creator=$WfRec->{openuser};

   my $wsheight=$self->getWorkHeight($WfRec,$actions);
   $wsheight="200" if ($wsheight=~m/%/);
   $wsheight=~s/px//g;

   my $noteheight=$wsheight-90;
   if (defined($param{height})){
      $noteheight=$param{height};
   }

   my $note=Query->Param($name);
   my $d="<table width=\"100%\" border=0 cellspacing=0 cellpadding=0><tr>".
         "<td colspan=2><textarea name=$name ".
         "onkeydown=\"textareaKeyHandler(this,event);\" ".
         "style=\"width:100%;resize:none;height:${noteheight}px\">".
         quoteHtml($note)."</textarea></td></tr>";
   if ($mode eq "local"){
      $d.="<tr><td valign=left style='padding:2px'>".
          $self->getParent->getParent->T("LOCALNOTE","base::workflowaction").
          "<td></tr>";
   }
   if ($mode eq "addnote" || $mode eq "simple"){
      if ($mode eq "simple"){
         $d.="<tr><td width=1% nowrap valign=center>&nbsp;";
      }
      else{
         $d.="<tr><td width=1% nowrap valign=center>&nbsp;".
             $self->getParent->getParent->T("personal Effort",
                                            "base::workflowaction").
             ":&nbsp;</td>".
             "<td nowrap valign=center>".
             $self->getParent->getParent->Action->
                    getEffortSelect("Formated_effort");
      }
      if (defined($WfRec->{initiatorid}) && $userid ne $WfRec->{initiatorid}){
         $d.="&nbsp;&nbsp;&nbsp;";
         $d.="&nbsp;&nbsp;&nbsp;";
         $d.=$self->getParent->getParent->T("notify intiator",
                                         "base::workflowaction");
         my $oldval=Query->Param("intiatornotify");
         my $checked;
         $checked=" checked " if ($oldval ne "");
         $d.="&nbsp;<input style=\"background-color:transparent\" ".
             "type=checkbox $checked name=\"intiatornotify\">";
      }


      $d.="</td>";
      $d.="</tr>";
    #  this must be added, if it is sure that costcenter are always recorded
    #  if ($WfRec->{involvedcostcenter} eq "" && $mode eq "addnote"){
    #      $d.="<tr><td colspan=2>";
    #      $d.="&nbsp; <b>".$self->getParent->getParent->T(
    #          "NOTE: no costcenter allocation posible!")."</b>";
    #      $d.="</td></tr>";
    #  }
   }
   if ($mode eq "defer"){
      my $app=$self->getParent->getParent;
      #######################################################################
      # Build a select box with free editable entry (other)
      #
      my $eid="e".time().int(rand(1000));
      my $oldval=Query->Param("Formated_postponeduntil");
      $oldval="now+7d" if ($oldval eq "" || $oldval eq "now+?d");
      my @t=(
             'now+7d'  =>$app->T("one week"),
             'now+14d' =>$app->T("two weeks"),
             'now+28d' =>$app->T("one month"),
             'now+60d' =>$app->T("two months"),
             'now+90d' =>$app->T("three months"),
             'now+180d'=>$app->T("half a year"),
             'now+?d'  =>$app->T("other"));
      $d.="<tr><td width=1% nowrap>".
          $app->T("postponed until").
          ":&nbsp;</td>".
          "<td>";
      my $s="";
      $s.="<script language=\"JavaScript\" type=\"text/javascript\">";
      $s.="function OnChange$eid(dropDown){";
      $s.="var selectedValue = dropDown.options[dropDown.selectedIndex].value;";
      $s.="document.getElementById(\"text$eid\").value=selectedValue;";
      $s.="if (selectedValue=='now+?d'){";
      $s.=" document.getElementById(\"text$eid\").style.visibility='visible';";
      $s.=" dropDown.style.display='none';";
      $s.=" dropDown.style.visibility='hidden';";
      $s.=" dropDown.style.width='0px';";
      $s.="}";
      $s.="}";
      $s.="</script>";
      $s.="<select onChange=\"OnChange$eid(this);\" style=\"width:200px\">";
      my $foundentry=0;
      while(defined(my $min=shift(@t))){
         my $l=shift(@t);
         $s.="<option value=\"$min\"";
         if ($min eq $oldval){
            $s.=" selected";
            $foundentry++;
         }
         $s.=">$l</option>";
      }
      $s.="</select>";
      my $textboxtype="visibility:visible";
      if ($foundentry){
         $textboxtype="visibility:hidden";
         $d.=$s;
      }

      $oldval=quoteHtml($oldval);
      $d.="<input id=\"text$eid\" ".
          "type=\"text\" value=\"$oldval\" ".
          "style=\"width:200px;$textboxtype\" ".
          "name=\"Formated_postponeduntil\">";
      #######################################################################
      $d.="</td>";
      $d.="</tr>";
   }
   $d.="</table>";
   return($d);
}



sub generateNotificationPreview
{
   my $self=shift;
   return($self->getParent->generateNotificationPreview(@_));
}

sub CreateSubTip
{
   my $self=shift;
   my $subtip="";
   my $url=$ENV{SCRIPT_URI};
   $url=~s/\/auth\/.*$//;
   $url.="/auth/base/menu/msel/MyW5Base";
   my $qhash=Query->MultiVars();
   delete($qhash->{NextStep});
   delete($qhash->{SaveStep});
   my $qhash=new kernel::cgi($qhash);
   my $OpenURL="$ENV{SCRIPT_URI}?".$qhash->QueryString();
   if (lc($ENV{HTTP_FRONT_END_HTTPS}) eq "on"){
      $OpenURL=~s/^http:/https:/i;
      $url=~s/^http:/https:/i;
   }
   my $openquery={OpenURL=>$OpenURL};
   my $queryobj=new kernel::cgi($openquery);
   $url.="?".$queryobj->QueryString();
   $url=~s/\%/\\\%/g;
   if (length($url)<2048){ # a limitation by Microsoft
      $subtip.="<div style=\"border-style:solid;border-width:1px;".
               "border-color:gray\">";
      my $a="<a href=\"$url\" ".
            "target=_blank title=\"Workflow link included current query\">".
            "<img src=\"../../base/load/anker.gif\" ".
            "height=10 border=0></a>";
      $subtip.="&nbsp;".sprintf($self->getParent->T(
                    "You can add a shortcut of this anker %s to ".
                    "your bookmarks, to access faster to this workflow.",
                    'base::workflow'),$a);
      $subtip.="</div>";
   }
   return($subtip);
}


1;

