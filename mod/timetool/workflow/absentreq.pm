package timetool::workflow::absentreq;
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

sub IsModuleSelectable
{
   my $self=shift;
   my $acl;

#   $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
#                          "base::workflow",
#                          func=>'New',
#                          param=>'WorkflowClass=timetool::workflow::absentreq');
#   if (defined($acl)){
#      return(1) if (grep(/^read$/,@$acl));
#   }
   return(1) if ($self->getParent->IsMemberOf("admin"));
   return(0);
}

sub Init
{
   my $self=shift;
   $self->AddGroup("absentreqhead");
   return($self->SUPER::Init(@_));
}


sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my @l=();

   return($self->InitFields(
           new kernel::Field::Text(
                name          =>'absentreqname',
                label         =>'Shortdescription',
                group         =>'absentreqhead',
                alias         =>'name'),

           new kernel::Field::Text(
                name          =>'absentreqreuestor',
                label         =>'Requestor',
                group         =>'absentreqhead',
                alias         =>'openusername'),

           new kernel::Field::Date(
                name          =>'absentstart',
                label         =>'Absent start',
                group         =>'absentreqhead',
                alias         =>'eventstart'),

           new kernel::Field::Date(
                name          =>'absentend',
                label         =>'Absent end',
                group         =>'absentreqhead',
                alias         =>'eventend'),

           new kernel::Field::Duration(
                name          =>'absentduration',
                label         =>'Absent duration',
                group         =>'absentreqhead',
                depend        =>['eventstart','eventend']),

           new kernel::Field::Textarea(
                name          =>'absentreqdesc',
                label         =>'Argumentation',
                group         =>'absentreqhead',
                alias         =>'description'),

         ));

}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("absentreqhead","flow","default","header","state");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
#   return(1) if (!defined($rec));
#   return("default") if ($rec->{state}<=7 &&
#                         ($self->getParent->getCurrentUserId()==$rec->{owner} ||
#                          $self->getParent->IsMemberOf("admin")));
   return(undef);
}

sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   return("timetool::workflow::absentreq::".$shortname);
}


sub getNextStep
{
   my $self=shift;
   my $currentstep=shift;
   my $WfRec=shift;

   if($currentstep eq "timetool::workflow::absentreq::finish"){
      return($self->getStepByShortname("finish",$WfRec)); 
   }
   elsif($currentstep=~m/^.*::workflow::absentreq::dataload$/){
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

   return(0) if ($name eq "prio");
   return(0) if ($name eq "name");
   return(1) if ($name eq "shortactionlog");
   return(0) if ($name eq "detaildescription");
   return(0);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return("absentreqhead","flow","state");
}


sub getPosibleDirectActions
{
   my $self=shift;
   my $WfRec=shift;
   return("approve");
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

   if ($WfRec->{state}>20 && 
       ($WfRec->{openuser}==$userid || 
        $self->getParent->IsMemberOf(["admin","admin.workflow"]))){
      push(@l,"reactivate");
   }

   if ($WfRec->{fwdtarget} eq 'base::grp'){
      if ($app->IsMemberOf($WfRec->{fwdtargetid},undef,"up")){
         push(@l,"addnote");
      }
   }
   elsif ($WfRec->{fwdtarget} eq 'base::user' && 
       $userid==$WfRec->{fwdtargetid}){
         push(@l,"addnote");
   }
   elsif ($WfRec->{fwddebtarget} eq 'base::grp'){
      if ($app->IsMemberOf($WfRec->{fwddebtargetid},undef,"up")){
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
   msg(INFO,"valid operations=%s",join(",",@l));

   return(@l);
}


#######################################################################
package timetool::workflow::absentreq::dataload;
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

   return("100%");
}

#######################################################################
package timetool::workflow::absentreq::main;
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
   if (!$self->ValidActionCheck(0,$actions,"addnote")){
      $Daddnote="disabled";
      $Dnote="readonly";
   }
   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100% height=110>
<tr><td align=center valign=top>
<textarea name=note $Dnote style=\"width:100%;height:80\"></textarea>
<input type=submit name=addnote $Daddnote value="Notiz hinzufügen" 
       class=workflowbutton style="width:70%">
</td>
<td width=1% valign=top>
<input type=submit $Daddsup 
       class=workflowbutton name=addsup value="Unterstützung hinzuziehen">
<input type=submit $Dremsup 
       class=workflowbutton name=remsup value="Unterstützung entfernen">
<input type=submit $Dwfclose
       class=workflowbutton name=wfclose value="Workflow abschließen">
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

   foreach my $v (qw(name emailtext)){
      if ((!defined($oldrec) || exists($newrec->{$v})) && $newrec->{$v} eq ""){
         $self->LastMsg(ERROR,"field '%s' is empty",
                        $self->getField($v)->Label());
         return(0);
      }
   }

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
      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"note",
          {translation=>'timetool::workflow::absentreq'},$note)){
         $self->StoreRecord($WfRec,{stateid=>4});
         Query->Delete("WorkflowStep");
         return(1);
      }
      return(0);
   }
   if (!defined($action) && Query->Param("addsup")){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"addsup"));
      my @WorkflowStep=Query->Param("WorkflowStep");
      push(@WorkflowStep,"timetool::workflow::absentreq::addsup");
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
             {translation=>'timetool::workflow::absentreq'},undef)){
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
package timetool::workflow::absentreq::addsup;
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
<table border=1 cellspacing=0 cellpadding=0 width=100% height=180>
<tr height=1%>
<td class=fname width=20%>$l1:</td>
<td class=finput>%fwdtargetname(detail)%</td>
</tr>
<tr height=1%>
<td class=fname colspan=2>$l2:</td>
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
                {translation=>'timetool::workflow::absentreq',
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
package timetool::workflow::absentreq::prewfclose;
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
             {translation=>'timetool::workflow::absentreq'},$note)){
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
package timetool::workflow::absentreq::wfclose;
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
      push(@WorkflowStep,"timetool::workflow::absentreq::addsup");
      Query->Param("WorkflowStep"=>\@WorkflowStep);
      return(0);
   }
   if (!defined($action) && Query->Param("wffinish")){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"wffinish"));
      if ($self->StoreRecord($WfRec,{
                                step=>'timetool::workflow::absentreq::wffinish',
                                fwdtarget=>undef,
                                fwdtargetid=>undef,
                                closedate=>NowStamp("en"),
                                stateid=>21})){
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wffinish", 
             {translation=>'timetool::workflow::absentreq'},undef)){
            Query->Delete("WorkflowStep");
            return(1);
         }
         return(0);
      }
      return(0);
   }
   return(0);
}




#######################################################################
package timetool::workflow::absentreq::wffinish;
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
                                step=>'timetool::workflow::absentreq::main',
                                fwdtarget=>undef,
                                fwdtargetid=>undef,
                                closedate=>undef,
                                eventend=>undef,
                                stateid=>4})){
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"reactivate", 
             {translation=>'timetool::workflow::absentreq'},undef)){
            Query->Delete("WorkflowStep");
            return(1);
         }
         return(0);
      }
      return(0);
   }
   return(0);
}


1;
