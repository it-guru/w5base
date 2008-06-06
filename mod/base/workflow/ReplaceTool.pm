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

   $self->AddFrontendFields(
      new kernel::Field::TextDrop(
                name          =>'wfreplaceusersrc',
                label         =>'Search User',
                htmldetail    =>0,
                group         =>'init',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['wfreplaceusersrcid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link (
                name          =>'wfreplaceusersrcid',
                container     =>'headref'),

      new kernel::Field::TextDrop(
                name          =>'wfreplaceuserdst',
                label         =>'Replace by',
                htmldetail    =>0,
                group         =>'init',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['wfreplaceuserdstid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link (
                name          =>'wfreplaceuserdstid',
                container     =>'headref'),

      new kernel::Field::TextDrop(
                name          =>'wfreplacegrpsrc',
                label         =>'Search Group',
                htmldetail    =>0,
                group         =>'init',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['wfreplacegrpsrcid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link (
                name          =>'wfreplacegrpsrcid',
                container     =>'headref'),

      new kernel::Field::TextDrop(
                name          =>'wfreplacegrpdst',
                label         =>'Replace by',
                htmldetail    =>0,
                group         =>'init',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['wfreplacegrpdstid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link (
                name          =>'wfreplacegrpdstid',
                container     =>'headref'),

    );
   $self->LoadSubObjs("ext/ReplaceTool","ReplaceTool");


   return($self);
}


sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;

   return($self->InitFields(
                   new kernel::Field::Select(
                             name               =>'replaceoptype',
                             htmleditwidth      =>'350px',
                             readonly           =>sub{
                                my $self=shift;
                                my $current=shift;
                                return(0) if (!defined($current));
                                return(1);
                             },
                             transprefix        =>'SR::',
                             translation        =>'base::workflow::ReplaceTool',
                             value              =>['base::user','base::grp'],
                             translation        =>'base::workflow::ReplaceTool',
                             label              =>'Replace operation type',
                             container          =>'headref'),
                   new kernel::Field::Text(
                             name               =>'replacesearch',
                             readonly           =>1,
                             translation        =>'base::workflow::ReplaceTool',
                             label              =>'search for',
                             container          =>'headref'),
                   new kernel::Field::Link(
                             name               =>'replacesearchid',
                             readonly           =>1,
                             container          =>'headref'),
                   new kernel::Field::Text(
                             name               =>'replacereplacewith',
                             readonly           =>1,
                             translation        =>'base::workflow::ReplaceTool',
                             label              =>'replace with',
                             container          =>'headref'),
                   new kernel::Field::Link(
                             name               =>'replacereplacewithid',
                             readonly           =>1,
                             container          =>'headref'),
                   new kernel::Field::Textarea(
                             name               =>'replaceat',
                             readonly           =>1,
                             translation        =>'base::workflow::ReplaceTool',
                             label              =>'replace at fields',
                             container          =>'headref'),
   ));
}


sub getImputTemplate
{
   my $self=shift;
   my $replaceoptype=shift;

   my $d="<table border=0 bgcolor=silver width=100%>";
   $d.="<tr><td width=20></td><td>".
       "<b>".
       $self->T("Replace operation in the following fields").":</b></td></tr>";

   foreach my $module (sort(keys(%{$self->{ReplaceTool}}))){
      my $crec=$self->{ReplaceTool}->{$module}->getControlRecord();
      while(my $k=shift(@$crec)){
         my $data=shift(@$crec);
         if ($data->{replaceoptype} eq $replaceoptype){
            my $dataobj=getModuleObject($self->getParent->Config,
                                        $data->{dataobj});
            my $label;
            if ($data->{label} ne ""){
               $label=$self->getParent->T($data->{label},$data->{dataobj});
            }
            if (!defined($label) && defined($dataobj)){
               my $fldobj=$dataobj->getField($data->{target});
               if (defined($fldobj)){
                  $label=$fldobj->Label();
               }
            }
            if (defined($dataobj)){
               $d.="<tr>";
               my $optname="SR:".$module."::".$k;
               my $checked;
               $checked=" checked" if (Query->Param($optname) ne "");
               $d.="<td width=20><input type=checkbox class=ACT ".
                   " name=\"$optname\"$checked></td>";
               $d.="<td>".
                   $self->getParent->T($data->{dataobj},$data->{dataobj});
               $d.=" - Field: ".$label if ($label ne "");
               $d.="</td>";
               $d.="</tr>";
            }
         }
      }
   }
   $d.="<tr><td width=20><input type=button style=\"width:20px;height:20px\" ".
       "onClick=checkAll()></td>".
       "<td><b>".
       $self->T("all posible elements")."</b></td></tr>";
   $d.="</table>";
   $d.=<<EOF;
<script language=JavaScript>
var allon=false;

function checkAll()
{
   for(var i = 0; i < document.forms.length; i++) {
      for(var e = 0; e < document.forms[i].length; e++){
         if(document.forms[i].elements[e].className == "ACT") {
            document.forms[i].elements[e].checked=!allon;
         }
      }
   }
   allon=!allon;
}
</script>

EOF

   return($d);

}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/workflow_replacetool.jpg?".
          $cgi->query_string());
}



