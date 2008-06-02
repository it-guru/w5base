package base::workflow::ReplaceTool;
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
   return($self);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/workflow-ReplaceTool.jpg?".$cgi->query_string());
}



sub IsModuleSelectable
{
   my $self=shift;
   my $acl;

   return(1) if ($self->IsMemberOf("admin"));
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
   return("default","state","flow","header","relations");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(1) if (!defined($rec));
   return("default") if ($rec->{state}<=20 &&
                         ($self->getParent->getCurrentUserId()==$rec->{owner} ||
                          $self->getParent->IsMemberOf("admin")));
   return(undef);
}

sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   return("base::workflow::ReplaceTool::".$shortname);
}


sub getNextStep
{
   my $self=shift;
   my $currentstep=shift;
   my $WfRec=shift;

   if($currentstep eq "base::workflow::ReplaceTool::finish"){
      return($self->getStepByShortname("finish",$WfRec)); 
   }
   elsif($currentstep=~m/^.*::workflow::ReplaceTool::dataload$/){
      return($self->getStepByShortname("main",$WfRec)); 
   }
   elsif($currentstep eq ""){
      return($self->getStepByShortname("dataload",$WfRec)); 
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
   return("base::workflow::ReplaceTool"=>'relinfo');
}



sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;
   my $app=$self->getParent;
   my $userid=$self->getParent->getCurrentUserId();
   my @l=();
   if ($WfRec->{state}==17 && $WfRec->{openuser}==$userid){
      push(@l,"addsup");
      push(@l,"wffinish");
   }

   if ($WfRec->{state}>=21 && 
       ($WfRec->{openuser}==$userid || 
        $self->getParent->IsMemberOf(["admin","admin.workflow"]))){
      push(@l,"reactivate");
   }

   if ($WfRec->{fwdtarget} eq 'base::grp'){
      if ($app->IsMemberOf($WfRec->{fwdtargetid},undef,"both")){
         push(@l,"addnote");
      }
   }
   elsif ($WfRec->{fwdtarget} eq 'base::user' && 
       $userid==$WfRec->{fwdtargetid}){
         push(@l,"addnote");
   }
   elsif ($WfRec->{fwddebtarget} eq 'base::grp'){
      if ($app->IsMemberOf($WfRec->{fwddebtargetid},undef,"both")){
         push(@l,"addnote");
      }
      else{
         if ($app->IsMemberOf(["admin","admin.workflow"])){
            push(@l,"addnote");
         }
      }
   }
   elsif ($WfRec->{fwddeptarget} eq 'base::user'){
      if ($userid==$WfRec->{fwddeptargetid}){
         push(@l,"addnote");
      }
   }
   if ($WfRec->{owner}==$userid || $WfRec->{openuser}==$userid){
      push(@l,"addnote");
      if ($WfRec->{fwdtarget} ne ""){
         push(@l,"remsup");
      }
      else{
         push(@l,"addsup");
      }
      push(@l,"wfclose");
   }
   #msg(INFO,"valid operations=%s",join(",",@l));

   return(@l);
}


#######################################################################
package base::workflow::ReplaceTool::dataload;
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

   foreach my $v (qw(name)){
      if ((!defined($oldrec) || exists($newrec->{$v})) && $newrec->{$v} eq ""){
         $self->LastMsg(ERROR,"field '%s' is empty",
                        $self->getField($v)->Label());
         return(0);
      }
   }
   $newrec->{step}=$self->getNextStep();

   return(1);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      my $h=$self->getWriteRequestHash("web");
      $h->{stateid}=1;
      $h->{eventstart}=NowStamp("en");
      $h->{eventend}=undef;
      $h->{closedate}=undef;
      if (!$self->StoreRecord($WfRec,$h)){
         return(0);
      }
   }
   return($self->SUPER::Process($action,$WfRec));
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(100);
}

