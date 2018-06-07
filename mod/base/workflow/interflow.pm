package base::workflow::interflow;
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
   $self->{_permitted}->{to}=1;
   $self->AddFields(
   );
   return($self);
}

sub Init
{
   my $self=shift;

   $self->AddFields(
   );

   $self->AddGroup("interflow",translation=>'base::workflow::interflow');
}


sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;

   return($self->InitFields(   
#      new kernel::Field::Textarea(name       =>'inderflowdescription',
#                                  translation=>'base::workflow::interflow',
#                                  htmlwidth  =>'300',
#                                  label      =>'Description',
#                                  group      =>'default',
#                                  alias      =>'description'),
   ));
}

sub IsModuleSelectable
{
   my $self=shift;
   my $acl;

   $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
                          "base::workflow",
                          func=>'New',
                          param=>'WorkflowClass=base::workflow::interflow');
   if (defined($acl)){
      return(1) if (grep(/^read$/,@$acl));
   }
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
   return("default","state","flow","header");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(1) if (!defined($rec));
   return(undef);
   return("default");
}

sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   return("base::workflow::interflow::".$shortname);
}


sub getNextStep
{
   my $self=shift;
   my $currentstep=shift;
   my $WfRec=shift;

   if($currentstep eq "base::workflow::interflow::finish"){
      return($self->getStepByShortname("finish",$WfRec)); 
   }
   elsif($currentstep eq "base::workflow::interflow::dataload"){
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

   return(1) if ($name eq "shortactionlog");
   return(1) if ($name eq "detaildescription");
   return(0);
}

sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;
   my $app=$self->getParent;
   my $userid=$self->getParent->getCurrentUserId();
   my @l=();
   if ($WfRec->{openuser} eq $userid && $WfRec->{state}==17){
      push(@l,"wffinish");
      push(@l,"forwardto");
   }
   if ($WfRec->{owner} eq $userid && 
       ($WfRec->{state}==17 || $WfRec->{state}==3 || 
        $WfRec->{state}==4 || $WfRec->{state}==1)){
      push(@l,"forwardto");
   }
   if ($WfRec->{owner} eq $userid && ($WfRec->{state}!=2)){
      push(@l,"addnote");
   }
   if ($WfRec->{owner} eq $userid && ($WfRec->{state}!=2)){
      push(@l,"wfclose");
   }

   if ($WfRec->{fwdtarget} eq 'base::grp'){
      if ($app->IsMemberOf($WfRec->{fwdtargetid},undef,"up")){
         push(@l,"takeover");
      }
   }
   elsif ($WfRec->{fwdtarget} eq 'base::user' && 
       $userid==$WfRec->{fwdtargetid}){
         push(@l,"takeover");
   }
   elsif ($WfRec->{fwddebtarget} eq 'base::grp'){
      if ($app->IsMemberOf($WfRec->{fwddebtargetid},undef,"up")){
         push(@l,"takeover");
      }
      else{
         if ($app->IsMemberOf(["admin","w5base.base.workflow"])){
            push(@l,"takeover");
         }
      }
   }
   elsif ($WfRec->{fwddeptarget} eq 'base::user'){
      if ($userid==$WfRec->{fwddeptargetid}){
         push(@l,"takeover");
      }
   }
   if ($WfRec->{owner} ne $userid && 
       $app->IsMemberOf(["admin","w5base.base.workflow"])){
      push(@l,"takeover");
   }

   return(@l);
}


#######################################################################
package base::workflow::interflow::dataload;
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
<td colspan=2 class=fname>%detaildescription(label)%:<br>
%detaildescription(detail)%</td>
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
   return($self->SUPER::Process($action,$WfRec,$actions));
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(190);
}

#######################################################################
package base::workflow::interflow::main;
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

   my ($Dforwardto,$Dwfclose,$Daddnote,$Dtakeover);
   $Dforwardto="disabled" if (!$self->ValidActionCheck(0,$actions,"forwardto"));
   $Dwfclose="disabled"   if (!$self->ValidActionCheck(0,$actions,"wfclose"));
   $Daddnote="disabled"   if (!$self->ValidActionCheck(0,$actions,"addnote"));
   $Dtakeover="disabled"  if (!$self->ValidActionCheck(0,$actions,"takeover"));
   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100% height=70>
<tr><td width=50% align=center>
<input type=submit $Dforwardto 
       class=workflowbutton name=forwardto value="weiterleiten">
</td>
<td width=50% align=center>
<input type=submit $Dwfclose 
       class=workflowbutton name=wfclose value="abschließen">
</td></tr> 
<tr><td align=center>
<input type=submit $Daddnote
       class=workflowbutton name=addnote value="Notiz hinzufügen">
