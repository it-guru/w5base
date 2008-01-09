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
use Data::Dumper;
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

sub getPosibleDirectActions
{
   my $self=shift;
   my $WfRec=shift;

   return();
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
   eval("\$obj=new $stepname(\$self);");
   if (!defined($obj)){
      print STDERR msg(ERROR,"getStepObject($stepname):$@");
   }

   return($obj);
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

   my @actions=$self->getPosibleActions($WfRec);
   my %button=$StepObj->getPosibleButtons($WfRec,\@actions);
   my $workspace=$StepObj->generateWorkspace($WfRec,\@actions);

   my $nextbutton="";
   my $prevbutton="";
   my $breakbutton="";
   my $addbuttons="";
   foreach my $b (sort(keys(%button))){
      if ($b eq "SaveStep"){
         $nextbutton.="<input type=submit class=workflowbutton ".
                      "value=\"$button{$b}\" name=$b>";
      }
      elsif ($b eq "NextStep"){
         $nextbutton.="<input type=submit class=workflowbutton ".
                      "value=\"$button{$b}\" name=$b>";
      }
      elsif ($b eq "PrevStep"){
         $prevbutton.="<input type=submit class=workflowbutton ".
                      "value=\"$button{$b}\" name=$b>";
      }
      elsif ($b eq "BreakWorkflow"){
         $breakbutton.="<input type=submit class=workflowbutton ".
                      "value=\"$button{$b}\" name=$b>";
      }
      else{
         $addbuttons.="<input type=submit class=workflowbutton ".
                      "value=\"$button{$b}\" name=$b><br>";
      }
   }

   print $app->HttpHeader("text/html");
   print $app->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css','workflow.css',
                                   'kernel.TabSelector.css'],
                          js=>['toolbox.js','subModal.js','Workflow.js',
                               'TextTranslation.js'],
                           body=>1,form=>1,
                           title=>"Workflow Process - $label");
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
<table width=100% border=0 cellspacing=0 cellpadding=0>
<tr>
<td valign=top>$workspace</td>
<td width=1% valign=top>$addbuttons</td>
</tr>
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
      my $dst="HtmlDetail?id=$id";
      if ($p eq "HtmlHistory"){
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
<table width=100% border=0 height=100% cellspacing=1 cellpadding=0>
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
      $template.=$app->HtmlPersistentVariables(qw(id));
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
      #if ($self->getParent->IsMemberOf("admin")){
         $tip.="<hr>";
         my $url=$ENV{SCRIPT_URI};
         $url=~s/\/auth\/.*$//;
         $url.="/auth/base/menu/msel/MyW5Base";
         my $qhash=Query->MultiVars();
         delete($qhash->{NextStep});
         delete($qhash->{SaveStep});
         my $qhash=new kernel::cgi($qhash);
         my $openquery={OpenURL=>"$ENV{SCRIPT_URI}?".$qhash->QueryString()};
         my $queryobj=new kernel::cgi($openquery);
         $url.="?".$queryobj->QueryString();
         $url=~s/\%/\\\%/g;
         my $a="<a href=\"$url\" ".
               "target=_blank title=\"Workflow link included current query\">".
               "<img src=\"../../base/load/anker.gif\" ".
               "height=10 border=0></a>";
         $tip.=sprintf($self->T("You can add a shortcut of this anker %s to ".
                       "your bookmarks, to access faster to this workflow.",
                       'base::workflow'),$a);
         $tip.="<hr>";
      #}
      $template.=<<EOF;
<div align=left class=newworkflowtip id=tip><div style="margin:5px;margin-top:10px">$tip</div></div>
<div id=ProcessHandler style="border-top-style:outset;border-width:4px;visibility:hidden">
<div class=WorkBorder>
$LastMsg
<div id=ProcessWindow class=ProcessHandler style="visibility:hidden"><table width=100% border=0 height=100% cellspacing=0 cellpadding=0><tr><td colspan=3 valign=top><div id=WorkArea class=WorkArea style="height:${workareah}">$workarea</div>&nbsp;</td></tr>
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
   var ProcessHandler=document.getElementById("ProcessHandler");
   var ProcessWindow=document.getElementById("ProcessWindow");
   var LastMsg=document.getElementById("LastMsg");

   if ("$workheight" == "100%"){
      var h1=ModeSelect.offsetHeight;
      var h4=0;
      if (LastMsg){
         h4=LastMsg.offsetHeight;
      }
      ProcessWindow.style.height=h-h1-h4-90;
      var h2=ProcessHandler.offsetHeight;
      Tip.style.height=h-h2-h1-5;
      var WorkArea=document.getElementById("WorkArea");
      WorkArea.style.height=(ProcessWindow.offsetHeight-40)+"px";
   }
   else{
      ProcessWindow.style.height=($workheight+30)+"px";
      var h1=ModeSelect.offsetHeight;
      var h2=ProcessHandler.offsetHeight;
      Tip.style.height=h-h1-h2-1;
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
      $template.=$app->HtmlPersistentVariables(qw(WorkflowClass));
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
              page        =>$template,
             );
   print(TabSelectorTool("ModeSelect",%param));
   print("<script language=\"JavaScript\">");
   print($self->getDetailFunctionsCode($WfRec));
   print("function setEditMode(m)");
   print("{");
   print("   this.SubFrameEditMode=m;");
   print("}");
   print("function TabChangeCheck()");
   print("{");
   print("if (this.SubFrameEditMode==1){return(DataLoseWarn());}");
   print("return(true);");
   print("}");
   print("function SubmitCheck()");
   print("{");
   print("if (this.SubFrameEditMode==1){return(DataLoseWarn());}");
   print("return(true);");
   print("}");
  # print("addEvent(window, \"submit\", SubmitCheck);");
   print("</script>");

   print $app->HtmlBottom(body=>1,form=>1);

}

sub getDetailFunctions
{
   my $self=shift;
   my $rec=shift;
   my @f=($self->T('WorkflowPrint')=>'WorkflowPrint',
          $self->T('WorkflowClose')=>'WorkflowClose'
         );
   if (defined($rec) && $self->getParent->isDeleteValid($rec)){
      my $idname=$self->IdField->Name();
      my $id=$rec->{$idname};
      unshift(@f,$self->T("WorkflowDelete")=>"WorkflowDelete");
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

   my $d=<<EOF;
function WorkflowPrint(){
   window.frames['ProcessWindow'].focus();
   window.frames['ProcessWindow'].print();
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
   return(undef);
}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

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
   elsif ($WfRec->{fwddeptarget} eq 'base::user'){
      if ($userid==$WfRec->{fwddeptargetid}){
         return(1);
      }
   }
   return(0);
}














1;

