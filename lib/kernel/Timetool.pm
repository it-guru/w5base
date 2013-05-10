package kernel::Timetool;
#  W5Base Framework
#  Copyright (C) 2002  Hartmut Vogler (hartmut.vogler@epost.de)
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
#
use vars qw(@ISA);
use strict;
use kernel;
use kernel::date;
use kernel::SubDataObj;

@ISA=qw(kernel::SubDataObj);

sub new
{
   my $type=shift;
   my $self=bless({@_},$type);
   return($self);
}

sub NavBar
{
   my $self=shift;
   my $starttime=shift;
   my $endtime=shift;
   my $tz=shift;
   my $d=shift;

   $d.=<<EOF;
<table width="100%" border=0>
<tr>
<td width=1%><div class=navigation><a href="JavaScript:prev()" title="prev"><img border=0 src="../../../public/base/load/button_prev.gif"></a></div></td>
<td align=center valign=bottom><span class=headline>$self->{headline}</span>&nbsp; &nbsp;&nbsp;</td>
<td width=1%><div class=navigation><a href="JavaScript:next()" title="next"><img border=0 src="../../../public/base/load/button_next.gif"></a></div></td>
</tr>
</table>
<script language="JavaScript">
function next()
{
   var s=parent.document.forms[0].elements['CalendarStart'];
   var w=parent.document.forms[0].elements['CalendarWidth'];
   if (l=w.value.match("^day([0-9]+)\$")){
      if (o=s.value.match("([+\\-])([0-9]+)d\$")){
         if (o[1]=="+"){
            o[2]=parseInt(o[2])+parseInt(l[1]/2);
         }
         if (o[1]=="-"){
            o[2]=parseInt(o[2])-parseInt(l[1]/2);
         }
         if (o[2]<0){
            o[1]="-";
         }
         s.value=s.value.replace(/([+\\-])([0-9]+)d\$/,"");
         if (o[2]!=0){
            s.value=s.value+o[1]+o[2]+"d";
         }
      }
      else{
         s.value=s.value+"+"+parseInt(l[1]/2)+"d";
      }
   }
   if (l=w.value.match("^hour([0-9]+)\$")){
      if (o=s.value.match("([+\\-])([0-9]+)h\$")){
         if (o[1]=="+"){
            o[2]=parseInt(o[2])+parseInt(l[1]/2);
         }
         if (o[1]=="-"){
            o[2]=parseInt(o[2])-parseInt(l[1]/2);
         }
         if (o[2]<0){
            o[1]="-";
         }
         s.value=s.value.replace(/([+\\-])([0-9]+)h\$/,"");
         if (o[2]!=0){
            s.value=s.value+o[1]+o[2]+"h";
         }
      }
      else{
         s.value=s.value+"+"+parseInt(l[1]/2)+"h";
      }
   }
   if (l=w.value.match("^month([0-9]+)\$")){
      if (o=s.value.match("([+\\-])([0-9]+)h\$")){
         if (o[1]=="+"){
            o[2]=parseInt(o[2])+1;
         }
         if (o[1]=="-"){
            o[2]=parseInt(o[2])-1;
         }
         if (o[2]<0){
            o[1]="-";
         }
         s.value=s.value.replace(/([+\\-])([0-9]+)M\$/,"");
         if (o[2]!=0){
            s.value=s.value+o[1]+o[2]+"M";
         }
      }
      else{
         s.value=s.value+"+1M";
      }
   }
   parent.document.forms[0].submit();
}
function prev()
{
   var s=parent.document.forms[0].elements['CalendarStart'];
   var w=parent.document.forms[0].elements['CalendarWidth'];
   if (l=w.value.match("^day([0-9]+)\$")){
      if (o=s.value.match("([+\\-])([0-9]+)d\$")){
         if (o[1]=="+"){
            o[2]=parseInt(o[2])-parseInt(l[1]/2);
         }
         if (o[1]=="-"){
            o[2]=parseInt(o[2])+parseInt(l[1]/2);
         }
         if (o[2]<0){
            o[1]="-";
         }
         s.value=s.value.replace(/([+\\-])([0-9]+)d\$/,"");
         if (o[2]!=0){
            s.value=s.value+o[1]+o[2]+"d";
         }
      }
      else{
         s.value=s.value+"-"+parseInt(l[1]/2)+"d";
      }
   }
   if (l=w.value.match("^hour([0-9]+)\$")){
      if (o=s.value.match("([+\\-])([0-9]+)h\$")){
         if (o[1]=="+"){
            o[2]=parseInt(o[2])-(l[1]/2);
         }
         if (o[1]=="-"){
            o[2]=parseInt(o[2])+(l[1]/2);
         }
         if (o[2]<0){
            o[1]="-";
         }
         s.value=s.value.replace(/([+\\-])([0-9]+)h\$/,"");
         if (o[2]!=0){
            s.value=s.value+o[1]+o[2]+"h";
         }
      }
      else{
         s.value=s.value+"-"+parseInt(l[1]/2)+"h";
      }
   }
   if (l=w.value.match("^month([0-9]+)\$")){
      if (o=s.value.match("([+\\-])([0-9]+)M\$")){
         if (o[1]=="+"){
            o[2]=parseInt(o[2])-1;
         }
         if (o[1]=="-"){
            o[2]=parseInt(o[2])+1;
         }
         if (o[2]<0){
            o[1]="-";
         }
         s.value=s.value.replace(/([+\\-])([0-9]+)M\$/,"");
         if (o[2]!=0){
            s.value=s.value+o[1]+o[2]+"M";
         }
      }
      else{
         s.value=s.value+"-1M";
      }
   }
   parent.document.forms[0].submit();
}
</script>
<style>
.headline{
}
\@media print {
   .navigation{
      display:none;
      visibility:hidden;
   }
}
</style>
EOF

   return($d);
}


