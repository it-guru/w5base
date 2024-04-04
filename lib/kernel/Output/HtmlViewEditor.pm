package kernel::Output::HtmlViewEditor;
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
use Data::Dumper;
use base::load;
@ISA    = qw(kernel::Formater);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
  # my $config=$self->getParent->getParent->Config();
   #$self->{SkinLoad}=getModuleObject($config,"base::load");

   return($self);
}

sub getHttpHeader
{  
   my $self=shift;
   my $app=$self->getParent->getParent();
   my $d=$app->HttpHeader();
   $d.=$app->HtmlHeader();
   $d.="\n<title>".$app->T("ViewEditor",$app->Self())."</title>\n";
   $d.="<link rel=stylesheet ".
       "href=\"../../base/load/default.css\"></link>\n";
   $d.="<link rel=stylesheet ".
       "href=\"../../base/load/work.css\"></link>\n";
   $d.="<link rel=stylesheet ".
       "href=\"../../base/load/Output.HtmlDetail.css\"></link>\n";
   $d.="<link rel=stylesheet ".
       "href=\"../../base/load/Output.HtmlViewLine.css\"></link>\n";
   $d.="<link rel=stylesheet ".
       "href=\"../../base/load/Output.HtmlViewEditor.css\"></link>\n";
   $d.="<link rel=stylesheet ".
       "href=\"../../base/load/MkTree.css\"></link>\n";
   $d.="<script language=JavaScript ".
       "src=\"../../../public/base/load/MkTree.js\"></script>\n";
   $d.="<script language=JavaScript ".
       "src=\"../../../public/base/load/toolbox.js\"></script>\n";
   $d.="<body onload=\"ResizeObj()\" onresize=\"ResizeObj()\">";
   return($d);
}

sub getStyle
{
   my ($self,$fh)=@_;
   my $app=$self->getParent->getParent();
   my $d="";

   $d.=$app->getTemplate("css/Output.HtmlFormatSelector.css","base");
   return($d);
}

sub isRecordHandler
{
   return(0);
}

sub ProcessHead
{
   my ($self,$fh)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my $userid=$app->getCurrentUserId();
   my $dest=$app->Self();
   my $module=$app->ViewEditorModuleName();
   $dest=~s/::/\//g;
   $dest="../../$dest/Result";

   my $d="";
   $d.="<form method=post><style>";
   $d.=$self->getStyle($fh);
   $d.="</style>\n\n";
   $d.="<script language=JavaScript ".
         "src=\"../../../public/base/load/toolbox.js\"></script>\n";
#   $d.="<script language=JavaScript ".
#         "src=\"../../../public/base/load/firebug-lite.js\"></script>\n";
#   $d.="<script language=JavaScript ".
#         "src=\"../../../public/base/load/firebugx.js\"></script>\n";
#   $d.="<script language=JavaScript ".
#         "src=\"../../../public/base/load/firebug.js\"></script>\n";
   $d.="<script language=JavaScript ".
         "src=\"../../../public/base/load/OutputHtml.js\"></script>\n";
   $d.="<table id=viewline class=maintable>\n";
   $d.=$self->getHtmlViewLine($fh,$dest);

   $d.="<tr><td class=mainblock>";
   $d.="<table  class=datatable width=\"100%\" border=0>\n".
       "<tr class=headline>";
   $app->{userview}->ResetFilter();
   $app->{userview}->SetFilter({module=>\$module,
                                userid=>\$userid,
                                name=>\$view});
   my ($vrec,$msg)=$app->{userview}->getOnlyFirst(qw(id));
   my $link=$self->getParent->getParent->T("Edit your view")." ...";
   if (defined($vrec)){
      my $dest="../../base/userview/Detail?id=$vrec->{id}&AllowClose=1";
      my $detailx=$app->DetailX();
      my $detaily=$app->DetailY();
      my $label=$self->getParent->getParent->T("direct edit view");
      my $lineonclick="openwin(\"$dest\",\"_blank\",".
             "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
             "resizable=yes,scrollbars=auto\")";
      $link="<a title=\"$label\" class=viewdirectedit ".
            "href=JavaScript:$lineonclick>$link</a>";
   }
   $d.="<th colspan=2 class=headfield height=1%>".$link."</th></tr>\n";
   $d.="</table>";
   $d.="</table>";
   return($d);
}

