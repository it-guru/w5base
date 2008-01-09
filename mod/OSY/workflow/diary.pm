package OSY::workflow::diary;
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
use base::workflow::diary;
use itil::workflow::base;
@ISA=qw(base::workflow::diary itil::workflow::base);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);


   $self->{systemfield}=new kernel::Field::TextDrop( 
                                  name       =>'system',
                                  label      =>'System',
                                  translation=>'OSY::workflow::diary',
                                  vjointo    =>'itil::system',
                                  vjoinon    =>['affectedsystemid'=>'id'],
                                  vjoindisp  =>'name');
   $self->{systemfield}->setParent($self);


   return($self);
}

sub Init
{
   my $self=shift;
   itil::workflow::base::Init($self,@_);
   return($self->SUPER::Init(@_));
}

sub IsModuleSelectable
{
   my $self=shift;
   my $acl;

   $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
                          "base::workflow",
                          func=>'New',
                          param=>'WorkflowClass=OSY::workflow::diary');
   if (defined($acl)){
      return(1) if (grep(/^read$/,@$acl));
   }
   return(0);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @l=("affected");
   push(@l,"source") if ($self->getParent->IsMemberOf("admin"));
   return($self->SUPER::isViewValid($rec),@l);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(1) if (!defined($rec));
   return("default") if ($rec->{state}<21 &&
                         ($self->getParent->getCurrentUserId()==$rec->{owner} ||
                          $self->getParent->IsMemberOf("admin")));
   if ($rec->{state}<21){
      my @acl=$self->getFinishUseridList($rec);
      my $userid=$self->getParent->getCurrentUserId();
      if (grep(/^$userid$/,@acl) || $self->getParent->IsMemberOf("admin")){
         return("default");
      }
   }

   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("affected");
}



sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   if ($shortname eq "dataload" || $shortname eq "loadsystem" || 
       $shortname eq "prewfclose" || $shortname eq "loadtxt"){
      return("OSY::workflow::diary::".$shortname);
   }

   return($self->SUPER::getStepByShortname($shortname,$WfRec));
}


sub getFinishUseridList
{
   my $self=shift;
   my $WfRec=shift;
   my @l=();

   if (ref($WfRec->{affectedsystemid}) eq "ARRAY"){
      my @app=@{$WfRec->{affectedsystemid}};
      my $app=getModuleObject($self->getParent->Config,"itil::appl");
      $app->SetFilter(id=>\@app);
      my @rec=$app->getHashList(qw(tsmid tsm2id));
      foreach my $rec (@rec){
         push(@l,$rec->{tsmid})  if (defined($rec->{tsmid}));
      }
      foreach my $rec (@rec){
         push(@l,$rec->{tsm2id}) if (defined($rec->{tsm2id}));
      }
      if ($#l==-1){
         push(@l,$WfRec->{openuser});
         msg(INFO,"warn: no TSM found - using openuser");
      }
   }
   return(@l);
}

sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;
   my $app=$self->getParent;
   my $userid=$self->getParent->getCurrentUserId();
   my @l=($self->SUPER::getPosibleActions($WfRec));
   @l=grep(!/^wffinish$/,@l);
   if ($WfRec->{state}>20){   # wenn schon ein P800 rep freigeben, dann  nix
      if (defined($WfRec) &&
          ref($WfRec->{affectedcontractid}) eq "ARRAY" &&
          $#{$WfRec->{affectedcontractid}}!=-1){
         my @p800ids;
         if (my ($y,$m)=$WfRec->{eventend}=~m/^(\d{4})-(\d{2})-.*$/){
            foreach my $contractid (@{$WfRec->{affectedcontractid}}){
               push(@p800ids,"$m/$y-$contractid");
            }
            if ($#p800ids!=-1){
               my $wf=$self->getPersistentModuleObject("p800repcheck",
                                                       "base::workflow");
               $wf->SetFilter({srcid=>\@p800ids,
                               stateid=>\'21',
                               srcsys=>\"OSY::event::mkp800"});
               my @l=$wf->getHashList(qw(id));
               return() if ($#l!=-1);
            }
         }
      }
   }
   if ($WfRec->{state}==17){
      my @acl=$self->getFinishUseridList($WfRec);
      if (grep(/^$userid$/,@acl)){
         push(@l,"addsup");
         push(@l,"wffinish");
      }
   }
   if ($WfRec->{state}>17){
      my @acl=$self->getFinishUseridList($WfRec);
      if (grep(/^$userid$/,@acl)){
         push(@l,"reactivate");
      }
   }
   return(@l);
}