sub IsModuleSelectable
{
   my $self=shift;
   my $acl;

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
   return("default","state","flow","header");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(1) if (!defined($rec));
   return("default") if ($rec->{state}<=20 &&
                         $self->getParent->IsMemberOf("admin"));
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
   elsif($currentstep=~m/^.*::workflow::ReplaceTool::asktype$/){
      return($self->getStepByShortname("askreplace",$WfRec)); 
   }
   elsif($currentstep=~m/^.*::workflow::ReplaceTool::askreplace$/){
      return($self->getStepByShortname("askarg",$WfRec)); 
   }
   elsif($currentstep=~m/^.*::workflow::ReplaceTool::askarg$/){
      return($self->getStepByShortname("approval",$WfRec)); 
   }
   elsif($currentstep eq ""){
      return($self->getStepByShortname("asktype",$WfRec)); 
   }
   return(undef);
}

sub isOptionalFieldVisible
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   my $name=$param{field}->Name();

   return(1) if ($name eq "name");
   return(1) if ($name eq "shortactionlog");
   return(1) if ($name eq "detaildescription");
   return(0);
}

sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;
   my @l;
   my $app=$self->getParent;
   my $userid=$self->getParent->getCurrentUserId();
   my $creator=$WfRec->{openuser};
   my $iscurrent=$self->isCurrentForward($WfRec);

   if ($WfRec->{step} eq "base::workflow::ReplaceTool::approval"){
      if ($iscurrent){
         push(@l,"approve");
         push(@l,"break");
      }
      if ($userid==$creator){
         push(@l,"break");
      }
   }
         push(@l,"nop");

   return(@l);
}
#######################################################################
package base::workflow::ReplaceTool::asktype;
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
<tr>
<td class=fname style="width:200px">%replaceoptype(label)%:</td>
<td class=finput>%replaceoptype(storedworkspace)%</td>
</tr>
EOF

   return($self->SUPER::generateStoredWorkspace($WfRec,@steplist).$d);
}

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my @steplist=Query->Param("WorkflowStep");
   pop(@steplist);
   my $StoredWorkspace=$self->SUPER::generateStoredWorkspace($WfRec,@steplist);

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
$StoredWorkspace
<tr>
<td class=fname style="width:150px">%replaceoptype(label)%:</td>
<td class=finput>%replaceoptype(detail)%</td>
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


   return(1);
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(340);
}



#######################################################################
package base::workflow::ReplaceTool::askreplace;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateStoredWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $replaceoptype=Query->Param("Formated_replaceoptype");

   my @steplist=@_;
   my $d;
   if ($replaceoptype eq "base::user"){
      $d=<<EOF;
<tr>
<td class=fname>%wfreplaceusersrc(label)%:</td>
<td class=finput>%wfreplaceusersrc(storedworkspace)%</td>
</tr>
<tr>
<td class=fname>%wfreplaceuserdst(label)%:</td>
<td class=finput>%wfreplaceuserdst(storedworkspace)%</td>
</tr>
EOF
   }
   if ($replaceoptype eq "base::grp"){
      $d=<<EOF;
<tr>
<td class=fname>%wfreplacegrpsrc(label)%:</td>
<td class=finput>%wfreplacegrpsrc(storedworkspace)%</td>
</tr>
<tr>
<td class=fname>%wfreplacegrpdst(label)%:</td>
<td class=finput>%wfreplacegrpdst(storedworkspace)%</td>
</tr>
EOF
   }

   return($self->SUPER::generateStoredWorkspace($WfRec,@steplist).$d);
}

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $replaceoptype=Query->Param("Formated_replaceoptype");
printf STDERR ("fifi replaceoptype=$replaceoptype\n");

   my @steplist=Query->Param("WorkflowStep");
   pop(@steplist);
   my $StoredWorkspace=$self->SUPER::generateStoredWorkspace($WfRec,@steplist);


   my $templ;
   if ($replaceoptype eq "base::user"){
      $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
$StoredWorkspace
<tr>
<td class=fname>%wfreplaceusersrc(label)%:</td>
<td class=finput>%wfreplaceusersrc(detail)%</td>
</tr>
<tr>
<td class=fname>%wfreplaceuserdst(label)%:</td>
<td class=finput>%wfreplaceuserdst(detail)%</td>
</tr>
</table>
EOF
   }
   if ($replaceoptype eq "base::grp"){
      $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
$StoredWorkspace
<tr>
<td class=fname>%wfreplacegrpsrc(label)%:</td>
<td class=finput>%wfreplacegrpsrc(detail)%</td>
</tr>
<tr>
<td class=fname>%wfreplacegrpdst(label)%:</td>
<td class=finput>%wfreplacegrpdst(detail)%</td>
</tr>
</table>
EOF
   }
