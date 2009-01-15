package base::workflow::request;
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
use vars qw(@ISA);
use kernel;
use kernel::WfClass;
@ISA=qw(kernel::WfClass);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{history}=[qw(insert modify delete)];

   $self->AddFrontendFields(
      new kernel::Field::TextDrop(
                name          =>'approverrequest',
                label         =>'Approve requested by',
                htmldetail    =>0,
                group         =>'init',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['approverrequestid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link (
                name          =>'approverrequestid',
                container     =>'headref'),

    );
   return($self);
}

sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;

   return($self->InitFields(
      new kernel::Field::TextDrop(
                name          =>'initiator',
                label         =>'Initiated by',
                group         =>'init',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['initiatorid'=>'userid'],
                vjoindisp     =>'fullname',
                altnamestore  =>'initiatorname'),

      new kernel::Field::TextDrop(
                name          =>'initiatorgroupname',
                label         =>'Initiated by group',
                group         =>'init',
                AllowEmpty    =>1,
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['initiatorgroupid'=>'grpid'],
                vjoindisp     =>'fullname',
                altnamestore  =>'initiatorgroup'),

      new kernel::Field::Link (
                name          =>'initiatorid',
                container     =>'headref'),

      new kernel::Field::Link (
                name          =>'initiatorgroupid',
                container     =>'headref'),

      new kernel::Field::Link (
                name          =>'initiatorname',
                container     =>'headref'),

      new kernel::Field::Link (
                name          =>'initiatorgroup',
                container     =>'headref'),

      new kernel::Field::Text (
                name          =>'implementedto',
                group         =>'init',
                label         =>'implemented to',
                container     =>'headref'),

      new kernel::Field::Textarea(
                name          =>'initiatorcomments',
                label         =>'Comments of implementor',
                group         =>'init',
                container     =>'headref'),

      new kernel::Field::Text(
                name          =>'conumber',
                label         =>'CO-Number',
                htmldetail    =>0,
                readonly      =>1,
                container     =>'headref'),


    ));
}


sub IsModuleSelectable
{
   my $self=shift;
   my $acl;

   $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
                          "base::workflow",
                          func=>'New',
                          param=>'WorkflowClass=base::workflow::request');
   if (defined($acl)){
      return(1) if (grep(/^read$/,@$acl));
   }
   return(1) if ($self->getParent->IsMemberOf("admin"));
   return(0);
}

sub InitWorkflow
{
   my $self=shift;
   return(undef);
}

sub getDefaultContractor
{
   my $self=shift;
   return('');
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","state","flow","header","relations","init","history");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(1) if (!defined($rec));
   my @l;
   push(@l,"default") if ($rec->{state}<10 &&
                         ($self->isCurrentForward() ||
                          $self->getParent->IsMemberOf("admin")));
   if (grep(/^default$/,@l) &&
       ($self->getParent->getCurrentUserId() != $rec->{initiatorid} ||
        $self->getParent->IsMemberOf("admin"))){
      push(@l,"init");
   }
   return(@l);
}

sub getDetailBlockPriority            # posibility to change the block order
{
   return("init","flow");
}





sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   return("base::workflow::request::".$shortname);
}


sub getNextStep
{
   my $self=shift;
   my $currentstep=shift;
   my $WfRec=shift;

   if($currentstep eq ""){
      return($self->getStepByShortname("dataload",$WfRec)); 
   }
   if($currentstep=~m/::dataload$/){
      return($self->getStepByShortname("main",$WfRec)); 
   }
   return(undef);
}

sub isOptionalFieldVisible
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   my $name=$param{field}->Name();

   return(1) if ($name eq "relations");
   return(1) if ($name eq "prio");
   return(1) if ($name eq "name");
   return(1) if ($name eq "shortactionlog");
   return(1) if ($name eq "detaildescription");
   return(0);
}

sub getPosibleRelations
{
   my $self=shift;
   my $WfRec=shift;
   return("base::workflow::request"=>'relinfo');
}

sub Init
{  
   my $self=shift;

   $self->AddGroup("init",
                   translation=>'base::workflow::request');

   return(1);
}


sub getWorkflowMailName
{
   my $self=shift;

   my $workflowname=$self->getParent->T($self->Self(),$self->Self());
   return($workflowname);
}


sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;
   my $app=$self->getParent;
   my $userid=$self->getParent->getCurrentUserId();
   my $isadmin=$self->getParent->IsMemberOf("admin");
   my $stateid=$WfRec->{stateid};
   my $lastworker=$WfRec->{owner};
   my $creator=$WfRec->{openuser};
   my $initiatorid=$WfRec->{initiatorid};
   my @l=();
   my $iscurrent=$self->isCurrentForward($WfRec);
   my $isworkspace=0;
   if (!$iscurrent){  # check Workspace only if not current
      $isworkspace=$self->isCurrentWorkspace($WfRec); 
   }
   my $iscurrentapprover=0;

   if ($stateid==6){
      # load current approvers and check if current user is one of them
      my $foundapprover=0;
      if (ref($WfRec->{shortactionlog}) eq "ARRAY"){
         foreach my $action (reverse(@{$WfRec->{shortactionlog}})){
            last if ($action->{name} ne "wfapprovereq");
            if (ref($action->{additional}) ne "HASH"){
               $action->{additional}={Datafield2Hash($action->{additional})};
            }
            if (defined($action->{additional}->{approvereqtarget}) &&
                defined($action->{additional}->{approvereqtargetid}) &&
                $action->{additional}->{approvereqtarget}->[0] eq "base::user"){
               if ($action->{additional}->{approvereqtargetid}->[0]==$userid){
                  $iscurrentapprover=1;
                  $foundapprover=1;
                  last;
               }
            }
         }
         #printf STDERR ("fifi actions=%s\n",Dumper($WfRec));
      }
   }

   if ($iscurrentapprover && $stateid==6){
      push(@l,"wfapprovok");     # ok
      push(@l,"wfapprovreject"); # reject
   }

   if ($iscurrent){
      push(@l,"iscurrent"); # Merker, dass der Workflow aktuell ansteht
   }
   if ($stateid==1 && ($userid==$creator)){
      push(@l,"wfactivate");
   }
   if ((!$iscurrent && !$iscurrentapprover) && $stateid>1){
      push(@l,"nop");       # No operation as first entry in Action list
   }
   if ($iscurrent && $stateid==6){
      push(@l,"nop");       # Worker, but there are open approve requests
      push(@l,"wfapprovalreq"); # Genehmigung anfordern      (durch Bearbeiter)
      push(@l,"wfapprovalcan"); # Genehmigung abbrechen      (durch Bearbeiter)
   }
   if ((($isadmin && !$iscurrent) || ($userid==$creator && !$iscurrent)) &&
       $stateid<3 && $stateid>1){
      push(@l,"wfbreak");   # workflow abbrechen      (durch Anforderer o admin)
      push(@l,"wfcallback");# workflow zurueckholen   (durch Anforderer o admin)
   }
   if ((($stateid==4 || $stateid==3) && ($lastworker==$userid || $isadmin)) ||
       ($iscurrent && $userid==$creator)){
      push(@l,"wfmailsend");   # notiz hinzufügen        (jeder)
      push(@l,"wfaddnote");    # notiz hinzufügen        (jeder)
      push(@l,"wfdefer");      # notiz hinzufügen        (jeder)
   }
   if (($stateid==2 || $stateid==7 || $stateid==10 || $stateid==5) &&
       ((($lastworker!=$userid) && 
        (($userid!=$creator) || ($userid!=$initiatorid)) &&  $iscurrent) ||
        $iscurrent || $isworkspace)){
      push(@l,"wfapprovalreq"); # Genehmigung anfordern      (durch Bearbeiter)
      push(@l,"wfaccept");  # workflow annehmen              (durch Bearbeiter)
      push(@l,"wfacceptp"); # workflow annehmen und bearbeit.(durch Bearbeiter)
      push(@l,"wfacceptn"); # workflow annehmen und notiz anf(durch Bearbeiter)
      push(@l,"wfreject");  # workflow bearbeitung abgelehnt (durch Bearbeiter)
   }
   if (($stateid==2 || $stateid==4 || $stateid==10) && ($iscurrent || 
                                        ($isadmin && !$lastworker==$userid))){
      push(@l,"wfforward"); # workflow weiterleiten   (neuen Bearbeiter setzen)
   }
   if ($isadmin){
      push(@l,"wfforward"); # workflow weiterleiten   (neuen Bearbeiter setzen)
   }
   if (($stateid==4 || $stateid==3) && 
       ($lastworker==$userid || $isadmin) && ($userid!=$creator)){
      push(@l,"wffineproc");# Bearbeiten und zurück an Anf.  (durch Bearbeiter)
      push(@l,"wfapprovalreq"); # Genehmigung anfordern      (durch Bearbeiter)
   }

   #push(@l,"wfapprove");    # workflow genehmigen            (durch Aprover)
   #push(@l,"wfdisapprove"); # workflow genehmigung ablehnen  (durch Aprover)
   #push(@l,"wfreqapprove"); # genehmigung anfordern bei      (durch Bearbeiter)
   if (($stateid==16 && ($userid==$creator || $isadmin))||
       ($iscurrent && $userid==$creator)){
      if (!grep(/^wfforward$/,@l)){
         push(@l,"wfreprocess");# Nachbesserung notwendig     (durch Anforderer)
      }
      push(@l,"wffine");     # Workflow erfolgreich beenden   (durch Anforderer)
   }
   if (($stateid==3 || $stateid==4) && ($lastworker==$userid || $isadmin)){
      push(@l,"wfdefer");    # Zurückstellen    (durch Anforderer o. Bearbeiter)
   }
   if (1){
      printf STDERR ("WFSTATE:\n".
                     "========\n");
      printf STDERR (" - stateid              : %d\n",$stateid);
      printf STDERR (" - iscurrent            : %d\n",$iscurrent);
      printf STDERR (" - isadmin              : %d\n",$isadmin);
      printf STDERR (" - iscurrentapprover    : %d\n",$iscurrentapprover);
      printf STDERR (" - userid               : %s\n",$userid);
      printf STDERR (" - creator              : %s\n",$creator);
      printf STDERR (" - lastworker           : %s\n",$lastworker);
      printf STDERR (" - actions              : %s\n",join(", ",@l));
      #printf STDERR (" - WfRec :\n%s\n",Dumper($WfRec));
   }
   if ($#l==0 && $l[0] eq "nop"){
      @l=();
   }
   return(@l);
}


sub NotifyUsers
{
   my $self=shift;

}



