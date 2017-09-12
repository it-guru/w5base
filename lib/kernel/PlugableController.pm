package kernel::PlugableController;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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
   $self->{'PlugableClass'}='NoMod' if (!defined($self->{'PlugableClass'}));
   if (!defined($self->{'PlugableSelektor'})){
      $self->{'PlugableSelektor'}=$self->{'PlugableClass'}.'SUBMOD';
   }
   $self->LoadSubObjs($self->{'PlugableClass'});
   return($self);
}  

sub getValidWebFunctions
{  
   my ($self)=@_;
   return(qw(Main Welcome Result ViewEditor Bookmark));
}

sub getAppDirectLink
{
   my $self=shift;
   my $oldval=Query->Param($self->{'PlugableSelektor'});
   my $q="";
   if ($oldval ne ""){
      $q="?".$self->{'PlugableSelektor'}.'='.$oldval;
   }
   my $mp=Query->Param("originalMenuSelection");
   if ($mp ne ""){
      return("../../base/menu/msel".$mp.$q);
   }
   return('Main'.$q);
}

sub getOperationTarget
{
   my $self=shift;

   return("Result","Result");
}

sub submitOnEnter
{
   my $self=shift;

   return(1);
}


sub Main
{
   my $self=shift;
   my $oldval=Query->Param($self->{'PlugableSelektor'});
   my $originalMenuSelection=Query->Param("originalMenuSelection");
   my $title=$self->T($self->Self,$self->Self);
   my $submitOnEnter=$self->submitOnEnter();

   my %l=();
   my $DefaultFormat="HtmlV01";
   my $doAutoSearch=0;

   foreach my $m (values(%{$self->{SubDataObj}})){
      my $mlabel=$m->getLabel();
      $l{$mlabel}=$m;
      if ($oldval eq $m->Self()){
         if (length($mlabel)>30){
            $title="... &rArr; ".$mlabel;
         }
         else{
            $title.=" &rArr; ".$mlabel;
         }
      }
   }
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                   'kernel.App.Web.css','myw5base.css',
                                   'frames.css'],
                           title=>$title,
                           js=>['toolbox.js','subModal.js'],
                           body=>1,form=>1);
   print $self->HtmlSubModalDiv();
   #print Query->Dumper();
   print("<table width=\"100%\" height=\"100%\" border=0 ".
         "cellspacing=0 cellpadding=0>");
   printf("<tr><td height=\"1%%\" valign=top>%s</td></tr>",
          $self->getAppTitleBar(title=>$title));
   print("<tr><td height=\"1%\" valign=top>");
   print("<div class=searchframe><table class=searchframe>");
   my $selectname=$self->{'PlugableSelektor'};

   my $s="<input type=hidden name=originalMenuSelection ".
         " value=\"$originalMenuSelection\">".
         "<select name=\"$selectname\" style=\"width:100%\" ".
         "OnChange=\"SelectionChanged();\">";
   $s.="<option value=\"\">&lt;".$self->T("please select a query",$self->Self).
       "&gt;</option>";

   my $UserCache=$self->Cache->{User}->{Cache};
   $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   my %selectCache;
   my $lastGroup;
   foreach my $label (sort(grep(/^\[/,keys(%l))),
                      sort(grep(!/^\[/,keys(%l)))){
      my $curGroup="";
      if (my ($g)=$label=~m/^(.*):/){
         $curGroup=$g;
      }
      if ($curGroup ne $lastGroup){
         if (defined($lastGroup)){
            $s.="</optgroup>";
         }
         $s.="<optgroup label=\"$curGroup\">";
         $lastGroup=$curGroup;
      }
      my $useLabel=$label;
      if ($curGroup ne ""){
         my $qm=quotemeta($curGroup);
         $useLabel=~s/^$qm:\s*//;
      }
      if (defined($l{$label}) &&
          $l{$label}->can("isSelectable") && 
          $l{$label}->isSelectable(user=>$UserCache,cache=>\%selectCache)){
         $s.="<option ";
         $s.="selected " if ($l{$label}->Self() eq $oldval);
         $s.="value=\"".$l{$label}->Self()."\">$useLabel</option>";
      }
   }
   if (defined($lastGroup)){
      $s.="</optgroup>";
   }
   $s.="</select>";
   printf("<tr><td valign=top height=1%%>%s</td></tr>",$s);
   print("</table></div>");
   if (defined($oldval) && exists($self->{SubDataObj}->{$oldval})){
      my $curquery=$self->{SubDataObj}->{$oldval};
      my $o=$curquery->getDataObj();
      my $templ=$curquery->getQueryTemplate();
      $submitOnEnter=$curquery->submitOnEnter();
      $DefaultFormat=$curquery->getDefaultFormat();
      $doAutoSearch=$curquery->doAutoSearch();
      if (defined($o)){
         $o->ParseTemplateVars(\$templ);
      }
      printf("<tr><td valign=top height=1%%>%s</td></tr>",$templ);
      my $if;
      if ($curquery->can("Welcome")){
         $if="<iframe src=\"Welcome?".$self->{'PlugableSelektor'}."=$oldval\" ".
             "name=Result id=Result style=\"width:100%;height:100%\">".
             "</iframe>";
      }
      else{
         $if="<iframe src=\"../../base/load/loading\" ".
             "name=Result id=Result style=\"width:100%;height:100%\">".
             "</iframe>";
      }
      printf("<tr><td>%s</td></tr>",$if);
   }
   else{
      printf("<tr><td valign=top height=1%%>%s</td></tr>",
             $self->getWelcomeQueryTemplate());
      my $restempl=$self->getWelcomeResultTemplate();
      if ($restempl ne ""){
         printf("<tr><td>%s</td></tr>",$restempl);
      }
   }
   print("</td></tr></table>");
   my ($target,$action)=$self->getOperationTarget();
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
      if (document.forms[0].elements['$selectname'].value!=""){
         DoSearch();
      }
      return false;
   }
}
if ("$submitOnEnter"=="1"){
   document.onkeypress=keyhandler;
}
function inputkeyhandler()
{
   if (window.event && window.event.keyCode==13){
      if (document.forms[0].elements['$selectname'].value!=""){
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
   if (document.forms[0].elements['$selectname'].value!=""){
      DoSearch();
   }
   return(0);
}

function DoSearch()
{
   if ("$target"!="_self"){
      document.forms[0].target="$target";
   }
   document.forms[0].action="$action";
   document.forms[0].elements['FormatAs'].value="$DefaultFormat";
   document.forms[0].elements['UseLimit'].value='';
   document.forms[0].submit();
}

function SelectionChanged()
{
   var o=document.getElementById('Result');
   if (o){  // reset content of a posible existing Result iframe
      o.src="about:blank";
   }
   document.forms[0].target="_self";
   document.forms[0].action="Main";
   document.forms[0].submit();
}

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


sub Welcome
{
   my $self=shift;
   my $oldval=Query->Param($self->{'PlugableSelektor'});
   if (defined($oldval) && exists($self->{SubDataObj}->{$oldval})){
      return($self->{SubDataObj}->{$oldval}->Welcome());
   }
}

sub Result
{
   my $self=shift;

   my $oldval=Query->Param($self->{'PlugableSelektor'});
   if (defined($oldval) && exists($self->{SubDataObj}->{$oldval}) &&
       $self->{SubDataObj}->{$oldval}->can("Result")){
      my $curquery=$self->{SubDataObj}->{$oldval};
      my %data=Query->MultiVars();
      my $res=$curquery->Result(\%data);
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
   print "<table width=\"100%\" cellpadding=20><tr><td>";
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

   my $oldval=Query->Param($self->{'PlugableSelektor'});
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

   print $self->getParsedTemplate("tmpl/".
                                  $self->{'PlugableClass'}.".bookmarkform",
                                  {
                                    skinbase=>'base',
                                    static=>{BOOKM=>$BOOKM,
                                             REPL=>$repl}
                                  });
   #printf("Bookmark Handler");
   print("<input type=hidden name=SAVE value=\"1\">");
   print $self->HtmlPersistentVariables(qw(ALL));
   print $self->HtmlBottom(body=>1,form=>1);
   return(0);
}

sub getWelcomeQueryTemplate
{
   return("&nbsp;");
}


sub getWelcomeResultTemplate
{
   return("&nbsp;");
}


1;