printf STDERR ("fifi templ=$templ\n");
   return($templ);
}

sub ProcessNext                
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $replaceoptype=Query->Param("Formated_replaceoptype");

   my $srcfieldname;
   my $dstfieldname;
   if ($replaceoptype eq "base::user"){
      $srcfieldname="wfreplaceusersrc";
      $dstfieldname="wfreplaceuserdst";
   }
   if ($replaceoptype eq "base::grp"){
      $srcfieldname="wfreplacegrpsrc";
      $dstfieldname="wfreplacegrpdst";
   }
   if (defined($srcfieldname) && defined($dstfieldname)){
      my $srcfield=$self->getField($srcfieldname);
      my $f=Query->Param("Formated_".$srcfield->Name());
      if ($f=~m/^\s*$/){
         $self->LastMsg(ERROR,"no src specified");
         return(0);
      }
     
      if (my $appl=$srcfield->Validate($WfRec,{$srcfield->Name()=>$f})){

         my $dstfield=$self->getField($dstfieldname);
         my $f=Query->Param("Formated_".$dstfield->Name());
         if ($f=~m/^\s*$/){
            $self->LastMsg(ERROR,"no dst specified");
            return(0);
         }
        
         if (my $appl=$dstfield->Validate($WfRec,{$dstfield->Name()=>$f})){
            my $nextstep=$self->getParent->getNextStep($self->Self(),$WfRec);
            if (defined($nextstep)){
               my @WorkflowStep=Query->Param("WorkflowStep");
               push(@WorkflowStep,$nextstep);
               Query->Param("WorkflowStep"=>\@WorkflowStep);
               return(0);
            }
            return(0);
         }
         else{
            if ($self->LastMsg()==0){
               $self->LastMsg(ERROR,"unexpected error while dstfield check");
            }
            return(0);
         }


      }
      else{
         if ($self->LastMsg()==0){
            $self->LastMsg(ERROR,"unexpected error while srcfield check");
         }
         return(0);
      }
   }
   return(0);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   return(1);
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(340);
}



#######################################################################
package base::workflow::ReplaceTool::askarg;
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
<tr>
<td class=fname colspan=2>Begründung:<br>
%detaildescription(storedworkspace)%</td>
</tr>
EOF

   return($self->SUPER::generateStoredWorkspace($WfRec,@steplist).$d);
}

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $replaceoptype=Query->Param("Formated_replaceoptype");
   my @steplist=Query->Param("WorkflowStep");
   pop(@steplist);
   my $StoredWorkspace=$self->SUPER::generateStoredWorkspace($WfRec,@steplist);

   my $inputTempl=$self->getParent()->getImputTemplate($replaceoptype);
   my $q=$self->getParent->T("Yes, i am sure to want to start the workflow replacing the matching references.","base::workflow::ReplaceTool");
   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
$StoredWorkspace
</table>
<div style="overflow:auto;width:100%;height:80px">
$inputTempl
</div>
<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr>
<td class=fname colspan=2>Begründung:<br>
%detaildescription(detail)%</td>
</tr>
<tr>
<td class=fname colspan=2><input name=FORCE type=checkbox>$q</td></tr>
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


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(340);
}