sub Header
{
   my $self=shift;
   my $starttime=shift;
   my $endtime=shift;
   my $tz=shift;
   return($self->NavBar($starttime,$endtime,$tz));
}

sub Bottom
{
   my $self=shift;
   my $starttime=shift;
   my $endtime=shift;
   my $tz=shift;

   return("");
}

sub getCalendars
{
   my $self=shift;

   return;

}

sub getCalendarModes
{
   my $self=shift;

   return;

}

sub getSubsysName
{
   my $self=shift;

   return($self->Self());
}


sub AddLineLabels
{
   my $self=shift;
   my $vbar=shift;
   my $id=shift;

   $vbar->SetLabel("-","&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; ");
}



sub getAddOrModifyForm
{
   my $self=shift;
   my $tz=shift;
   my $TSpanID=shift;
   my $TSpanRec=undef;
   my $NeedRefresh=Query->Param("NeedRefresh");

   my $tspan=$self->getParent->getPersistentModuleObject("timetool::tspan");
   if (!defined($TSpanID)){
      my $calmode=Query->Param("CalMode");
      if ($calmode ne ""){
         $self->InitNewRecordQuery($tz);
      }
   }
   else{
      $tspan->SetFilter({id=>\$TSpanID});
      my ($rec,$msg)=$tspan->getOnlyFirst(qw(ALL));
      $TSpanRec=$rec;
      my $lang=$self->getParent->Lang();
   }
   my ($Operation,$NeedRefresh);
   ($Operation,$TSpanRec,$TSpanID,$NeedRefresh)=
               $self->ProcessDataModificationOP($TSpanID,$TSpanRec,$tz,
                                                                 $NeedRefresh);
   if ($Operation && $self->getParent->LastMsg()==0){
      my $d=$self->getParent->HttpHeader("text/html");
      $d.=<<EOF;
<script language="JavaScript">
parent.hidePopWin(true);
</script>
EOF
      return($d);
   }
   my $writeok=$self->isWriteValid($TSpanRec);
   if (!$writeok && !defined($TSpanRec)){
      return($self->noAccess());
   }
   my $d=$self->getParent->HttpHeader("text/html");
   my $t=$self->getParent->T("create timespan entry","kernel::Timetool");
   if (defined($TSpanID)){
      $t=$self->getParent->T("modify timespan entry","kernel::Timetool");
   }
   $d.=$self->getParent->HtmlHeader(style=>['default.css','mainwork.css',
                                   'kernel.App.Web.css',
                                   'Output.HtmlDetail.css'],
                           title=>$t,
                           js=>['toolbox.js','subModal.js'],
                           body=>1,form=>1);
   my $mode="edit";
   $mode="HtmlV01" if (!$writeok);

   my $subsysform=$self->getAddOrModifySubsysForm($tz,$TSpanRec,$writeok);
   my $Calendar=Query->Param("Calendar");
   my $timeplanref=Query->Param("Formated_timeplanrefid");
   my $subsys=$self->Self();
   my $lastmsg=$self->getParent->findtemplvar({},"LASTMSG");
   my $delbutton="<input type=submit name=DELETE style=\"margin:5px\" ".
                 "value=\" ".
                 $self->getParent->T("Delete","kernel::App::Web")." \">";
   my $savebutton="<input type=submit name=SAVE style=\"margin:5px\" ".
                  "value=\" ".
                  $self->getParent->T("Save","kernel::App::Web")." \">";
   my $breakname=$self->getParent->T("Cancel","kernel::App::Web");
   $savebutton="" if (!$writeok);
   $delbutton="" if ($TSpanID eq "" || !$writeok);
   $d.=<<EOF;
<center>
<div style="border-width:1px;border-style:solid;border-color:gray;margin:5px">
<table width=96% height=90%>
<tr height=1%>
<td width=10%>von:</td><td width=40%>\%tfrom(detail)\%</td>
<td width=10%>bis:</td><td width=40%>\%tto(detail)\%</td>
</tr>
EOF
    $tspan->ParseTemplateVars(\$d,{current=>$TSpanRec,currentid=>$TSpanID,
                                   WindowMode=>'HtmlDetailEdit',mode=>$mode});
    $d.=<<EOF;
<tr>
<td colspan=4 valign=top>$subsysform</td>
</tr>
<td colspan=4 height=1% valign=top>$lastmsg</td>
</tr>
<tr height=1%>
<td colspan=4 valign=top align=center>$delbutton
<input onClick="closewin()" style="margin:5px" type=button value=" $breakname ">
$savebutton
<input type=hidden name=Calendar value="$Calendar">
<input type=hidden name=Formated_timeplanrefid value="$timeplanref">
<input type=hidden name=TSpanID value="$TSpanID">
<input type=hidden name=NeedRefresh value="$NeedRefresh">
</td>
</tr>
</table>
</div>
</center>
<script language="JavaScript">
function closewin()
{
   if (parseInt(document.forms[0].elements['NeedRefresh'].value)){
      parent.hidePopWin(true);
   }
   else{
      parent.hidePopWin(false);
   }
}
</script>
EOF
   $d.=$self->getParent->HtmlBottom(body=>1,form=>1);
   
   return($d);
}

