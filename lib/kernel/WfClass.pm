package kernel::WfClass;
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
use kernel::SubDataObj;
use kernel::TabSelector;


@ISA=qw(kernel::Operator kernel::Wf kernel::SubDataObj);

sub new
{
   my $type=shift;
   my $self={@_};
   $self=bless($self,$type);
   $self->{_permitted}->{Name}=1;
   return($self);
}

sub IsModuleSelectable
{
   my $self=shift;
   return(1);
}

sub InitWorkflow    # initializes the Workflow based on a DataObj
{
   my $self;
}

sub getDynamicFields
{
   my $self=shift;
   my %param=@_;

   return();
}

sub getNextStep
{
   my $self=shift;
   my $curentstep=shift;          
   my $WfRec=shift;               # current Workflow Record

   return(undef);
}

sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;

   return();
}


sub getWorkflowMailName
{
   my $self=shift;

   my $workflowname=$self->getParent->T($self->Self(),$self->Self());
   return($workflowname);
}



sub handleDependenceChange
{
   my $self=shift;
   my $rec=shift;
   my $dependwfheadid=shift;
   my $dependmode=shift;
   my $dependoldstateid=shift;
   my $dependnewstateid=shift;

   if ($dependoldstateid<=15 && $dependnewstateid>15){
      my $stepobj;
      my $stepobj=$self->getStepObject($self->getParent->Config,$rec->{step});
      if (!defined($stepobj)){
         return(undef);
      }
      if ($stepobj->can("nativProcess")){
         $stepobj->nativProcess("wfw5event",{
            note=>"The depend workflow ... \n".
                  $dependwfheadid.
                  "\n... has reached the ".
                  "end of inwork phase."

         },$rec,['wfw5event']);
      }
   }
}


sub  recalcResponsiblegrp
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $fwdtargetid=effVal($oldrec,$newrec,"fwdtargetid");
   my $fwdtarget=effVal($oldrec,$newrec,"fwdtarget");
   if ($fwdtarget eq "base::grp"){
      my $grp=getModuleObject($self->getParent->Config,"base::grp");
      $grp->SetFilter({grpid=>\$fwdtargetid});
      my ($grprec)=$grp->getOnlyFirst(qw(fullname));
      if (defined($grprec)){
         $newrec->{responsiblegrp}=[$grprec->{fullname}];
         $newrec->{responsiblegrpid}=[$fwdtargetid];
      }
   }
   if ($fwdtarget eq "base::user"){
      my $user=getModuleObject($self->getParent->Config,"base::user");
      $user->SetFilter({userid=>\$fwdtargetid});
      my ($usrrec)=$user->getOnlyFirst(qw(groups usertyp));
      if (defined($usrrec) && ref($usrrec->{groups}) eq "ARRAY"){
         my %ogrp;
         my %pgrp;
         my %grp;
         my @chkroles=orgRoles();
         if ($usrrec->{usertyp} eq "service"){
            push(@chkroles,"RMember"); # for Service-Users stats goes to RMember
         }
         foreach my $grec (@{$usrrec->{groups}}){
            if (ref($grec->{roles}) eq "ARRAY"){
               if (in_array($grec->{roles},\@chkroles)){
                  if ($grec->{is_projectgrp}){
                     $pgrp{$grec->{grpid}}=$grec->{group};
                  }
                  elsif ($grec->{is_orggrp}){
                     $ogrp{$grec->{grpid}}=$grec->{group};
                  }
                  else{
                     $grp{$grec->{grpid}}=$grec->{group};
                  }
               }
            }
         }
         if (keys(%pgrp)){
            $newrec->{responsiblegrp}=[values(%pgrp)];
            $newrec->{responsiblegrpid}=[keys(%pgrp)];
         }
         elsif (keys(%ogrp)){
            $newrec->{responsiblegrp}=[values(%ogrp)];
            $newrec->{responsiblegrpid}=[keys(%ogrp)];
         }
         elsif (keys(%grp)){
            $newrec->{responsiblegrp}=[values(%grp)];
            $newrec->{responsiblegrpid}=[keys(%grp)];
         }
      }
   }
}


sub getPosibleDirectActions
{
   my $self=shift;
   my $WfRec=shift;

   return();
}


sub isEffortReadAllowed
{
   my $self=shift;
   my $WfRec=shift;
   my $app=$self->getParent();

   return(1) if ($W5V2::OperationContext eq "W5Server");
   my $fo=$self->getField("mandatorid");
   my $mandatorid=$fo->RawValue($WfRec);
   $mandatorid=[$mandatorid] if (ref($mandatorid) ne "ARRAY");
   @$mandatorid=grep(!/^\s*$/,@$mandatorid);
   if ($#{$mandatorid}!=-1){
      my @m=$app->getMandatorsOf($app->getCurrentUserId(),["read","direct"]);
      foreach my $mid (@$mandatorid){

         if (grep(/^$mid$/,@m)){
            return(1);
         }
      }
   }
   else{
      return(1);
   }
   return(0);
}

sub getPosibleWorkflowDerivations
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my @l;


   return(@l);
}