sub ProcessOp
{
   my $self=shift;
   my $op=shift;
   my $app=$self->getParent->getParent();
   my $curruserid=$app->getCurrentUserId();

   $app->{userview}->ResetFilter();
   if ($op eq "save"){
      my $name=Query->Param("CurrentView");
      my $module=$app->ViewEditorModuleName();
      my %flt=(name=>$name,module=>$module,userid=>$curruserid);
      $app->{userview}->SetFilter(\%flt);
      my ($oldrec,$msg)=$app->{userview}->getFirst();
      my %rec=(viewrevision=>1,%flt,editor=>$ENV{REMOTE_USER});
      $rec{data}=join(", ",Query->Param("ViewFieldList"));
      $app->{userview}->ValidatedInsertOrUpdateRecord(\%rec,\%flt);
   }
   if ($op eq "del"){
      my $name=Query->Param("CurrentView");
      my $delcount=0;
      my $module=$app->ViewEditorModuleName();
      my %flt=(name=>$name,module=>\$module,userid=>\$curruserid);
      $app->{userview}->SetFilter(\%flt);
      $app->{userview}->ForeachFilteredRecord(sub{
         if ($app->{userview}->ValidatedDeleteRecord($_)){
            $delcount++;
         }
      });
      if ($delcount){
         $name=Query->Param("CurrentView"=>"default");
      }
   }
   if ($op eq "add"){
      my $name=Query->Param("AddView");
      my $module=$app->ViewEditorModuleName();
      my %rec=(viewrevision=>1,name=>$name,module=>$module,userid=>$curruserid,
               editor=>$ENV{REMOTE_USER});
      if ($name eq "all"){
         $rec{data}="ALL";
      }
      if (my $id=$app->{userview}->ValidatedInsertRecord(\%rec)){
         Query->Delete("AddView");
         $app->{userview}->SetFilter(id=>\$id); # Datensatz neu lesen, damit
         my ($rec,$msg)=$app->{userview}->getOnlyFirst(qw(name)); # der name
         $app->{userview}->ResetFilter();       # correct neu gesetzt werdne k
         $name=$rec->{name};
         
         $name=Query->Param("CurrentView"=>$name);
      }
   }
   Query->Delete("OP");
}

sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $outputhandler=$self->getParent();
   my $op=Query->Param("OP");
   $self->ProcessOp($op) if ($op ne "");
   my $delconfirm=$app->T("are you sure, that you want to delete '\%s'");
   my $currentview=Query->Param("CurrentView");
   $delconfirm=sprintf($delconfirm,$currentview);
   my $d=<<EOF;
<script language="JavaScript">

function ResizeObj(obj)
{
   h=getViewportHeight();
   w=getViewportWidth();
   document.getElementById('ViewEditor').style.height=h-60;
   document.getElementById('ViewEditorMain').style.height=h-60;
   document.getElementById('FullFieldTree').style.height=h-170;
   document.getElementById('NewCurrentView').style.height=h-170;
   document.getElementById('NewCurrentView').style.width=w-(w/2)-30;
}

function DoAdd()
{
   document.forms[0].elements['OP'].value="add";
   document.forms[0].target="_self";
   document.forms[0].submit();
}