#######################################################################
package base::workflow::ReplaceTool::main;
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

   my ($Dremsup,$Dwfclose,$Daddnote,$Daddsup,$Dnote);
   $Dwfclose="disabled"   if (!$self->ValidActionCheck(0,$actions,"wfclose"));
   $Daddsup="disabled"    if (!$self->ValidActionCheck(0,$actions,"addsup"));
   $Dremsup="disabled"    if (!$self->ValidActionCheck(0,$actions,"remsup"));
   my $t0=$self->T("Effort");
   my $t1=$self->T("Add Note");
   my $t2=$self->T("Add Support");
   my $t3=$self->T("Remove Support");
   my $t4=$self->T("Close Workflow");
   if (!$self->ValidActionCheck(0,$actions,"addnote")){
      $Daddnote="disabled";
      $Dnote="readonly";
   }
   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100% height=110>
<tr><td align=center valign=top>
<textarea name=note $Dnote style=\"width:100%;height:80\"></textarea>
<table border=0 width=100% cellspacing=0 cellpadding=0>
<tr>
<td width=25% nowrap>&nbsp;$t0:</td>
<td width=25%><select name=Formated_effort>
<option value=""></option>
<option value="10">10 min</option>
<option value="15">15 min</option>
<option value="20">20 min</option>
<option value="25">25 min</option>
<option value="30">30 min</option>
<option value="45">45 min</option>
<option value="60">1,0 h</option>
<option value="90">1,5 h</option>
<option value="120">2,0 h</option>
<option value="180">3,0 h</option>
<option value="240">4,0 h</option>
<option value="300">5,0 h</option>
<option value="360">6,0 h</option>
<option value="420">7,0 h</option>
<option value="480">8,0 h</option>
</select></td>
<td>
<input type=submit name=addnote $Daddnote value="$t1" 
       class=workflowbutton>
</td>
<td width=25%>&nbsp;</td>
<td width=25%>&nbsp;</td>
</tr>
</table>
</td>
<td width=1% valign=top>
<input type=submit $Daddsup 
       class=workflowbutton name=addsup value="$t2">
<input type=submit $Dremsup 
       class=workflowbutton name=remsup value="$t3">
<input type=submit $Dwfclose
       class=workflowbutton name=wfclose value="$t4">
<input type=submit disabled 
       class=workflowbutton name=forwardtox value="Workflow Einstellungen">
</td>
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

   foreach my $v (qw(name)){
      if ((!defined($oldrec) || exists($newrec->{$v})) && $newrec->{$v} eq ""){
         $self->LastMsg(ERROR,"field '%s' is empty",
                        $self->getField($v)->Label());
         return(0);
      }
   }
   $newrec->{stateid}=4 if (!defined($newrec->{stateid}));

   return(1);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if (!defined($action) && Query->Param("addnote")){
      my $note=Query->Param("note");
      if ($note=~m/^\s*$/){
         $self->LastMsg(ERROR,"nix drin");
         return(0);
      }
      $note=trim($note);
      my $effort=Query->Param("Formated_effort");
      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"note",
          {translation=>'base::workflow::ReplaceTool'},$note,$effort)){
         $self->StoreRecord($WfRec,{stateid=>4});
         Query->Delete("WorkflowStep");
         return(1);
      }
      return(0);
   }
   if (!defined($action) && Query->Param("addsup")){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"addsup"));
      my @WorkflowStep=Query->Param("WorkflowStep");
      push(@WorkflowStep,"base::workflow::ReplaceTool::addsup");
      Query->Param("WorkflowStep"=>\@WorkflowStep);
      return(0);
   }
   if (!defined($action) && Query->Param("remsup")){
      return(0) if (!$self->ValidActionCheck(1,$actions,"remsup"));
      my $maindisp=$self->getParent->getStepByShortname("main",$WfRec);
      if ($self->StoreRecord($WfRec,{step=>$maindisp,
                                     fwdtarget=>undef,
                                     fwdtargetid=>undef,
                                     stateid=>4})){
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"remsup", 
             {translation=>'base::workflow::ReplaceTool'},undef)){
            Query->Delete("WorkflowStep");
            return(1);
         }
         return(0);
      }
      return(0);
   }
   if (!defined($action) && Query->Param("wfclose")){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"wfclose"));
      my @WorkflowStep=Query->Param("WorkflowStep");
      push(@WorkflowStep,$self->getParent->getStepByShortname('prewfclose',
                                                              $WfRec));
      Query->Param("WorkflowStep"=>\@WorkflowStep);
      return(0);
   }
   return($self->SUPER::Process($action,$WfRec));
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(140);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my %p=$self->SUPER::getPosibleButtons($WfRec);
   delete($p{PrevStep});
   delete($p{NextStep});
   return()   if (!$self->ValidActionCheck(0,$actions,"BreakWorkflow"));
   return(%p);
}

