package kernel::App::Web::WorkflowLink;
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
use kernel::date;
use kernel::MyW5Base;

sub HtmlWorkflowLink
{
   my ($self)=@_;
   return($self->ListeditTabObjectSearch("WorkflowLinkResult",
                 $self->getParsedWorkflowLinkSearchTemplate()));
}

sub getParsedWorkflowLinkSearchTemplate
{
   my $self=shift;
   my $d;

   my $idobj=$self->IdField();
   my $idname=$idobj->Name();
   my $dataobjectid=Query->Param($idname);
   return("-undef ID - System ERROR-") if ($dataobjectid eq "");
   $self->ResetFilter();
   $self->SetFilter({$idname=>\$dataobjectid});
   my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));
   my $fobj=$self->getField("fullname");
   $fobj=$self->getField("name") if (!defined($fobj));
   my $title="Workflows";
   if (defined($fobj)){
      my $t=$fobj->RawValue($rec);
      if ($t ne ""){
         $title.=": ".$t;
      }
   }
   $title=~s/"/ /g;
   $d.=<<EOF;
<script language="JavaScript">
function setTitle()
{
   var t="$title";
   window.document.getElementById("WindowTitle");
   parent.document.title=t;
   return(true);
}
addEvent(window, "load", setTitle);
</script>
EOF

   my $h=$self->getPersistentModuleObject("WorkflowLink","base::workflow");
   $h->setParent(undef); # reset parent link

   my $wftype=$self->T("Workflow nature",'base::workflow');
   my @wt=();
   foreach my $t (sort(keys(%{$h->{SubDataObj}}))){
      next if ($self->T($t,$t) eq $t);
      if (!defined($self->{workflowlink}->{workflowtyp})){
         push(@wt,$self->T($t,$t),$t);
      }
      else{
         my $qt=quotemeta($t);
         if (grep(/^$qt$/,@{$self->{workflowlink}->{workflowtyp}})){
            push(@wt,$self->T($t,$t),$t);
         } 
      }
   }
   push(@wt,"- ".$self->T("all")." -","*");
   my $wt="<select onchange=\"SetStart();\" name=class style=\"width:100%\">";
   my %wt=@wt;
   foreach my $l (sort(keys(%wt))){
      my $k=$wt{$l};
      $wt.="<option value=\"$k\">$l</option>";
   }
   $wt.="</select>";


   my $changes=$self->T("Event End");
   my $tt=$self->kernel::MyW5Base::getTimeRangeDrop("Search_ListTime",
                                                    $self,
                                                    qw(selectshorthistory
                                                       shorthistory monthyear
                                                       lastweek
                                                       last2weeks
                                                       longhistory));
   my $wfstart="";
   my $workflowstart=$self->{workflowlink}->{workflowstart};
   if (ref($workflowstart) eq "CODE"){
      $workflowstart=&{$self->{workflowlink}->{workflowstart}}($self);
   }
   if (defined($workflowstart)){
      $wfstart=join(",",map({"'".$_."'"} keys(%{$workflowstart})));
   }

   my $label1=$self->T("Fulltext",'base::workflow');
   $d.=<<EOF;
<script language="JavaScript">
function SetStart()
{
   var stok=new Array($wfstart);
   var found=0;
   var cc=document.forms[0].elements['class'].selectedIndex;
   var v=document.forms[0].elements['class'].options[cc].value
   for(var c=0;c<stok.length;c++){
      if (v==stok[c]){
         found=1;
      }
   }
   var b=document.getElementById("startbutton");
 //  alert("found="+found+" v="+v);
   if (found){
      b.disabled=false;
   }
   else{
      b.disabled=true;
   }
}
</script>