function DoDel()
{
   if (confirm("$delconfirm")){
      document.forms[0].elements['OP'].value="del";
      document.forms[0].target="_self";
      document.forms[0].submit();
   }
}
function DoSave()
{
   document.forms[0].elements['OP'].value="save";
   document.forms[0].target="_self";
   var view=document.forms[0].elements['ViewFieldList'];
   for(c=view.length-1;c>=0;c--){
      view.options[c].selected=1
   }
   document.forms[0].submit();
}
function DoUp()
{
   var view=document.forms[0].elements['ViewFieldList'];
   for(c=0;c<view.length;c++){
      if (view.options[c].selected && c != 0){
         var oldText = view.options[c-1].text;
         var oldVal = view.options[c-1].value;
         view.options[c-1].text=view.options[c].text;
         view.options[c-1].value=view.options[c].value;
         view.options[c].text=oldText;
         view.options[c].value=oldVal;
         view.options[c-1].selected=1;
         view.options[c].selected=0;
      }else if (view.options[c].selected && c == 0){
         c=view.length+1;
      }else{
         view.options[c].selected=0;
      }
   }
}

function DoDown()
{
   var view=document.forms[0].elements['ViewFieldList'];
   for(var c=view.length-1;c>=0;c--){
      if (view.options[c].selected && c != view.length-1){
         var oldText = view.options[c+1].text;
         var oldVal = view.options[c+1].value;
         view.options[c+1].text=view.options[c].text;
         view.options[c+1].value=view.options[c].value;
         view.options[c].text=oldText;
         view.options[c].value=oldVal;
         view.options[c+1].selected=1;
         view.options[c].selected=0;
      }else if (view.options[c].selected && c == view.length-1){
         c=-1;
      }
   }
}

function RowsDel(delary)
{
   var d=document.getElementById("NewCurrentView");
   if (delary.constructor.toString().indexOf(Array) == -1) {
      d.remove(delary);
      inittree('tree_route');
   }else{
      for(var i=0;i<delary.length;++i){
         d.remove(delary[i]);
      }
   }
   inittree('tree_route');
}


function DropBoxKh(e)
{
   var d = document.getElementById("NewCurrentView");
   var delary = new Array();
   if (e.keyCode == 46 || e.keyCode == 44 || e.keyCode == 110){
      for(var c=d.length-1;c>=0;c--){
         if (d.options[c].selected ){
            delary.push(c); 
         }
      }   
   }
   RowsDel(delary); 
}

function InitDropBox()
{
   var d=document.getElementById("NewCurrentView");
   addEvent(d,"keydown",DropBoxKh);
   var i=document.getElementById("shortsearch");
   i.focus();
}

addEvent(window,"load",InitDropBox);
addEvent(window,"load",convertTrees);

