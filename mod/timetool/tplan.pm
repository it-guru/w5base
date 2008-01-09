package timetool::tplan;
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
use kernel::config;
use kernel::App::Web;
use kernel::Output;
use kernel::TabSelector;
use kernel::vbar;

@ISA    = qw(kernel::App::Web);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->LoadSubObjs("timetool","subsys");
   $self->{WidthList}=[qw(hour24 hour48 day14 day28 month1 month3 
                          month6 month12)];
   return($self);
}  

sub Main
{
   my $self=shift;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                   'kernel.App.Web.css'],
                           js=>['toolbox.js','kernel.App.Web.js','subModal.js'],
                           body=>1,form=>1);
   print $self->HtmlSubModalDiv();
   print ("<style>body{overflow:hidden}</style>");
   print("<table style=\"border-collapse:collapse;width:100%;height:100%\" ".
         "border=0 cellspacing=0 cellpadding=0>");
   printf("<tr><td colspan=2 height=1%% style=\"padding:1px\" ".
          "valign=top>%s</td></tr>",$self->getAppTitleBar());
   printf("<tr style=\"height:1%%\"><td colspan=2>%s</td></tr>",
          $self->getCalendarSelector());
   printf("<tr><td colspan=2 height=1%% style=\"padding:1px\">%s</td></tr>",
          $self->getCalendarSearchHeader());

   my %qu=Query->MultiVars();
   my $q=kernel::cgi::Hash2QueryString(%qu);

   my $welcomeurl="Result?$q";
   print(<<EOF);
<tr><td colspan=2><iframe class=result name="Result" src="$welcomeurl"></iframe></td></tr>
</table>
<script language="JavaScript">
function FinishModify()
{
   document.forms[0].submit();
}
function AddOrModify(calendar,q)
{
   q=jsAddVarToQueryString(q,"Calendar",calendar);
   showPopWin('AddOrModify?'+q,450,310,FinishModify);
}
</script>

EOF
   print $self->HtmlBottom(body=>1,form=>1);
}

sub getFunctionHeader
{
   my $self=shift;
   my $Calendar=Query->Param("Calendar");

   #my $add=$self->T("add entry");
   my $print=$self->T("print");

#   my $d=<<EOF;
#<a class=FunctionLink href=JavaScript:AddOrModify("$Calendar","")>$add</a> &bull; <a class=FunctionLink href="JavaScript:DoPrint()">$print</a>
#
#EOF
   my $d=<<EOF;
<a class=FunctionLink href="JavaScript:DoPrint()">$print</a> &nbsp;

EOF
   return($d);
}


sub getCalendarSelector
{
   my $self=shift;
   my @cal;
   foreach my $subsys (sort(keys(%{$self->{subsys}}))){
      push(@cal,$self->{subsys}->{$subsys}->getCalendars());
   }
     # ToDo : order the entries


   my $oldval=Query->Param("Calendar");
   if ($oldval eq "" && $cal[0] ne ""){
      $oldval=$cal[0];
      Query->Param("Calendar"=>$cal[0]);
   }
   my $c="<select name=Calendar onChange=\"document.forms[0].submit();\" ".
         "style=\"width:100%\">";
   while(my $entry=shift(@cal)){
      my $level=shift(@cal);
      my $name=shift(@cal);
      $c.="<option value=\"$entry\"";
      $c.=" selected" if ($oldval eq $entry);
      $c.=">$name</option>";
   }
   $c.="</select>";
   my $planselection=$self->T("plan selection");
   my $f=$self->getFunctionHeader();

   my $d=<<EOF;
<table border=0 width=100% cellspacing=0 cellpadding=0><tr>
<td width=1% nowrap>&nbsp;$planselection:&nbsp;</td><td width=35%>$c</td><td align=right>$f</td></tr>
</table>
EOF
   return($d);
}
  