sub getDefaultMarkHour
{
   my $self=shift;
   return(0);
}

sub InitNewRecordQuery
{
   my $self=shift;
   my $tz=shift;

   my $sseg=Query->Param("StartSegment");
   my $eseg=Query->Param("EndSegment");
   $eseg++ if ($eseg==$sseg);
   my $start=Query->Param("StartSecond");
   my $calmode=Query->Param("CalMode");
   my $lang=$self->getParent->Lang();
   my ($from,$to);
   my @t0=Time_to_Date($tz,$start);
   if ($calmode eq "hour"){
      $from=Date_to_String($lang,
                        Add_Delta_YMDHMS($tz,@t0,0,0,0,0,0,3600*$sseg));
      $to=Date_to_String($lang,
                        Add_Delta_YMDHMS($tz,@t0,0,0,0,0,0,
                                                 (3600*$eseg)-1));
   }
   if ($calmode eq "day"){
      my $h=$self->getDefaultMarkHour();
      
      $from=Date_to_String($lang,
                        Add_Delta_YMDHMS($tz,@t0,0,0,0,$h,0,86400*$sseg));
      $to=Date_to_String($lang,
                        Add_Delta_YMDHMS($tz,@t0,0,0,0,$h,0,
                                                 (86400*$eseg)-1));
   }
   if ($calmode eq "month"){
      $from=Date_to_String($lang,
                        Add_Delta_YMDHMS($tz,@t0,0,$sseg,0,0,0,0));
      $to=Date_to_String($lang,
                        Add_Delta_YMDHMS($tz,@t0,0,$eseg,0,0,0,-1));
   }
   Query->Param("Formated_tfrom"=>$from);
   Query->Param("Formated_tto"=>$to);
   foreach my $qvar (Query->Param()){
      if ($qvar=~m/^search_/){
         Query->Delete($qvar);
      } 
   }
}