#######################################################################
package base::workflow::request::dataload;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr>
<td class=fname width=20%>%name(label)%:</td>
<td class=finput>%name(detail)%</td>
</tr>
<tr>
<td class=fname valign=top width=20%>%detaildescription(label)%:</td>
<td class=finput>%detaildescription(detail)%</td>
</tr>
<tr>
<td class=fname valign=top width=20%>%fwdtargetname(label)%:</td>
<td class=finput>%fwdtargetname(detail)%</td>
</tr>
</table>
EOF
   return($templ);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   foreach my $v (qw(name detaildescription)){
      if ((!defined($oldrec) || exists($newrec->{$v})) && $newrec->{$v} eq ""){
         if ($self->LastMsg()==0){
            $self->LastMsg(ERROR,"field '%s' is empty",
                           $self->getField($v)->Label());
         }
         return(0);
      }
   }
   if (!defined($newrec->{stateid}) || $newrec->{stateid}==0){
      $newrec->{stateid}=1; # erfassen
   }
  # $self->LastMsg(ERROR,"no op");
  # return(0);
   $newrec->{step}=$self->getNextStep();

   return(1);
}

sub addInitialParameters
{
   my $self=shift;
   my $newrec=shift;
   return(1);
}

sub nativProcess
{
   my $self=shift;
   my $action=shift;
   my $h=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      my ($target,$fwdtarget,$fwdtargetid,$fwddebtarget,$fwddebtargetid,@wsref)=
             $self->getParent->getDefaultContractor($h,$actions);
#printf STDERR ("fifi fwdtarget=$fwdtarget\n");
#printf STDERR ("fifi fwdtargetid=$fwdtargetid\n");
#printf STDERR ("fifi fwddebtarget=$fwddebtarget\n");
#printf STDERR ("fifi fwddebtargetid=$fwddebtargetid\n");
      if ($self->LastMsg()){
         return(undef);
      }
      $h->{stateid}=1;
      if (!$h->{noautoassign}){
         $h->{stateid}=2;
         if ($target ne ""){
            $h->{fwdtargetname}=$target;
         }
         if ($fwdtarget ne "" && $fwdtargetid ne ""){
            $h->{fwdtarget}=$fwdtarget;
            $h->{fwdtargetid}=$fwdtargetid;
         }
         if ($fwddebtarget ne "" && $fwddebtargetid ne ""){
            $h->{fwddebtarget}=$fwddebtarget;
            $h->{fwddebtargetid}=$fwddebtargetid;
         }
      }
      $h->{eventend}=undef;
      $h->{closedate}=undef;
      delete($h->{noautoassign});

      if ($W5V2::OperationContext ne "Kernel"){
         $h->{eventstart}=NowStamp("en");
         $h->{implementedto}="?" if ($h->{implementedto} eq "");
         $h->{initiatorid}=$self->getParent->getParent->getCurrentUserId();
         my $UserCache=$self->Cache->{User}->{Cache};
         if (defined($UserCache->{$ENV{REMOTE_USER}})){
            my $fullname=$UserCache->{$ENV{REMOTE_USER}}->{rec}->{fullname};
            $h->{initiatorname}=$fullname;
         }
        
         my %groups=$self->getGroupsOf($ENV{REMOTE_USER},
                                       [qw(REmployee RBoss)],'direct');
         if (keys(%groups)>0){
            my @k=keys(%groups);
            $h->{initiatorgroupid}=$k[0];
            $h->{initiatorgroup}=$groups{$k[0]}->{fullname};
         }
      }
      if (!$self->addInitialParameters($h)){
         if (!$self->getParent->LastMsg()){
            $self->getParent->LastMsg(ERROR,
                   "unknown error while addInitialParameters");
         }
         return(0);
      }
      if (my $id=$self->StoreRecord($WfRec,$h)){
         $h->{id}=$id;
         if ($#wsref!=-1){
            while(my $target=shift(@wsref)){
               my $targetid=shift(@wsref);
               last if ($targetid eq "" || $target eq "");
               $self->getParent->getParent->AddToWorkspace($id,
                                                           $target,$targetid);
            }
         }
         $self->PostProcess($action,$h,$actions);
      }
      else{
         return(0);
      }
      return(1);
   }
   return(undef);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      my $h=$self->getWriteRequestHash("web");
      if (Query->Param("Formated_noautoassign") ne ""){
         $h->{noautoassign}=1;
      }
      else{
         $h->{noautoassign}=0;
      }
      return($self->nativProcess($action,$h,$WfRec,$actions));
   }
   return($self->SUPER::Process($action,$WfRec,$actions));
}


sub PostProcess
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;
   my %param=@_;

   $self->getParent->getParent->ResetFilter();
   $self->getParent->getParent->SetFilter({id=>\$WfRec->{id}});
   my ($cur,$msg)=$self->getParent->getParent->getOnlyFirst(
                  qw(fwdtarget fwdtargetid));

   if (defined($cur)){
      if ($cur->{fwdtarget} ne "" && $cur->{fwdtargetid} ne ""){ 
         my $aobj=$self->getParent->getParent->Action();
         my $workflowname=$self->getParent->getWorkflowMailName();
         $aobj->NotifyForward($WfRec->{id},
                              $cur->{fwdtarget},$cur->{fwdtargetid},undef,
                              $WfRec->{detaildescription},
                              workflowname=>$workflowname,
                              sendercc=>1);
      }
   }
       
}



sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("100%");
}

#######################################################################
package base::workflow::request::main;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);


