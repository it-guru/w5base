package base::workflow::task;
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
      new kernel::Field::Select(
                name          =>'tasktyp',
                label         =>'Task type',
                htmldetail    =>0,
                group         =>'init',
                getPostibleValues=>\&getTaskTypList)

    );
   return($self);
}

sub getTaskTypList
{
   my $self=shift;
   my $app=$self->getParent->getParent;

   my @l;
   push(@l,"personaltask", $app->T("personal task"));
   push(@l,"personal:education", $app->T("personal: education"));
   push(@l,"personal:teammeeting", $app->T("personal: team meeting"));


   foreach my $prec ($self->getParent->getAllowedProjects()){
      push(@l,"projectroom:$prec->{id}",$app->T("Project").": ".$prec->{name});
   }
   return(@l);
}

sub getAllowedProjects
{
   my $self=shift;
   my $app=$self->getParent;
   my @flt;

   my %grps=$app->getGroupsOf($ENV{REMOTE_USER},
       [orgRoles()],"both");
   my @grpids=keys(%grps);
   my $userid=$app->getCurrentUserId();
   push(@flt,[
              {projectbossid=>$userid,cistatusid=>[3,4]},
              {projectboss2id=>$userid,cistatusid=>[3,4]},
              {sectargetid=>\$userid,sectarget=>\'base::user',
               secroles=>"*roles=?PManager?=roles* *roles=?PMember?=roles*",
               cistatusid=>[3,4],isrestirctiv=>\'0'},
              {sectargetid=>\@grpids,sectarget=>\'base::grp',
               secroles=>"*roles=?PManager?=roles* *roles=?PMember?=roles*",
               cistatusid=>[3,4],isrestirctiv=>\'0'},
              {sectargetid=>\$userid,sectarget=>\'base::user',
               secroles=>"*roles=?PManager?=roles*",
               cistatusid=>[3,4],isrestirctiv=>\'1'},
              {sectargetid=>\@grpids,sectarget=>\'base::grp',
               secroles=>"*roles=?PManager?=roles*",
               cistatusid=>[3,4],isrestirctiv=>\'1'}
             ]);
   my $o=getModuleObject($app->Config,"base::projectroom");
   $o->SetFilter(@flt);
   my @l=$o->getHashList(qw(name id mandator mandatorid iscommercial conumber));
   Dumper($_) foreach (@l);
   return(@l);
}

sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;

   $self->AddGroup("affectedproject",translation=>'base::workflow::task');
   return($self->InitFields(
      new kernel::Field::TextDrop(
                name          =>'initiator',
                label         =>'Initiated by',
                group         =>'init',
                htmldetail    =>0,
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['initiatorid'=>'userid'],
                vjoindisp     =>'fullname',
                altnamestore  =>'initiatorname'),

      new kernel::Field::TextDrop(
                name          =>'initiatorgroupname',
                label         =>'Initiated by group',
                group         =>'init',
                htmldetail    =>0,
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

      new kernel::Field::Select(
                name          =>'tasknature',
                label         =>'task nature',
                readonly      =>1,
                htmlwidth     =>'10px',
                value         =>['Tpersonal','Tproject','Tsubtask'],
                translation   =>'base::workflow::task',
                container     =>'headref'),

      new kernel::Field::Text(
                name          =>'taskclass',
                label         =>'task class',
                readonly      =>1,
                htmlwidth     =>'10px',
                container     =>'headref'),

      new kernel::Field::Select(
                name          =>'taskexecstate',
                label         =>'Execution state',
                htmleditwidth =>'40px',
                htmlwidth     =>'10px',
                value         =>[qw(0 5 10 15 20 25 30 35 40 45 50 
                                    55 65 70 75 80 85 90 95 100)],
                default       =>0,
                unit          =>'%',
                container     =>'headref'),

      new kernel::Field::KeyText(
                name       =>'affectedproject',
                translation=>'itil::workflow::base',
                keyhandler =>'kh',
                multiple   =>0,
                vjointo    =>'base::projectroom',
                vjoinon    =>['affectedprojectid'=>'id'],
                vjoindisp  =>'name',
                container  =>'headref',
                group      =>'affectedproject',
                label      =>'Affected Project'),

      new kernel::Field::KeyText(
                name       =>'affectedprojectid',
                htmldetail =>0,
                translation=>'itil::workflow::base',
                searchable =>0,
                keyhandler =>'kh',
                container  =>'headref',
                group      =>'affectedproject',
                label      =>'Affected Project ID'),

      new kernel::Field::Text(
                name       =>'involvedcostcenter',
                htmldetail =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   if ($current->{involvedcostcenter}=~m/^[\s\?]*$/){
                      return(0);
                   }
                   return(1);


                },
                searchable =>0,
                container  =>'headref',
                group      =>'affectedproject',
                label      =>'Involved CostCenter'),

    ));
}