#sub getDynamicFields
#{
#   my $self=shift;
#   my %param=@_;
#   my @l=();
#   
#   return($self->SUPER::getDynamicFields(%param),
#          $self->InitFields(
#           new kernel::Field::Select(    name       =>'tcomcodrelevant',
#                                         label      =>'Relevant',
#                                         selectwidth=>'20%',
#                                         value      =>['',qw(yes no)],
#                                         default    =>'yes',
#                                         group      =>'tcomcod',
#                                         container  =>'headref'),
#
#           new kernel::Field::Textarea(  name        =>'tcomcodcomments',
#                                         label       =>'Comments',
#                                         group       =>'tcomcod',
#                                         container   =>'headref'),
#
#           new kernel::Field::Number(    name       =>'tcomworktime',
#                                         unit       =>'min',
#                                         label      =>'Worktime',
#                                         group      =>'tcomcod',
#                                         container  =>'headref'),
#
#   ));
#}

sub getNextStep
{
   my $self=shift;
   my $currentstep=shift;
   my $WfRec=shift;

   if($currentstep eq ""){
      return($self->getStepByShortname("loadtxt",$WfRec));
   }
   if($currentstep eq "OSY::workflow::diary::loadtxt"){
      return($self->getStepByShortname("loadsystem",$WfRec));
   }
   elsif($currentstep=~m/^.*::workflow::diary::loadsystem$/){
      return($self->getStepByShortname("dataload",$WfRec));
   }
   return($self->SUPER::getNextStep($currentstep,$WfRec));
}

sub getDetailFunctions
{
   my $self=shift;
   my $rec=shift;
   my @f;
   if (defined($rec)){
      @f=($self->T('WorkflowCopy')=>'WorkflowCopy');
   }
   return(@f,$self->SUPER::getDetailFunctions($rec));
}

sub getDetailFunctionsCode
{
   my $self=shift;
   my $rec=shift;
   my $wfclass=$self->Self();
   my $d;
   if (defined($rec)){
      my $idname=$self->IdField->Name();
      my $id=$rec->{$idname};
      $d=<<EOF;
function WorkflowCopy()
{
   custopenwin("Copy?CurrentIdToEdit=$id","",640);
}
EOF
   }
   return($self->SUPER::getDetailFunctionsCode($rec).$d);
}

sub InitCopy
{
   my ($self,$copyfrom,$copyinit)=@_;

   my $appl=$copyinit->{Formated_affectedsystem};
   $copyinit->{Formated_system}=$appl;
   $copyinit->{WorkflowStep}=[qw(OSY::workflow::diary::loadtxt
                                 OSY::workflow::diary::loadsystem
                                 OSY::workflow::diary::dataload)];
   $copyinit->{WorkflowClass}=$self->Self();
}







#######################################################################
package OSY::workflow::diary::loadtxt;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub generateStoredWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my @steplist=@_;

   my $d=<<EOF;
<tr>
<td class=fname width=20%>%name(label)%:</td>
<td class=finput>%name(storedworkspace)%</td>
</tr>
<tr>
<td class=fname colspan=2>
%detaildescription(label)%:<br>
%detaildescription(storedworkspace)%</td>
</tr>
EOF
#   $d.=$self->getParent->getParent->HtmlPersistentVariables(
#            qw(Formated_comcodrelevant Formated_tcomcodcomments 
#               Formated_tcomworktime));

   return($self->SUPER::generateStoredWorkspace($WfRec,@steplist).$d);
}


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
<td class=fname colspan=2>
%detaildescription(label)%:<br>
%detaildescription(detail)%</td>
</tr>
</table>
<script language="JavaScript">
setFocus("Formated_name");
setEnterSubmit(document.forms[0],"NextStep");
</script>
EOF
   $templ.=$self->getParent->getParent->HtmlPersistentVariables(
            qw(Formated_system));


   return($templ);
}

