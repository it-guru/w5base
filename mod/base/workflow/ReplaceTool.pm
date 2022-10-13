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

   $self->LoadSubObjs("ext/ReplaceTool","ReplaceTool");
   return($self);
}


sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;

   if (!defined($self->{dstobjects})){
      $self->{dstobjects}=[];
      $self->{dstnames}={};
      my %target;
      foreach my $module (sort(keys(%{$self->{ReplaceTool}}))){
         my $crec=$self->{ReplaceTool}->{$module}->getControlRecord();
         while(my $k=shift(@$crec)){
            my $data=shift(@$crec);
            my $referenceonly=0;
            if (exists($data->{referenceonly}) && $data->{referenceonly}){
               $referenceonly=$data->{referenceonly};
            }
            if (!$referenceonly){
               my $do=$data->{replaceoptype};
               $self->{dstnames}->{$do}=$self->getParent->T($do,$do);
               my $dataobj=getModuleObject($self->getParent->Config,$do);
               if (defined($dataobj)){
                  my $idname=$dataobj->IdField->Name();
                  my $nameobj=$dataobj->getField("fullname");
                  if (!defined($nameobj)){
                     $nameobj=$dataobj->getField("name");
                  }
                  if (defined($nameobj)){
                     my $name=$nameobj->Name();
                     $target{$do}=$name;
                  }
               }
            }
         }
      }
      @{$self->{dstobjects}}=%target;
   }

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
                             getPostibleValues=>sub{
                                my $self=shift;
                                my @l=%{$self->getParent->{dstnames}};
                                return(@l);
                             },
                             translation        =>'base::workflow::ReplaceTool',
                             label              =>'Replace operation type',
                             container          =>'headref'),
                   new kernel::Field::MultiDst(
                             name               =>'replacesearch',
                             selectivetyp       =>'1',
                             dsttypfield        =>'replaceoptype',
                             dstidfield         =>'replacesearchid',
                             altnamestore       =>'altreplacesearch',
                             dst                =>$self->{dstobjects},
                             translation        =>'base::workflow::ReplaceTool',
                             label              =>'search for'),
                   new kernel::Field::Link(
                             name               =>'altreplacesearch',
                             container          =>'headref'),
                   new kernel::Field::Link(
                             name               =>'replacesearchid',
                             readonly           =>1,
                             container          =>'headref'),
                   new kernel::Field::MultiDst(
                             name               =>'replacereplacewith',
                             selectivetyp       =>'1',
                             dsttypfield        =>'replaceoptype',
                             dstidfield         =>'replacereplacewithid',
                             altnamestore       =>'altreplacereplacewith',
                             dst                =>$self->{dstobjects},
                             translation        =>'base::workflow::ReplaceTool',
                             label              =>'replace with'),
                   new kernel::Field::Link(
                             name               =>'altreplacereplacewith',
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
                             viewarea           =>\&viewReplaceFields,
                             container          =>'headref'),
   ));
}