sub getStepObject
{
   my $self=shift;
   my $config=shift;
   my $stepname=shift;

   my $obj;
   if ($stepname eq ""){
      print STDERR msg(ERROR,"getStepObject:no stepname spezified");
      return(undef);
   }
   if ($self->Self() eq "base::workflow::Archive"){
      $stepname="base::workflow::Archive::Archive";
   }
   $stepname=~s/[^a-z0-9:_]//gi;
   eval("\$obj=new $stepname(\$self);");
   if (!defined($obj)){
      msg(ERROR,"getStepObject($stepname) can not be created\n$@\n");
      $stepname="base::workflow::Archive::Archive";
      eval("\$obj=new $stepname(\$self);");
   }
   
   if (!defined($obj)){
      print STDERR msg(ERROR,"getStepObject($stepname):$@");
   }

   return($obj);
}

#
# SOAP Interface connector
#
sub nativProcessInitiate
{
   my $self=shift;
   my $action=shift;
   my $h=shift;
   my $step=shift;
   my $WfRec=shift;

   my $stepobj=$self->getStepObject($self->getParent->Config,$step);
   if (!defined($stepobj)){
      $self->LastMsg(ERROR,"invalid stepname specified");
      return(undef);
   }
   if ($stepobj->can("nativProcess")){
      my $d=Dumper($h);
      $d=~s/^.*?=\s*//;
      msg(DEBUG,"*nativProcess on $self\n action='$action'\nstep='$step'\n ".
               "dataload=%s",$d);
      my @actions=$self->getPosibleActions($WfRec);
      return($stepobj->nativProcess($action,$h,$WfRec,\@actions));
   }
   $self->LastMsg(ERROR,"step '\%s' does not support nativ action requests",$step);
   return(undef);
}


sub getFollowupTargetUserids
{
   my $self=shift;
   my $WfRec=shift;
   my $param=shift;
   if ($WfRec->{owner}!=0){
      push(@{$param->{addtarget}},$WfRec->{owner});
   }
}

sub handleFollowupExtended  # hock to handel additional parameters in followup
{
   my $self=shift;
   my $WfRec=shift;
   my $h=shift;
   my $param=shift;
   # here it is posible to modifiy wfhead parameters or change $param->{note}
   # format

   return(1);
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $step=defined($newrec->{step}) ? $newrec->{step} : $oldrec->{step};

   if (!defined($step)){
      $self->LastMsg(ERROR,"no worflow step specified");
      return(0);
   }
   my $StepObj=$self->getStepObject($self->Config,$step);
   if (!defined($StepObj)){
      $self->LastMsg(ERROR,"invalid worflow step specified");
      return(0);
   }
   return($StepObj->Validate($oldrec,$newrec,$origrec));
}


sub PostponeMaxDays   # postpone max days after WfStart
{
   my $self=shift;
   my $WfRec=shift;

   return(365*1);
}


sub ValidatePostpone    #validate postpone operation
{
   my $self=shift;
   my $WfRec=shift;
   my $Postpone=shift;
   my $dFromNow=shift;
   my $dFromStart=shift;

   my $maxPostponeDays=$self->PostponeMaxDays($WfRec);
   if (!defined($dFromStart) || 
       $dFromStart->{totaldays}>$maxPostponeDays){
      my $msg=sprintf($self->T(
         "defer not allowed! ".
         "- Target date is more then %d days after start of workflow"),
         $maxPostponeDays);
      $self->LastMsg(ERROR,$msg);
      return(0);
   }
   if ($dFromNow->{totalminutes}<720){
      $self->LastMsg(ERROR,"target date must be behind now");
      return(0);
   }


   return(1);
}



sub isMarkDeleteValid
{
   my $self=shift;
   my $rec=shift;
   if ($self->getParent->IsMemberOf("admin")){
      return(1);
   }
   return(0);
}

sub IsMemberOf
{
   my $self=shift;
   return($self->getParent->IsMemberOf(@_));
}


sub preValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $step=defined($newrec->{step}) ? $newrec->{step} : $oldrec->{step};

   if (!defined($step)){
      $self->LastMsg(ERROR,"preValidate:no worflow step specified");
      return(0);
   }
   my $StepObj=$self->getStepObject($self->Config,$step);
   if (!defined($StepObj)){
      $self->LastMsg(ERROR,"preValidate:invalid worflow step specified");
      return(0);
   }
   return($StepObj->preValidate($oldrec,$newrec,$origrec));
}

