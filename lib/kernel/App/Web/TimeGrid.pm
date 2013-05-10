package kernel::App::Web::TimeGrid;
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
######################################################################
use vars qw(@ISA);
use kernel;
use kernel::date;
use kernel::App::Web;
use kernel::TabSelector;
use kernel::App::Web::TimeGrid;
@ISA=qw(kernel::App::Web::Listedit);


##########################################################################
#  TimeGrid Backcalls
#
sub getValidWebFunctions
{  
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),
          qw(TimeGrid TimeGridMain));
}

sub getTimeGridFunctions
{
   my $self=shift;

   return("TimeGridFunctionA","TimeGridFunctionB","TimeGridFunctionC");
}

sub getTimeGridJavaScriptCode
{
   my $self=shift;

   return("");
}


sub TimeGrid
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'public/timetool/load/TimeGrid.css'],
                           body=>1,form=>1,
                           title=>"TimeGrid");
   my $name="ModeSelect";
   my $activpage=Query->Param($name."CurrentMode");
   my $base=Query->Param("base");
   my $todaybase=$self->ExpandTimeExpression("now","stamp");
   if (!($base=~m/^\d{14}$/)){
      $base=$todaybase;
   }
   Query->Param("base"=>$base);
   $activpage="yearV1" if ($activpage eq "");
   Query->Param($name."CurrentMode"=>$activpage);

   my $page="<iframe frameborder=0 class=TimeGridMain name=TimeGridMain ".
            "src=\"TimeGridMain?Mode=$activpage&base=$base\"></iframe>";
   my %param=(functions=>['FunctionA' => $self->T("FunctionA"),
                          'FunctionB' => $self->T("FunctionB"),
                          'SetToday' => $self->T("SetToday")],
              pages=>    [
                          'dayV1'     => $self->T("dayV1"),
                          'weekV1'    => $self->T("weekV1"),
                          'monthV1'   => $self->T("monthV1"),
                          'yearV1'    => $self->T("yearV1"),
                          'dayV2'     => $self->T("dayV2"),
                          'weekV2'    => $self->T("weekV2"),
                          'monthV2'   => $self->T("monthV2"),
                          'yearV2'    => $self->T("yearV2"),
                         ],
              tabwidth    =>"10%",
              topline     =>$self->getAppTitleBar(),
              activpage   =>$activpage,
              page        =>$page,
             );
   print <<EOF;
<script language="JavaScript">
function SetToday()
{
   SetBase('$todaybase');
}
function SetBase(n)
{
   document.forms[0].elements['base'].value=n;
   document.forms[0].submit();
}
</script>
EOF
   print TabSelectorTool($name,%param);
   print ($self->HtmlPersistentVariables("base"));
   print $self->HtmlBottom(body=>1,form=>1);
}

sub TimeGridMain
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css','WebCalendar.css',
                                   'public/timetool/load/TimeGrid.css',
                                   'public/timetool/load/TimeGridMain.css'],
                           js=>['TimeGrid.js'],
                           body=>1,form=>1,
                           title=>"TimeGrid");
   my $mode=Query->Param("Mode");
   my $base=Query->Param("base");
   print("<center>");
   print($self->WebCalendar("RecSys",base=>$base,
                              lang=>$self->Lang(),
                              setbasefunc =>'parent.SetBase',
                              data=>[
                                     {
                                      label=>"Zeile 1",
                                     },
                                     {
                                      label=>"Zeile 2 asdfjhasd fsdjfh sdj fjksdfh sdfhkasdfaksdfksdf vjh dfvhas",
                                     },
                                     {
                                      label=>"Zeile 3 yyyyyyyyyyyyyyyyyyy",
                                     },
                                     {
                                      label=>"Andreas, Wieschollek (andreas.wieschollek\@xxxxxxxxx.com)",
                                     },
                                     {
                                      label=>"Vogler, Hartmut (hartmut.vogler\@xxxxxxxxx.com)",
                                     }
                                    ],
                              mode=>$mode));

   print $self->HtmlBottom(body=>1,form=>1);
}

