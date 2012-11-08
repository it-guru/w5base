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
<table width=100% border=0>
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
<table width=100% cellspacing=0 cellpadding=0>
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
   if (Query->Param("MultiActOperation") eq ':doPROCESS:'){
      my $q=Query->MultiVars();
      my @idl;
      foreach my $k (keys(%$q)){
         if (my ($id)=$k=~m/^ACT:(\d+)$/){
            if ($q->{$k} eq "1" || $q->{$k} eq "on"){
               push(@idl,$id);
            }
         }
      }
      if ($#idl!=-1){
         $h->ResetFilter();
         $h->SecureSetFilter({id=>\@idl});
         return($h->Result(ExternalFilter=>1));
      }
   }
   if ($h->validateSearchQuery()){
      my %q=$h->getSearchHash();
      my $tt=Query->Param("Search_ListTime");
      if ($tt=~m/[\(\)]/){     # if a month or year is specified, the open
         $q{eventend}=$tt;     # entrys will not be displayed
      }
      elsif ($tt eq ""){
         $q{eventend}=[undef];
      }
      else{
         $q{eventend}=[$tt,undef];
      }
      #Query->Delete("Search_ListTime");  # a test - to allo search time in
      my $class=Query->Param("class");    # bookmark entries
      if ($class ne "*" && $class ne ""){
         $q{class}=[$class];
      }
      if ($class eq "*" && defined($self->{workflowlink}->{workflowtyp})){
         $q{class}=$self->{workflowlink}->{workflowtyp};
      }
      my %qorg=%q;

      my $dataobject=$self->Self;
      my $dataobjectid=Query->Param("CurrentId");
      my $idobj=$self->IdField();
      my $idname=$idobj->Name();
      if (ref($self->{workflowlink}->{workflowkey}) eq "ARRAY" &&
          $self->{workflowlink}->{workflowkey}->[0] eq $idname){
         $q{$self->{workflowlink}->{workflowkey}->[1]}=\$dataobjectid;
       #  $q{affectedapplication}="ASS_ADSL-NI(P)";
      }
      else{
         if (ref($self->{workflowlink}->{workflowkey}) eq "CODE"){
            &{$self->{workflowlink}->{workflowkey}}($self,\%q,$dataobjectid);
         }
         else{
            $q{id}="none";
         }
      }


      my $fulltext=Query->Param("fulltext");

      my %qmax=%q;
      $h->ResetFilter();
      $h->SetFilter(\%qmax);
      $h->Limit(1502);
      $h->SetCurrentOrder("id");
      my @l=$h->getHashList("id");
      my %idl=();
      map({$idl{$_->{id}}=1} @l);
      if (keys(%idl)>1500){
         print $self->noAccess(msg(ERROR,$self->T("selection to ".
                               "unspecified for search",
                               "kernel::App::Web::WorkflowLink")));
         return();
      }
      if ($q{class} eq "" || $q{class}=~m/::(DataIssue|mailsend)$/ ||
          (ref($q{class}) eq "ARRAY" && 
           grep(/::(DataIssue|mailsend)$/,@{$q{class}}))){
         my $fo=$h->getField("directlnktype");
         if (defined($fo)){
            my $mode="*";
            if ($q{class} eq ""){
               $mode=['DataIssue','W5BaseMail'];
            }
            if ($q{class}=~m/::(DataIssue)$/ ||
                (ref($q{class}) eq "ARRAY" && 
                 grep(/::(DataIssue)$/,@{$q{class}}))){
               push(@$mode,'DataIssue') if (ref($mode) eq "ARRAY");
            }
            if ($q{class}=~m/::(mailsend)$/ ||
                (ref($q{class}) eq "ARRAY" && 
                 grep(/::(mailsend)$/,@{$q{class}}))){
               push(@$mode,'W5BaseMail') if (ref($mode) eq "ARRAY");
            }
           
            my %qadd=%qorg; # now add the DataIssue Workflows to 
                            # DataSelection idl
            $qadd{directlnktype}=[$self->Self,$self->SelfAsParentObject()];
            $qadd{directlnkid}=\$dataobjectid;
            $qadd{directlnkmode}=$mode;
            $qadd{isdeleted}=\'0';
            $h->ResetFilter();
            $h->SetFilter(\%qadd);
            $h->Limit(1502);
            $h->SetCurrentOrder("id");
            my @l=$h->getHashList("id");
            map({$idl{$_->{id}}=1} @l);
         }
      }
      if (keys(%idl)>1500){
         print $self->noAccess(msg(ERROR,$self->T("selection to ".
                               "unspecified for search",
                               "kernel::App::Web::WorkflowLink")));
         return();
      }
      %q=(id=>[keys(%idl)],isdeleted=>\'0');


      if (!$fulltext=~m/^\s*$/){
         if (keys(%idl)!=0){
            my %ftname=%q;
            $ftname{name}="*$fulltext*";
            $ftname{id}=[keys(%idl)];
            my %ftdesc=%q;
            $ftdesc{detaildescription}="*$fulltext*";
            $ftdesc{id}=[keys(%idl)];
            $h->ResetFilter();
            $h->SetFilter([\%ftdesc,\%ftname]);
            $h->SetCurrentOrder("id");
            my %idl1=();
            my %idl2=();
            my %idl3=();
            my @l=$h->getHashList("id");
            map({$idl1{$_->{id}}=1} @l);

            { # and now the note search
               $h->{Action}->ResetFilter(); 
               $h->{Action}->SetFilter({comments=>"*$fulltext*",
                                        wfheadid=>[keys(%idl)]}); 
               $h->SetCurrentOrder("wfheadid");
               my @l=$h->{Action}->getHashList("wfheadid");
               $h->{Action}->ResetFilter(); 
               map({$idl2{$_->{wfheadid}}=1} @l);
            }
            map({$idl3{$_}=1} keys(%idl2));
            map({$idl3{$_}=1} keys(%idl1));
            %q=(id=>[keys(%idl3)],isdeleted=>\'0');
         }
         else{
            %q=(id=>[-1]);
         }
      }
      $h->ResetFilter();
      $h->SecureSetFilter(\%q);
      $h->setDefaultView(qw(linenumber eventstart eventend state name));
      return($h->Result(ExternalFilter=>1));
   }
   return("");
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
