package itil::MyW5Base::mymodifiedchanges;
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
   my $t1=$self->getParent->T("modified since");
   my @p=('1h'=>1,
          '6h'=>6,
          '12h'=>12,
          '24h'=>24,
          '36h'=>36);
   my $tdrop="<select name=LastHours>";
   my $oldval=Query->Param("LastHours");
   $oldval=6 if (!defined($oldval));
   while(my ($p,$k)=(shift(@p),shift(@p))){
      last if (!defined($k));
      $tdrop.="<option value=\"$k\"";
      $tdrop.=" selected" if ($oldval eq $k);
      $tdrop.=">$p</option>";
   }
   $tdrop.="</select>";


   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>\%name(label)\%:</td>
<td class=finput width=40% >\%name(search)\%</td>
<td class=fname widths10%>\%affectedapplication(label)\%:</td>
<td class=finput width=40%>\%affectedapplication(search)\%</td>
</tr>
<tr>
<td class=fname>$t1:</td>
<td class=finput>$tdrop</td>
<td class=fname>\%affectedcontract(label)\%:</td>
<td class=finput>\%affectedcontract(search)\%</td>
</tr>
<tr>
<td class=fname>&nbsp;</td>
<td class=finput>&nbsp;</td>
<td class=fname>\%srcid(label)\%:</td>
<td class=finput>\%srcid(search)\%</td>
</tr>
</table>
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
      $q1{semid}=\$userid;
      $q2{tsmid}=\$userid;
      $q3{databossid}=\$userid;
      push(@q,\%q1,\%q2,\%q3);
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
                        [qw(REmployee RApprentice RFreelancer RBoss)],
                        "both");
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
   my $tq=Query->Param("LastHours");
   $tq=1 if ($tq<=0 || !defined($tq));
   $tq=36 if ($tq>=36);
   $q1{mdate}=">now-${tq}h";
  
   $q1{class}=[grep(/^.*::change$/,keys(%{$self->{DataObj}->{SubDataObj}}))];
   $self->{DataObj}->ResetFilter();
   $self->{DataObj}->SecureSetFilter([\%q1]);
   my @l=$self->{DataObj}->getHashList("id");
   my @idl=map({$_->{id}} @l);
   %q1=(id=>\@idl,affectedapplicationid=>\@appl);

   $self->{DataObj}->ResetFilter();
   $self->{DataObj}->SetFilter([\%q1]);
   $self->{DataObj}->setDefaultView(qw(linenumber name state srcid));
   my %param=(ExternalFilter=>1,
              Limit=>50);
   return($self->{DataObj}->Result(%param));
}



1;