sub WebCalendar
{
   my $self=shift;
   my $name=shift;
   my %param=@_;
   my $d="";
   my ($Y,$M,$D,$T)=$param{base}=~/^(\d{4})(\d{2})(\d{2})(\d+)$/;
   $param{lang}="en" if (!defined($param{lang}));
   $param{data}=[]   if (!defined($param{data})|| ref($param{data}) ne "ARRAY");
   Language(Decode_Language($param{lang}));
   if ($param{mode} eq "dayV1"){
      my $mname=Month_to_Text($M);
      my ($week,$year)=Week_of_Year($Y,$M,$D);;
      my $c=Day_of_Week($Y,$M,$D);
      my $l=Day_of_Week_to_Text($c);
      my ($nY,$nM,$nD)=Add_Delta_YMD($Y,$M,$D,0,0,1);
      my ($pY,$pM,$pD)=Add_Delta_YMD($Y,$M,$D,0,0,-1);
      my $nbase=sprintf("%04d%02d%02d000000",$nY,$nM,$nD);
      my $pbase=sprintf("%04d%02d%02d000000",$pY,$pM,$pD);
      $d.="<table class=WebCalendar border=0>";
      $d.="<tr height=1%><td align=center class=WebCalendarHeader>".
          WebCalendarHeader($param{setbasefunc},$pbase,$nbase,
                            "$year KW$week","$l der $D. $mname").
          "</td></tr>";
      $d.="<tr><td>";
      my $val=WebCalendarDayDefaultData("dayV1",$Y,$M,$D);
      $d.=$val."</td></tr>";
      $d.="</table>";
   }
   if ($param{mode} eq "weekV1"){
      my $mname=Month_to_Text($M);
      my ($week,$year)=Week_of_Year($Y,$M,$D);;
      my ($nY,$nM,$nD)=Add_Delta_YMD($Y,$M,$D,0,0,7);
      my ($pY,$pM,$pD)=Add_Delta_YMD($Y,$M,$D,0,0,-7);
      my $nbase=sprintf("%04d%02d%02d000000",$nY,$nM,$nD);
      my $pbase=sprintf("%04d%02d%02d000000",$pY,$pM,$pD);
      $d.="<table class=WebCalendar border=0>";
      $d.="<tr height=1%><td align=center class=WebCalendarHeader>".
          WebCalendarHeader($param{setbasefunc},$pbase,$nbase,
                            "$year KW$week",$mname)."</td></tr>";
      $d.="<tr><td>";
      my $val=WebCalendarWeekDefaultData("weekV1",$Y,$M,$D);
      $d.=$val."</td></tr>";
      $d.="</table>";
   }
   if ($param{mode} eq "monthV1"){
      my $mname=Month_to_Text($M);
      my $nbase=sprintf("%04d%02d%02d000000",$Y,$M+1,1);
      my $pbase=sprintf("%04d%02d%02d000000",$Y,$M-1,1);
      $nbase=sprintf("%04d%02d%02d000000",$Y+1,1,1) if ($M==12);
      $pbase=sprintf("%04d%02d%02d000000",$Y-1,12,1) if ($M==1);
      $d.="<table class=WebCalendar border=0>";
      $d.="<tr height=1%><td align=center class=WebCalendarHeader>".
          WebCalendarHeader($param{setbasefunc},$pbase,$nbase,$mname,$Y).
          "</td></tr>";
      $d.="<tr><td>";
      my $val=WebCalendarMonthV1Data("monthV1",$Y,$M);
      $d.=$val."</td></tr>";
      $d.="</table>";
   }
   if ($param{mode} eq "monthV2"){
      my $mname=Month_to_Text($M);
      my $nbase=sprintf("%04d%02d%02d000000",$Y,$M+1,1);
      my $pbase=sprintf("%04d%02d%02d000000",$Y,$M-1,1);
      $nbase=sprintf("%04d%02d%02d000000",$Y+1,1,1) if ($M==12);
      $pbase=sprintf("%04d%02d%02d000000",$Y-1,12,1) if ($M==1);
      $d.="<table class=WebCalendar border=0>";
      $d.="<tr height=1%><td align=center class=WebCalendarHeader>".
          WebCalendarHeader($param{setbasefunc},$pbase,$nbase,"","").
          "</td></tr>";
      $d.="<tr><td>";
      my $val=WebCalendarMonthV2Data("monthV2",$Y,$M,$D,\%param);
      $d.=$val."</td></tr>";
      $d.="</table>";
   }
   if ($param{mode} eq "yearV1"){
      my $cols=3;
      my $nbase=sprintf("%04d%02d%02d000000",$Y+1,$M,$D);
      my $pbase=sprintf("%04d%02d%02d000000",$Y-1,$M,$D);
      $d.="<table class=WebCalendar border=0>";
      $d.="<tr height=1%><td align=center ".
          "class=WebCalendarHeader colspan=$cols>".
          WebCalendarHeader($param{setbasefunc},$pbase,$nbase,$Y)."</td></tr>";
      $d.="<tr>";
      my $c=0;
      for(my $m=1;$m<=12;$m++){
         my $w=int(100.0/$cols);
         $d.="</tr><tr>" if ($c % $cols==0);
         my $val=$param{data}->[$m];
         $val=WebCalendarMonthV1Data("YearV1",$Y,$m) if (!defined($val));
         $d.="<td style=\"width:$w%\" align=center ".
             "class=yearV1monthLabel valign=top>".
             "<div style=\"width:100%;text-align:left\">".
             "<div style=\"width:100%;text-align:center\">".
             Month_to_Text($m).
             "</div>".
             "<div style=\"width:100%;\">$val</div>";
             "</div>".
             "</td>";
         $c++;
      }
      $d.="</tr>";
      $d.="</table>";
   }
   $d.="<input type=hidden name=base value=\"$param{base}\">";
   return($d);
}