sub Process
{
   my $self=shift;
   my $class=shift;
   my $step=shift;
   my $WfRec=shift;
   my $app=$self->getParent();
   my $label=$self->Label();
   my $id=Query->Param("id");


   if (!defined($step)){
      $self->InitWorkflow(undef); 
      $step=$self->getNextStep(undef,$WfRec);
   }
   if (!defined($step)){
      print $app->HttpHeader("text/html");
      print $app->HtmlHeader(style=>['default.css','kernel.App.Web.css',
                                     'work.css'],
                             body=>1,form=>1,
                             title=>"Workflow Process - ERROR");
      print msg(ERROR,"no step found in '%s'",$self->Self);
      print $app->HtmlBottom(body=>1,form=>1);
      return(undef); 
   }
   else{
     if (!defined(Query->Param("WorkflowStep"))){
        Query->Param("WorkflowStep"=>$step);
     }
   }
   my $stepchanged=0;
   my $StepObj=$self->getStepObject($self->Config,$step);

   if (defined($StepObj)){
      my @varlist=Query->Param();
      if (grep(/^PrevStep$/,@varlist)){
         $stepchanged+=$StepObj->ProcessPrev("PrevStep",$WfRec);
         Query->Delete("PrevStep");
      }
      my @WorkflowStep=Query->Param("WorkflowStep");
      if (defined($WfRec)){
         if ($WorkflowStep[0] eq $WfRec->{step}){
            $step=$WorkflowStep[$#WorkflowStep];
         }
         else{
            $step=$WfRec->{step};
         }
      }
      else{
         $step=$WorkflowStep[$#WorkflowStep];
      }
      $StepObj=$self->getStepObject($self->Config,$step);
   }


   if (!defined($StepObj)){
      print $app->HttpHeader("text/html");
      print $app->HtmlHeader(style=>['default.css','work.css'],
                             body=>1,form=>1,
                             title=>"Workflow Process - ERROR");
      print msg(ERROR,"can't load step object '%s' in '%s'",$step,$self->Self);
      print $app->HtmlBottom(body=>1,form=>1);
      return(undef); 
   }
   my @actions=$self->getPosibleActions($WfRec);
   my %button=$StepObj->getPosibleButtons($WfRec,\@actions);
   my @varlist=Query->Param();
   my @posiblebuttons=keys(%button);

   if (grep(/^PrevStep$/,@varlist)){
      $stepchanged+=$StepObj->ProcessPrev("PrevStep",$WfRec,\@actions);
   }
   elsif(grep(/^NextStep$/,@varlist)){
      $stepchanged+=$StepObj->ProcessNext("NextStep",$WfRec,\@actions);
   }
   else{
      my $found=0;
      foreach my $b (keys(%button)){
         my $qb=quotemeta($b);
         if (grep(/^$qb$/,@varlist)){
            $stepchanged+=$StepObj->Process($b,$WfRec,\@actions);
            $found=1;
            last;
         }
      }
      $stepchanged+=$StepObj->Process(undef,$WfRec,\@actions) if (!$found);
   }
   if ($stepchanged || (!defined($id) && defined(Query->Param("id")))){
      $id=Query->Param("id");
      Query->Delete("WorkflowStep");
      if (defined($id)){   # Process old Workflow
         ($WfRec,$class,$step)=$self->getParent->getWfRec($id);
      }
      Query->Param("WorkflowStep"=>$step);
      $StepObj=$self->getStepObject($self->Config,$step);
   }
   my @WorkflowStep=Query->Param("WorkflowStep");
   if (defined($WfRec) && $WfRec->{step} ne $WorkflowStep[0]){
      Query->Param("WorkflowStep"=>$WfRec->{step});
      @WorkflowStep=Query->Param("WorkflowStep");
   }
   if ($WorkflowStep[$#WorkflowStep] ne $step){
      my $nextstep=$WorkflowStep[$#WorkflowStep];
      my $NextStepObj=$self->getStepObject($self->Config,$nextstep);
      if (defined($NextStepObj)){
         $StepObj=$NextStepObj;
         $step=$nextstep;
      }
      else{
         print STDERR msg(ERROR,"can't load step '$nextstep'");
      }
   }

   @actions=$self->getPosibleActions($WfRec);
   %button=$StepObj->getPosibleButtons($WfRec,\@actions);
   my $workspace=$StepObj->generateWorkspace($WfRec,\@actions);

   my $nextbutton="";
   my $prevbutton="";
   my $breakbutton="";
   my $addbuttons="";
   foreach my $b (sort(keys(%button))){
      if ($b eq "SaveStep"){
         $nextbutton.="<input type=submit class=workflowbutton ".
                      "value=\"$button{$b}\" ".
                      "onclick=\"document.btnWhich=this;\" ".
                      "name=$b>";
      }
      elsif ($b eq "NextStep"){
         $nextbutton.="<input type=submit class=workflowbutton ".
                      "value=\"$button{$b}\" ".
                      "onclick=\"document.btnWhich=this;\" ".
                      "name=$b>";
      }
      elsif ($b eq "PrevStep"){
         $prevbutton.="<input type=submit class=workflowbutton ".
                      "value=\"$button{$b}\" ".
                      "onclick=\"document.btnWhich=this;\" ".
                      "name=$b>";
      }
      elsif ($b eq "BreakWorkflow"){
         $breakbutton.="<input type=submit class=workflowbutton ".
                      "value=\"$button{$b}\" ".
                      "onclick=\"document.btnWhich=this;\" ".
                      "name=$b>";
      }
      else{
         $addbuttons.="<input type=submit class=workflowbutton ".
                      "value=\"$button{$b}\" ".
                      "onclick=\"document.btnWhich=this;\" ".
                      "name=$b><br>";
      }
   }
   if (keys(%button)==1 && $addbuttons ne ""){ # only one button can be placed
      $nextbutton=$addbuttons;                # at the nextbutton position.
      $addbuttons="";                         # this looks better.
   }

   print $app->HttpHeader("text/html");
   print $app->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css','workflow.css',
                                   'kernel.TabSelector.css'],
                          js=>['toolbox.js','subModal.js','Workflow.js',
                               'TextTranslation.js','jquery.js'],
                          body=>1,
                          title=>"Workflow Process - $label");
   print("<form method=POST onsubmit=\"return(ValidateSubmit(this));\">");
   my $appheader=$app->getAppTitleBar();
   print $app->HtmlSubModalDiv();


   my $p=Query->Param("ModeSelectCurrentMode");
   if (defined($WfRec)){
      $p="StandardDetail" if ($p eq "" || $p eq "new");
   }
   else{
      $p="new";
   }

   my $template;
   my $workarea=<<EOF;

<table id=WorkareaTable width="100%" border=0 cellspacing=0 cellpadding=0>
<tr><td valign=top>$workspace</td>
<td width=1% valign=top>$addbuttons</td></tr>
</table>

EOF
   my $LastMsg="";
   if ($self->LastMsg){
      $LastMsg="<div align=left class=LastMsg id=LastMsg>".
               join("<br>\n",map({
                            if ($_=~m/^ERROR/){
                               $_="<font style=\"color:red;\">".$_.
                                  "</font>";
                            }
                            if ($_=~m/^OK/){
                               $_="<font style=\"color:darkgreen;\">".$_.
                                  "</font>";
                            }
                            $_;
                           } $self->LastMsg())).
               "</div>";
   }
   if (defined($WfRec)){
      my $workheight=$StepObj->getWorkHeight($WfRec,\@actions);
      my $workareah=$workheight-30;
      if ($WfRec->{isdeleted}){
         $workheight=0;
      }
      my $dst="HtmlDetail?id=$id";
      if ($p eq "WorkflowSpecView"){
         $template=$self->WorkflowSpecView($WfRec);
      }
      elsif ($p eq "HtmlHistory"){
         $dst="HtmlHistory?id=$id" if ($id ne "");
         $template=(<<EOF);
<iframe style="height:99%" src="$dst" name=ProcessWindow
        id=ProcessWindow class=ProcessWindow scrollbars=no>
</iframe>
EOF
      }
      else{
         $template=<<EOF;
<iframe style="visibility:hidden" src="$dst" name=ProcessWindow
        id=ProcessWindow class=ProcessWindow scrollbars=no>
</iframe>
<div id=ProcessHandler style="border-top-style:outset;border-width:4px;visibility:hidden">
<div class=WorkBorder>
$LastMsg
<div id=Process class=ProcessHandler>
<table width="100%" border=0 height=100% cellspacing=1 cellpadding=0>
<tr><td colspan=3><div class=WorkArea style="height:${workareah}px">$workarea</div></td></tr>
<tr>
<tr height=1%>
<td width=30% align=left valign=bottom>$prevbutton</td>
<td width=30% align=center>&nbsp;$breakbutton&nbsp;</td>
<td width=30% align=right valign=bottom>$nextbutton</td>
</tr>
</table>
</div>
</div>
</div>
<script language="JavaScript">
function ProcessResize()
{
   var h=getViewportHeight();
   var ModeSelect=document.getElementById("ModeSelect");
   var ProcessHandler=document.getElementById("ProcessHandler");
   var ProcessWindow=document.getElementById("ProcessWindow");
   var Process=document.getElementById("Process");
   var LastMsg=document.getElementById("LastMsg");
   Process.style.height="${workheight}px";
   var h1=ModeSelect.offsetHeight;
   var h2=ProcessHandler.offsetHeight;
   var h4=0;
   //if (LastMsg){
   //   h4=LastMsg.offsetHeight;
   //}
   ProcessWindow.style.height=h-h1-h2-h4-1;
   ProcessHandler.style.visibility="visible";
   ProcessWindow.style.visibility="visible";
   return;
}
function ProcessInit()
{
   ProcessResize();
}
addEvent(window, "resize", ProcessResize);
addEvent(window, "load",   ProcessInit);
</script>
EOF
      }
      $template.=$app->HtmlPersistentVariables(qw(id isCopyFromId 
                                                  isDerivateFrom));
   }
   else{
      my $workheight=$StepObj->getWorkHeight();
      my $workareah=($workheight-30)."px";
      $workareah="100%" if ($workheight eq "100%");
      my $tiplabel=$step."::tip";
      my $tip=$self->T($tiplabel,$class);
      if ($tip eq $tiplabel){
         $tiplabel=$class."::tip";
         $tip=$self->T($tiplabel,$class);
      }
      if ($tip ne $tiplabel && $workheight ne "100%"){
         $tip="<b>".$self->getParent->T($self->Self,$self->Self).":</b><br>".
              $tip;
      }
      else{
         $tip="<div style=\"margin-top:5px\"><b>".
              $self->getParent->T($self->Self,$self->Self).
              "</b></div>";
      }

      my $faq=getModuleObject($self->getParent->Config(),"faq::article");

      if (defined($faq)){
         my $further=$faq->getFurtherArticles("workflow ".$self->Self);
         if ($further ne ""){
            $tip.=$further;
         }
      }

      my $imgurl=$self->getRecordImageUrl();
      my $subtip=$StepObj->CreateSubTip();
      $subtip="&nbsp;" if ($subtip eq "");
      $template.=<<EOF;
<div align=left class=newworkflowtip id=tip>
<div><div style="height:100px;margin:5px;margin-top:10px">
<img style="border-color:black;border-style:solid;border-width:1px;margin:5px;margin-top:2px;margin-right:8px;float:left" src="$imgurl">
$tip
</div></div></div><div id=subtip style="text-align:left;float:none;margin:0;padding:0">$subtip</div><div id=ProcessHandler style="border-top-style:outset;border-width:4px;visibility:hidden">
<div class=WorkBorder>
$LastMsg
<div id=ProcessWindow class=ProcessHandler style="visibility:hidden"><table width="100%" border=0 height="100%" cellspacing=0 cellpadding=0><tr><td colspan=3 valign=top><div id=WorkArea class=WorkArea style="height:${workareah}">$workarea</div>&nbsp;</td></tr>
<tr>
<tr height=1%>
<td width=30% align=left nowrap valign=bottom>$prevbutton&nbsp;</td>
<td width=30% align=center valign=top nowrap>&nbsp;$breakbutton&nbsp;</td>
<td width=30% align=right nowrap valign=bottom>&nbsp;$nextbutton</td>
</tr>
</table>
</div>
</div>
</div>
<script language="JavaScript">
function ProcessResize()
{
   var h=getViewportHeight();
   var ModeSelect=document.getElementById("ModeSelect");
   var Tip=document.getElementById("tip");
   var SubTip=document.getElementById("subtip");
   var ProcessHandler=document.getElementById("ProcessHandler");
   var ProcessWindow=document.getElementById("ProcessWindow");
   var LastMsg=document.getElementById("LastMsg");

   Tip.style.height="1px";
   if ("$workheight" == "100%"){
      var h1=ModeSelect.offsetHeight;
      var h4=0;
      if (LastMsg){
         h4=LastMsg.offsetHeight;
      }
      ProcessWindow.style.height=h-h1-h4-180;
      var h2=ProcessHandler.offsetHeight;
      var h3=SubTip.offsetHeight;
      Tip.style.height=h-(h2+h3+h1)-5;
      var WorkArea=document.getElementById("WorkArea");
      WorkArea.style.height=(ProcessWindow.offsetHeight-40)+"px";
   }
   else{
      ProcessWindow.style.height=($workheight+30)+"px";
      var h1=ModeSelect.offsetHeight;
      var h2=ProcessHandler.offsetHeight;
      var h3=SubTip.offsetHeight;
      var newtiph=(h-(h1+h2+h3));
      if (newtiph<0){
         newtiph=0;
         document.body.style.overflow='auto';
      }
      else{
         document.body.style.overflow='hidden';
      }
      Tip.style.height=newtiph+"px";
   }
   ProcessHandler.style.visibility="visible";
   ProcessWindow.style.visibility="visible";
   return;
}
function ProcessInit()
{
   ProcessResize();
}
addEvent(window, "resize", ProcessResize);
addEvent(window, "load",   ProcessInit);
</script>
EOF
      Query->Param("WorkflowClass"=>$class);
      $template.=$app->HtmlPersistentVariables(qw(WorkflowClass 
                                                  isDerivateFrom
                                                  isCopyFromId));
   }
   my @l=Query->Param("WorkflowStep");
   if ($#l!=-1){
      $template.=$app->HtmlPersistentVariables(qw(WorkflowStep));
   }
   my $fieldbase=$self->getParent->getFieldHash();  # add dynamic
   my @localfields=$self->getDynamicFields();       # fields for
   my %localfieldbase=%{$fieldbase};                # local fieldbase
   foreach my $fobj (@localfields){                 # this is special
      my $name=$fobj->Name();                       # needed for template
      $localfieldbase{$name}=$fobj;                 # parsing
   }                                                #
   if (defined($self->{FrontendField})){
      foreach my $fname (keys(%{$self->{FrontendField}})){
         $localfieldbase{$fname}=$self->{FrontendField}->{$fname};
      }
   }

   $self->ParseTemplateVars(\$template,{
                              mode             =>'workflow',
                              fieldbase       =>\%localfieldbase,
                              current          =>$WfRec,
                              editgroups       =>['ALL'],
                              viewgroups       =>['ALL'],
                              });
   my @WfFunctions=$self->getDetailFunctions($WfRec);
  
   my %param=(functions   =>\@WfFunctions,
              pages       =>[$self->getHtmlDetailPages($p,$WfRec)],
              activpage   =>$p,
              tabwidth    =>"20%",
              actionbox   =>'<div id=IssueState></div>',
              page        =>$template,
             );
   print(TabSelectorTool("ModeSelect",%param));
   print("<script language=\"JavaScript\">");
   print($self->getDetailFunctionsCode($WfRec));
   my $breakmsg=$self->T("Break the current workflow - are you sure?");
   my $detailx=$self->DetailX();
   my $detaily=$self->DetailY()+100;
   print(<<EOF);
addEvent(document,'keydown',function(e){
   e=e || window.event;
   globalKeyHandling(document,e);
});

function globalKeyHandling(doc,e){
   if (e.altKey){
      if (directTabKeyHandling){
         directTabKeyHandling(doc,e);
      }
   }
}

function setEditMode(m)
{
   this.SubFrameEditMode=m;
}
function TabChangeCheck()
{
if (this.SubFrameEditMode==1){return(DataLoseWarn());}
return(true);
}
function SubmitCheck()
{
if (this.SubFrameEditMode==1){return(DataLoseWarn());}
return(true);
}
function disableButtons()
{
   document.btnWhich.oldonclick=document.btnWhich.onclick;
   document.btnWhich.onclick=function(){  // prevent double click
      return(false);
   };
   document.btnWhich.oldvalue=document.btnWhich.value;
   document.btnWhich.value="Working ...";
}

function enableButtons()
{
   document.btnWhich.onclick=document.btnWhich.oldonclick;
   document.btnWhich.value=document.btnWhich.oldvalue;
}

var submitCount=0;
function ValidateSubmit(f)
{
   if (submitCount>0){   // prevent doubleclick idiots
      return(false);
   }
   submitCount++;
   if (this.SubFrameEditMode==1){
      if (!DataLoseWarn()){
         return(false);
      }
   }
   if (!document.btnWhich){
      return(true);
   }
   disableButtons();
  // window.setTimeout("disableButtons();",10);
   if (window.doValidateSubmit && typeof(window.doValidateSubmit)=='function'){
      return(doValidateSubmit(f,document.btnWhich));
   }
   return(defaultValidateSubmit(f,document.btnWhich));
}
function derivateWorkflow(){
   var v=document.getElementById('doDerivateWorkflow');
   if (v.value!="" && v.value!=undefined){
      openwin("DerivateFrom?id=$id&doDerivateWorkflow="+v.value,"_blank",
              "height=$detaily,width=$detailx,toolbar=no,status=no,"+
              "resizable=yes,scrollbars=auto");
   }
}
function defaultValidateSubmit(f,b)
{
   if (b.name=="SaveStep"){
      var s=document.getElementById("OP");
      if (s){
         if (s.value=="wfstartnew"){
            derivateWorkflow();
            enableButtons();
            submitCount=0;
            return(false);
         }
      }
   }
   if (b.name=="BreakWorkflow"){
      if (confirm("$breakmsg")){
         b.disabled=false;
         return(true);
      }
      else{
         enableButtons();
         submitCount=0;
         return(false);
      }
   }
   return(true);
}
</script>
EOF
   print $app->HtmlBottom(body=>1,form=>1);

}

sub WorkflowSpecView
{
   my $self=shift;
   return("no special View for Workflow $self");
}

sub getDetailFunctions
{
   my $self=shift;
   my $rec=shift;
   my @f=($self->T('WorkflowPrint')=>'WorkflowPrint',
          $self->T('WorkflowClose')=>'WorkflowClose'
         );
   if (defined($rec) && $self->isMarkDeleteValid($rec)){
      if (!$rec->{isdeleted}){
         unshift(@f,$self->T("DetailMarkDelete")=>"DetailMarkDelete");
      }
      else{
         unshift(@f,$self->T("DetailUnMarkDelete")=>"DetailUnMarkDelete");
      }
   }
   if (defined($rec) && $self->getParent->isDeleteValid($rec)){
      my $idname=$self->IdField->Name();
      my $id=$rec->{$idname};
      unshift(@f,$self->T("WorkflowDelete")=>"WorkflowDelete");
   }
   if (defined($rec) && $self->getParent->isCopyValid($rec)){
     # my $idname=$self->IdField->Name();
     # my $id=$rec->{$idname};
      unshift(@f,$self->T("DetailCopy")=>"DetailCopy");
   }
   if (defined($rec) && $self->getParent->can("HandleQualityCheck") &&
       $self->getParent->isQualityCheckValid($rec)){
      unshift(@f,$self->T("QualityCheck")=>"DetailHandleQualityCheck");
   }
   return(@f);
}

sub getDetailFunctionsCode
{
   my $self=shift;
   my $rec=shift;
   my $idname=$self->IdField->Name();
   my $id=$rec->{$idname};
   my $detailx=$self->DetailX();
   my $detaily=$self->DetailY();
   my $copyo="openwin(\"Copy?CurrentIdToEdit=$id\",\"_blank\",".
          "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
          "resizable=yes,scrollbars=auto\")";


   my $d=<<EOF;
function WorkflowPrint(){
   if (window.frames['ProcessWindow']){
      window.frames['ProcessWindow'].focus();
      window.frames['ProcessWindow'].print();
   }
   else{
      window.print();
   }
}
function WorkflowClose(){
   if (window.name=="work"){
      document.location.href="Welcome";
   }
   else{
      if (this.SubFrameEditMode==1){
         if (!DataLoseWarn()){
            return;
         }
      }
      window.close();
   }
}
function WorkflowDelete(id)
{
   showPopWin('DeleteRec?CurrentIdToEdit=$id',null,200,FinishDelete);
}
function DetailCopy(id)
{
   $copyo;
}

function FinishDelete()
{
   if (window.name=="work"){
      document.location.href="Welcome";
   }
   else{
      window.close();
   }
}
function DetailHandleQualityCheck()
{
   openwin('HandleQualityCheck?CurrentIdToEdit=$id',"qc$id",
           "height=240,width=$detailx,toolbar=no,status=no,"+
           "resizable=yes,scrollbars=auto");
}
function DetailMarkDelete()
{
   var ua=getXMLHttpRequest();
   ua.open("GET","DetailMarkDelete?CurrentIdToEdit=$id",true);
   ua.onreadystatechange=function() {
    if (ua.readyState==4){
       document.forms[0].submit();
    }
   };
   ua.setRequestHeader('Content-Type','application/x-www-form-urlencoded');
   var r=ua.send('');
}
function DetailUnMarkDelete()
{
   var ua=getXMLHttpRequest();
   ua.open("GET","DetailUnMarkDelete?CurrentIdToEdit=$id",true);
   ua.onreadystatechange=function() {
    if (ua.readyState==4 && (ua.status==200 || ua.status==304)){
       document.forms[0].submit();
    }
   };
   ua.setRequestHeader('Content-Type','application/x-www-form-urlencoded');
   var r=ua.send('');
}

EOF
   return($d);
}




sub StoreRecord
{
   my $self=shift;
   my $rec=shift;
   my $step=shift;
   my $data=shift;

   my $StepObj=$self->getStepObject($self->Config,$step);
   if (!defined($StepObj)){
      $self->LastMsg(ERROR,"invalid worflow step specified");
      return(undef);
   }
   return($StepObj->StoreRecord($rec,$data));
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $step;

   if (defined($oldrec)){
      $step=$oldrec->{step};
   }
   if (defined($newrec->{step})){
      $step=$newrec->{step};
   }
   if (defined($step)){
      my $StepObj=$self->getStepObject($self->Config,$step);
      if (defined($StepObj)){
         $StepObj->FinishWrite($oldrec,$newrec);
      }
   }
}

#sub getClassFieldList
#{
#   my $self=shift;
#   my $p=$self->getParent;
#
#   my @fl=(@{$p->{'FieldOrder'}});
#   push(@fl,$self->getFieldList());
#   return(@fl);
#}

#sub getFieldObjsByView
#{
#   my $self=shift;
#   my $view=shift;
#   my %param=@_;
#   my @l=$self->getDynamicFields();
#   return(@l)
#}

sub getField
{
   my $self=shift;
   my $name=shift;

   if (defined($self->{FrontendField}->{$name})){
      return($self->{FrontendField}->{$name});
   }
   if (!exists($self->{Fields})){
      $self->getDynamicFields();
   }
   if (defined($self->{Fields}->{$name})){
      return($self->{Fields}->{$name});
   }

   return($self->getParent->getField($name,@_));
}

sub isOptionalFieldVisible
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;

   return(1) if ($mode eq "ViewEditor"); 
   return(0);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;
   return(1) if ($self->getParent->IsMemberOf("admin"));
   return();
}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   return(0) if (ref($actions) eq "ARRAY" && $#{$actions}==-1);

   return(200);
}


sub isRecordMandatorReadable
{
   my $self=shift;
   my $rec=shift;
   my $kh=$self->getField("kh")->RawValue($rec);

   if (!defined($kh->{mandatorid}) ||
       ref($kh->{mandatorid}) ne "ARRAY"){
      return(0);
   }
   my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
   foreach my $m (@{$kh->{mandatorid}}){
      return(1) if (grep(/^$m$/,@mandators));
   }
   return(0);
}

sub InitFields
{
   my $self=shift;

   my @fl=$self->SUPER::InitFields(@_);
   foreach my $obj (@fl){
      $self->{Fields}->{$obj->Name()}=$obj;
   }
   return(@fl);
}

sub allowAutoScroll
{
   my $self=shift;
   return(1);
}


sub getPosibleRelations
{
   my $self=shift;
   my $WfRec=shift;
   return;
}

sub validateRelationWrite
{
   my $self=shift;
   my $WfRec=shift;
   my $dstwfid=shift;


   return(1);
}


sub linkMail
{
   my $self=shift;
   my $srcid=shift;
   my $dstid=shift;

   my $wr=$self->getParent->getPersistentModuleObject("base::workflowrelation");
   $wr->ValidatedInsertOrUpdateRecord({srcwfid=>$srcid,dstwfid=>$dstid},
                                      {srcwfid=>\$srcid,dstwfid=>\$dstid});

}


sub addSRCLinkToFacility
{
   my $self=shift;
   my $d=shift;
   my $current=shift;

   return("none",undef);
}

sub isCurrentForward
{
   my $self=shift;
   my $WfRec=shift;
   my $app=$self->getParent;
   my $userid=$self->getParent->getCurrentUserId();

   if ($WfRec->{fwdtarget} eq 'base::grp'){
      if ($app->IsMemberOf($WfRec->{fwdtargetid},undef,"up")){
         return(1);
      }
   }
   elsif ($WfRec->{fwdtarget} eq 'base::user' &&
       $userid==$WfRec->{fwdtargetid}){
         return(1);
   }
   elsif ($WfRec->{fwddebtarget} eq 'base::grp'){
      if ($app->IsMemberOf($WfRec->{fwddebtargetid},undef,"up")){
         return(1);
      }
   }
   elsif ($WfRec->{fwddebtarget} eq 'base::user'){
      if ($userid==$WfRec->{fwddebtargetid}){
         return(1);
      }
   }
   return(0);
}

sub isCurrentWorkspace
{
   my $self=shift;
   my $WfRec=shift;

   my $userid=$self->getParent->getCurrentUserId();
   my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},"RMember","both");
   my @grpids=keys(%grp);
   @grpids=(qw(NONE)) if ($#grpids==-1);

   my $ws=$self->getParent->getPersistentModuleObject("base::workflowws");
   $ws->SetFilter([{fwdtargetid=>\$userid,fwdtarget=>\'base::user',
                    wfheadid=>\$WfRec->{id}},
                   {fwdtargetid=>\@grpids,fwdtarget=>\'base::grp',
                    wfheadid=>\$WfRec->{id}}]);
   if ($ws->CountRecords()){
      return(1);
   }
   return(0);
}

