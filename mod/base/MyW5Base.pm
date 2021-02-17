package base::MyW5Base;
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
use kernel::PlugableController;
@ISA    = qw(kernel::PlugableController);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{'PlugableClass'}='MyW5Base';
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}  

sub getWelcomeQueryTemplate
{
   my $self=shift;


   my $userid=$self->getCurrentUserId();
   my $bm=$self->getPersistentModuleObject("BookMark","base::userbookmark");
   $bm->ResetFilter();
   $bm->SetFilter({userid=>\$userid});
   my @bm=$bm->getHashList(qw(name srclink target));
   my $l1=$self->T("monitor my workflows");
   my $l2=$self->T("my current jobs");
   my $l3=$self->T("start a new workflow");
   my $mywf  ="<a tabindex=12 href=\"../MyW5Base/Main?".
              "MyW5BaseSUBMOD=base::MyW5Base::mywf\">".
              "<img border=0 src=\"../../base/load/MyW5Base-MyWf.jpg\">".
              "</a>";
   my $myjobs="<a tabindex=11 href=\"../MyW5Base/Main?".
              "MyW5BaseSUBMOD=base::MyW5Base::wfmyjobs\">".
              "<img border=0 src=\"../../base/load/MyW5Base-MyJobs.jpg\">".
              "</a>";
   my $newwf ="<a tabindex=10 href=\"../workflow/New\">".
              "<img border=0 src=\"../../base/load/MyW5Base-NewWf.jpg\">".
              "</a>";
   my $newstext=$self->getNews();
   $newstext=$self->addNewsFrame($newstext) if ($newstext ne "");
   my $d;
   if ($#bm==-1){
      $d=<<EOF;
<tr><td valign=top align=center><br><br>
<table width="80%" border=0>
<tr>
<td align=center width="20%">$mywf</td><td align=center width="20%">&nbsp;</td>
<td align=center width="20%">$myjobs</td><td align=center width="20%">&nbsp;</td>
<td align=center width="20%">$newwf</td>
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
              "<table width=\"100%\" cellspacing=0 cellpadding=0 border=0>".
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
         if ($b->{target} eq "fullscreen"){
            my $onclick="openwin(\"$b->{srclink}\",\"fullscreen\",".
                    "\"height=480,width=640,toolbar=no,status=no,".
                    "resizable=yes,scrollbars=no\")";
            $link="<a class=bookmark href=javascript:$onclick>";
         }
         if ($b->{srclink}=~m/^javascript:/i){
            $link="<a class=bookmark target=_self href=$b->{srclink}>";
         }
         my $name=quoteHtml($b->{name});
         
         $bmdiv.="<li class=bookmark>$link".$name."</a></li>";
      }
      $bmdiv.="</ul>";

      $bmdiv.="</div></div>";
      my $qf=getModuleObject($self->Config,"faq::QuickFind");
      my $quickfind;
      if (defined($qf)){
         $quickfind=$self->addQuickFind($qf);
      }
      $d=<<EOF;
<tr><td valign=top align=center>
<table width="100%" border=0>
<td valign=top>$bmdiv
$newstext
</td>
<td width="40%" valign=top>
<div class=winframe id=workflowlinks>

<div class=winframehead>Workflow Links:</div>
<table width="99%">
<tr>
<td align=center width="50%">$mywf</td>
<td align=center width="50%">$newwf</td>
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



   # add resising methods as javascript for news page
   $d.=<<EOF;

<script language="JavaScript">
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

   return($d);

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
<table width="100%" border=1>
<tr>
<td>
<input style="width:100%" type=text value="" name=searchtext>
</td>
<td width="1%">
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
           "<table width=\"100%\" cellspacing=0 cellpadding=0 border=0>".
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
      $d.="<table width=\"100%\" border=0 cellspacing=0>";
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
         my $bstart="";
         my $bend="";
         my $dd=CalcDateDuration($cdate,NowStamp("en"));
         if (defined($dd) && $dd->{totaldays}<15){
            $bstart="<b>";
            $bend="</b>";
         }
         $cdate=$self->ExpandTimeExpression($cdate,"ultrashort","GMT",$utz);
         if ($rec->{entrycount}>0){
            $name.=" ($rec->{entrycount})";
         }
         my $link="openwin(\"../../faq/forum/Topic/$rec->{id}".
                  "&AllowClose=1\",\"_blank\",".
                  "\"height=520,width=640,toolbar=no,".
                  "status=no,resizable=yes,scrollbars=auto\")";
         $d.="<tr height=24 class=newsline$newsline>".
             "<td width=25 align=center valign=center>$icon</td>".
             "<td valign=center><a href=JavaScript:$link class=news>".
             $bstart.$name.$bend.
             "</a> ".
             "</td><td width=1% nowrap align=center>".
             $bstart.$cdate.$bend.
             "</td></tr>";
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
   if ($self->LastMsg()==0){
      $self->LastMsg(ERROR,"the requested query isn't supported or ".
                           "has internal errors procreated");
   }
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

sub Welcome
{
   my $self=shift;

   my $oldval=Query->Param("MyW5BaseSUBMOD");
   if (defined($oldval) && exists($self->{SubDataObj}->{$oldval}) &&
       $self->{SubDataObj}->{$oldval}->can("Welcome")){
      my $curquery=$self->{SubDataObj}->{$oldval};
      my $res=$curquery->Welcome();
      return($res) if (defined($res));
   }
   return($self->SUPER::Welcome());
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




1;