sub ProcessNext                
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $forcechk=Query->Param("FORCE");
   if ($forcechk eq ""){
      $self->LastMsg(ERROR,"verfication question noch checked");
      return(0);
   }
   print STDERR Dumper(scalar(Query->MultiVars()));
   my $h=$self->getWriteRequestHash("web");
   my $q=Query->MultiVars();
   my @replaceat;
   foreach my $k (keys(%$q)){
      if (($k=~m/^SR:/) && $q->{$k} ne ""){
         push(@replaceat,$k);
      }
   }
   
  
   my $newrec={step =>'base::workflow::ReplaceTool::approval',
               name =>'Reference replace: ',
               eventstart=>NowStamp("en"),
               eventend=>undef,
               replaceat=>join("\n",sort(@replaceat)),
               detaildescription=>'Ja',
               stateid=>4};
   if ($h->{replaceoptype} eq "base::user"){
      $newrec->{replacesearch}=$q->{Formated_wfreplaceusersrc};
      $newrec->{replacereplacewith}=$q->{Formated_wfreplaceuserdst};
      my $user=getModuleObject($self->Config,"base::user");
      $user->ResetFilter();
      $user->SetFilter({fullname=>[$newrec->{replacesearch}]});
      my ($rec,$msg)=$user->getOnlyFirst(qw(userid));
      if (defined($rec)){
         $newrec->{replacesearchid}=$rec->{userid};
      }
      $user->ResetFilter();
      $user->SetFilter({fullname=>[$newrec->{replacereplacewith}]});
      my ($rec,$msg)=$user->getOnlyFirst(qw(userid));
      if (defined($rec)){
         $newrec->{replacereplacewithid}=$rec->{userid};
      }
   }
   if ($h->{replaceoptype} eq "base::grp"){
      $newrec->{replacesearch}=$q->{Formated_wfreplacegrpsrc};
      $newrec->{replacereplacewith}=$q->{Formated_wfreplacegrpdst};
      my $grp=getModuleObject($self->Config,"base::grp");
      $grp->ResetFilter();
      $grp->SetFilter({fullname=>[$newrec->{replacesearch}]});
      my ($rec,$msg)=$grp->getOnlyFirst(qw(grpid));
      if (defined($rec)){
         $newrec->{replacesearchid}=$rec->{grpid};
      }
      $grp->ResetFilter();
      $grp->SetFilter({fullname=>[$newrec->{replacereplacewith}]});
      my ($rec,$msg)=$grp->getOnlyFirst(qw(grpid));
      if (defined($rec)){
         $newrec->{replacereplacewithid}=$rec->{grpid};
      }
   }
   $newrec->{name}.=$newrec->{replacesearch};
   $newrec->{replaceoptype}=$h->{replaceoptype};
   $newrec->{detaildescription}=$h->{detaildescription};
               

   my $fobj=$self->getParent->getField("fwdtargetname");
   if (my $admrec=$fobj->Validate(undef,{fwdtargetname=>'admin'})){
      if (!defined($admrec->{fwdtarget}) ||
          !defined($admrec->{fwdtargetid} ||
          $admrec->{fwdtargetid}==0)){
         if ($self->LastMsg()==0){
            $self->LastMsg(ERROR,"invalid forwarding target");
         }
         return(0);
      }
      $newrec->{fwdtarget}=$admrec->{fwdtarget};
      $newrec->{fwdtargetid}=$admrec->{fwdtargetid};
   }
               
   if (my $id=$self->StoreRecord($WfRec,$newrec)){
      return(1);
   }

   return(0);
}







#######################################################################
package base::workflow::ReplaceTool::approval;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   return(1);
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(150);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my %p=$self->SUPER::getPosibleButtons($WfRec);
   delete($p{NextStep});
   delete($p{BreakWorkflow})      if (!grep(/^break$/,@$actions));
   $p{SaveStep}=$self->T('SaveStep')  if (grep(/^approve$/,@$actions));
   return(%p);
}

sub generateWorkspacePages
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $divset=shift;
   my $selopt=shift;
   my $tr="base::workflow::actions";
   my $class="display:none;visibility:hidden";

#   if (grep(/^nop$/,@$actions)){
#      $$selopt.="<option value=\"nop\" class=\"$class\">".
#                $self->getParent->T("nop",$tr).
#                "</option>\n";
#      $$divset.="<div id=OPnop style=\"margin:15px\"><br>".
#                $self->getParent->T("The current workflow isn't forwared ".
#                "to you. At now there is no action nessasary.",$tr)."</div>";
#   }
   return($self->SUPER::generateWorkspacePages($WfRec,$actions,$divset,$selopt));
}





1;