</td>
<td align=center>
<input type=submit $Dtakeover
       class=workflowbutton name=takeover value="übernehmen">
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
      my @WorkflowStep=Query->Param("WorkflowStep");
      push(@WorkflowStep,"base::workflow::interflow::addnote");
      Query->Param("WorkflowStep"=>\@WorkflowStep);
      return(0);
   }
   if (!defined($action) && Query->Param("forwardto")){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"forwardto"));
      my @WorkflowStep=Query->Param("WorkflowStep");
      push(@WorkflowStep,"base::workflow::interflow::forwardto");
      Query->Param("WorkflowStep"=>\@WorkflowStep);
      return(0);
   }
   if (!defined($action) && Query->Param("takeover")){
      return(0) if (!$self->ValidActionCheck(1,$actions,"takeover"));
      my $maindisp=$self->getParent->getStepByShortname("main",$WfRec);
      if ($self->StoreRecord($WfRec,{step=>$maindisp,
                                     fwdtarget=>undef,
                                     fwdtargetid=>undef,
                                     stateid=>3})){
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"takeover", 
             {translation=>'base::workflow::interflow'},undef)){
            Query->Delete("WorkflowStep");
            return(1);
         }
         return(0);
      }
      return(0);
   }
   if (!defined($action) && Query->Param("wfclose")){
      my %fwd;
      %fwd=(fwdtarget=>"base::user",fwdtargetid=>$WfRec->{openuser});
      if ($self->StoreRecord($WfRec,{
                                %fwd,
                                step=>'base::workflow::interflow::wfclose',
                                eventend=>NowStamp("en"),
                                stateid=>17})){
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wfclose", 
             {translation=>'base::workflow::interflow'},undef)){
            Query->Delete("WorkflowStep");
            return(1);
         }
         return(0);
      }
      return(0);
   }
   if ($action eq "BreakWorkflow"){
      if (!$self->StoreRecord($WfRec,{
                                step=>'base::workflow::interflow::break',
                                eventend=>NowStamp("en"),
                                closedate=>NowStamp("en"),
                                stateid=>22})){
         return(0);
      }
      return(1);
   }
   return($self->SUPER::Process($action,$WfRec,$actions));
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
   my $actions=shift;
   my %p=$self->SUPER::getPosibleButtons($WfRec);
   delete($p{PrevStep});
   delete($p{NextStep});
   return()   if (!$self->ValidActionCheck(0,$actions,"BreakWorkflow"));
   return(%p);
}

#######################################################################
package base::workflow::interflow::addnote;
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
   my $templ=<<EOF;
<table border=1 cellspacing=0 cellpadding=0 width=100% height=180>
<tr><td align=center>
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


   return(1);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

#      my $h=$self->getWriteRequestHash();
#      $h->{state}=1;
#      $h->{eventstart}=NowStamp("en");
#      $h->{eventend}=undef;
#      $h->{closedate}=undef;
#      if (!$self->StoreRecord($WfRec,$h)){
#         return(0);
#      }
#   }
   if ($action eq "NextStep"){
      my $note=Query->Param("note");
      if ($note=~m/^\s*$/){
         $self->LastMsg(ERROR,"nix drin");
         return(0);
      }
      $note=trim($note);
      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"note",
          {translation=>'base::workflow::interflow'},$note)){
         $self->StoreRecord($WfRec,{stateid=>4,fwdtarget=>undef,
                                    fwdtargetid=>undef});
         Query->Delete("WorkflowStep");
         return(1);
      }
      return(0);
   }
   return(0) if ($action eq "BreakWorkflow");
   return($self->SUPER::Process($action,$WfRec,$actions));
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
package base::workflow::interflow::forwardto;
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
   my $templ=<<EOF;
<table border=1 cellspacing=0 cellpadding=0 width=100% height=180>
<tr height=1%>
<td class=fname width=20%>%fwdtargetname(label)%:</td>
<td class=finput>%fwdtargetname(detail)%</td>
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
      return(undef) if (!$self->ValidActionCheck(1,$actions,"forwardto"));
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
                $WfRec->{id},"forwardto",
                {translation=>'base::workflow::interflow',
                 additional=>$additional},$note)){
               Query->Delete("WorkflowStep");
               return(1);
            }
            return(0);
         }
      }
      return(0);
   }
   return(0) if ($action eq "BreakWorkflow");
   return($self->SUPER::Process($action,$WfRec,$actions));
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
package base::workflow::interflow::break;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $msg=$self->T("Workflow breaked.");
   my $templ=<<EOF;
<br><div class=Question><table border=0><tr><td>$msg</td></tr></table></div>
EOF
   return($templ);
}

sub getPosibleButtons
{
   return();
}

sub getWorkHeight
{
   return(100);
}


#######################################################################
package base::workflow::interflow::wfclose;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my ($Dwffinish,$Dforwardto);
   $Dwffinish="disabled"  if (!$self->ValidActionCheck(0,$actions,"wffinish"));
   $Dforwardto="disabled" if (!$self->ValidActionCheck(0,$actions,"forwardto"));
   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100% height=50>
<tr><td width=50% align=center>
<input type=submit $Dforwardto 
       class=workflowbutton name=forwardto value="weiterleiten">
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

   if (!defined($action) && Query->Param("forwardto")){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"forwardto"));
      my @WorkflowStep=Query->Param("WorkflowStep");
      push(@WorkflowStep,"base::workflow::interflow::forwardto");
      Query->Param("WorkflowStep"=>\@WorkflowStep);
      return(0);
   }
   if (!defined($action) && Query->Param("wffinish")){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"wffinish"));
      if ($self->StoreRecord($WfRec,{
                                step=>'base::workflow::interflow::wffinish',
                                fwdtarget=>undef,
                                fwdtargetid=>undef,
                                closedate=>NowStamp("en"),
                                stateid=>21})){
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wffinish", 
             {translation=>'base::workflow::interflow'},undef)){
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
package base::workflow::interflow::wffinish;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100% height=50>
<tr><td align=center>beendet
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
   return(0);
}


1;