<script language="JavaScript">
function startWorkflow()
{
   var fr=document.getElementById("startframe");
   var id=document.getElementById('CurrentId').value;
   var cc=document.forms[0].elements['class'].selectedIndex;
   var cl=document.forms[0].elements['class'].options[cc].value
   fr.src="startWorkflow?class="+cl+"&CurrentId="+id;
}
</script>
<table width="100%" border=0>
<tr><td width=1% nowrap>$changes:</td>
<td width=280>$tt</td>
<td width=1% nowrap>$label1:</td>
<td><input type=text name=fulltext style="width:100%"></td>
<td width=1% rowspan=2 valign=center>
<input class=button type=button value="Aktualisieren" onclick="DoSearch();">
<iframe id=startframe style="visibility:hidden" width=10 height=10 frameborder=0 border=0 src="startWorkflow"></iframe>
</td></tr>
<tr><td width=1% nowrap>$wftype:</td>
<td colspan=3>
<table width="100%" cellspacing=0 cellpadding=0>
<tr><td width=90%>$wt</td>
<td width=1%><input type=button onclick="startWorkflow();" id=startbutton disabled value="=> start Workflow" class=button style="width:100px"></td>
</tr></table>
</td>
</tr>
</table>
EOF
   return($d);
}



sub WorkflowLinkResult
{
   my $self=shift;
   my %param=@_;

   my $h=$self->getPersistentModuleObject("WorkflowLink","base::workflow");
   $h->setParent(undef); # reset parent link
   if (!$h->{IsFrontendInitialized}){
      $h->{IsFrontendInitialized}=$h->FrontendInitialize();
   }

   my $tt=Query->Param("Search_ListTime");
   my $class=Query->Param("class");    
   my $currentid=Query->Param("CurrentId");
   my $fulltext=Query->Param("fulltext");

   if ($currentid=~m/,/){
      $currentid=[split(/,/,$currentid)];
   }
   
   my $ids=$self->getRelatedWorkflows($currentid,
             {timerange=>$tt,class=>$class,fulltext=>$fulltext});
   if ($self->LastMsg()){
      my $outtmpl='<br><br><center>%LASTMSG%</center>'; 
      $self->ParseTemplateVars(\$outtmpl,{});
      print($self->HttpHeader("text/html"));
      print($self->HtmlHeader(style=>['default.css'],body=>1));
      print($outtmpl);
      print("</body></html>");
   }
   else{
      if (defined($ids)){
         $h->ResetFilter();
         $h->SecureSetFilter({id=>[keys(%{$ids})],isdeleted=>0});
         $h->setDefaultView(qw(linenumber eventstart eventend state name));
         return($h->Result(ExternalFilter=>1));
      }
   }
}

sub startWorkflow
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(form=>1,body=>1,
                           js=>['toolbox.js','OutputHtml.js'],
                           title=>"W5 start Workflow");
   my $class=Query->Param("class");
   my $id=Query->Param("CurrentId");
   print("<script language=\"JavaScript\">\n\n");
   if ($id ne "" && $class ne ""){
      my $workflowstart=$self->{workflowlink}->{workflowstart};
      if (ref($workflowstart) eq "CODE"){
         $workflowstart=&{$self->{workflowlink}->{workflowstart}}($self,$id);
      }
      if (!defined($workflowstart) || !defined($workflowstart->{$class})){
         print("alert(\"direct start Workflow denyed\");\n");
      }
      my $idfield=$self->IdField();
      my $flt={$idfield->Name()=>\$id};
      $self->SetFilter($flt);
      my @fields=keys(%{$workflowstart->{$class}});
      my ($rec,$msg)=$self->getOnlyFirst(@fields);
      if (defined($rec)){
         my %q=();
         foreach my $v (@fields){
            if (ref($workflowstart->{$class}->{$v}) eq "CODE"){
               &{$workflowstart->{$class}->{$v}}($self,$rec,\%q);
            }
            else{
               $q{$workflowstart->{$class}->{$v}}=
                   $rec->{$v};
            }
         }
         $q{WorkflowClass}=$class;
         my $q=kernel::cgi::Hash2QueryString(%q);
         print(<<EOF);
function openUrl()
{
openwin("../../base/workflow/New?$q","_blank","height=480,width=640,toolbar=no,status=no,resizable=yes,scrollbars=auto");
}
addEvent(window, "load", openUrl);
EOF
         print STDERR Dumper(\%q);
      }
      else{
         print("alert(\"open error - please contact developer\");\n");
      }
   }
   print("\n</script>");

   #print STDERR ("fifi startWorkflow class=$class id=$id\n");

   print $self->HtmlBottom(body=>1,form=>1);
}


######################################################################

1;
