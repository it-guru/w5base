package AL_TCom::MyW5Base::MIReport;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
use kernel::MyW5Base;
use kernel::XLSReport;
use kernel::date;
@ISA=qw(kernel::MyW5Base);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub Init
{
   my $self=shift;
   return(1);
}

sub isSelectable
{
   my $self=shift;

   return(1); # for testing!

   my $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
                          'AL_TCom::MyW5Base::MIReport$',
                          func=>'Main');

   if (defined($acl)){
      return(1) if (grep(/^read$/,@$acl));
   }
   return(0);
}

sub getQueryTemplate
{
   my $self=shift;

   my $tt=$self->kernel::MyW5Base::getTimeRangeDrop("search_year",
                                                    $self,
                                                    qw(year));
   my $t0=$self->T("Only Prio 1 events");
   my $t1=$self->T("Year");
   my $t2=$self->T("Yes");
   my $t3=$self->T("No - show all");


   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>$t1:</td><td class=finput>$tt</td>
<td class=fname width=20%>$t0:</td>
<td class=finput width=30% nowrap>
<select name=search_onlyprio1>
<option selected value="1">$t2</option>
<option value="0">$t3</option>
</select>
</td>
</tr>
<tr>
<td colspan=4 align=right>
<input type=button 
       style='margin:2px;margin-right:10px;'
       onclick="DoSearch();" 
       value="generate Report">
</td>
</tr>
</table>
</div>
EOF
   return($d);
}

sub doAutoSearch
{
   my $self=shift;

   return(0);
}




sub Result
{
   my $self=shift;
   my $wf=getModuleObject($self->Config,"base::workflow");
   my %flt=$wf->getSearchHash();

   my $year=$flt{year};
   my $onlyprio1=$flt{onlyprio1};
   my $tz=$self->getParent->UserTimezone();
   my ($y,$m,$d)=Today_and_Now($tz);

   # $year and $tz are initial parameters

   if ($year eq ""){
      $year="($year)"; 
   }

   if ($year eq "($y)"){
      $year=">=\"01.01.$y 00:00:00\"";
      for(my $c=0;$c<=7;$c++){
         last if (Day_of_Week($y,$m,$d)==7);
         ($y,$m,$d)=Add_Delta_YMD($tz,$y,$m,$d,0,0,-1);
      }
     # $year.=" AND <=\"$d.$m.$y 23:59:59\"";
   }
   msg(INFO,"processing MI-Report for '$year'");

   $wf->SetFilter({eventend=>$year,
                   class=>\'AL_TCom::workflow::eventnotify',
                   isdeleted=>\'0'});

   my %sheet=();
   foreach my $wfrec ($wf->getHashList(qw(wffields.eventmode 
                                  wffields.eventstatclass
                                  wffields.eventignoreforkpi
                                  wffields.affecteditemgroup id))){
      my $top=$wfrec->{affecteditemgroup};
      $top="NONE" if (!defined($top) || $top eq "");
      $top=[split(/\s*;\s*/,$top)] if (ref($top) ne "ARRAY");
      next if ($onlyprio1 && $wfrec->{eventstatclass} ne "1");
      next if ($wfrec->{eventignoreforkpi} eq "1"); 
      foreach my $t (@$top){
         push(@{$sheet{$t}},$wfrec->{id});
      }
   }
   my @control;
   my $wf=getModuleObject($self->Config,"base::workflow");
   $wf->AddFields(
      new kernel::Field::Text(
                name          =>'YEAR',
                label         =>'Jahr',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   if ($current->{eventstart} ne ""){
                      my ($Y,$M,$D,$h,$m,$s)=
                            $self->getParent->ExpandTimeExpression(
                            $current->{eventstart},"stamp","GMT","CET");
                      return(sprintf("%04d",$Y));
                   }
                   return("");
                },
                htmldetail    =>0),
   );
   $wf->AddFields(
      new kernel::Field::Text(
                name          =>'MONTH',
                label         =>'Monat',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   if ($current->{eventstart} ne ""){
                      my ($Y,$M,$D,$h,$m,$s)=
                            $self->getParent->ExpandTimeExpression(
                            $current->{eventstart},"stamp","GMT","CET");
                      return(sprintf("%02d",$M));
                   }
                   return("");
                },
                htmldetail    =>0),
   );
   $wf->AddFields(
      new kernel::Field::Text(
                name          =>'CWEEK',
                label         =>'KW',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   if ($current->{eventstart} ne ""){
                      my ($Y,$M,$D)=$self->getParent->ExpandTimeExpression(
                            $current->{eventstart},"stamp","GMT","CET");
                      return(kernel::date::Week_of_Year($Y,$M,$D));
                   }
                   return("");
                },
                htmldetail    =>0),
   );
   $wf->AddFields(
      new kernel::Field::Text(
                name          =>'QUART',
                label         =>'Quartal',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   if ($current->{eventstart} ne ""){
                      my ($Y,$M,$D)=$self->getParent->ExpandTimeExpression(
                            $current->{eventstart},"stamp","GMT","CET");
                      return(1) if ($M>=1 && $M<=3);
                      return(2) if ($M>=4 && $M<=6);
                      return(3) if ($M>=7 && $M<=9);
                      return(4) if ($M>=10 && $M<=12);
                      return("?");
                   }
                   return("");
                },
                htmldetail    =>0),
   );



   foreach my $s (sort(keys(%sheet))){
      push(@control,{
         sheet=>$s,DataObj=>$wf,
         filter=>{id=>$sheet{$s}},
         view=>[qw(
                   mandator
                   wffields.solutionline
                   wffields.affectedapplication wffields.affectedlocation
                   wffields.eventstatreportinglabel
                   wffields.eventstatclass
                   wffields.eventstartofevent
                   wffields.eventendofevent
                   eventduration
                   eventdurationhour
                   wffields.eventnetduration
                   wffields.eventkpifirstinfo
                   wffields.eventnetdurationsolved4h
                   wffields.eventchmticket
                   detaildescription
                   wffields.eventstatreasonFrontendText 
                   wffields.eventstatrespo 
                   id 
                   YEAR 
                   QUART 
                   MONTH
                   CWEEK
                   wffields.eventinmticket
                   wffields.eventscproblemstatus 
                   wffields.eventprmticket
                   wffields.eventscprmstatus 
                   wffields.eventscprmsolutiontype
                   wffields.eventscprmclosetype
                   wffields.eventspecrespocustomer wffields.eventspecrespoitprov
                   wffields.eventrcfound10wt
                   wffields.eventisconsequence
                   wffields.eventconsequenceof
                   wffields.affecteditemprio
                   name
                   wffields.qceventendofevent
                   wffields.affectedregion
                   wffields.eventstattype
                   wffields.eventrcfoundat
                   wffields.affecteditemgroup
                   createdate
                   wffields.affectedcustomer)]}
      );
   }
   my ($Y,$M,$D,$h,$m,$s)=$self->getParent->ExpandTimeExpression("now","stamp",
                                                                 "GMT","CET");
   my $t=sprintf("_%04d%02d%02d%02d%02d%02d",$Y,$M,$D,$h,$m,$s);

   my $out=new kernel::XLSReport($self,">&STDOUT",
                                 FinalFilename=>'W5Base-MI-Report'.$t);
   $out->initWorkbook();


   $out->Process(@control);


}

1;