sub WebCalendarHeader
{
   my $basefunc=shift;
   my $pbase=shift;
   my $nbase=shift;
   my $l1=shift;
   my $l2=shift;


   my $str=$l1;
   $str.="- $l2" if ($l2 ne "");
   my $nextlink="<a href=JavaScript:SetBase('$nbase')>N</a>";
   my $prevlink="<a href=JavaScript:SetBase('$pbase')>P</a>";
   my $tl=<<EOF;
<script language="JavaScript">
function SetBase(newBase)
{
   ${basefunc}(newBase);
}
</script>
<table width="100%" cellspacing=0 cellpadding=0 border=0>
<tr><td width=1% valign=center align=left>$prevlink</td>
<td align=center>$str</td>
<td width=1% valign=center align=right>$nextlink</td></tr></table>
EOF
   return($tl);
}

sub WebCalendarDayDefaultData
{
   my ($name,$y,$m)=@_;
   my $d="<table class=$name>";
   for(my $c=0;$c<=23;$c++){
      $d.="<tr class=$name>".
          "<td width=1% class=${name}hour>".sprintf("%02d",$c)."</td>";
      $d.="<td class=${name}data>&nbsp;</td>";
      $d.="</td>";
   }
   $d.="</table>";
   return($d);
}

sub WebCalendarWeekDefaultData
{
   my ($name,$y,$m,$d)=@_;
   my $d="<table cellspacing=0 cellpadding=0 class=$name>";
   $d.="<tr>";
   for(my $c=1;$c<=7;$c++){
      $d.="<td align=center class=${name}dateLabel>$c</td>";
   }
   $d.="</tr>";
   $d.="<tr>";
   for(my $c=1;$c<=7;$c++){
      my $l=substr(Day_of_Week_to_Text($c),0,2);
      $d.="<td align=center class=${name}dayLabel>$l</td>";
   }
   $d.="</tr>";
   $d.="<tr>";
   for(my $c=1;$c<=7;$c++){
      $d.="<td align=center class=${name}data></td>";
   }
   $d.="</tr>";


   $d.="</table>"; 
   return($d);
}

