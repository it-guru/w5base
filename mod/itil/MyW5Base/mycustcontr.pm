package itil::MyW5Base::mycustcontr;
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
   $self->{DataObj}=getModuleObject($self->getParent->Config,
                                    "itil::custcontract");
   return(0) if (!defined($self->{DataObj}));
   return(1);
}

sub getQueryTemplate
{
   my $self=shift;
   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=20%>\%name(label)\%:</td>
<td class=finput width=80% >\%name(search)\%</td>
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

   my $userid=$self->getParent->getCurrentUserId();
   $userid=-1 if (!defined($userid) || $userid==0);

   my $dc=Query->Param("EXVIEWCONTROL");
   my @q=();
   if (($dc eq "ADDDEP" || $dc ne "DEPONLY") &&  $dc ne "TEAM"){
      my %q1=%q;
      my %q2=%q;
      $q1{semid}=\$userid;
      $q1{cistatusid}='<=4';
      $q2{databossid}=\$userid;
      $q2{cistatusid}='<=4';
      push(@q,\%q1,\%q2);
   }
   if ($dc eq "DEPONLY" && $dc ne "TEAM"){
      my %q1=%q;
      $q1{sem2id}=\$userid;
      $q1{cistatusid}='4';

      my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                                            ["RBoss2"],
                                            "down");
      my @grpids=keys(%grp);
      @grpids=(qw(-1)) if ($#grpids==-1);
      my %q2=%q;
      $q2{cistatusid}='<=4';
      $q2{responseteamid}=\@grpids;
      push(@q,\%q1,\%q2);

   }
   if ($dc eq "TEAM"){
      my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                                 [qw(REmployee RApprentice RFreelancer RBoss)],
                                 "down");
      my @grpids=keys(%grp);
      @grpids=(qw(-1)) if ($#grpids==-1);

      my %q1=%q;
      $q1{cistatusid}='<=4';
      $q1{responseteamid}=\@grpids;

      push(@q,\%q1);
   }

   $self->{DataObj}->ResetFilter();
   $self->{DataObj}->SecureSetFilter(\@q);
   return($self->{DataObj}->Result(ExternalFilter=>1));
}





1;
