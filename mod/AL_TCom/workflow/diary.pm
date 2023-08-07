package AL_TCom::workflow::diary;
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
use AL_TCom::lib::workflow;
@ISA=qw(base::workflow::diary itil::workflow::base AL_TCom::lib::workflow);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);


   $self->AddFrontendFields(
      new kernel::Field::TextDrop(name       =>'affectedapplication',
                                  translation=>'AL_TCom::workflow::diary',

                                  readonly   =>sub {
                                      my $self=shift;
                                      my $current=shift;
                                      return(0) if (!defined($current));
                                      return(1);
                                   },
                                   vjointo    =>'itil::appl',
                                   vjoinon    =>['affectedapplicationid'=>'id'],
                                   vjoindisp  =>'name',
                                   vjoineditbase  =>{cistatusid=>"<6"},

                                   keyhandler =>'kh',
                                   container  =>'headref',
                                   uivisible  =>0,
                                   group      =>'affected',
                                   label      =>'Application'),
   );

   $self->{history}=[qw(insert modify delete)];

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
                          param=>'WorkflowClass=AL_TCom::workflow::diary');
   if (defined($acl)){
      return(1) if (grep(/^read$/,@$acl));
   }
   return(0);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @l=("affected","history");
   if (ref($rec->{affectedcontractid}) eq "ARRAY" &&
       $#{$rec->{affectedcontractid}}!=-1){
      push(@l,"tcomcod");
   }
   push(@l,"source") if ($self->getParent->IsMemberOf("admin"));
   return($self->SUPER::isViewValid($rec),@l);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(1) if (!defined($rec));
   return("default","tcomcod","relations","affected") if ($rec->{state}<21 &&
                         ($self->getParent->getCurrentUserId()==$rec->{owner} ||
                          $self->getParent->IsMemberOf("admin")));
   if ($rec->{state}<21){
      my @acl=$self->getFinishUseridList($rec);
      my $userid=$self->getParent->getCurrentUserId();
      if (grep(/^$userid$/,@acl) || $self->getParent->IsMemberOf("admin")){
         return("default","tcomcod","affected","relations");
      }
   }

   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("tcomcod","affected","relations");
}



sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   if ($shortname eq "dataload" || $shortname eq "loadappl" || 
       $shortname eq "prewfclose" || $shortname eq "loadtxt" ||
       $shortname eq "wfclose"){
      return("AL_TCom::workflow::diary::".$shortname);
   }

   return($self->SUPER::getStepByShortname($shortname,$WfRec));
}