sub ProcessNext                
{                               
   my $self=shift;            
   my $action=shift;            
   my $WfRec=shift;
   my $actions=shift;

   my $f=Query->Param("Formated_name");
   if ($f=~m/^\s*$/){
      $self->LastMsg(ERROR,"no short description");
      return(0);
   }
   return($self->SUPER::ProcessNext($action,$WfRec,$actions));
}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(260);
}

#######################################################################
package OSY::workflow::diary::loadsystem;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub generateStoredWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my @steplist=@_;
   my $d="";
   my $app=$self->getParent();
   my $l1=$app->{systemfield}->Label();
   my $e1=$app->{systemfield}->FormatedDetail($WfRec,"storedworkspace");

   $d=<<EOF;
<tr>
<td class=fname width=20%>$l1:</td>
<td class=finput>$e1</td>
</tr>
EOF

   return($self->SUPER::generateStoredWorkspace($WfRec,@steplist).$d);
}


sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $l1=$self->getParent->{systemfield}->Label();
   my $e1=$self->getParent->{systemfield}->FormatedDetail($WfRec,"workflow");
   my @steplist=Query->Param("WorkflowStep");
   pop(@steplist);
   my $StoredWorkspace=$self->SUPER::generateStoredWorkspace($WfRec,@steplist);

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
$StoredWorkspace
<tr>
<td class=fname width=20%>$l1:</td>
<td class=finput>$e1</td>
</tr>
</table>
<script language="JavaScript">
setFocus("Formated_system");
setEnterSubmit(document.forms[0],"NextStep");
</script>
EOF
   return($templ);
}

sub ProcessNext                
{                               
   my $self=shift;            
   my $action=shift;            
   my $WfRec=shift;
   my $actions=shift;

   my $f=Query->Param("Formated_system");
   if (my $appl=$self->getParent->{systemfield}->Validate($WfRec,{system=>$f})){
      $f=Query->Param("Formated_system");
      if (!defined(Query->Param("Formated_fwdtargetname"))){
         my $app=getModuleObject($self->getParent->Config,"itil::system");
         $app->SetFilter({name=>\$f});
         my @l=$app->getHashList(qw(adminteam));
         Query->Param("Formated_fwdtargetname"=>$l[0]->{adminteam}); 
      }
      my $nextstep=$self->getParent->getNextStep($self->Self(),$WfRec);
      if (defined($nextstep)){
         my @WorkflowStep=Query->Param("WorkflowStep");
         push(@WorkflowStep,$nextstep);
         Query->Param("WorkflowStep"=>\@WorkflowStep);
         return(0);
      }
   }
   else{
      $self->LastMsg(ERROR,"selten sam");
      return(0);
   }
   return(0);
}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(250);
}

#######################################################################
package OSY::workflow::diary::dataload;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(base::workflow::diary::dataload);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my @steplist=Query->Param("WorkflowStep");
   pop(@steplist);
   my $StoredWorkspace=$self->SUPER::generateStoredWorkspace($WfRec,@steplist);
   my $e1=$self->T("Add Support","base::workflow::diary::main");

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
$StoredWorkspace
<tr>
<td class=fname width=20%>$e1:</td>
<td class=finput>%fwdtargetname(detail)%</td>
</tr>
</table>
<script language="JavaScript">
setFocus("Formated_fwdtargetname");
setEnterSubmit(document.forms[0],"NextStep");
</script>
EOF
   return($templ);
}

