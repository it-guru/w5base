package base::MyW5Base;
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
use kernel::config;
use kernel::App::Web;
use kernel::Output;
@ISA    = qw(kernel::App::Web);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->LoadSubObjs("MyW5Base");
   return($self);
}  

sub getValidWebFunctions
{  
   my ($self)=@_;
   return(qw(Main Welcome Result ViewEditor Bookmark));
}

sub Main
{
   my $self=shift;
   my $oldval=Query->Param("MyW5BaseSUBMOD");
   my $title=$self->T($self->Self);

   my %l=();
   my $DefaultFormat="HtmlV01";
   my $doAutoSearch=0;
   foreach my $m (values(%{$self->{SubDataObj}})){
      $l{$m->getLabel()}=$m;
      $title.=" &rArr; ".$m->getLabel() if ($oldval eq $m->Self()); 
   }
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                   'kernel.App.Web.css','myw5base.css',
                                   'frames.css'],
                           title=>$title,
                           js=>['toolbox.js','subModal.js'],
                           body=>1,form=>1);
   print $self->HtmlSubModalDiv();

   print("<table width=100% height=100% border=0 cellspacing=0 cellpadding=0>");
   printf("<tr><td height=1%% valign=top>%s</td></tr>",
          $self->getAppTitleBar(title=>$title));
   print("<tr><td height=1% valign=top>");
   print("<div class=searchframe><table class=searchframe>");

   my $s="<select name=MyW5BaseSUBMOD style=\"width:100%\" ".
         "OnChange=\"SelectionChanged();\">";
   $s.="<option value=\"\">&lt;".$self->T("please select a query").
       "&gt;</option>";

   my $UserCache=$self->Cache->{User}->{Cache};
   $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   my %selectCache;
   foreach my $label (sort(grep(/^\[/,keys(%l))),
                      sort(grep(!/^\[/,keys(%l)))){
      if (defined($l{$label}) &&
          $l{$label}->can("isSelectable") && 
          $l{$label}->isSelectable(user=>$UserCache,cache=>\%selectCache)){
         $s.="<option ";
         $s.="selected " if ($l{$label}->Self() eq $oldval);
         $s.="value=\"".$l{$label}->Self()."\">$label</option>";
      }
   }
   $s.="</select>";
   printf("<tr><td valign=top height=1%%>%s</td></tr>",$s);
   print("</table></div>");
   if (defined($oldval) && exists($self->{SubDataObj}->{$oldval})){
      my $curquery=$self->{SubDataObj}->{$oldval};
      my $o=$curquery->getDataObj();
      my $templ=$curquery->getQueryTemplate();
      $DefaultFormat=$curquery->getDefaultFormat();
      $doAutoSearch=$curquery->doAutoSearch();
      if (defined($o)){
         $o->ParseTemplateVars(\$templ);
      }
      printf("<tr><td valign=top height=1%%>%s</td></tr>",$templ);
      my $if="<iframe src=\"../../base/load/loading\" ".
             "name=Result style=\"width:100%;height:100%\">".
             "</iframe>";
      printf("<tr><td>%s</td></tr>",$if);
   }
   else{
      my $userid=$self->getCurrentUserId();
      my $bm=$self->getPersistentModuleObject("BookMark","base::userbookmark");
      $bm->ResetFilter();
      $bm->SetFilter({userid=>\$userid});
      my @bm=$bm->getHashList(qw(name srclink target));
      my $l1=$self->T("monitor my workflows");
      my $l2=$self->T("my current jobs");
      my $l3=$self->T("start a new workflow");
      my $mywf  ="<a href=\"../MyW5Base/Main?".
                 "MyW5BaseSUBMOD=base::MyW5Base::mywf\">".
                 "<img border=0 src=\"../../base/load/MyW5Base-MyWf.jpg\">".
                 "</a>";
      my $myjobs="<a href=\"../MyW5Base/Main?".
                 "MyW5BaseSUBMOD=base::MyW5Base::wfmyjobs\">".
                 "<img border=0 src=\"../../base/load/MyW5Base-MyJobs.jpg\">".
                 "</a>";
      my $newwf ="<a href=\"../workflow/New\">".
                 "<img border=0 src=\"../../base/load/MyW5Base-NewWf.jpg\">".
                 "</a>";
      my $newstext=$self->getNews();
      $newstext=$self->addNewsFrame($newstext) if ($newstext ne "");
      if ($#bm==-1){
         print <<EOF;
<tr><td valign=top align=center><br><br>
<table width=80% border=0>
<tr>
<td align=center width=20%>$mywf</td><td align=center width=20%>&nbsp;</td>
<td align=center width=20%>$myjobs</td><td align=center width=20%>&nbsp;</td>
<td align=center width=20%>$newwf</td>
</td>
</tr>
<tr>
<td align=center>$l1</td><td align=center>&nbsp;</td>
<td align=center>$l2</td><td align=center>&nbsp;</td>
<td align=center>$l3</td>
</tr>
</table>
$newstext
</td></tr>
EOF
      }
      else{
         my $userpropetitle=$self->T("modify user properties");
         my $userbookmarktitle=$self->T("bookmarks");
         my $bmdiv="<div class=winframe>";
         $bmdiv.="<div class=winframehead>".
                 "<table width=100% cellspacing=0 cellpadding=0 border=0>".
                 "<tr><td valign=center>".
                 "<a target=msel class=winframehead ".
                 "href=\"../../base/menu/msel/sysadm.userenv.bookmarks\">".
                 "Bookmarks:</a></td><td align=right valign=top>".
                 "<a target=msel class=winframehead ".
                 "title=\"$userbookmarktitle\" ".
                 "href=\"../../base/menu/msel/sysadm.userenv.bookmarks\">".
                 "<img width=14 height=14 border=0 ".
                 "src=\"../../base/load/bookmark.gif\"></a>".
                 "</td></tr></table>";
         $bmdiv.="</div><div class=winframebody id=bm><ul class=bookmarks>";
         foreach my $b (@bm){
            my $link="<a href=\"$b->{srclink}\" class=bookmark ".
                     "target=\"$b->{target}\">";
            if ($b->{target} eq "smallwin"){
               my $onclick="openwin(\"$b->{srclink}\",\"_blank\",".
                       "\"height=480,width=640,toolbar=no,status=no,".
                       "resizable=yes,scrollbars=no\")";
               $link="<a class=bookmark href=javascript:$onclick>";
            }
            if ($b->{srclink}=~m/^javascript:/i){
               $link="<a class=bookmark target=_self href=$b->{srclink}>";
            }
            $bmdiv.="<li class=bookmark>$link".$b->{name}."</a></li>";
         }
         $bmdiv.="</ul>";

         $bmdiv.="</div></div>";
         my $qf=getModuleObject($self->Config,"faq::QuickFind");
         my $quickfind;
         if (defined($qf)){
            $quickfind=$self->addQuickFind($qf);
         }
         print <<EOF;
<tr><td valign=top align=center>
<table width=100% border=0>
<td valign=top>$bmdiv
$newstext
</td>
<td width=40% valign=top>
<div class=winframe id=workflowlinks>

<div class=winframehead>Workflow Links:</div>
<table width=99%>
<tr>
<td align=center width=50%>$mywf</td>
<td align=center width=50%>$newwf</td>
</td>
</tr>
<tr>
<td align=center style="padding:10px">$l1</td>
<td align=center style="padding:10px">$l3</td>
</tr>
<tr><td align=center colspan=2>$myjobs</tr>
<tr><td align=center colspan=2 style="padding:10px">$l2</tr>
</table>

</div>
$quickfind
</td>
</tr>
</table>
</td></tr>
EOF
      }
   }
   print("</td></tr></table>");
   print <<EOF;
<input type=hidden name=CurrentView>
<input type=hidden name=UseLimit>
<input type=hidden name=UseLimitStart>
<input type=hidden name=FormatAs value="$DefaultFormat">
<style>body{overflow:hidden}</style>
<script language="JavaScript">
function keyhandler(ev)
{
   if (ev && ev.keyCode==13){
      if (document.forms[0].elements['MyW5BaseSUBMOD'].value!=""){
         DoSearch();
      }
      return false;
   }
}
document.onkeypress=keyhandler;
function inputkeyhandler()
{
   if (window.event && window.event.keyCode==13){
      if (document.forms[0].elements['MyW5BaseSUBMOD'].value!=""){
         DoSearch();
      }
      return false;
   }
   return(true);
}

function DoPrint()
{
   window.frames['Result'].focus();
   window.frames['Result'].print();
}

document.onsubmit=OnSubmit;

function OnSubmit()
{
   if (document.forms[0].elements['MyW5BaseSUBMOD'].value!=""){
      DoSearch();
   }
   return(0);
}

function DoSearch()
{
   document.forms[0].target="Result";
   document.forms[0].action="Result";
   document.forms[0].elements['FormatAs'].value="$DefaultFormat";
   document.forms[0].submit();
}

function SelectionChanged()
{
   document.forms[0].target="_self";
   document.forms[0].action="Main";
   document.forms[0].submit();
}
function RecalcNews()
{
   var newsall=document.getElementById("newsall");
   if (newsall){
      var news=document.getElementById("news");
      var bm=document.getElementById("bm");
      var h=getViewportHeight();
      news.style.height="10px";
      newsall.style.display="block";
      newsall.style.visibility="visible";
      if (bm){ 
         h=h-bm.offsetHeight-150;
      }
      else{
         h=h-280;
      }
      if (h<50){
         newsall.style.display="none";
         newsall.style.visibility="hidden";
      }
      else{
         news.style.height=h+"px";
      }
   }
   var quickfind=document.getElementById("quickfind");
   var workflowlinks=document.getElementById("workflowlinks");
   if (quickfind && workflowlinks){
      var h=getViewportHeight();
      if (h-workflowlinks.offsetHeight<140){
         quickfind.style.display="none";
         quickfind.visibility="hidden";
      }
      else{
         quickfind.style.display="block";
         quickfind.visibility="visible";
      }
   }
}
addEvent(window, "load", RecalcNews);
addEvent(window, "resize", RecalcNews);

</script>
EOF
   if ($doAutoSearch){
      print(<<EOF);
<script language="JavaScript">
addEvent(window, "load", DoSearch);
</script>
EOF
   }
   print $self->HtmlBottom(body=>1,form=>1);
}

sub addQuickFind
{
   my $self=shift;
   my $qf=shift;
   my $detailx=$qf->DetailX();
   my $detaily=$qf->DetailY();
   my $search=$self->T("search");

   my $d=<<EOF;
<script language="JavaScript">
function doQuickFind()
{
   var t=document.forms['QuickFind'].elements['searchtext'].value;
   if (t!="" && t.length>2){
      openwin("../../faq/QuickFind/Result?"+
              "forum=on&ci=on&article=on&searchtext="+t,
              "_quickfind",
              "height=$detaily,width=$detailx,toolbar=no,status=no,"+
                       "resizable=yes,scrollbars=no");
   }
   return(false);
}
</script>
<div class=winframe style=\"margin-top:4px\" id=quickfind>
</form>
<form name=QuickFind>
<div class=winframehead>QuickFind:</div>
<table width=100% border=1>
<tr>
<td>
<input style="width:100%" type=text value="" name=searchtext>
</td>
<td width=1%>
<input onclick="doQuickFind();" type=button value="$search">
</td>
</tr>
</table>
</div>
<script language="JavaScript">
setEnterSubmit(document.forms['QuickFind'],doQuickFind);
</script>
EOF
   return($d);
}

sub addNewsFrame
{
   my $self=shift;
   my $newstext=shift;
   my $news="";

   $news="<div class=winframe style=\"margin-top:4px\" id=newsall>";
   $news.="<div class=winframehead>".
           "<table width=100% cellspacing=0 cellpadding=0 border=0>".
           "<tr><td valign=center>".
           "<a target=msel class=winframehead ".
           "href=\"../../base/menu/msel/faq.forum\">".
         $self->T("current topics from the Knowledge-Management Forum").
           ":</a></td><td align=right valign=top>".
           "</td></tr></table>";
   $news.="</div><div class=winframebody id=news ".
          "style=\"height:50px;overflow:auto\">".$newstext;
   $news.="</div></div>";
   return($news);
}

sub getNews
{
   my $self=shift;
   my $d="";
   my $to=$self->getPersistentModuleObject("faq::forumtopic");
   if (defined($to)){
      $to->SecureSetFilter();
      $to->Limit(50);
      $d.="<table width=100% border=0 cellspacing=0>";
      my $newsline=1;
      my $newscount=0;
      $to->SetCurrentOrder(qw(cdate));
      foreach my $rec ($to->getHashList(qw(name cdate entrycount mdate
                                           topicicon isreaded))){
         my $name=$rec->{name};
         $name=~s/</&lt;/g;
         $name=~s/>/&gt;/g;
         my $iconobj=$to->getField("topicicon");
         my $icon=$iconobj->FormatedDetail($rec,"HtmlDetail");
         my $utz=$self->UserTimezone();
         my $cdate=$rec->{cdate};
         $cdate=$self->ExpandTimeExpression($cdate,"ultrashort","GMT",$utz);
         if ($rec->{entrycount}==0){
            $name="<b>".$name."</b>";
         }
         else{
            $name.=" ($rec->{entrycount})";
         }
         my $link="openwin(\"../../faq/forum/Topic/$rec->{id}".
                  "&AllowClose=1\",\"_blank\",".
                  "\"height=520,width=640,toolbar=no,".
                  "status=no,resizable=yes,scrollbars=auto\")";
         $d.="<tr height=24 class=newsline$newsline>".
             "<td width=25 align=center valign=center>$icon</td>".
             "<td valign=center><a href=JavaScript:$link class=news>$name</a> ".
             "</td><td width=1% nowrap align=center>$cdate</td></tr>";
         $newsline++;
         $newsline=1 if ($newsline>2);
         $newscount++;
      }
      $d.="</table>";
      $d="" if ($newscount==0);
   }
   return($d);
}

sub Result
{
   my $self=shift;

   my $oldval=Query->Param("MyW5BaseSUBMOD");
   if (defined($oldval) && exists($self->{SubDataObj}->{$oldval}) &&
       $self->{SubDataObj}->{$oldval}->can("Result")){
      my $curquery=$self->{SubDataObj}->{$oldval};
      my $res=$curquery->Result();
      return($res) if (defined($res));
   }

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                   'kernel.App.Web.css'],
                           body=>1,form=>1);
   $self->LastMsg(ERROR,"the requested query isn't supported or ".
                        "has internal errors procreated");
   my @msglist;
   if ($self->LastMsg()){
      @msglist=$self->LastMsg();
   }
   print "<table width=100% cellpadding=20><tr><td>";
   print "<div class=lastmsg style=\"width:100%\">".
          join("<br>\n",map({
                              if ($_=~m/^ERROR/){
                                 $_="<font style=\"color:red;\">".$_.
                                    "</font>";
                              }
                              $_;
                            } @msglist))."</div>";
   print "</td></tr></table>";
   print $self->HtmlBottom(body=>1,form=>1);
}