sub generateWorkspacePages
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $divset=shift;
   my $selopt=shift;
   my $tr="base::workflow::actions";
   my $class="display:none;visibility:hidden";

   my $defop;
   if (grep(/^wfacceptp$/,@$actions)){
      $$selopt.="<option value=\"wfacceptp\">".
                $self->getParent->T("wfacceptp",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfacceptp class=\"$class\">".
                $self->getDefaultNoteDiv($WfRec,$actions).
                "</div>";
      $defop="wfacceptp";
   }
   if (grep(/^wfacceptn$/,@$actions)){
      $$selopt.="<option value=\"wfacceptn\">".
                $self->getParent->T("wfacceptn",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfacceptn class=\"$class\">".
                $self->getDefaultNoteDiv($WfRec,$actions).
                "</div>";
   }
   if (grep(/^wfapprove$/,@$actions)){
      $$selopt.="<option value=\"wfapprove\">".
                $self->getParent->T("wfapprove",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfapprove class=\"$class\"><textarea name=note ".
                "style=\"width:100%;height:110px\"></textarea></div>";
   }
   if (grep(/^wfactivate$/,@$actions)){
      $$selopt.="<option value=\"wfactivate\">".
                $self->getParent->T("wfactivate",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfactivate class=\"$class\"></div>";
   }
   if (grep(/^wfaccept$/,@$actions)){
      $$selopt.="<option value=\"wfaccept\">".
                $self->getParent->T("wfaccept",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfaccept class=\"$class\"></div>";
   }
   if (grep(/^wffine$/,@$actions)){
      $$selopt.="<option value=\"wffine\">".
                $self->getParent->T("wffine",$tr).
                "</option>\n";
      $$divset.="<div id=OPwffine style=\"$class;margin:15px\"><br>".
                $self->getParent->T("use this action,".
                " to finish this request and mark it as according to ".
                "desire processed")."</div>";
   }
   if (grep(/^wffineproc$/,@$actions)){
      $$selopt.="<option value=\"wffineproc\">".
                $self->getParent->T("wffineproc",$tr).
                "</option>\n";
      my $note=Query->Param("note");
      $$divset.="<div id=OPwffineproc class=\"$class\">".
                $self->getDefaultNoteDiv($WfRec,$actions).
                "</div>";
   }
   if (grep(/^wfreprocess$/,@$actions)){
      $$selopt.="<option value=\"wfreprocess\">".
                $self->getParent->T("wfreprocess",$tr).
                "</option>\n";
      my $d="<table width=100% border=0 cellspacing=0 cellpadding=0><tr>".
         "<td colspan=2><textarea name=note style=\"width:100%;height:100px\">".
         "</textarea></td></tr>";
      $d.="<tr><td width=1% nowrap>Weiterleiten an:&nbsp;</td>".
          "<td>\%fwdtargetname(detail)\%".
          "</td>";
      $d.="</tr></table>";
      my $devpartner=$self->getParent->getDefaultContractor($WfRec,$actions);
      $d.='<script language="JavaScript">'.
          'function setDevReprocess(){'.
          ' var d=document.getElementById("OPwfreprocess");'.
          ' var f=d.getElementsByTagName("input");'.
          ' for(var i=0;i<f.length;i++){'.
          '    if (f[i].name=="Formated_fwdtargetname"){'.
          '       f[i].value="'.$devpartner.'";'.
          '    }'.
          ' }'.
          '}'.
          'addEvent(window, "load", setDevReprocess);'.
          '</script>';
      $$divset.="<div id=OPwfreprocess>$d</div>";
   }
   if (grep(/^wfcallback$/,@$actions)){
      $$selopt.="<option value=\"wfcallback\" class=\"$class\">".
                $self->getParent->T("wfcallback",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfcallback style=\"$class;margin:15px\"><br>".
                $self->getParent->T("use this action,".
                " to call the request back. This can be usefull, if the ".
                "request needs to be corrected.")."</div>";
   }
   if (grep(/^wfreject$/,@$actions)){
      $$selopt.="<option value=\"wfreject\">".
                $self->getParent->T("wfreject",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfreject class=\"$class\"><textarea name=note ".
                "style=\"width:100%;height:110px\"></textarea></div>";
   }
   if (grep(/^wfapprovalreq$/,@$actions)){
      $$selopt.="<option value=\"wfapprovalreq\">".
                $self->getParent->T("wfapprovalreq",$tr).
                "</option>\n";
      my $note=Query->Param("note");
      my $d="<table width=100% border=0 cellspacing=0 cellpadding=0><tr>".
         "<td colspan=2><textarea name=note style=\"width:100%;height:70px\">".
         $note."</textarea></td></tr>";
      $d.="<tr><td width=1% nowrap>&nbsp;Genehmigungs ".
          "Anforderung bei:&nbsp;</td>".
          "<td>\%approverrequest(detail)\%".
          "</td></tr>";
      $d.="</table>";
      $$divset.="<div id=OPwfapprovalreq class=\"$class\">$d</div>";
   }
   if (grep(/^wfapprovok$/,@$actions)){
      $$selopt.="<option value=\"wfapprovok\">".
                $self->getParent->T("wfapprovok",$tr).
                "</option>\n";
      my $note=Query->Param("note");
      my $d="<table width=100% border=0 cellspacing=0 cellpadding=0><tr>".
         "<td colspan=2><textarea name=note style=\"width:100%;height:70px\">".
         $note."</textarea></td></tr>";
      $d.="<tr><td colspan=2>Ja, ich bin sicher, dass ich diese Anforderung ".
          "genehmigen möchte <input name=VERIFY type=checkbox></td></tr>";
      $d.="</table>";
      $$divset.="<div id=OPwfapprovok class=\"$class\">$d</div>";
   }
   if (grep(/^wfapprovreject$/,@$actions)){
      $$selopt.="<option value=\"wfapprovreject\">".
                $self->getParent->T("wfapprovreject",$tr).
                "</option>\n";
      my $note=Query->Param("note");
      my $d="<table width=100% border=0 cellspacing=0 cellpadding=0><tr>".
         "<td colspan=2><textarea name=note style=\"width:100%;height:70px\">".
         $note."</textarea></td></tr>";
      $d.="</table>";
      $$divset.="<div id=OPwfapprovreject class=\"$class\">$d</div>";
   }
   if (grep(/^wfapprovalcan$/,@$actions)){
      $$selopt.="<option value=\"wfapprovalcan\">".
                $self->getParent->T("wfapprovalcan",$tr).
                "</option>\n";
      my $d="<table width=100% border=0 cellspacing=0 cellpadding=0><tr>".
         "<td colspan=2><textarea name=note style=\"width:100%;height:70px\">".
         "</textarea></td></tr>";
      #$d.="<tr><td width=1% nowrap>&nbsp;Genehmigungs ".
      #    "Anforderung bei:&nbsp;</td>".
      #    "<td>\%approverrequest(detail)\%".
      #    "</td></tr>";
      $d.="</table>";
      $$divset.="<div id=OPwfapprovalcan class=\"$class\">$d</div>";
   }
   $self->SUPER::generateWorkspacePages($WfRec,$actions,$divset,$selopt);
   if ($WfRec->{stateid}==4){
      $defop="wfaddnote";
   }
   if ($WfRec->{stateid}==1){
      $defop="wfactivate";
   }
   return($defop); 
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

#   foreach my $v (qw(name)){
#      if ((!defined($oldrec) || exists($newrec->{$v})) && $newrec->{$v} eq ""){
#         $self->LastMsg(ERROR,"field '%s' is empty",
#                        $self->getField($v)->Label());
#         return(0);
#      }
#   }

   return(1);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $userid=$self->getParent->getParent->getCurrentUserId();

   if ($action eq "BreakWorkflow"){
      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"wfbreak",
          {translation=>'base::workflow::request'},"",undef)){
         my $openuserid=$WfRec->{openuser};
         my $step=$self->getParent->getStepByShortname("break");
         $self->StoreRecord($WfRec,{stateid=>22,
                                    step=>$step,
                                    eventend=>NowStamp("en"),
                                    closedate=>NowStamp("en"),
                                    fwddebtargetid=>undef,
                                    fwddebtarget=>undef,
                                    fwdtargetid=>undef,
                                    fwdtarget=>undef,
                                   });
         if ($openuserid!=$userid){
            $self->PostProcess($action,$WfRec,$actions,
                               "breaked by $ENV{REMOTE_USER}",
                               fwdtarget=>'base::user',
                               fwdtargetid=>$openuserid,
                               fwdtargetname=>"Requestor");
         }
         return(1);
      }
      return(0);
   }

   if ($action eq "SaveStep"){
      my $op=Query->Param("OP");
      if ($action ne "" && !grep(/^$op$/,@{$actions})){
         $self->LastMsg(ERROR,"invalid disalloed action requested");
         return(0);
      }
     
      if ($op eq "wfaccept"){
     
         if ($self->StoreRecord($WfRec,{stateid=>3,
                                        fwdtarget=>'base::user',
                                        fwdtargetid=>$userid,
                                        fwddebtarget=>undef,
                                        fwddebtargetid=>undef})){
            if ($self->getParent->getParent->Action->StoreRecord(
                $WfRec->{id},"wfaccept",
                {translation=>'base::workflow::request'},"",undef)){
               $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
               $self->PostProcess($action.".".$op,$WfRec,$actions);
               return(1);
            }
         }
         return(0);
      }
     
      if ($op eq "wfacceptn"){
         my $note=Query->Param("note");
         if ($note=~m/^\s*$/  || length($note)<10){
            $self->LastMsg(ERROR,"empty or to short notes are not allowed");
            return(0);
         }
         $note=trim($note);
         my $effort=Query->Param("Formated_effort");
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wfaccept",
             {translation=>'base::workflow::request'},"",undef)){
            sleep(1);
            if ($self->getParent->getParent->Action->StoreRecord(
                $WfRec->{id},"wfaddnote",
                {translation=>'base::workflow::request'},$note,$effort)){
               if ($self->StoreRecord($WfRec,{fwdtarget=>'base::user',
                                              fwdtargetid=>$userid,
                                              fwddebtarget=>undef,
                                              fwddebtargetid=>undef,
                                              stateid=>4})){
                  $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
                  $self->PostProcess($action.".".$op,$WfRec,$actions);
               }
               return(1);
            }
         }
         return(0);
      }
     
      if ($op eq "wfacceptp"){
         my $note=Query->Param("note");
         if ($note=~m/^\s*$/  || length($note)<10){
            $self->LastMsg(ERROR,"empty or to short notes are not allowed");
            return(0);
         }
         $note=trim($note);
         my $effort=Query->Param("Formated_effort");
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wfaccept",
             {translation=>'base::workflow::request'},"",undef)){
            sleep(1);
            if ($self->getParent->getParent->Action->StoreRecord(
                $WfRec->{id},"wfaddnote",
                {translation=>'base::workflow::request'},$note,$effort)){
               my $openuserid=$WfRec->{openuser};
               $self->StoreRecord($WfRec,{stateid=>16,fwdtargetid=>$openuserid,
                                                      fwdtarget=>'base::user',
                                                      eventend=>NowStamp("en"),
                                                      fwddebtarget=>undef,
                                                      fwddebtargetid=>undef});
               $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
               $self->PostProcess($action.".".$op,$WfRec,$actions,
                                  note=>$note,
                                  fwdtarget=>'base::user',
                                  fwdtargetid=>$openuserid,
                                  fwdtargetname=>'Requestor');
               return(1);
            }
         }
         return(0);
      }
     
      if ($op eq "wffine"){
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wffine",
             {translation=>'base::workflow::request'},"",undef)){
            my $nextstep=$self->getParent->getStepByShortname("finish");
            my $store={stateid=>21,
                       step=>$nextstep,
                       fwdtargetid=>undef,
                       fwdtarget=>undef,
                       closedate=>NowStamp("en"),
                       fwddebtarget=>undef,
                       fwddebtargetid=>undef};
            if ($WfRec->{eventend} eq ""){
               $store->{eventend}=NowStamp("en");
            }
            $self->StoreRecord($WfRec,$store);
            $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
            $self->PostProcess($action.".".$op,$WfRec,$actions);
            return(1);
         }
         return(0);
      }
     
      if ($op eq "wffineproc"){
         my $note=Query->Param("note");
         if ($note=~m/^\s*$/  || length($note)<10){
            $self->LastMsg(ERROR,"empty or to short notes are not allowed");
            return(0);
         }
         $note=trim($note);
         my $effort=Query->Param("Formated_effort");
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wfaddnote",
             {translation=>'base::workflow::request'},$note,$effort)){
            my $openuserid=$WfRec->{openuser};
            $self->StoreRecord($WfRec,{stateid=>16,
                                       fwdtargetid=>$openuserid,
                                       fwdtarget=>'base::user',
                                       eventend=>NowStamp("en"),
                                       fwddebtarget=>undef,
                                       fwddebtargetid=>undef});
            $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
            $self->PostProcess($action.".".$op,$WfRec,$actions,
                               note=>$note,
                               fwdtarget=>'base::user',
                               fwdtargetid=>$openuserid,
                               fwdtargetname=>'Requestor');
            return(1);
         }
         return(0);
      }
     
      if ($op eq "wfreject"){
         my $note=Query->Param("note");
         if ($note=~m/^\s*$/ || length($note)<10){
            $self->LastMsg(ERROR,"empty or to short notes are not allowed");
            return(0);
         }
         $note=trim($note);
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wfreject",
             {translation=>'base::workflow::request'},$note,undef)){
            my $openuserid=$WfRec->{openuser};
            $self->StoreRecord($WfRec,{stateid=>24,fwdtargetid=>$openuserid,
                                                   fwdtarget=>'base::user',
                                                   eventend=>NowStamp("en"),
                                                   fwddebtarget=>undef,
                                                   fwddebtargetid=>undef});

            $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
            $self->PostProcess($action.".".$op,$WfRec,$actions,
                               note=>$note,
                               fwdtarget=>'base::user',
                               fwdtargetid=>$openuserid,
                               fwdtargetname=>"Requestor");
            return(1);
         }
         return(0);
      }
     
      if ($op eq "wfapprovok"){
         my $note=Query->Param("note");
         $note=trim($note);
         if (Query->Param("VERIFY") eq ""){
            $self->LastMsg(ERROR,"you don't have check the ensure checkbox");
            return(0);
         }
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wfapprove",
             {translation=>'base::workflow::request'},$note,undef)){
            my $openuserid=$WfRec->{openuser};
            $self->StoreRecord($WfRec,{stateid=>7});
            $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
            #
            # MAIL versenden: Workflow wurde genehmigt
            #
            $self->PostProcess($action.".".$op,$WfRec,$actions,
                               note=>$note);
            return(1);
         }
         return(0);
      }
     
      if ($op eq "wfapprovreject"){
         my $note=Query->Param("note");
         if ($note=~m/^\s*$/ || length($note)<10){
            $self->LastMsg(ERROR,"you need to specified a descriptive note");
            return(0);
         }
         $note=trim($note);
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wfapprovereject",
             {translation=>'base::workflow::request'},$note,undef)){
            my $openuserid=$WfRec->{openuser};
            $self->StoreRecord($WfRec,{stateid=>10});
            $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
            #
            # MAIL versenden: Workflow wurde abgelehnt
            #
            $self->PostProcess($action.".".$op,$WfRec,$actions,
                               note=>$note);
            return(1);
         }
         return(0);
      }
     
      if ($op eq "wfcallback"){
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wfcallback",
             {translation=>'base::workflow::request'},undef,undef)){
            $self->StoreRecord($WfRec,{stateid=>4,
                                       fwdtargetid=>$userid,
                                       fwdtarget=>'base::user',
                                       fwddebtarget=>undef,
                                       fwddebtargetid=>undef
                                   });
            $self->PostProcess($action.".".$op,$WfRec,$actions);
            return(1);
         }
         return(0);
      }
     
      if ($op eq "wfactivate"){
         my $note=Query->Param("note");
         $note=trim($note);
     
         my $fobj=$self->getParent->getField("fwdtargetname");
         my $h=$self->getWriteRequestHash("web");
         my $newrec;
         if ($newrec=$fobj->Validate($WfRec,$h)){
            if (!defined($newrec->{fwdtarget}) ||
                !defined($newrec->{fwdtargetid} ||
                $newrec->{fwdtargetid}==0)){
               if ($self->LastMsg()==0){
                  $self->LastMsg(ERROR,"invalid forwarding target");
               }
               return(0);
            }
         }
         my $fwdtargetname=Query->Param("Formated_fwdtargetname");
     
         if ($self->StoreRecord($WfRec,{stateid=>2,
                                       fwdtarget=>$newrec->{fwdtarget},
                                       fwdtargetid=>$newrec->{fwdtargetid},
                                       eventend=>undef,
                                       closedate=>undef,
                                       fwddebtarget=>undef,
                                       fwddebtargetid=>undef })){
            if ($self->getParent->getParent->Action->StoreRecord(
                $WfRec->{id},"wfforward",
                {translation=>'base::workflow::request'},$fwdtargetname."\n".
                                                         $note,undef)){
               $self->PostProcess($action.".".$op,$WfRec,$actions,
                                  note=>$note,
                                  fwdtarget=>$newrec->{fwdtarget},
                                  fwdtargetid=>$newrec->{fwdtargetid},
                                  fwdtargetname=>$fwdtargetname);
               return(1);
            }
         }
         return(0);
      }
     
      if ($op eq "wfreprocess"){
         my $note=Query->Param("note");
         $note=trim($note);
     
         my $fobj=$self->getParent->getField("fwdtargetname");
         my $h=$self->getWriteRequestHash("web");
         my $newrec;
         if ($newrec=$fobj->Validate($WfRec,$h)){
            if (!defined($newrec->{fwdtarget}) ||
                !defined($newrec->{fwdtargetid} ||
                $newrec->{fwdtargetid}==0)){
               if ($self->LastMsg()==0){
                  $self->LastMsg(ERROR,"invalid forwarding target");
               }
               return(0);
            }
         }
         my $fwdtargetname=Query->Param("Formated_fwdtargetname");
     
         if ($self->StoreRecord($WfRec,{stateid=>2,
                                       fwdtarget=>$newrec->{fwdtarget},
                                       fwdtargetid=>$newrec->{fwdtargetid},
                                       eventend=>undef,
                                       closedate=>undef,
                                       fwddebtarget=>undef,
                                       fwddebtargetid=>undef })){
            if ($self->getParent->getParent->Action->StoreRecord(
                $WfRec->{id},"wfforward",
                {translation=>'base::workflow::request'},$fwdtargetname."\n".
                                                         $note,undef)){
               $self->PostProcess($action.".".$op,$WfRec,$actions,
                                  note=>$note,
                                  fwdtarget=>$newrec->{fwdtarget},
                                  fwdtargetid=>$newrec->{fwdtargetid},
                                  fwdtargetname=>$fwdtargetname);
               return(1);
            }
         }
         return(0);
      }
     
      if ($op eq "wfapprovalreq"){
         my $note=Query->Param("note");
         $note=trim($note);
    
         my $approverrequest="approverrequest"; 
         my $fobj=$self->getParent->getField($approverrequest);
        # my $f=defined($newrec->{$approverrequest}) ?
        #       $newrec->{$approverrequest} :
        #       Query->Param("Formated_$approverrequest");
         my $f=Query->Param("Formated_$approverrequest");

         my $new1;
         if ($new1=$fobj->Validate($WfRec,{$approverrequest=>$f})){
            if (!defined($new1->{"${approverrequest}id"}) ||
                $new1->{"${approverrequest}id"}==0){
               if ($self->LastMsg()==0){
                  $self->LastMsg(ERROR,"invalid approve target");
               }
               return(0);
            }
         }
         else{
            return(0);
         }
         if ($self->getParent->getParent->getCurrentUserId()==
             $new1->{"${approverrequest}id"}){
            $self->LastMsg(ERROR,"you could'nt request approve by your self");
            return(0);
         }
         if ($note=~m/^\s*$/ ||
             length($note)<10){
            $self->LastMsg(ERROR,"you need to specified a descriptive note");
            return(0);
         }

         my $approverrequestname=Query->Param("Formated_approverrequest");
         my $info="\@:".$approverrequestname;
         $info.="\n".$note;
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wfapprovereq",
             {translation=>'base::workflow::request',
              additional=>{
                            approvereqtarget=>'base::user',
                            approvereqtargetid=>$new1->{"${approverrequest}id"}
                          }},$info,undef)){
            my $openuserid=$WfRec->{openuser};
            if ($self->getParent->getParent->AddToWorkspace($WfRec->{id},
                               "base::user",$new1->{"${approverrequest}id"})){
               if ($self->StoreRecord($WfRec,{stateid=>6})){
                  Query->Delete("OP");
                  #
                  # Mail versenden - Genehmigungsanforderung
                  #
                  $self->PostProcess($action.".".$op,$WfRec,$actions,
                                 note=>$note,
                                 fwdtarget=>'base::user',
                                 fwdtargetid=>$new1->{"${approverrequest}id"},
                                 fwdtargetname=>$approverrequestname);
                  return(1);
               }
            }
         }
         return(0);
      }


      if ($op eq "wfapprovalcan"){
         my $note=Query->Param("note");
         $note=trim($note);
    
         if ($note=~m/^\s*$/ ||
             length($note)<10){
            $self->LastMsg(ERROR,"you need to specified a descriptive reason");
            return(0);
         }
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wfapprovecan",
             {translation=>'base::workflow::request'},$note,undef)){
            if ($self->StoreRecord($WfRec,{stateid=>2})){
               $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
               Query->Delete("OP");
               return(1);
            }
         }
         return(0);
      }

   }
   return($self->SUPER::Process($action,$WfRec,$actions));
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

   if ($action eq "SaveStep.wfapprovalreq"){
      $aobj->NotifyForward($WfRec->{id},
                           $param{fwdtarget},
                           $param{fwdtargetid},
                           $param{fwdtargetname},
                           $param{note},
                           mode=>'APRREQ:',
                           workflowname=>$workflowname,
                           sendercc=>1);
   }
   if ($action eq "SaveStep.wfapprovok"){
      $aobj->NotifyForward($WfRec->{id},
                           $WfRec->{fwdtarget},
                           $WfRec->{fwdtargetid},
                           undef,
                           $param{note},
                           mode=>'APROK:',
                           workflowname=>$workflowname,
                           sendercc=>1);
   }
   if ($action eq "SaveStep.wfapprovreject"){
      $aobj->NotifyForward($WfRec->{id},
                           $WfRec->{fwdtarget},
                           $WfRec->{fwdtargetid},
                           undef,
                           $param{note},
                           mode=>'APRREJ:',
                           workflowname=>$workflowname,
                           sendercc=>1);
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
   if ($action eq "SaveStep.wfreject" ||
       $action eq "SaveStep.wffineproc" ||
       $action eq "SaveStep.wfacceptp" ||
       $action eq "BreakWorkflow" ){
      $aobj->NotifyForward($WfRec->{id},
                           $param{fwdtarget},
                           $param{fwdtargetid},
                           $param{fwdtargetname},
                           $param{note},
                           workflowname=>$workflowname);
   }

   if ($action eq "SaveStep.wfacceptp" ||
       $action eq "SaveStep.wffineproc"){
      if ($WfRec->{initiatorid} ne "" &&
          $WfRec->{initiatorid} ne $WfRec->{openuser}){
         my $n=$param{note};
         $n="\n\n".$n if ($n ne "");
         $aobj->NotifyForward($WfRec->{id},
                              'base::user',
                              $WfRec->{initiatorid},
                              'Initiator',
                              $self->T('Your request has been processed. '.
                              'For further informations use the '.
                              'attached link','base::workflow::request').$n.
                              "\n\n-- ".
                              $self->T("original request text",
                                       'base::workflow::request').
                              " --\n".$WfRec->{detaildescription}."\n----\n",
                              mode=>'INFO:',
                              workflowname=>$workflowname);
      }
   }
   return($self->SUPER::PostProcess($action,$WfRec,$actions));
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my @saveables=grep(!/^wfbreak$/,@$actions);
   return(0)  if ($#{$actions}==-1);
   return(20) if ($#saveables==-1);
   return(180);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my @WorkflowStep=Query->Param("WorkflowStep");
   my %b=();
   my @saveables=grep(!/^wfbreak$/,@$actions);
   if ($#saveables!=-1){
      %b=(SaveStep=>$self->T('Save')) if ($#{$actions}!=-1);
   }
   if (defined($WfRec->{id})){
      if (grep(/^wfbreak$/,@$actions)){
         $b{BreakWorkflow}=$self->T('abbort request');
      }
   }
   return(%b);
}

#######################################################################
package base::workflow::request::finish;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $templ;

   if ($self->getParent->getParent->IsMemberOf("admin")){
      $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr>
<td class=fname width=20%>%fwdtargetname(label)%:</td>
<td class=finput>%fwdtargetname(detail)%</td>
</tr>
</table>
EOF
   }
   return($templ);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   return(1);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($self->getParent->getParent->IsMemberOf("admin")){
      if ($action eq "NextStep"){
         my $h=$self->getWriteRequestHash("web");
         my $fobj=$self->getParent->getField("fwdtargetname");
         my $h=$self->getWriteRequestHash("web");
         if ($h=$fobj->Validate($WfRec,$h)){
            if (!defined($h->{fwdtarget}) ||
                !defined($h->{fwdtargetid} ||
                $h->{fwdtargetid}==0)){
               if ($self->LastMsg()==0){
                  $self->LastMsg(ERROR,"invalid or no forwarding target");
               }
               return(0);
            }
         }
         else{
            return(0);
         }
         $h->{stateid}=2;
         $h->{eventend}=undef;
         $h->{closedate}=undef;
         $h->{step}=$self->getParent->getStepByShortname("main");
         if (!$self->StoreRecord($WfRec,$h)){
            return(0);
         }
         my $fwdtargetname=Query->Param("Formated_fwdtargetname");
         $self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wfreactiv",
             {translation=>'base::workflow::request'},$fwdtargetname,undef);

         Query->Delete("WorkflowStep");
         return(1);
      }
   }
   return($self->SUPER::Process($action,$WfRec));
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("60") if ($self->getParent->getParent->IsMemberOf("admin"));
   return(0);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   return() if (!$self->getParent->getParent->IsMemberOf("admin"));;
   my %p=$self->SUPER::getPosibleButtons($WfRec);
   delete($p{BreakWorkflow});
   return(%p);
}


#######################################################################
package base::workflow::request::break;
use vars qw(@ISA);
use kernel;
@ISA=qw(base::workflow::request::finish);


1;
