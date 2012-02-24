package itil::MyW5Base::mycloseddiary;
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
use kernel::MyW5Base;
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

sub getQueryTemplate
{
   my $self=shift;
   my $timelabel=$self->getParent->T("Close time");;
   my $timedrop=$self->getTimeRangeDrop("Search_TimeRange",
                                        $self->getParent,
                                        qw(shorthistory month));
   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>\%name(label)\%:</td>
<td class=finput width=40% >\%name(search)\%</td>
<td class=fname width=10%>\%affectedapplication(label)\%:</td>
<td class=finput width=40% >\%affectedapplication(search)\%</td>
</tr>
<tr>
<td class=fname>$timelabel:</td>
<td class=finput>$timedrop</td>
<td class=fname>\%affectedcontract(label)\%:</td>
<td class=finput>\%affectedcontract(search)\%</td>
</tr>
</table>
</div>
%StdButtonBar(teamviewcontrol,deputycontrol,print,search)%
EOF
   return($d);
}


sub Result
{
   my $self=shift;
   my %q=$self->{DataObj}->getSearchHash();
   my %orgq=%q;
   if (exists($q{affectedapplication})){
      $q{name}=$q{affectedapplication};
      delete($q{affectedapplication});
   }
   delete($q{name});

   my $userid=$self->getParent->getCurrentUserId();
   $userid=-1 if (!defined($userid) || $userid==0);

   my $dc=Query->Param("EXVIEWCONTROL");
   my @q=();
   if ($dc eq "TEAM"){
      my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
              [qw(REmployee RApprentice RFreelancer RBoss)],
                                            "down");
      my @grpids=keys(%grp);
      @grpids=(qw(-1)) if ($#grpids==-1);

      my %q1=%q;
      $q1{cistatusid}='<=4';
      $q1{businessteamid}=\@grpids;

      my %q2=%q;
      $q2{cistatusid}='<=4';
      $q2{responseteamid}=\@grpids;

      my %q3=%q;
      $q3{cistatusid}='<=4';
      $q3{delmgrteamid}=\@grpids;

      push(@q,\%q1,\%q2,\%q3);
   }
   if ($dc eq "ADDDEP" || $dc eq "DEPONLY"){
      my %q1=%q;
      my %q2=%q;
      my %q3=%q;
      my %q4=%q;
      my %q5=%q;
      my %q6=%q;
      $q1{sem2id}=\$userid;
      $q2{tsm2id}=\$userid;

      my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                                            ["RBoss2"],
                                            "down");
      my @grpids=keys(%grp);
      @grpids=(qw(-1)) if ($#grpids==-1);
      $q3{businessteamid}=\@grpids;
      $q4{responseteamid}=\@grpids;
      $q5{delmgr2id}=\$userid;
      push(@q,\%q1,\%q2,\%q3,\%q4,\%q5,\%q6);
   }
   if ($dc ne "DEPONLY" && $dc ne "TEAM"){
      my %q1=%q;
      my %q2=%q;
      my %q3=%q;
      my %q4=%q;
      $q1{semid}=\$userid;
      $q2{tsmid}=\$userid;
      $q3{databossid}=\$userid;
      $q4{delmgrid}=\$userid;
      push(@q,\%q1,\%q2,\%q3,\%q4);
   }


   $self->{appl}->ResetFilter();
   $self->{appl}->SecureSetFilter(\@q);
   my @l=$self->{appl}->getHashList("id");
   my @appl=("none");
   if ($#l>-1){
      @appl=map({$_->{id}} @l);
   }
   my %q1=%orgq;
   $q1{affectedapplicationid}=\@appl;
   $q1{stateid}='>6';
   $q1{eventend}=Query->Param("Search_TimeRange");
   $q1{eventend}="<now AND >now-24h" if (!defined($q1{eventend}));
   $q1{class}=[grep(/^.*::diary$/,keys(%{$self->{DataObj}->{SubDataObj}}))];


   $self->{DataObj}->ResetFilter();
   $self->{DataObj}->SecureSetFilter([\%q1]);
   $self->{DataObj}->setDefaultView(qw(linenumber name state id srcid));
   my %param=(ExternalFilter=>1);
   return($self->{DataObj}->Result(%param));
}



1;
