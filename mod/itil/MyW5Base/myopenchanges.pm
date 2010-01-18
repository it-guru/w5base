package itil::MyW5Base::myopenchanges;
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
   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>\%name(label)\%:</td>
<td class=finput width=40% >\%name(search)\%</td>
<td class=fname widths10%>\%affectedapplication(label)\%:</td>
<td class=finput width=40%>\%affectedapplication(search)\%</td>
</tr><tr>
<td colspan=2></td>
<td class=fname>\%affectedcontract(label)\%:</td>
<td class=finput>\%affectedcontract(search)\%</td>
</tr></table>
</div>
%StdButtonBar(exviewcontrol,deputycontrol,teamviewcontrol,search)%
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
   if ($dc eq "ADDDEP" || $dc eq "DEPONLY"){
      my %q1=();
      my %q2=();
      my %q3=();
      my %q4=();
      $q1{sem2id}=\$userid;
      $q2{tsm2id}=\$userid;

      my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                                            ["RBoss2"],
                                            "down");
      my @grpids=keys(%grp);
      @grpids=(qw(-1)) if ($#grpids==-1);
      my %q3=();
      $q3{businessteamid}=\@grpids;
      my %q4=();
      $q4{responseteamid}=\@grpids;

      push(@q,\%q1,\%q2,\%q3,\%q4);
   }
   if ($dc ne "DEPONLY" && $dc ne "TEAM" && $dc ne "CUSTOMER"){
      my %q1=();
      my %q2=();
      my %q3=();
      my %q4=();
      my %q5=();
      $q1{semid}=\$userid;
      $q2{tsmid}=\$userid;
      $q3{databossid}=\$userid;
      $q4{delmgrid}=\$userid;
      $q5{opmid}=\$userid;
      push(@q,\%q1,\%q2,\%q3,\%q4,\%q5);
   }
   if ($dc eq "TEAM"){
      my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
               [qw(REmployee RApprentice RFreelancer RBoss)],
                                            "down");
      my @grpids=keys(%grp);
      @grpids=(qw(-1)) if ($#grpids==-1);

      my %q1=();
      $q1{cistatusid}='<=4';
      $q1{businessteamid}=\@grpids;

      my %q2=();
      $q2{cistatusid}='<=4';
      $q2{responseteamid}=\@grpids;

      push(@q,\%q1,\%q2);
   }
   if ($dc eq "CUSTOMER"){
      my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                [qw(REmployee RApprentice RFreelancer RBoss
                    RQManager)], "both");
      my @grpids=keys(%grp);
      @grpids=(qw(-1)) if ($#grpids==-1);

      my %q1=();
      $q1{cistatusid}='<=4';
      $q1{customerid}=\@grpids;

      push(@q,\%q1);
   }
   if ($dc ne "TEAM" &&
       $dc ne "DEPONLY" &&
       $dc ne "CUSTOMER" &&
       $dc ne "" &&
       $dc ne "ADDDEP"){
      return(undef);
   }



   $self->{appl}->ResetFilter();
   $self->{appl}->SetFilter(\@q);
   my @l=$self->{appl}->getHashList("id");
   my @appl=("none");
   if ($#l>-1){
      @appl=map({$_->{id}} @l);
   }
   my %q1=%q;
   $q1{stateid}='<17';
   $q1{affectedapplicationid}=\@appl;
   #$q1{mdate}='>now-4h';
   $q1{class}=[grep(/^.*::change$/,keys(%{$self->{DataObj}->{SubDataObj}}))];


   $self->{DataObj}->ResetFilter();
   $self->{DataObj}->SecureSetFilter([\%q1]);
   $self->{DataObj}->setDefaultView(qw(linenumber name state srcid));
   my %param=(ExternalFilter=>1,
              Limit=>50);
   return($self->{DataObj}->Result(%param));
}



1;