sub noAccess
{
   my $self=shift;
   return($self->getParent->noAccess());
}

sub ProcessDataModificationOP
{
   my $self=shift;
   my $TSpanID=shift;
   my $TSpanRec=shift;
   my $tz=shift;
   my $NeedRefresh=shift;
   my $Operation=0;

   if (Query->Param("DELETE") ne ""){
      $Operation=1;
      Query->Delete("DELETE");
      $NeedRefresh+=$self->HandleDelete($TSpanID,$TSpanRec,$tz);
   }
   if (Query->Param("SAVE") ne ""){
      $Operation=1;
      Query->Delete("SAVE");
      $NeedRefresh+=$self->HandleSave($TSpanID,$TSpanRec,$tz);
      if ($NeedRefresh){
         $TSpanID=Query->Param("TSpanID");
         my $tspan=$self->getParent->getPersistentModuleObject(
                                                         "timetool::tspan");
         $tspan->SetFilter({id=>\$TSpanID});
         my ($rec,$msg)=$tspan->getOnlyFirst(qw(ALL));
         if (defined($rec)){
            $TSpanRec=$rec;
            $TSpanID=$rec->{id};
         }
      }

   }
   return($Operation,$TSpanRec,$TSpanID,$NeedRefresh)
}

sub HandleSave
{
   my $self=shift;
   my $TSpanID=shift;
   my $oldrec=shift;
   my $tz=shift;

   my $tspan=$self->getParent->getPersistentModuleObject("timetool::tspan");
   my $newrec=$tspan->getWriteRequestHash("web",$oldrec);
   if (!defined($newrec)){
      if ($self->LastMsg()==0){
         $self->LastMsg(ERROR,"unknown error in ".
                              $self->Self()."::getWriteRequestHash()");
      }
      return(undef);
   }
   if ($self->isWriteValid($oldrec,$newrec)){
      if ($self->Validate($oldrec,$newrec)){
         if (!defined($newrec->{subsys})){
            $newrec->{subsys}=$self->getSubsysName();
         }
         my $writeok=0;
         printf STDERR ("fifi new=%s\n",Dumper($newrec));
         if (defined($oldrec)){
            my %flt=(id=>\$TSpanID);
            if ($tspan->ValidatedUpdateRecord($oldrec,$newrec,\%flt)){
               $writeok=1;
            }
         }
         else{
            my $TSpanID=$tspan->ValidatedInsertRecord($newrec);
            if ($TSpanID){
               Query->Param("TSpanID"=>$TSpanID);
               $writeok=1;
            }
         }
         if ($writeok){
            $tspan->ClearSaveQuery();
            return(1); 
         }
         else{
            if ($self->LastMsg()==0){
               $self->LastMsg(ERROR,"unknown error in ".
                              $self->Self()."::HandleSave()");
            }
         }
      }
      else{
         if ($self->LastMsg()==0){
            $self->LastMsg(ERROR,"unknown error in ".
                              $self->Self()."::Validate()");
         }
      }
   }
   else{
      if ($self->LastMsg()==0){
         $self->LastMsg(ERROR,"unknown error in ".
                           $self->Self()."::isWriteValid()");
      }
   }
   return(0);
}