sub ViewEditor
{
   my $self=shift;

   my $oldval=Query->Param("MyW5BaseSUBMOD");
   if (defined($oldval) && exists($self->{SubDataObj}->{$oldval}) &&
       $self->{SubDataObj}->{$oldval}->can("Result")){
      my $curquery=$self->{SubDataObj}->{$oldval};
      return($curquery->Result());
   }

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           body=>1,form=>1);
   printf("Satz ViewEditor mit X ...");

   print $self->HtmlBottom(body=>1,form=>1);
}

sub Bookmark
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css'],
                           title=>$self->T("... add a bookmark"),
                           body=>1,form=>1);
   my $autosearch=Query->Param("AutoSearch");
   my $replace=Query->Param("ReplaceBookmark");
   Query->Delete("ReplaceBookmark");
   my $bookmarkname=Query->Param("BookmarkName");
   if ($bookmarkname eq ""){
      $bookmarkname=$self->T($self->Self,$self->Self());
      $bookmarkname.=": ".$self->T("my search");
   }
   my $closewin="";
   my $dosave=0;

   if (Query->Param("SAVE")){
      Query->Delete("SAVE");
      $dosave=1;
   }

   Query->Delete("AutoSearch");
   my %qu=Query->MultiVars();
   foreach my $sv (keys(%qu)){
      next if ($qu{$sv} ne "");
      delete($qu{$sv});
   }
   my $querystring=kernel::cgi::Hash2QueryString(%qu);
   $querystring="?".$querystring;
   my $srclink=$self->Self();
   $srclink=~s/::/\//g;
   my $bmsrclink="../../".$srclink."/Main$querystring&AutoSearch=$autosearch";
   my $clipsrclink=$ENV{SCRIPT_URI}."/../../../".$srclink."/Main$querystring";

   if ($dosave){
      my $bm=getModuleObject($self->Config,"base::userbookmark");
      my $target="_self";
      if ($replace){
         my $userid=$self->getCurrentUserId();
         $bm->SetFilter({name=>\$bookmarkname,userid=>\$userid});
         $bm->SetCurrentView(qw(ALL));
         $bm->ForeachFilteredRecord(sub{
                            $bm->ValidatedDeleteRecord($_);
                         });
      }
      if ($bm->SecureValidatedInsertRecord({name=>$bookmarkname,
                                            srclink=>$bmsrclink,
                                            target=>$target})){
         $closewin="parent.hidePopWin();";
      }
   }


   my $quest=$self->T("please copy this URL to your clipboard:");
   print(<<EOF);
<script language="JavaScript">
$closewin
function showUrl()
{
   var x;
   x=prompt("$quest:","$clipsrclink");
   if (x){
      parent.hidePopWin();
   }
}
</script>
EOF
   my $repl="<select name=ReplaceBookmark>";
   $repl.="<option value=\"0\">".$self->T("no")."</option>";
   $repl.="<option value=\"1\"";
   $repl.=" selected" if ($replace);
   $repl.=">".$self->T("yes")."</option>";
   $repl.="</select>";
   my $BOOKM="<input type=text style=\"width:100%\" name=BookmarkName ".
             "value=\"$bookmarkname\">";

   print $self->getParsedTemplate("tmpl/MyW5Base.bookmarkform",{skinbase=>'base',
                                    static=>{BOOKM=>$BOOKM,
                                             REPL=>$repl}});
   #printf("Bookmark Handler");
   print("<input type=hidden name=SAVE value=\"1\">");
   print $self->HtmlPersistentVariables(qw(ALL));
   print $self->HtmlBottom(body=>1,form=>1);
   return(0);
}

1;