sub viewReplaceFields
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=shift;
   my @sets=split(/\s+/,$d);
   my $app=$self->getParent;
   my @d;

   if ($#sets==0 && $sets[0] eq "ALL"){
      @sets=();
      foreach my $mod (keys(%{$app->{ReplaceTool}})){
         my $crec=$app->{ReplaceTool}->{$mod}->getControlRecord();
         my %crec=@{$crec};
         foreach my $tag (keys(%crec)){
            push(@sets,'SR:'.$mod."::".$tag);
         }
      }
   }
   
   foreach my $s (@sets){
      if (my ($mod,$tag)=$s=~m/^SR:(.*)::([^:]+)$/){
         if (defined($app->{ReplaceTool}->{$mod})){
            my $crec=$app->{ReplaceTool}->{$mod}->getControlRecord();
            my %crec=@{$crec};
            my $data=$crec{$tag};
            my $dataobj=getModuleObject($app->Config,
                                        $data->{dataobj});
            if (defined($dataobj)){
               my $label;
               if ($data->{label} ne ""){
                  $label=$app->T($data->{label},$data->{dataobj});
               }
               if (!defined($label) && defined($dataobj)){
                  my $fldobj=$dataobj->getField($data->{target});
                  if (defined($fldobj)){
                     $label=$fldobj->Label();
                  }
               }
               my $name=$app->T($data->{dataobj},$data->{dataobj});
               push(@d," - $name: $label");
            }
         }
      }
   }
   my $d=join("\n",sort(@d));
   $d="<table style=\"width:100%;table-layout:fixed;padding:0;margin:0\">".
      "<tr><td><img class=printspacer style=\"float:left\" ".
      "src=\"../../../public/base/load/empty.gif\" width=1 height=100>".
      "<div class=multilinetext>".
      "<pre class=multilinetext>".$d.
      "</pre></div></td></tr></table>";

   return($d);
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
         my $referenceonly=0;
         if (exists($data->{referenceonly}) && $data->{referenceonly}){
            $referenceonly=$data->{referenceonly};
         }
         if ((!$referenceonly) && $data->{replaceoptype} eq $replaceoptype){
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

sub doReplaceOperation
{
   my $self=shift;
   my $WfRec=shift;
   my $log;

   my @sets=split(/\s+/,$WfRec->{replaceat});
   my $app=$self;
   my $oldOperationContext=$W5V2::OperationContext;

   if ($ENV{SCRIPT_URI} ne ""){
      my $baseurl=$ENV{SCRIPT_URI};
      $baseurl=~s#/(auth|public)/.*$##;
      my $url=$baseurl;
      $url.="/auth/base/workflow/ById/".$WfRec->{id};
      $W5V2::OperationContext=$url;
   }

  if ($#sets==0 && $sets[0] eq "ALL"){
      @sets=();
      foreach my $mod (keys(%{$app->{ReplaceTool}})){
         my $crec=$app->{ReplaceTool}->{$mod}->getControlRecord();
         my %crec=@{$crec};
         foreach my $tag (keys(%crec)){
            push(@sets,'SR:'.$mod."::".$tag);
         }
      }
   }

   my $count=0;
   
   foreach my $s (@sets){
      if (my ($mod,$tag)=$s=~m/^SR:(.*)::([^:]+)$/){
         if (defined($app->{ReplaceTool}->{$mod})){
            my $workmod=$app->{ReplaceTool}->{$mod};
            my $crec=$workmod->getControlRecord();
            my %crec=@{$crec};
            my $data=$crec{$tag};
            if (defined($data) && $workmod->can("doReplaceOperation")){
               my $replacemode=$WfRec->{replaceoptype};
               my $search=$WfRec->{replacesearch};
               my $searchid=$WfRec->{replacesearchid};
               my $replace=$WfRec->{replacereplacewith};
               my $replaceid=$WfRec->{replacereplacewithid};
               $count+=$workmod->doReplaceOperation($tag,$data,
                          $replacemode,$search,$searchid,$replace,$replaceid);
            }
         }
      }
   }
   $W5V2::OperationContext=$oldOperationContext;
   my $msg="$count entrys replaced";
   if ($self->LastMsg()>0){
      $msg.="\n\n".join("",$self->LastMsg());
      $self->LastMsg("");
   }
   return($msg);
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
   my @l=$self->getPosibleActions($rec);

   return("default") if (grep(/^wfapproveop$/,@l));
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
         push(@l,"wfaddnote");
         push(@l,"wfapproveop");
         push(@l,"wfrejectop");
         push(@l,"iscurrent");
      }
      elsif ($userid==$creator){
         push(@l,"nop");
         push(@l,"break");
      }
      else{
         push(@l,"nop");
      }
   }
   if ($WfRec->{stateid}==16){
      if ($userid==$creator){
         push(@l,"wffinish");
      }
      else{
         push(@l,"nop");
      }
   }
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
   $d=<<EOF;
<tr>
<td class=fname>%replacesearch(label)%:</td>
<td class=finput>%replacesearch(storedworkspace)%</td>
</tr>
<tr>
<td class=fname>%replacereplacewith(label)%:</td>
<td class=finput>%replacereplacewith(storedworkspace)%</td>
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


   my $templ;
   $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