sub getCalendarSearchHeader
{
   my $self=shift;
   my $Calendar=Query->Param("Calendar");
   my ($subsys,$id)=split(/;/,$Calendar);

   my $CalendarStart=Query->Param("CalendarStart");
   if ($CalendarStart eq ""){
      $CalendarStart=$self->T("today");
      Query->Param("CalendarStart"=>$CalendarStart);
   }

   my $oldval=Query->Param("CalendarWidth");
   if ($oldval eq ""){
      $oldval="day28";
      Query->Param("CalendarWidth"=>$oldval);
   }
   my $w="<select name=CalendarWidth onChange=\"document.forms[0].submit()\" ".
         "style=\"width:100px\">";
   foreach my $width (@{$self->{WidthList}}){
      $w.="<option value=\"$width\"";
      $w.=" selected" if ($oldval eq $width);
      $w.=">".$self->T($width)."</option>";
   }
   $w.="</select>";

   my $planstart=$self->T("plan start");
   my $refresh=$self->T("refresh");
   my $width=$self->T("plan width");

   my $addsearch=$self->{subsys}->{$subsys}->getAdditionalSearchMask();


   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe width=100%>
<tr class=fline>
<td width=1% nowrap>$planstart:</td>
<td width=1%><input type=text name=CalendarStart value="$CalendarStart"></td>
<td width=1% nowrap>$width:</td><td width=140>$w</td>
<td>$addsearch</td>
<td width=1%><input type=submit value="$refresh"></td>
</tr>
</table>
</div>

EOF
}

sub Result
{
   my $self=shift;
   my $CalendarStart=Query->Param("CalendarStart");
   my $CalendarWidth=Query->Param("CalendarWidth");
   $CalendarWidth="day28" if ($CalendarWidth eq "");
   my $Calendar=Query->Param("Calendar");
printf STDERR ("fifi Calendar=$Calendar\n");
   my ($subsys,$id)=split(/;/,$Calendar);
   my ($calmode,$width)=$CalendarWidth=~m/^([a-z]+)(\d+)$/;
   my $usertimezone;

   if ($subsys eq "" || !defined($self->{subsys}->{$subsys})){
      print $self->HttpHeader("text/plain");
      print("nopan subsys=$subsys\n");
      return();
   }
   {  # calc timezone
      my $UserCache=$self->Cache->{User}->{Cache};
      if (defined($UserCache->{$ENV{REMOTE_USER}})){
         $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
      }
      if (defined($UserCache->{tz})){
         $usertimezone=$UserCache->{tz};
      }
      $usertimezone="GMT" if ($usertimezone eq "");
   }

   my $starttime=$self->ExpandTimeExpression($CalendarStart,"en",
                                             $usertimezone,$usertimezone);
   if ($starttime eq ""){
      if ($self->LastMsg()==0){
         $self->LastMsg(ERROR,"unknown error while expanding time expression");
      }
   }
   if ($self->LastMsg()!=0){
      my $lastmsg=$self->findtemplvar({},"LASTMSG");
      print $self->HttpHeader("text/html");
      print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                      'kernel.App.Web.css']);
      print $lastmsg;
      print $self->HtmlBottom();
      return();
   }
   my $endtime=$starttime;
   if ($calmode eq "day"){
      ($starttime)=$starttime=~m/(\d{4}-\d{2}-\d{2})/;
      $starttime.=" 00:00:00";
      $endtime="$starttime+${width}d";
   }
   if ($calmode eq "hour"){
      ($starttime)=$starttime=~m/(\d{4}-\d{2}-\d{2} \d+)/;
      $starttime.=":00:00";
      $endtime="$starttime+${width}h";
   }
   if ($calmode eq "month"){
      ($starttime)=$starttime=~m/(\d{4}-\d{2})/;
      $starttime.="-01 00:00:00";
      $endtime="$starttime+${width}M";
      my ($y,$m)=$starttime=~m/^(\d{4})-(\d{2})-/;
      if ($width==1){
         $calmode="day";
         $width=Days_in_Month($y,$m);
         $endtime="$starttime+${width}d";
      }
   }
   $endtime=$self->ExpandTimeExpression($endtime,"en",
                                        $usertimezone,$usertimezone);
   my $starttimesec=Date_to_Time($usertimezone,$starttime);

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                   'kernel.App.Web.css',
                                   'public/timetool/load/timetool.css'],
                           js=>['toolbox.js','subModal.js'],
                           body=>1,form=>1);
   my $addstore="";
   foreach my $qv (Query->Param()){
      if ($qv=~m/^search_/){
         my $v=Query->Param($qv);
         if ($v ne ""){
            $v=~s/'/\\'/g;
            $addstore.="q=jsAddVarToQueryString(q,'$qv','$v');\n";
         }
      }
   }
   if ($id ne ""){
      $addstore.="q=jsAddVarToQueryString(q,'TimeplanID','$id');\n";
   }


   print(<<EOF);