sub preValidate                 # das muß in preValidate behandelt werden,
{                               # da später noch die KeyHandler beeinflußt
   my $self=shift;              # werden
   my $oldrec=shift;
   my $newrec=shift;

   my $f=Query->Param("Formated_system");
   if (my $system=$self->getParent->{systemfield}->Validate($oldrec,
                                                            {system=>$f})){
      if (defined($system->{affectedsystemid}) &&
          $system->{affectedsystemid}!=0){
         my $f=Query->Param("Formated_system");
         $newrec->{affectedsystemid}=$system->{affectedsystemid};
         $newrec->{affectedsystem}=$f;
         my $systemid=$newrec->{affectedsystemid};
         my $sys=getModuleObject($self->getParent->Config,"itil::system");
         $sys->SetFilter({id=>\$systemid});
         my @l=$sys->getHashList(qw(mandator mandatorid applications));
         my %mandator;
         my %mandatorid;
         my %application;
         my %applicationid;
         my %custcontract;
         my %custcontractid;
         foreach my $sysrec (@l){
            printf STDERR ("fifi sys=%s\n",Dumper($sysrec));
            if (defined($sysrec->{mandator})){
               $mandator{$sysrec->{mandator}}=1;
            }
            if (defined($sysrec->{mandatorid})){
               $mandatorid{$sysrec->{mandatorid}}=1;
            }
            if (defined($sysrec->{applications}) &&
                ref($sysrec->{applications}) eq "ARRAY"){
               foreach my $appl (@{$sysrec->{applications}}){
                  if (defined($appl->{applid})){
                     $applicationid{$appl->{applid}}=1;
                  }
                  if (defined($appl->{appl})){
                     $application{$appl->{appl}}=1;
                  }
               }
            }
         }
         if (keys(%applicationid)){
            my $appl=getModuleObject($self->getParent->Config,"itil::appl");
            $appl->SetFilter({id=>[keys(%applicationid)]});
            my @l=$appl->getHashList(qw(custcontracts));
            foreach my $apprec (@l){
               if (defined($apprec->{mandator})){
                  $mandator{$apprec->{mandator}}=1;
               }
               if (defined($apprec->{mandatorid})){
                  $mandatorid{$apprec->{mandatorid}}=1;
               }
               next if (!defined($apprec->{custcontracts}));
               foreach my $rec (@{$apprec->{custcontracts}}){
                  if (defined($rec->{custcontractid})){
                     $custcontractid{$rec->{custcontractid}}=1;
                  }
                  if (defined($rec->{custcontract})){
                     $custcontract{$rec->{custcontract}}=1;
                  }
               }
            }
         }
         if (keys(%custcontract)){
            $newrec->{affectedcontract}=[keys(%custcontract)];
         }
         if (keys(%custcontractid)){
            $newrec->{affectedcontractid}=[keys(%custcontractid)];
         }
         if (keys(%application)){
            $newrec->{affectedapplication}=[keys(%application)];
         }
         if (keys(%applicationid)){
            $newrec->{affectedapplicationid}=[keys(%applicationid)];
         }
         if (keys(%mandator)){
            $newrec->{mandator}=[keys(%mandator)];
         }
         if (keys(%mandatorid)){
            $newrec->{mandatorid}=[keys(%mandatorid)];
         }
      }
      else{
         $self->LastMsg(ERROR,"no valid system specified");
         return(0);
      }
   }
   else{
      $self->LastMsg(ERROR,"selten sam");
      return(0);
   }
   return(1);
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   return($self->SUPER::Validate($oldrec,$newrec,$origrec));
}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(250);
}

#######################################################################
package OSY::workflow::diary::prewfclose;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(base::workflow::diary::prewfclose);


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
      my @l=$self->getParent->getFinishUseridList($WfRec);
      %fwd=(fwdtarget=>"base::user",fwdtargetid=>$l[0]);
      if ($#l>0){
         $fwd{fwddebtarget}="base::user";
         $fwd{fwddebtargetid}=$l[1];
      }
      my $note=Query->Param("note");
      if (!($note=~m/^\s*$/) && $WfRec->{detaildescription}=~m/^\s*$/){
         $fwd{detaildescription}=$note;
      }
      my $newstep=$self->getParent->getStepByShortname('wfclose',$WfRec);

      if ($self->getParent->StoreRecord($WfRec,$newstep,{
                                %fwd,
                                step=>$newstep,
                                eventend=>NowStamp("en"),
                                stateid=>17})){
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wfclose",
             {translation=>'base::workflow::diary'},$note)){
            Query->Delete("WorkflowStep");
            return(1);
         }
         return(0);
      }
      return(0);
   }
   return($self->SUPER::Process($action,$WfRec));
}






1;
