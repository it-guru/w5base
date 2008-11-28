package AL_TCom::MyW5Base::myP800;
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
use AL_TCom::lib::tool;
@ISA=qw(kernel::MyW5Base AL_TCom::lib::tool);

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
   $self->{DataObj}=getModuleObject($self->getParent->Config,"base::workflow");
   $self->{appl}=getModuleObject($self->getParent->Config,"itil::appl");
   return(0) if (!defined($self->{DataObj}));
   return(1);
}

sub isSelectable
{
   my $self=shift;

   my $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
                                        'base::MyW5Base::myP800$');
   if (defined($acl)){
      return(1) if (grep(/^read$/,@$acl));
   }
   return(0);
}

sub getQueryTemplate
{
   my $self=shift;
   my $timelabel=$self->getParent->T("P800 reporting month");;
   my $timedrop=$self->getTimeRangeDrop("P800_TimeRange",
                                        $self->getParent,
                                        qw(fixmonth selectlastmonth 
                                           relativemonth));
   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>\%name(label)\%:</td>
<td class=finput width=40% >\%name(search)\%</td>
<td class=fname width=10%>\%affectedcontract(label)\%:</td>
<td class=finput width=40%>\%affectedcontract(search)\%</td>
<td colspan=2></td>
</tr><tr>
<td class=fname>$timelabel:</td>
<td class=finput>$timedrop</td>
<td class=fname>\%affectedapplication(label)\%:</td>
<td class=finput>\%affectedapplication(search)\%</td>
</tr>
</table>
</div>
%StdButtonBar(teamviewcontrol,bookmark,deputycontrol,print,search)%
EOF
   return($d);
}


sub Result
{
   my $self=shift;
   my %q=$self->{DataObj}->getSearchHash();

   my $userid=$self->getParent->getCurrentUserId();
   $userid=-1 if (!defined($userid) || $userid==0);

   my $dc=Query->Param("EXVIEWCONTROL");
   my @q=();
   my %mainq1=%q;
   $mainq1{stateid}=['1','21'];

   my @appl=("none");
   if ($dc eq "ADDDEP"){
      @appl=$self->getRequestedApplicationIds($userid,user=>1,dep=>1);
   }
   if ($dc eq "DEPONLY"){
      @appl=$self->getRequestedApplicationIds($userid,dep=>1);
   }
   if ($dc eq "TEAM"){
      @appl=$self->getRequestedApplicationIds($userid,team=>1);
   }
   $mainq1{affectedapplicationid}=\@appl;
   my $p800m=Query->Param("P800_TimeRange");
   if ($p800m eq "currentmonth" || $p800m eq "lastmonth" || 
       $p800m eq "nextmonth"){
      my $tz=$self->getParent->UserTimezone();
      my ($Y,$M,$D,$h,$m,$s)=Today_and_Now($tz);
      if ($p800m eq "nextmonth"){
         ($Y,$M,$D)=Add_Delta_YM($tz,$Y,$M,$D,0,1);
      }
      elsif ($p800m eq "lastmonth"){
         ($Y,$M,$D)=Add_Delta_YM($tz,$Y,$M,$D,0,-1);
      }
      $p800m=sprintf("%02d/%04d",$M,$Y);
   }
   $p800m="now" if (!defined($p800m) || $p800m eq ""); 
   $mainq1{srcid}="$p800m-*";
   $mainq1{eventstart}=">$p800m-1000h AND <$p800m+1000h";
   my @valids=grep(/^.*::P800.*$/,keys(%{$self->{DataObj}->{SubDataObj}}));
   if ($mainq1{class} ne ""){
      my $q=quotemeta($mainq1{class});
      if (!grep(/^$q$/i,@valids)){
         delete($mainq1{class});
      } 
   }
   if ($mainq1{class} eq ""){
      $mainq1{class}=\@valids;
   }

   $self->{DataObj}->ResetFilter();
   $self->{DataObj}->SecureSetFilter([\%mainq1]);
   $self->{DataObj}->setDefaultView(qw(linenumber name state id srcid));
   my %param=(ExternalFilter=>1);
   return($self->{DataObj}->Result(%param));
}



1;