<script language="JavaScript">
function AddFromMark(selNode,markbar,selStart,selEnd)
{
   var seg0=document.getElementById(selNode.id+"_seg0");
   if (seg0){
      var StartSegment=Math.round(selStart/seg0.offsetWidth);
      var EndSegment=Math.round(selEnd/seg0.offsetWidth);
      var StartSecond=$starttimesec;
      var CalMode="$calmode";
      var q="";
      //alert("StartSegment="+StartSegment+" EndSegment="+EndSegment+
      //      " selStart="+selStart+" selEnd"+selEnd);
      q=jsAddVarToQueryString(q,"CalMode",CalMode);
      q=jsAddVarToQueryString(q,"StartSecond",StartSecond);
      q=jsAddVarToQueryString(q,"StartSegment",StartSegment);
      q=jsAddVarToQueryString(q,"EndSegment",EndSegment);
      q=jsAddVarToQueryString(q,"name",selNode.id);
      $addstore
      parent.AddOrModify('$Calendar',q);
   }
}
</script>
<style>
.bar{
   border-style:solid;
   border-width:1px;
}
</style>
EOF
   my $vbar=new kernel::vbar(onMarkAction=>'AddFromMark');
   $self->{subsys}->{$subsys}->AddLineLabels($vbar,$id);
   $self->{subsys}->{$subsys}->ProcessSpans($vbar,$starttime,$endtime,
                                            $usertimezone,$id);
   $vbar->SetSegmentation($width);
   $self->{subsys}->{$subsys}->AddColumnLabels($vbar,$starttime,
                                               $calmode,$width,
                                               $usertimezone);
   
   #printf("timezone=%s start=%s calmode=$calmode width=$width CalendarStart=$CalendarStart<br><hr>",$usertimezone,$starttime);

   print("<table width=100%><tr><td align=center>");   
   print $vbar->init();
   print $self->{subsys}->{$subsys}->Header($starttime,$endtime,$usertimezone);
   print $vbar->render();
   print $self->{subsys}->{$subsys}->Bottom($starttime,$endtime,$usertimezone);
   print("</td></tr></table>");
   print $self->HtmlBottom(body=>1,form=>1);
}

sub AddOrModify
{
   my $self=shift;
   my $Calendar=Query->Param("Calendar");
   my $tspanid=Query->Param("TSpanID");
   my ($subsys,$id)=split(/;/,$Calendar);
   my $usertimezone;
   {  # calc timezone
      my $UserCache=$self->Cache->{User}->{Cache};
      if (defined($UserCache->{$ENV{REMOTE_USER}})){
         $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
      }
      if (defined($UserCache->{tz})){
         $usertimezone=$UserCache->{tz};
      }
      $usertimezone="GMT" if ($usertimezone eq "");
   }

   my $subsysform=$self->{subsys}->{$subsys}->getAddOrModifyForm($usertimezone,
                                                                 $tspanid);
   print($subsysform);
}


sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),
          qw(Result Main Welcome AddOrModify));
}







1;