$StoredWorkspace
<tr>
<td class=fname>%replacesearch(label)%:</td>
<td class=finput>%replacesearch(detail)%</td>
</tr>
<tr>
<td class=fname>%replacereplacewith(label)%:</td>
<td class=finput>%replacereplacewith(detail)%</td>
</tr>
</table>
EOF
   return($templ);
}

sub ProcessNext                
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $replaceoptype=Query->Param("Formated_replaceoptype");

   my $srcfieldname="replacesearch";
   my $dstfieldname="replacereplacewith";
   if (defined($srcfieldname) && defined($dstfieldname)){
      my $srcfield=$self->getField($srcfieldname);
      my $f=Query->Param("Formated_".$srcfield->Name());
      if ($f=~m/^\s*$/){
         $self->LastMsg(ERROR,"no src specified");
         return(0);
      }
      $f=trim($f);  # remove leading and trailing white spaces
     
      if (my $appl=$srcfield->Validate($WfRec,{$srcfield->Name()=>$f})){

         my $dstfield=$self->getField($dstfieldname);
         my $f=Query->Param("Formated_".$dstfield->Name());
         if ($f=~m/^\s*$/){
            $self->LastMsg(ERROR,"no dst specified");
            return(0);
         }
         $f=trim($f);  # remove leading and trailing white spaces
        
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
      $self->LastMsg(ERROR,"verfication question not checked");
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
   if ($#replaceat==-1){
      $self->LastMsg(ERROR,"no replace fields selected");
      return(0);
   }
   if (length(trim($h->{detaildescription}))<20){
      $self->LastMsg(ERROR,"description not detailed enough");
      return(0);
   }
   
  
   my $newrec={step =>'base::workflow::ReplaceTool::approval',
               name =>'Reference replace: ',
               eventstart=>NowStamp("en"),
               eventend=>undef,
               replaceat=>join("\n",sort(@replaceat)),
               detaildescription=>trim($h->{detaildescription}),
               stateid=>2};

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
      foreach my $k (keys(%$admrec)){
         $newrec->{$k}=$admrec->{$k};
      }
   }


   my $fobj=$self->getParent->getField("replacesearch");
   if (my $admrec=$fobj->Validate(undef,$h)){

      if (!defined($admrec->{replacesearchid} ||
          $admrec->{replacesearchid}==0)){
         if ($self->LastMsg()==0){
            $self->LastMsg(ERROR,"invalid replacesearch target");
         }
         return(0);
      }
      foreach my $k (keys(%$admrec)){
         $newrec->{$k}=$admrec->{$k};
      }
   }

   my $fobj=$self->getParent->getField("replacereplacewith");
   if (my $admrec=$fobj->Validate(undef,$h)){
      if (!defined($admrec->{replacereplacewithid} ||
          $admrec->{replacereplacewithid}==0)){
         if ($self->LastMsg()==0){
            $self->LastMsg(ERROR,"invalid replacereplacewith target");
         }
         return(0);
      }
      foreach my $k (keys(%$admrec)){
         $newrec->{$k}=$admrec->{$k};
      }
   }

   $newrec->{name}.=$newrec->{altreplacesearch};
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
      if ($self->getParent->getParent->Action->StoreRecord(
                $id,"forwardto",
                {additional=>{ForwardTarget=>$newrec->{fwdtarget},
                              ForwardTargetId=>$newrec->{fwdtargetid},
                              ForwardToName=>'admin'}})){
         return(1);
      }
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
   delete($p{BreakWorkflow})          if (!grep(/^break$/,@$actions));
   $p{SaveStep}=$self->T('SaveStep')  if (grep(/^wfapproveop$/,@$actions));
   return(%p);
}