sub WebCalendarMonthV2Data
{
   my ($name,$y,$m,$d,$param)=@_;
   my $d="";
   my $s="";
   $d.="<div style=\"position:absolute;padding:0;margin:0;border-width:0\">";
   $s.="<div style=\"position:absolute;padding:0;margin:0;border-width:0\">";
   $d.="<table cellspacing=0 cellpadding=0 class=$name>";
   $s.="<table cellspacing=0 cellpadding=0 class=$name>";
#   $d.="<tr height=1%><td width=1% class=${name}kwLabel>KW</td>";
#   for(my $c=1;$c<=7;$c++){
#      my $l=substr(Day_of_Week_to_Text($c),0,2);
#      $d.="<td align=center class=${name}dayLabel>$l</td>";
#   }
#   my $c=Day_of_Week($y,$m,1)-1;
#   my ($week,$year)=Week_of_Year($y,$m,1);
   $d.="<tr height=1%><td></td>";
   $s.="<tr height=1%><td></td>";
   my $days=Days_in_Month($y,$m);
   for(my $day=1;$day<=$days;$day++){
      $d.="<td valign=top class=${name}day><center>$day</center></td>";
      $s.="<td valign=top class=${name}day><center>$day</center></td>";
   }
   $d.="</tr>";
   $s.="</tr>";
   if (defined($param->{data})){
      my $dat=$param->{data};
      for(my $c=0;$c<=$#{$dat};$c++){
         my $rec=$dat->[$c];
         $d.="<tr height=1%>";
         $s.="<tr height=1%>";
         $d.="<td class=${name}dataLabel>$rec->{label}</td>";
         $s.="<td class=${name}dataLabel>$rec->{label}</td>";
         for(my $day=1;$day<=$days;$day++){
            $d.="<td valign=top align=center>x</td>";
         }
         $s.="<td valign=top align=center colspan=$days>x</td>";
         $d.="</tr>";
         $s.="</tr>";
      }
   }
   
   $d.="</table>";
   $s.="</table>";
   $d.="</div>";
   $s.="</div>";

   return("<div style=\"width:100%;height:100%\">".$d.$s."</div>");
}

sub WebCalendarMonthV1Data
{
   my ($name,$y,$m)=@_;
   my $d="<table cellspacing=0 cellpadding=0 class=$name>";
   $d.="<tr height=1%><td width=1% class=${name}kwLabel>KW</td>";
   for(my $c=1;$c<=7;$c++){
      my $l=substr(Day_of_Week_to_Text($c),0,2);
      $d.="<td align=center class=${name}dayLabel>$l</td>";
   }
   my $c=Day_of_Week($y,$m,1)-1;
   my ($week,$year)=Week_of_Year($y,$m,1);
   $d.="</tr><tr>";
   $d.="<td align=right class=${name}kw>$week</td>";
   $d.="<td colspan=".($c)."></td>" if ($c>0);
   my $days=Days_in_Month($y,$m);
   for(my $day=1;$day<=$days;$day++){
      $d.="<td valign=top class=${name}day><center>$day</center></td>";
      $c++;
      if (($c)%7==0 && $day<$days){
         my ($week,$year)=Week_of_Year(Add_Delta_YMD($y,$m,$day,0,0,1));
         $d.="</tr><tr><td align=right class=${name}kw>$week</td>";
      }
   }
   if (($c)%7>0){
      $d.="<td colspan=".((8-($c)%7))."></td>";
   }
   $d.="</tr>";
   $d.="</table>";

}





##########################################################################
1;
