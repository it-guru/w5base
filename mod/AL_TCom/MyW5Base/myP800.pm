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
use Data::Dumper;
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
   if ($dc eq "ADDDEP" || $dc eq "DEPONLY"){
      my %q1;
      my %q2;
      $q1{sem2id}=\$userid;
      $q2{tsm2id}=\$userid;

      my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                                            ["RChief2"],
                                            "down");
      my @grpids=keys(%grp);
      @grpids=(qw(-1)) if ($#grpids==-1);
      my %q3=%q;
      $q3{businessteamid}=\@grpids;
      my %q4=%q;
      my %q5=%q;
      my %q6=%q;
      $q4{responseteamid}=\@grpids;
      $q5{delmgr2id}=\$userid;
      $q6{ldelmgr2id}=\$userid;

      push(@q,\%q1,\%q2,\%q3,\%q4,\%q5,\%q6);
   }
   if ($dc ne "DEPONLY" && $dc ne "CUSTOMER"){
      my %q1;
      my %q2;
      my %q3;
      my %q4;
      my %q5;
      $q1{semid}=\$userid;
      $q2{tsmid}=\$userid;
      $q3{databossid}=\$userid;
      $q4{delmgrid}=\$userid;
      $q5{ldelmgrid}=\$userid;

      push(@q,\%q1,\%q2,\%q3,\%q4,\%q5);
   }
   if ($dc eq "TEAM"){
      my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                                            ["REmployee","RChief"],
                                            "down");
printf STDERR ("fifi groups=%s\n",Dumper(\%grp));
      my @grpids=keys(%grp);
      @grpids=(qw(-1)) if ($#grpids==-1);
   
      my %q1=();
      $q1{cistatusid}='<=4';
      $q1{businessteamid}=\@grpids;
   
      my %q2=();
      $q2{cistatusid}='<=4';
      $q2{responseteamid}=\@grpids;

      my %q3;
      $q3{cistatusid}='<=4';
      $q3{delmgrteamid}=\@grpids;
   
      push(@q,\%q1,\%q2,\%q3);
   }
   if ($dc ne "" &&
       $dc ne "ADDDEP" &&
       $dc ne "DEPONLY" &&
       $dc ne "TEAM"){
      return(undef);
   }

   $self->{appl}->ResetFilter();
   $self->{appl}->SecureSetFilter(\@q);
   my @l=$self->{appl}->getHashList("id");
   my @appl=("none");
   if ($#l>-1){
      @appl=map({$_->{id}} @l);
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