sub generateWorkspacePages
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $divset=shift;
   my $selopt=shift;
   my $tr="base::workflow::ReplaceTool";
   my $class="display:none;visibility:hidden";

   if (grep(/^wfapproveop$/,@$actions)){
      $$selopt.="<option value=\"wfapproveop\" class=\"$class\">".
                $self->getParent->T("wfapproveop",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfapproveop style=\"margin:15px\">".
                $self->getParent->T("MSG000")."</div>";
   }
   if (grep(/^wfrejectop$/,@$actions)){
      $$selopt.="<option value=\"wfrejectop\" class=\"$class\">".
                $self->getParent->T("wfrejectop",$tr).
                "</option>\n";
      my $note=Query->Param("note");
      $$divset.="<div id=OPwfrejectop>".$self->getDefaultNoteDiv($WfRec,$actions,
                                        mode=>'reject').
                "</div>";
   }

   return($self->SUPER::generateWorkspacePages($WfRec,$actions,$divset,$selopt));
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
          {translation=>'base::workflow::ReplaceTool'},"",undef)){
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
   elsif($action eq "SaveStep"){
      my $op=Query->Param("OP");
      if ($action ne "" && !grep(/^$op$/,@{$actions})){
         $self->LastMsg(ERROR,"invalid or disallowed action '$action.$op' ".
                              "requested");
         return(0);
      }
      if ($op eq "wfapproveop"){
         # check if any further approves are required. If not, do
         # the operation
         my $resultlog=$self->getParent->doReplaceOperation($WfRec); 
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"note",
             {translation=>'base::workflowaction'},$resultlog,undef)){
            my $openuserid=$WfRec->{openuser};
            my $openusername=$WfRec->{openusername};
            my $step=$self->getParent->getStepByShortname("opdone");
            if ($openuserid ne ""){
               $self->StoreRecord($WfRec,{stateid=>16,
                                          step=>$step,
                                          eventend=>NowStamp("en"),
                                          closedate=>NowStamp("en"),
                                          fwddebtargetid=>undef,
                                          fwddebtarget=>undef,
                                          fwdtarget=>'base::user',
                                          fwdtargetid=>$openuserid,
                                         });
               $self->PostProcess($action.".".$op,$WfRec,$actions,
                                  fwdtarget=>'base::user',
                                  fwdtargetid=>$openuserid,
                                  fwdtargetname=>$openusername);
            }
            else{
               my $step=$self->getParent->getStepByShortname("finish");
               $self->StoreRecord($WfRec,{stateid=>21,
                                          step=>$step,
                                          eventend=>NowStamp("en"),
                                          closedate=>NowStamp("en"),
                                          fwddebtargetid=>undef,
                                          fwddebtarget=>undef,
                                          fwdtargetid=>undef,
                                          fwdtarget=>undef,
                                         });
            }
            return(1);
         }

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

   if ($action eq "SaveStep.wfapproveop"){
      $aobj->NotifyForward($WfRec->{id},
                           $param{fwdtarget},
                           $param{fwdtargetid},
                           $param{fwdtargetname},
                           "replace operation done");
   }

   return($self->SUPER::PostProcess($action,$WfRec,$actions));
}







#######################################################################
package base::workflow::ReplaceTool::break;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(0);
}


#######################################################################
package base::workflow::ReplaceTool::opdone;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(30);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   return() if (!grep(/^wffinish$/,@$actions));
   return(FinishWorkflow=>$self->T('FinishWorkflow'));
}


sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $userid=$self->getParent->getParent->getCurrentUserId();

   if ($action eq "FinishWorkflow"){
      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"wffinish",
          {translation=>'base::workflow::ReplaceTool'},"",undef)){
         my $openuserid=$WfRec->{openuser};
         my $step=$self->getParent->getStepByShortname("finish");
         $self->StoreRecord($WfRec,{stateid=>21,
                                    step=>$step,
                                    eventend=>NowStamp("en"),
                                    closedate=>NowStamp("en"),
                                    fwddebtargetid=>undef,
                                    fwddebtarget=>undef,
                                    fwdtargetid=>undef,
                                    fwdtarget=>undef,
                                   });
         $self->PostProcess($action,$WfRec,$actions,
                            "finish by $ENV{REMOTE_USER}",
                            fwdtarget=>'base::user',
                            fwdtargetid=>$openuserid,
                            fwdtargetname=>"Requestor");
         return(1);
      }
      return(0);
   }
   return(0); 
}

sub Validate
{
   return(1);
}


#######################################################################
package base::workflow::ReplaceTool::finish;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(0);
}

sub Validate
{
   return(1);
}


1;