</script>
EOF
   $d.="<div id=ViewEditor class=ViewEditor ><div id=ViewEditorMain class=ViewEditorMain>";
   $d.="<table height=\"100%\" width=\"100%\" border=0 cellpadding=5>";
   $d.="<tr><td valign=top>";
   $d.="<table border=0 cellspacing=0 cellpadding=0 ".
       "width=\"100%\" height=\"100%\">".
       "<tr height=1%>";
   $d.="<td width=25% nowrap align=left>".
       "<input type=text size=10 name=AddView>";
   $d.="<input type=button OnClick=\"DoAdd();\" value=\"".
       $app->T("Add View",$self->Self())."\"></td>";
   $d.="<td align=center valign=top> <b><u>View Editor</u></b> </td>";
   $d.="<td width=25% nowrap align=right>".
       "<input type=button OnClick=\"DoDel();\" ".
       "value=\"".
       $app->T("Drop View",$self->Self())."\">";
   $d.="</td></tr>";
   $d.="<tr><td colspan=3><table width=\"100%\" border=1 height=\"100%\">";
   $d.="<tr height=1%>";
   $d.="<td width=50%><table width=\"100%\" ".
       " border=0><tr><td align=left valign=middle>".
       $app->T("MSG004",$self->Self())."</td><td valign=middle align=right>".
       "<input title=\"".$app->T("filter fields in menu tree",$self->Self()).
       "\" size=8 onKeyup=\"ShSearch();\" ".
       "id=shortsearch value=''/>&nbsp;&nbsp;&nbsp;&nbsp;".
       "<input type=\"image\" class=fieldadd ".
       "onclick=\"expandTree('tree_route');return(false);\" ".
       "src=\"../../base/load/expandall.gif\" style=\"cursor:pointer\"".
       "title=\"".$app->T("Expand All Fields",$self->Self())."\" name=exall ".
       ">".
       "&nbsp;".
       "<input type=\"image\" class=fieldadd ".
       " src=\"../../base/load/collapseall.gif\" style=\"cursor:pointer\"".
       "title=\"".$app->T("Collapse All Fields",$self->Self())."\" name=coall ".
       "OnClick=\"collapseTree('tree_route');return(false);\">".
       "</td></tr></table>";
   $d.="<td width=1%></td>";
   $d.="<td width=50%>".$app->T("MSG005",$self->Self())."</td>";
   $d.="</tr>";
   $d.="<tr><td width=49% valign=top>".$self->getFullFieldTreeSelect($rec);
   $d.="</td>";
   $d.="<td width=1%>";
   $d.="<table height=100%>".
       "<tr><td valign=top><img OnClick=\"DoUp();\" ".
       "src=\"../../base/load/DoUp.gif\" style=\"cursor:pointer\"".
       "title=\"".$app->T("Field of current View order up",$self->Self()).
       "\"></td></tr>".
       "<tr><td valign=bottom><img OnClick=\"DoDown();\" ".
       "style=\"cursor:pointer\" src=\"../../base/load/DoDown.gif\" ".
       "title=\"".
       $app->T("Field of current View order down",$self->Self()).
       "\"></td></tr></table>";
   $d.="</td>";
   $d.="<td width=49% valign=top>".$self->getViewFieldSelect();
   $d.="</td></tr></td></tr>";
   $d.="<tr height=1%><td colspan=3 align=center>".
       "<input type=button OnClick=\"DoSave();\" value=\"".
       $app->T("Save View",$self->Self())."\"></td><tr>";
   $d.="</table>";
   $d.="</td></tr>";
   my $lastmsg=$app->findtemplvar({},"LASTMSG");
   $d.="<tr height=1%><td colspan=3 nowrap align=left>".
       "$lastmsg </td><tr>";
   $d.="</table>";
   $d.="</td></tr>";
   $d.="</table>";
   $d.="</div></div>";

   return($d);
}

sub getViewFieldSelect
{
   my $self=shift;
   my $app=$self->getParent->getParent();
   my $d="<select size=5 id=NewCurrentView class=ViewFieldSelect multiple ".
         " onDblClick=\" RowsDel(this.options.selectedIndex);  \" ".
         " name=ViewFieldList >";
   my @showfieldlist=();
   my @oldval=Query->Param("ViewFieldList");
   my $op=Query->Param("OP");
   #printf STDERR ("on load op=$op\n");
   if ($op ne ""){
      @showfieldlist=Query->Param("ViewFieldList");
   }
   else{
      my $currentview=Query->Param("CurrentView");
      @showfieldlist=$app->getFieldListFromUserview($currentview);
   }
   foreach my $field (@showfieldlist){
      if ($field eq "ALL" || $field=~m/^\S+\.\S+$/){
         $d.="<option value=\"$field\">[$field]</option>";
      }
      else{
         my $purefieldname=$field;
         $purefieldname=~s/^[+-]+//; # stripe order
         my $fobj=$app->getField($purefieldname);
         if ($fobj){
            my $label=$fobj->Label();
            my $ext="";
            $fobj->extendFieldHeader("ViewEditor",undef,\$ext);
            $label.=$ext if ($ext ne "");
            $d.="<option value=\"$field\"";
           # $d.=" selected" if (grep(/^$field$/,@oldval));
            $d.=">".$label."</option>";
         }
      }
   }
   $d.="</select>";
   return($d);
}