sub getFinishUseridList
{
   my $self=shift;
   my $WfRec=shift;
   my @l=();

   if (ref($WfRec->{affectedapplicationid}) eq "ARRAY"){
      my @app=@{$WfRec->{affectedapplicationid}};
      my $app=getModuleObject($self->getParent->Config,"itil::appl");
      $app->SetFilter(id=>\@app);
      my @idnames=qw(tsmid tsm2id opmid opm2id);
      my @rec=$app->getHashList(@idnames);
      foreach my $idname (@idnames){
         foreach my $rec (@rec){
            push(@l,$rec->{$idname})  if (defined($rec->{$idname}));
         }
      }
      if ($#l==-1){
         push(@l,$WfRec->{openuser});
         msg(INFO,"warn: no TSM found - using openuser");
      }
      if ($self->getParent->IsMemberOf("admin")){
         my $userid=$self->getParent->getCurrentUserId();
         push(@l,$userid);
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
   if ($WfRec->{state}>20){   
      if (defined($WfRec) &&
          ref($WfRec->{affectedcontractid}) eq "ARRAY" &&
          $#{$WfRec->{affectedcontractid}}!=-1){
         if ($self->getParent->IsMemberOf("admin")){
            push(@l,"reactivate");
         }
         else{
            my $d=CalcDateDuration($WfRec->{eventend},NowStamp("en"));
            if ($d->{totalminutes}>5000){ # modify only allowed for 3 days
               return(@l);
            }
         }
      }
   }
   if ($WfRec->{state}==17 || $WfRec->{state}==18){
      my @acl=$self->getFinishUseridList($WfRec);
      if (grep(/^$userid$/,@acl)){
         push(@l,"addsup");
         push(@l,"wffinish");
      }
      if ($WfRec->{fwdtarget} eq 'base::user' &&
          $userid==$WfRec->{fwdtargetid}){
         push(@l,"wffinish");
      }
   }
   if ($WfRec->{state}>17){
      my @acl=$self->getFinishUseridList($WfRec);
      if ($self->getParent->IsMemberOf("admin")){
         push(@l,"reactivate");
      }
      else{
         if (grep(/^$userid$/,@acl)){
            if ($WfRec->{eventend} ne ""){
               my $now=NowStamp("en");
               my $d=CalcDateDuration($WfRec->{eventend},$now);
               if ($d->{totalminutes}<4320){
                  push(@l,"reactivate");
               }
            }
         }
      }
   }
   return(@l);
}




sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my @l=();
   
   return($self->SUPER::getDynamicFields(%param),
          $self->InitFields(
           new kernel::Field::Select(    name       =>'tcomcodrelevant',
                                         label      =>'Workflow invoice',
                                         htmleditwidth=>'20%',
                                         value      =>['',qw(yes no)],
                                         default    =>'yes',
                                         group      =>'tcomcod',
                                         container  =>'headref'),

           new kernel::Field::Select(    name       =>'tcomcodcause',
                                         label      =>'Activity',
                                         htmleditwidth=>'80%',
                                         translation=>'AL_TCom::lib::workflow',
                                         allownative=>['sw.addeff.swbase'],
                                         value      =>
                             [AL_TCom::lib::workflow::tcomcodcause()],
                                         default    =>'undef',
                                         group      =>'tcomcod',
                                         container  =>'headref'),

           new kernel::Field::Textarea(  name        =>'tcomcodcomments',
                                         label       =>'Comments',
                                         group       =>'tcomcod',
                                         container   =>'headref'),

           new kernel::Field::Text(      name        =>'tcomexternalid',
                                         label       =>'ExternalID (I-Network)',
                                         group       =>'tcomcod',
                                         container   =>'headref'),

           new kernel::Field::Text(      name        =>'conumber',
                                         label       =>'CO-Number',
                                         htmldetail  =>0,
                                         readonly    =>1,
                                         container   =>'headref'),

           new kernel::Field::Number(    name       =>'tcomworktime',
                                         unit       =>'min',
                                         onUnformat =>
                                      \&AL_TCom::lib::workflow::minUnformat,
                                         detailadd  =>
                                      \&AL_TCom::lib::workflow::tcomworktimeadd,
                                         label      =>'Worktime',
                                         group      =>'tcomcod',
                                         container  =>'headref'),

   ));
}

sub getNextStep
{
   my $self=shift;
   my $currentstep=shift;
   my $WfRec=shift;

   if($currentstep eq ""){
      return($self->getStepByShortname("loadtxt",$WfRec));
   }
   if($currentstep eq "AL_TCom::workflow::diary::loadtxt"){
      return($self->getStepByShortname("loadappl",$WfRec));
   }
   elsif($currentstep=~m/^.*::workflow::diary::loadappl$/){
      return($self->getStepByShortname("dataload",$WfRec));
   }
   return($self->SUPER::getNextStep($currentstep,$WfRec));
}

#sub getDetailFunctions
#{
#   my $self=shift;
#   my $rec=shift;
#   my @f;
#   if (defined($rec)){
#      @f=($self->T('WorkflowCopy')=>'WorkflowCopy');
#   }
#   return(@f,$self->SUPER::getDetailFunctions($rec));
#}

sub isCopyValid
{
   my $self=shift;
   my $copyfrom=shift;
   return(1);
}

#sub getDetailFunctionsCode
#{
#   my $self=shift;
#   my $rec=shift;
#   my $wfclass=$self->Self();
#   my $d;
#   if (defined($rec)){
#      my $idname=$self->IdField->Name();
#      my $id=$rec->{$idname};
#      $d=<<EOF;
#function WorkflowCopy()
#{
#   custopenwin("Copy?CurrentIdToEdit=$id","",640);
#}
#EOF
#   }
#   return($self->SUPER::getDetailFunctionsCode($rec).$d);
#}

sub InitCopy
{
   my ($self,$copyfrom,$copyinit)=@_;

   my $appl=$copyinit->{Formated_affectedapplication};
   $copyinit->{WorkflowStep}=[qw(AL_TCom::workflow::diary::loadtxt)];
   $copyinit->{WorkflowClass}=$self->Self();

}







#######################################################################
package AL_TCom::workflow::diary::loadtxt;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateStoredWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my @steplist=@_;

   my $d=<<EOF;
<tr><td class=fname width=20%>%name(label)%:</td>
<td class=finput>%name(storedworkspace)%</td></tr>
<tr><td class=fname colspan=2>
%detaildescription(label)%:<br>%detaildescription(storedworkspace)%</td></tr>
EOF
   $d.=$self->getParent->getParent->HtmlPersistentVariables(
            qw(Formated_tcomcodrelevant Formated_tcomcodcomments 
               Formated_tcomcodcause
               Formated_tcomworktime));

   return($self->SUPER::generateStoredWorkspace($WfRec,@steplist).$d);
}


sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr><td class=fname width=20%>%name(label)%:</td>
<td class=finput>%name(detail)%</td></tr>
<tr><td class=fname colspan=2>%detaildescription(label)%:<br>
%detaildescription(detail)%</td></tr></table>
<script language="JavaScript">
setFocus("Formated_name");
setEnterSubmit(document.forms[0],"NextStep");
</script>
EOF
   $templ.=$self->getParent->getParent->HtmlPersistentVariables(
            qw(Formated_tcomcodrelevant Formated_tcomcodcomments 
               Formated_tcomcodcause
               Formated_tcomworktime Formated_affectedapplication));
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

   return(250);
}

#######################################################################
package AL_TCom::workflow::diary::loadappl;
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
   #my $l1=$app->{applfield}->Label();
   #my $e1=$app->{applfield}->FormatedDetail($WfRec,"storedworkspace");

   $d=<<EOF;
<tr>
<td class=fname width=20%>%affectedapplication(label)%:</td>
<td class=finput>%affectedapplication(storedworkspace)%</td>
</tr>
EOF

   return($self->SUPER::generateStoredWorkspace($WfRec,@steplist).$d);
}


sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   #my $l1=$self->getParent->{applfield}->Label();
   #my $e1=$self->getParent->{applfield}->FormatedDetail($WfRec,"workflow");
   my @steplist=Query->Param("WorkflowStep");
   pop(@steplist);
   my $StoredWorkspace=$self->SUPER::generateStoredWorkspace($WfRec,@steplist);

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
$StoredWorkspace
<tr>
<td class=fname width=20%>%affectedapplication(label)%:</td>
<td class=finput>%affectedapplication(detail)%</td>
</tr>
</table>
<script language="JavaScript">
setFocus("Formated_affectedapplication");
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

   my $applfield=$self->getField("affectedapplication");
   my $f=Query->Param("Formated_".$applfield->Name());
   if ($f=~m/^\s*$/){
      $self->LastMsg(ERROR,"no application specified");
      return(0);
   }

   if (my $appl=$applfield->Validate($WfRec,{affectedapplication=>$f})){
      $f=Query->Param("Formated_affectedapplication");
      if (!defined(Query->Param("Formated_fwdtargetname"))){
         my $app=getModuleObject($self->getParent->Config,"itil::appl");
         $app->SetFilter({name=>\$f});
         my @l=$app->getHashList(qw(businessteam));
         Query->Param("Formated_fwdtargetname"=>$l[0]->{businessteam}); 
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
      if ($self->LastMsg()==0){
         $self->LastMsg(ERROR,"unexpected error while application check");
      }
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
package AL_TCom::workflow::diary::dataload;
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

sub nativProcess
{
   my $self=shift;
   my $action=shift;
   my $h=shift;
   my $WfRec=shift;
   my $actions=shift;

   return($self->SUPER::nativProcess($action,$h,$WfRec,$actions));
}



sub preValidate                 # das muß in preValidate behandelt werden,
{                               # da später noch die KeyHandler beeinflußt
   my $self=shift;              # werden
   my $oldrec=shift;
   my $newrec=shift;

   if (!defined($newrec->{tcomcodcause}) || $newrec->{tcomcodcause} eq ""){
      $newrec->{tcomcodcause}="undef";
   }

   my $f=defined($newrec->{affectedapplication}) ?
         $newrec->{affectedapplication} : 
         Query->Param("Formated_affectedapplication");
   $f=$f->[0] if (ref($f) eq "ARRAY");
   if (my $appl=$self->getField("affectedapplication")->
                     Validate($oldrec,{affectedapplication=>$f})){
      if (defined($appl->{affectedapplicationid}) &&
          $appl->{affectedapplicationid}!=0){
         my $f=Query->Param("Formated_affectedapplication");
         $newrec->{affectedapplicationid}=$appl->{affectedapplicationid};
         $newrec->{affectedapplication}=$f;
         my $applid=$newrec->{affectedapplicationid};
         my $co=getModuleObject($self->getParent->Config,"itil::costcenter");
         my $app=getModuleObject($self->getParent->Config,"itil::appl");
         $app->SetFilter({id=>\$applid});
         my @l=$app->getHashList(qw(custcontracts mandator 
                                    customerid customer 
                                    conumber mandatorid));
         my %custcontract;
         my %custcontractid;
         my %mandator;
         my %mandatorid;
         my %conumber;
         my %customer;
         my %customerid;
         foreach my $apprec (@l){
            if (defined($apprec->{mandator}) && $apprec->{mandator} ne ""){
               $mandator{$apprec->{mandator}}=1;
            }
            if (defined($apprec->{mandatorid}) && $apprec->{mandatorid} ne ""){
               $mandatorid{$apprec->{mandatorid}}=1;
            }
            if (defined($apprec->{customer}) && $apprec->{customer} ne ""){
               $customer{$apprec->{customer}}=1;
            }
            if (defined($apprec->{customerid}) && $apprec->{customerid} ne ""){
               $customerid{$apprec->{customerid}}=1;
            }
            if (defined($apprec->{conumber}) && $apprec->{conumber} ne ""){
               $co->ResetFilter();
               $co->SetFilter({name=>\$apprec->{conumber},cistatusid=>"<=4"});
               my ($corec)=$co->getOnlyFirst("id");
               if (!defined($corec)){
                  $self->LastMsg(ERROR,"invalid or inactive costcenter ".
                                       "used in application configuration");
                  return(0);
               }
               $conumber{$apprec->{conumber}}=1;
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
         if (keys(%custcontractid)){
            $newrec->{affectedcontractid}=[keys(%custcontractid)];
         }
         if (keys(%custcontract)){
            $newrec->{affectedcontract}=[keys(%custcontract)];
         }
         if (keys(%customer)){
            $newrec->{involvedcustomer}=[keys(%customer)];
         }
         if (keys(%mandator)){
            $newrec->{mandator}=[keys(%mandator)];
         }
         if (keys(%mandatorid)){
            $newrec->{mandatorid}=[keys(%mandatorid)];
         }
         if (keys(%conumber)){
            $newrec->{conumber}=[keys(%conumber)];
            $newrec->{involvedcostcenter}=[keys(%conumber)];
         }
      }
      else{
         $self->LastMsg(ERROR,"no valid application specified");
         return(0);
      }
   }
   else{
      if ($self->LastMsg()==0){
         $self->LastMsg(ERROR,"unexpected error while application check");
      }
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

   $newrec->{stateid}=1 if (!defined(effVal($oldrec,$newrec,"stateid")));
   return($self->SUPER::Validate($oldrec,$newrec,$origrec));
}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(250);
}

#######################################################################
package AL_TCom::workflow::diary::prewfclose;
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
   return($self->SUPER::Process($action,$WfRec,$actions));
}





#######################################################################
package AL_TCom::workflow::diary::wfclose;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(base::workflow::diary::wfclose);

sub Validate
{
   my $self=shift;
   my $WfRec=shift;
   my $newrec=shift;

   my @l=$self->getParent->getFinishUseridList($WfRec);
   if ($#l>=0){
      $newrec->{fwdtarget}="base::user";
      $newrec->{fwdtargetid}=$l[0];
      $newrec->{stateid}=17;
   }
   if ($#l>0){
      $newrec->{fwddebtarget}="base::user";
      $newrec->{fwddebtargetid}=$l[1];
   }
   if ($#l==-1){
      $newrec->{stateid}=21;
   }
   return(1)
}




1;