sub IsModuleSelectable
{
   my $self=shift;
   my $acl;

   $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
                          "base::workflow",
                          func=>'New',
                          param=>'WorkflowClass=base::workflow::task');
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

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @l=("default","state","flow","header","relations","init","history");
   if ($rec->{tasknature} eq "Tproject"){
      push(@l,"affectedproject");
   }

   return(@l);
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
   return(@l);
}

sub getDetailBlockPriority            # posibility to change the block order
{
   return("init","affectedproject","flow","relations");
}





sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   return("base::workflow::task::".$shortname);
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
   return("base::workflow::task"=>'relinfo');
}

sub Init
{  
   my $self=shift;

   $self->AddGroup("init",
                   translation=>'base::workflow::task');

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
   push(@l,"iscurrent") if ($iscurrent);
   my $iscurrentapprover=0;


   if ((($isadmin && !$iscurrent) || ($userid==$creator && !$iscurrent)) &&
       $stateid<3){
      push(@l,"wfbreak");   # workflow abbrechen      (durch Anforderer o admin)
   #   push(@l,"wfcallback");# workflow zurueckholen   (durch Anforderer o admin)
   }
   if ((($stateid==4 || $stateid==3) && ($lastworker==$userid || $isadmin)) ||
       ($iscurrent || $userid==$creator)){
      push(@l,"wfmailsend");   # mail versenden hinzufügen        (jeder)
      push(@l,"wfaddnote");    # allow effort notation, even if there is
                               # no costcenter involved

     # if ($WfRec->{involvedcostcenter} ne ""){  
     # }
     # else{
     #    push(@l,"wfaddsnote");  # notiz hinzufügen        (jeder)
     # }
      push(@l,"setprioexecs"); # Prio und erledigungsgrad setzen
      if ($WfRec->{tasknature} eq "Tproject"){
         push(@l,"wfaddsubtask"); # Unteraufgabe erzeugen
      }
   }
   if (($stateid==4 || $stateid==3) && 
       ($lastworker==$userid || $isadmin) && ($userid!=$creator)){
      push(@l,"wffineproc");# Bearbeiten und zurück an Anf.  (durch Bearbeiter)
   }

   #push(@l,"wfapprove");    # workflow genehmigen            (durch Aprover)
   #push(@l,"wfdisapprove"); # workflow genehmigung ablehnen  (durch Aprover)
   #push(@l,"wfreqapprove"); # genehmigung anfordern bei      (durch Bearbeiter)
   if (($stateid==16 && ($userid==$creator || $isadmin))||
       ($iscurrent && $userid==$creator)){
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
package base::workflow::task::dataload;
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
<table border=0 cellspacing=0 cellpadding=0 width="100%">
<tr>
<td class=fname width=20%>%tasktyp(label)%:</td>
<td class=finput>%tasktyp(detail)%</td>
</tr>
<tr>
<td class=fname width=20%>%name(label)%:</td>
<td class=finput>%name(detail)%</td>
</tr>
<tr>
<td class=fname valign=top width=20%>%detaildescription(label)%:</td>
<td class=finput>%detaildescription(detail)%</td>
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
         $self->LastMsg(ERROR,"field '%s' is empty",
                        $self->getField($v)->Label());
         return(0);
      }
   }
   $newrec->{stateid}=4; # zugewiesen
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
      if ($h->{tasknature} ne "Tproject"){
         delete($h->{affectedprojectid});
         delete($h->{affectedproject});
      }
      else{
         my $prec;
         foreach my $r ($self->getParent->getAllowedProjects()){
            if ($h->{affectedprojectid}==$r->{id}){
               $prec=$h->{affectedprojectid};
               $h->{affectedproject}=$r->{name};
               $h->{mandatorid}=[$r->{mandatorid}];
               $h->{mandator}=[$r->{mandator}];
               if ($r->{iscommercial}){
                  $h->{involvedcostcenter}=$r->{conumber};
               }
               last;
            }
         }
         if (!defined($prec)){
            $self->LastMsg(ERROR,"invalid project");
            return(undef);
         }
      }
      # if costcenter is specified - need to check if costcenter is active!

      if (my $id=$self->StoreRecord($WfRec,$h)){
         $h->{id}=$id;
      }
      else{
         return(0);
      }
      return(1);
   }
   return($self->SUPER::nativProcess($action,$h,$WfRec,$actions));
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      my $h=$self->getWriteRequestHash("web");
      if ($self->LastMsg()){
         return(undef);
      }
      my $tt=Query->Param("Formated_tasktyp");
      if ($tt eq "personaltask"){
         $h->{tasknature}="Tpersonal";
         $h->{taskclass}="non productive";
      }
      elsif (my ($t)=$tt=~m/^personal:(.*$)$/){
         $h->{tasknature}="Tpersonal";
         $h->{taskclass}=$t;
      }
      elsif (my ($pid)=$tt=~m/^projectroom:(.*$)$/){
         $h->{tasknature}="Tproject";
         $h->{taskclass}="project work";
         $h->{affectedprojectid}=$pid;
      }
      $h->{stateid}=4;
      $h->{eventstart}=NowStamp("en");
      $h->{eventend}=undef;
      $h->{closedate}=undef;
      $h->{fwdtargetid}=$self->getParent->getParent->getCurrentUserId();
      $h->{fwdtarget}="base::user";
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
      if (!$self->addInitialParameters($h)){
         if (!$self->getParent->LastMsg()){
            $self->getParent->LastMsg(ERROR,
                   "unknown error while addInitialParameters");
         }
         return(0);
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
   if (defined($cur) && $cur->{fwdtarget} ne "" && $cur->{fwdtargetid} ne ""){ 
      my $aobj=$self->getParent->getParent->Action();
      my $workflowname=$self->getParent->getWorkflowMailName();
      $aobj->NotifyForward($WfRec->{id},
                           $cur->{fwdtarget},$cur->{fwdtargetid},undef,
                           $WfRec->{detaildescription},
                           workflowname=>$workflowname,
                           sendercc=>1);
   }
}



sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("200");
}

#######################################################################
package base::workflow::task::main;
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

   if (grep(/^wfacceptp$/,@$actions)){
      $$selopt.="<option value=\"wfacceptp\">".
                $self->getParent->T("wfacceptp",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfacceptp class=\"$class\">".
                $self->getDefaultNoteDiv($WfRec,$actions).
                "</div>";
   }
   if (grep(/^wfacceptn$/,@$actions)){
      $$selopt.="<option value=\"wfacceptn\">".
                $self->getParent->T("wfacceptn",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfacceptn class=\"$class\">".
                $self->getDefaultNoteDiv($WfRec,$actions).
                "</div>";
   }
   if (grep(/^wfaccept$/,@$actions)){
      $$selopt.="<option value=\"wfaccept\">".
                $self->getParent->T("wfaccept",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfaccept class=\"$class\"></div>";
   }
   if (grep(/^wffine$/,@$actions)){
      $$selopt.="<option value=\"wffine\">".
                $self->getParent->T("wffine","base::workflow::task").
                "</option>\n";
      $$divset.="<div id=OPwffine style=\"$class;margin:15px\"><br>".
                $self->getParent->T("use this action,".
                " to finish this task and mark it as according to ".
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
   if (grep(/^wfreject$/,@$actions)){
      $$selopt.="<option value=\"wfreject\">".
                $self->getParent->T("wfreject",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfreject class=\"$class\"><textarea name=note ".
                "style=\"width:100%;height:110px\"></textarea></div>";
   }
   if (grep(/^wfaddsubtask$/,@$actions)){
      $$selopt.="<option value=\"wfaddsubtask\">".
                $self->getParent->T("wfaddsubtask","base::workflow::task").
                "</option>\n";
      my $note=Query->Param("note");
      my $d;
      $d.="<tr><td width=1% nowrap>".
          $self->getParent->T("assign to","base::workflow::task").
          ":&nbsp;</td>".
          "<td>\%fwdtargetname(detail)\%".
          "</td>";
      $d.="<tr><td width=1% nowrap>".
          $self->getParent->T("subtask label","base::workflow::task").
          ":&nbsp;</td>".
          "<td>\%name(detail)\%".
          "</td>";
      $d.="<tr><td colspan=2><textarea name=note ".
          "style=\"width:100%;height:70px\">".$note."</textarea></td></tr>";
      $$divset.="<div id=OPwfaddsubtask class=\"$class\">".
                "<table>$d</table></div>";
   }
   if (grep(/^setprioexecs$/,@$actions)){
      $$selopt.="<option value=\"setprioexecs\">".
                $self->getParent->T("setprioexecs","base::workflow::task").
                "</option>\n";
      my $app=$self->getParent->getParent;
      my $f1=$app->getField("prio",$WfRec);
      my $f2=$app->getField("wffields.taskexecstate",$WfRec);
      my $l1=$f1->Label();
      my $l2=$f2->Label();
      my $s1=$f1->FormatedDetail($WfRec,"edit");
      my $s2=$f2->FormatedDetail($WfRec,"edit");
      $$divset.="<div id=OPsetprioexecs class=\"$class\">".
                "<table width=\"100%\" border=0 style=\"margin-top:10px\">".
                "<tr><td width=\"20%\">$l1:</td><td>$s1</td></tr>".
                "<tr><td>$l2:</td><td>$s2</td></tr>".
                "</table></div>";
   }
   $self->SUPER::generateWorkspacePages($WfRec,$actions,$divset,$selopt);
   return("wfaddnote") if (grep(/^wfaddnote$/,@$actions));
   return("wfaddsnote") if (grep(/^wfaddsnote$/,@$actions));
   return("nop");
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
          {translation=>'base::workflow::task'},"",undef)){
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
         $self->LastMsg(ERROR,"invalid disalloed action tasked");
      }
     
      if ($op eq "wfaccept"){
     
         if ($self->StoreRecord($WfRec,{stateid=>3,
                                        fwdtarget=>'base::user',
                                        fwdtargetid=>$userid,
                                        fwddebtarget=>undef,
                                        fwddebtargetid=>undef})){
            if ($self->getParent->getParent->Action->StoreRecord(
                $WfRec->{id},"wfaccept",
                {translation=>'base::workflow::task'},"",undef)){
               $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
               $self->PostProcess($action.".".$op,$WfRec,$actions);
               return(1);
            }
         }
         return(0);
      }


      if ($op eq "wfaddsubtask"){
         my $note=Query->Param("note");
         $note=trim($note);
         if (length($note)<20){
            $self->LastMsg(ERROR,"invalid or not details subtask description");
            return(0);
         }

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
         my $fwdtargetname=Query->Param("Formated_fwdtargetname");
         my $name=Query->Param("Formated_name");
         
         if (my $subid=$self->StoreRecord(undef,{
                stateid=>2,
                name=>$name,
                tasknature=>"Tsubtask",
                taskclass=>$WfRec->{taskclass},
                mandatorid=>$WfRec->{mandatorid},
                affectedproject=>$WfRec->{affectedproject},
                affectedprojectid=>$WfRec->{affectedprojectid},
                mandator=>$WfRec->{mandator},
                detaildescription=>$note,
                fwdtarget=>$newrec->{fwdtarget},
                fwdtargetid=>$newrec->{fwdtargetid},
                fwddebtarget=>undef,
                fwddebtargetid=>undef })){
            my $wf=$self->getParent->getParent;
            my $wr=$wf->getPersistentModuleObject("base::workflowrelation");
            my $srcid=$WfRec->{id};
            my $dstid=$subid;
            $wr->ValidatedInsertOrUpdateRecord(
                                      {srcwfid=>$srcid,
                                       name=>'subtask',
                                       translation=>'base::workflow::task',
                                       additional=>{
                                          show=>[qw(headref.taskexecstate)],
                                       },
                                       dstwfid=>$dstid},
                                      {srcwfid=>\$srcid,dstwfid=>\$dstid});
            Query->Delete("note");
            Query->Delete("Formated_name");
            Query->Delete("Formated_fwdtargetname");
            $self->LastMsg(OK,"subtask sucessfuly created");
            return(1);
         }
         return(0);
      }

     

      if ($op eq "setprioexecs"){
         my $prio=Query->Param("Formated_prio");
         my $execstate=Query->Param("Formated_taskexecstate");
         if ($self->StoreRecord($WfRec,{prio=>$prio,
                                        taskexecstate=>$execstate})){
            $self->PostProcess($action.".".$op,$WfRec,$actions);
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
             {translation=>'base::workflow::task'},"",undef)){
            sleep(1);
            if ($self->getParent->getParent->Action->StoreRecord(
                $WfRec->{id},"wfaddnote",
                {translation=>'base::workflow::task'},$note,$effort)){
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
             {translation=>'base::workflow::task'},"",undef)){
            sleep(1);
            if ($self->getParent->getParent->Action->StoreRecord(
                $WfRec->{id},"wfaddnote",
                {translation=>'base::workflow::task'},$note,$effort)){
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
             {translation=>'base::workflow::task'},"",undef)){
            my $nextstep=$self->getParent->getStepByShortname("finish");
            my $store={stateid=>21,
                       step=>$nextstep,
                       taskexecstate=>100,
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
             {translation=>'base::workflow::task'},$note,$effort)){
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
             {translation=>'base::workflow::task'},$note,undef)){
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

#   if ($action eq "SaveStep.wfreject" ||
#       $action eq "SaveStep.wffineproc" ||
#       $action eq "SaveStep.wfacceptp" ||
#       $action eq "BreakWorkflow" ){
#      $aobj->NotifyForward($WfRec->{id},
#                           $param{fwdtarget},
#                           $param{fwdtargetid},
#                           $param{fwdtargetname},
#                           $param{note},
#                           workflowname=>$workflowname);
#   }

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
         $b{BreakWorkflow}=$self->T('abbort task');
      }
   }
   return(%b);
}

#######################################################################
package base::workflow::task::finish;
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
<table border=0 cellspacing=0 cellpadding=0 width="100%">
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
             {translation=>'base::workflow::task'},$fwdtargetname,undef);

         Query->Delete("WorkflowStep");
         return(1);
      }
   }
   return($self->SUPER::Process($action,$WfRec,$actions));
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
package base::workflow::task::break;
use vars qw(@ISA);
use kernel;
@ISA=qw(base::workflow::task::finish);


1;