sub HandleDelete
{
   my $self=shift;
   my $TSpanID=shift;
   my $TSpanRec=shift;
   my $tz=shift;

   if ($self->isDeleteValid($TSpanRec)){
      my $tspan=$self->getParent->getPersistentModuleObject("timetool::tspan");
      my %flt=(id=>\$TSpanID);
      $tspan->SetFilter(\%flt);
      $tspan->SetCurrentView(qw(ALL));
      $tspan->ForeachFilteredRecord(sub{
                                       my $rec=$_;
                                       if ($tspan->ValidatedDeleteRecord($rec)){
                                          Query->Delete("TSpanID");
                                       }
                                       else{
                                          if ($self->LastMsg()==0){
                                             $self->LastMsg(ERROR,"can't del");
                                          }
                                       }
                                    });

   }

   return(0);
}

sub getAddOrModifySubsysForm
{
   my $self=shift;
   my $Calendar=Query->Param("Calendar");
   my $d=<<EOF;
Calendar=$Calendar

EOF
  
   return($d);
}

sub AddColumnLabels
{
   my $self=shift;
   my $vbar=shift;
   my $starttime=shift;
   my $calmode=shift;
   my $width=shift;
   my $timezone=shift;

   my ($year,$month,$day, $hour,$min,$sec)=$starttime=~
            m/^(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)$/;
   my $lang=$self->getParent->Lang();
   Language(Decode_Language($lang));
   my @headline=();
   for(my $s=0;$s<$width;$s++){
      my %p=('head-background'=>'silver',
             'background'=>'#F9F9F9');
      $p{'head-border-left'}='solid' if ($s!=0);
      $p{'head-border-right'}='solid' if ($s==30);
      $p{'head-border-width'}='1px';
      $p{'head-border-color'}='gray';
      $p{'border-width'}='1px';
      $p{'border-color'}='#E9E9E9';
      if ($calmode eq "day"){
         my ($lyear,$lmonth,$lday)=
            Add_Delta_YMD($timezone,$year,$month,$day,0,0,$s);
         my $c=Day_of_Week($lyear,$lmonth,$lday);
         my $mname=Month_to_Text($lmonth)." - $lyear";
         my $l=substr(Day_of_Week_to_Text($c),0,2);
         push(@headline,$mname) if (!grep(/^$mname$/,@headline));
         $p{label}="<center>$l<br>$lday</center>";
         if ($c==6){
            $p{'head-border-left-color'}='black';
            $p{'head-border-left'}='solid';
            $p{'head-border-left-width'}='1px';
            $p{'border-color'}='black';
            $p{'border-left'}='solid';
            $p{'border-width'}='1px';
            $p{'background'}='lightyellow';
         }
         if ($c==7){
            $p{'head-border-right-color'}='black';
            $p{'head-border-right'}='solid';
            $p{'head-border-right-width'}='1px';
            $p{'border-color'}='black';
            $p{'border-right'}='solid';
            $p{'border-width'}='1px';
            $p{'background'}='lightyellow';
         }
         if ($lday==1 && $s!=0){
            $p{'head-border-left-color'}='black';
            $p{'head-border-left'}='solid';
            $p{'head-border-left-width'}='2px';
            $p{'border-left-color'}='black';
            $p{'border-left'}='solid';
            $p{'border-left-width'}='2px';
         }
         {
            my ($Y,$M,$D,$h,$m,$s)=Today_and_Now($timezone);
            if ($Y==$lyear && $M==$lmonth && $D==$lday){
               $p{'background'}='#ECF9F0';
            }
         }

      }
      if ($calmode eq "hour"){
         my ($lyear,$lmonth,$lday,$lhour,$lmin,$lsec)=
            Add_Delta_YMDHMS($timezone,$year,$month,$day,$hour,$min,$sec,
                             0,0,0,$s,0,0);
         my $hname=sprintf("%04d-%02d-%02d",$lyear,$lmonth,$lday);
         if ($lang eq "de"){
            $hname=sprintf("%02d.%02d.%04d",$lday,$lmonth,$lyear);
         }
         my $qhname=quotemeta($hname);
         push(@headline,$hname) if (!grep(/^$qhname$/,@headline));
         
         $p{label}="<center>${lhour}h</center>";
         if ($lhour==0 && $s!=0){
            $p{'head-border-left-color'}='black';
            $p{'head-border-left'}='solid';
            $p{'head-border-left-width'}='2px';
            $p{'border-left-color'}='black';
            $p{'border-left'}='solid';
            $p{'border-left-width'}='2px';
         }
      }
      if ($calmode eq "month"){
         my ($lyear,$lmonth,$lday,$lhour,$lmin,$lsec)=
            Add_Delta_YMD($timezone,$year,$month,$day,
                             0,$s,0);
         $p{label}=sprintf("<center>%02d/%04d</center>",${lmonth},$lyear);;
      }
      $vbar->SetSegmentParam($s,%p);
   }
   $self->{headline}=join(", ",@headline);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}

sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(0);
}

sub isDeleteValid
{
   my $self=shift;
   my $oldrec=shift;

   return(1);
}

sub SetFilter
{
   my $self=shift;
   my $tspan=shift;
   my $start=shift;
   my $end=shift;
   my $id=shift;

   my $subsys=$self->getSubsysName();

   my %globflt=(subsys=>\$subsys);
   if ($id ne ""){
      $globflt{timeplanrefid}=\$id;
   }
   my $flt=[{%globflt,tfrom=>">\"$start\" AND <\"$end\""},
            {%globflt,tto=>">\"$end\"",tfrom=>"<\"$start\""},
            {%globflt,tto=>">\"$start\" AND <\"$end\""}];
   $tspan->SetFilter($flt);
}

sub ProcessSpans
{
   my $self=shift;
   my $vbar=shift;
   my $start=shift;
   my $end=shift;
   my $dsttimezone=shift;
   my $id=shift;
   my $tspan=$self->getParent->getPersistentModuleObject("timetool::tspan");

   $self->SetFilter($tspan,$start,$end,$id);
   $tspan->SetCurrentView(qw(ALL));
   my ($rec,$msg)=$tspan->getFirst();
   while(defined($rec)){
      my $TSpanID=$rec->{id};
      $self->AddSpan($vbar,$start,$end,$dsttimezone,$rec,$TSpanID,$id);
      ($rec,$msg)=$tspan->getNext();
      last if (!defined($rec));
   }
   my $t1=Date_to_Time($dsttimezone,$start);
   my $t2=Date_to_Time($dsttimezone,$end);
   $vbar->SetRangeMin($t1);
   $vbar->SetRangeMax($t2);
}

sub AddSpan
{
   my $self=shift;
   my $vbar=shift;
   my $start=shift;
   my $end=shift;
   my $dsttimezone=shift;
   my $rec=shift;
   my $TSpanID=shift;
   my $id=shift;

   my $t1=Date_to_Time("GMT",$rec->{tfrom});
   my $t2=Date_to_Time("GMT",$rec->{tto});
   $vbar->AddSpan(2,"any",$t1,$t2,color=>'blue',id=>$TSpanID);

}

sub getAdditionalSearchMask
{
   return("&nbsp;");
}

1;