#######################################################################
package base::workflow::ReplaceTool::addsup;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $note=Query->Param("note");
   my $l1=$self->T("Support (Name or Group)");
   my $l2=$self->T("Mail notification (without text there will be no notification generated)");
   my $templ=<<EOF;
<table border=1 cellspacing=0 cellpadding=0 width=100% height=50>
<tr height=1%>
<td class=fname width=20%>$l1:</td>
<td class=finput>%fwdtargetname(detail)%</td>
</tr>
<!--
<tr height=1%>
<td class=fname colspan=2>$l2:</td>
</tr>
<tr><td align=center colspan=2>
<textarea class=multilinetext name=note style="height:100%">$note</textarea>
</td></tr>
-->
</table>
<script language="JavaScript">
setFocus("Formated_fwdtargetname");
setEnterSubmit(document.forms[0],"NextStep");
</script>

EOF
   return($templ);
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

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $note=Query->Param("note");

   if ($action eq "NextStep"){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"addsup"));
      my $fobj=$self->getParent->getField("fwdtargetname");
      my $h=$self->getWriteRequestHash("web");
      my $maindisp=$self->getParent->getStepByShortname("main",$WfRec);
      if (my $newrec=$fobj->Validate($WfRec,$h)){
         if (!defined($newrec->{fwdtarget}) ||
             !defined($newrec->{fwdtargetid} ||
             $newrec->{fwdtargetid}==0)){
            $self->LastMsg(ERROR,"invalid forwarding target");
            return(0);
         }
         $newrec->{stateid}=2;
         $newrec->{step}=$maindisp;
         if ($self->StoreRecord($WfRec,$newrec)){
            my $additional={};
            $additional->{ForwardToName}=Query->Param("Formated_fwdtargetname");
            $additional->{ForwardTarget}=$newrec->{fwdtarget};
            $additional->{ForwardTargetId}=$newrec->{fwdtargetid};
            if ($self->getParent->getParent->Action->StoreRecord(
                $WfRec->{id},"addsup",
                {translation=>'base::workflow::ReplaceTool',
                 additional=>$additional},$note)){
               Query->Delete("WorkflowStep");
               return(1);
            }
            return(0);
         }
      }
      return(0);
   }
   return($self->SUPER::Process($action,$WfRec));
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(100);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my %p=$self->SUPER::getPosibleButtons($WfRec);
   delete($p{BreakWorkflow});
   return(%p);
}

#######################################################################
package base::workflow::ReplaceTool::prewfclose;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);


sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $note=Query->Param("note");
   my $l1=$self->T("closing comments");
   my $templ=<<EOF;