sub getFullFieldTreeSelect
{
   my $self=shift;
   my $rec=shift;
   my $app=$self->getParent->getParent();

   my %sgrp=();
   my %translation=();

   foreach my $field ($app->getFieldList()){
      my $fobj=$app->getField($field);
      if ($fobj){
         my $grplist=$fobj->{group};
         $grplist=[$grplist] if (ref($grplist) ne "ARRAY");
         foreach my $grp (@$grplist){
            if (defined($fobj->{translation})){
               $translation{$grp}=[] if (!defined($translation{$grp}));
               if (!grep(/^$fobj->{translation}$/,@{$translation{$grp}})){
                  push(@{$translation{$grp}},$fobj->{translation});
               }
            }
            $sgrp{$grp}=[] if (!defined($sgrp{$grp}));
            push(@{$sgrp{$grp}},$fobj);
         }
      }
   }
   my $c=0;
   my $d="<div class=FullFieldTreeSelect id=FullFieldTree>".
         "<ul class=mktree id=tree_route>";
   my @translationbase=($self->Self,
                        $app->Self,
                        sort(keys(%{$app->{SubDataObj}}),
                        sort(keys(%{$app->{InactivSubDataObj}}))));
   foreach my $grp ($app->sortDetailBlocks([keys(%sgrp)])){
      my $grpentry=$app->getGroup($grp);
      if (defined($grpentry)){
         unshift(@{$translation{$grp}},@{$grpentry->{translation}});
      }
      my $trgrp;
      my @checkedobjs;
      foreach my $fobj (@{$sgrp{$grp}}){
         if (ref($fobj) eq "HASH"){
            printf STDERR ("SYSTEMERROR: invalid fobj in $self\n");
         }
         else{
            next if (!$fobj->UiVisible("ViewEditor"));
            push(@checkedobjs,$fobj);
         }
      }
      next if ($#checkedobjs==-1);
      if (defined($translation{$grp})){
         $trgrp=$app->T("fieldgroup.".$grp,@{$translation{$grp}});
      }
      else{
         $trgrp=$app->T("fieldgroup.".$grp,@translationbase);
      }
      if ($trgrp eq "fieldgroup.default"){
         $trgrp=$app->T($app->Self(),$app->Self());
      }
      $trgrp=~s/#.*$//g; #remove remarks
      $d.="<li class=liClosed id=tree_$c ".
          "onMouseDown=\"return(false)\" ".
          "xhead=1 onSelectStart=\"return(false)\" ".
          ">$trgrp";
      $c++;
      foreach my $fobj (@checkedobjs){
         my $field=$fobj->Name();
         my $label=$fobj->Label();
         my $ext="";
         $fobj->extendFieldHeader("ViewEditor",undef,\$ext);
         $label.=$ext if ($ext ne "");
         $d.="<ul id=tree_$c>";
         $c++;
         $d.="<li xvalue=\'$field\' downpoint=1 id=treediv_$c ".
             "onClick=\"DoFieldonClick(this);\" ".
             "onMouseDown=\"return(false)\" ".
             "onSelectStart=\"return(false)\" ".
             "><input ".
             "class=fieldadd type=button value=\"&#10148;\">".
             $label."</li>";
         $d.="</ul>";
      }
      $d.="</li>";
   }
   $d.="</ul></div>";

   return($d);
}

sub getHttpFooter
{  
   my $self=shift;
   my $d="";
   $d.=$self->HtmlStoreQuery();
   $d.=<<EOF;
<script language="JavaScript">
RefreshViewDropDown('tree_route');

</script>
<input type=hidden name=OP value="">
EOF
   if (Query->Param("CurrentId")){
      $d.="<input type=hidden name=CurrentId value=\"".
          Query->Param("CurrentId")."\">";  # for history view editor
   }
   $d.="</form>";
   $d.="</body>";
   $d.="</html>";
   return($d);
}



1;