sub ValidActionCheck
{
   my $self=shift;
   my $lastmsg=shift;
   my $actions=shift;
   my @reqaction=@_;
   foreach my $a (@reqaction){
      return(1) if ($a ne "" && grep(/^$a$/,@{$actions}));
   }
   if ($lastmsg){
      my $app=$self->getParent();   # seltsam, dass das so lange fehlerhaft war
      if (!defined($app)){
         msg(ERROR,"invalid request from '%s'",join("\n",caller())); 
      }
      else{
         $app->LastMsg(ERROR,$app->T("ileagal action '%s' requested"),
                       join(",",@reqaction));
      }
   }
   return(0);
}


sub cutIdenticalCharString
{
   my $self=shift;
   my $text=shift;
   my $len=shift;

   $text=~s/(^|\n)(.)(\2{$len})\2*/$1$3/g;
   return($text);
}


sub generateNotificationPreview
{
   my $self=shift;
   my %param=@_;
   my $email=$param{to};
   if (ref($param{to}) eq "ARRAY"){
      $email=join("; ",grep(!/^\s*$/,@{$param{to}}));
   }
   my $emailcc="";
 
   if (ref($param{cc}) eq "ARRAY"){
      $emailcc=join("; ",grep(!/^\s*$/,@{$param{cc}}));
   }

   my $emailbcc="";
 
   if (ref($param{bcc}) eq "ARRAY"){
      $emailbcc=join("; ",grep(!/^\s*$/,@{$param{bcc}}));
   }

   my $preview=$self->getParent->T("Preview");
   $preview.=":";
#   if (defined($param{subject})){
#      $preview=$param{subject};
#   }
   my $tomsg=$self->getParent->T("To");
   my $ccmsg=$self->getParent->T("CC");
   my $bccmsg=$self->getParent->T("BCC");
   my $subjectmsg=$self->getParent->T("Subject");
   my $sepstart="<table class=emailpreviewset border=1>";
   my $sepend="</table>";
   my $templ=<<EOF;
<center>
<div class=emailpreview>
<table>
<tr><td align=left>
&nbsp;<b>$preview</b>
<table class=emailpreview>
EOF
   $templ.=<<EOF if ($email ne "");
<tr>
<td valign=top width=50><b>$tomsg:</b></td>
<td>$email</td>
</tr>
EOF
   $templ.=<<EOF if ($emailcc ne "");
<tr>
<td valign=top width=50><b>$ccmsg:</b></td>
<td>$emailcc</td>
</tr>
EOF
   $templ.=<<EOF if ($emailbcc ne "");
<tr>
<td valign=top width=50><b>$bccmsg:</b></td>
<td>$emailbcc</td>
</tr>
EOF
   $templ.=<<EOF if ($param{subject});
<tr>
<td valign=top width=50><b>$subjectmsg:</b></td>
<td>$param{subject}</td>
</tr>
EOF
   $templ.=<<EOF;
<tr>
<td colspan=2>$sepstart
EOF
   $param{emailtext}=[$param{emailtext}] if (ref($param{emailtext}) ne "ARRAY");
   for(my $blk=0;$blk<=$#{$param{emailtext}};$blk++){

      if ($param{emailsubheader}->[$blk] ne "" &&
          $param{emailsubheader}->[$blk] ne "0"){
         my $sh=$param{emailsubheader}->[$blk];
         if ($sh eq "1"){
            $sh="";
         }
         if ($sh eq " "){
            $sh="&nbsp;";
         }
         $templ.="<tr><td colspan=2 class=emailpreviewemailsubheader>".
                 $sh."</td></tr>";
      }

      if ($param{emailsep}->[$blk] ne "" &&
          $param{emailsep}->[$blk] ne "0"){
         my $septext=$param{emailsep}->[$blk];
         if ($septext eq "1"){
            $septext="";
         }
         $templ.=$sepend.$septext.$sepstart;
      }
      $templ.="<tr>";
      $templ.="<td class=emailpreviewemailprefix>".
              $param{emailprefix}->[$blk]."</td>";
      my $emailtext=$param{emailtext}->[$blk];

      if (!(($emailtext=~m/<a/) ||
            ($emailtext=~m/<b>/) ||
            ($emailtext=~m/<\/b>/) ||
            ($emailtext=~m/<\/ul>/) ||
            ($emailtext=~m/<i>/) ||
            ($emailtext=~m/<div/))){
         $emailtext=~s/</&lt;/g;
         $emailtext=~s/>/&gt;/g;
      }
      $emailtext=~s/\%/\\\%/g;
      $templ.="<td class=emailpreviewemailtext>".
              "<table style=\"table-layout:fixed;width:100%\" ".
              "cellspacing=0 cellpadding=0><tr><td>".
              "<div style=\"overflow:hidden\"><pre class=emailpreview>".
              FancyLinks($emailtext)."</pre></div>".
              "</td></tr></table></td>";
      $templ.="</tr>";
   }
   $templ.=$sepend."</td></tr></table></div>";
   $templ.="</td></table>";

   return($templ);


}

sub getHtmlContextMenu
{
   my $self=shift;
   return($self->getParent->getHtmlContextMenu(@_));
}

sub WSDLcommon
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $class=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;

   $$XMLbinding.="<!-- no $class specified methods/types --> ";

}


sub WSDLaddNativFieldList
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $module=shift;
   my $mode=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;

   if ($mode eq "store"){
      $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
                  "name=\"action\" type=\"xsd:string\" />";
      $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
                  "name=\"note\" type=\"xsd:string\" />";
   }


}

















1;