<table border=1 cellspacing=0 cellpadding=0 width=100% height=180>
<tr height=1%>
<td class=fname>$l1:</td>
</tr>
<tr><td align=center colspan=2>
<textarea class=multilinetext name=note style="height:100%">$note</textarea>
</td></tr>
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

   return(0);
}
sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $note=Query->Param("note");

   if ($action eq "NextStep"){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"wfclose"));
      my %fwd;
      %fwd=(fwdtarget=>"base::user",fwdtargetid=>$WfRec->{openuser});
      my $note=Query->Param("note");
      if (!($note=~m/^\s*$/) && $WfRec->{detaildescription}=~m/^\s*$/){
         $fwd{detaildescription}=$note;
      }
      my $newstep=$self->getParent->getStepByShortname('wfclose',$WfRec);
      msg(INFO,"newstep=$newstep");
      if ($self->getParent->StoreRecord($WfRec,$newstep,{
                                %fwd,
                                step=>$newstep,
                                eventend=>NowStamp("en"),
                                stateid=>17})){
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wfclose",
             {translation=>'base::workflow::ReplaceTool'},$note)){
            Query->Delete("WorkflowStep");
            return(1);
         }
         return(0);
      }
   }
   return($self->SUPER::Process($action,$WfRec));
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(220);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my %p=$self->SUPER::getPosibleButtons($WfRec);
   delete($p{BreakWorkflow});
   return(%p);
}


#######################################################################
package base::workflow::ReplaceTool::wfclose;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my ($Dwffinish,$Daddsup);
   $Dwffinish="disabled"  if (!$self->ValidActionCheck(0,$actions,"wffinish"));
   $Daddsup="disabled"    if (!$self->ValidActionCheck(0,$actions,"addsup"));
   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100% height=50>
<tr><td width=50% align=center>
<input type=submit $Daddsup 
       class=workflowbutton name=addsup value="Unterstützung hinzuziehen">
</td>
<td width=50% align=center>
<input type=submit $Dwffinish
       class=workflowbutton name=wffinish value="beenden">
</td></tr> 
</table>
EOF
   return($templ);
}

sub getPosibleButtons
{
   return();
}

sub getWorkHeight
{
   return(80);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if (!defined($action) && Query->Param("addsup")){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"addsup"));
      my @WorkflowStep=Query->Param("WorkflowStep");
      push(@WorkflowStep,"base::workflow::ReplaceTool::addsup");
      Query->Param("WorkflowStep"=>\@WorkflowStep);
      return(0);
   }
   if (!defined($action) && Query->Param("wffinish")){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"wffinish"));
      if ($self->StoreRecord($WfRec,{
                                step=>'base::workflow::ReplaceTool::wffinish',
                                fwdtarget=>undef,
                                fwdtargetid=>undef,
                                closedate=>NowStamp("en"),
                                stateid=>21})){
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wffinish", 
             {translation=>'base::workflow::ReplaceTool'},undef)){
            Query->Delete("WorkflowStep");
            return(1);
         }
         return(0);
      }
      return(0);
   }
   return(0);
}

sub Validate
{
   my $self=shift;
   return(1);
}




#######################################################################
package base::workflow::ReplaceTool::wffinish;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;


   my ($Dwfreact);
   $Dwfreact="disabled"  if (!$self->ValidActionCheck(0,$actions,"reactivate"));
   my $label=$self->T("reactivate");

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100% height=50>
<tr><td align=center>
<input type=submit $Dwfreact 
       class=workflowbutton name=reactivate value="$label">
</td></tr> 
</table>
EOF
   return($templ);
}

sub getPosibleButtons
{
   return();
}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   return(0) if ($#{$actions}==-1);
   return(80);
}


sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if (!defined($action) && Query->Param("reactivate")){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"reactivate"));
      if ($self->StoreRecord($WfRec,{
                                step=>'base::workflow::ReplaceTool::main',
                                fwdtarget=>undef,
                                fwdtargetid=>undef,
                                closedate=>undef,
                                eventend=>undef,
                                stateid=>4})){
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"reactivate", 
             {translation=>'base::workflow::ReplaceTool'},undef)){
            Query->Delete("WorkflowStep");
            return(1);
         }
         return(0);
      }
      return(0);
   }
   return(0);
}


sub Validate
{
   my $self=shift;
   return(1);
}

1;
