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


   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>Year:</td><td class=finput>$tt</td>
<td class=fname width=20%>Only Prio 1 events:</td>
<td class=finput width=30% nowrap>
<select name=search_onlyprio1>
<option selected value="1">Yes</option>
<option value="0">No - show all</option>
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
   print STDERR Dumper(\%flt);



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

   my $mi=getModuleObject($self->Config,"itil::lnkmgmtitemgroup");
   $wf->SetFilter({eventend=>$year,
                   class=>['AL_TCom::workflow::eventnotify',
                           'itil::workflow::eventnotify'],
                   isdeleted=>\'0'});

   my %sheet=();
   foreach my $wfrec ($wf->getHashList(qw(wffields.eventmode 
                                  wffields.eventstatclass
                                  wffields.affecteditemgroup id))){
      my $top=$wfrec->{affecteditemgroup};
      $top="NONE" if (!defined($top) || $top eq "");
      $top=[split(/\s*;\s*/,$top)] if (ref($top) ne "ARRAY");
      next if ($onlyprio1 && $wfrec->{eventstatclass} ne "1");
      foreach my $t (@$top){
         push(@{$sheet{$t}},$wfrec->{id});
      }
   }
   my @control;
   foreach my $s (sort(keys(%sheet))){
      push(@control,{
         sheet=>$s,
         DataObj=>'base::workflow',
         filter=>{id=>$sheet{$s}},
         view=>[qw(
                   wffields.eventendofevent
                   wffields.affectedlocation wffields.affectedapplication
                   name 
                   wffields.eventstartofevent
                   wffields.qceventendofevent

                   wffields.solutionline

                   wffields.eventstatclass
                   wffields.affectedregion
                   wffields.eventstatrespo
                   wffields.eventstatreason

                   wffields.affecteditemprio

                   eventduration
                   eventdurationhour
                   wffields.eventnetduration
                   wffields.eventnetdurationsolved4h
                   wffields.eventrcfound10wt

                   wffields.eventkpifirstinfo

                   wffields.eventchmticket

                   wffields.eventprmticket
                   wffields.eventscprmstatus
                   wffields.eventscprmsolutiontype
                   wffields.eventscprmclosetype

                   wffields.eventinmticket
                   wffields.eventscproblemstatus

                   wffields.affecteditemgroup 
                   detaildescription createdate 
                   mandator wffields.affectedcustomer id)]}
      );
   }

   my $out=new kernel::XLSReport($self,">&STDOUT");
   $out->initWorkbook();


   $out->Process(@control);


}

1;
