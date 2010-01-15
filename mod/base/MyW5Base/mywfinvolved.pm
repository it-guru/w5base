package base::MyW5Base::mywfinvolved;
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

sub getDefaultStdButtonBar
{
   my $self=shift;
   my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
              [qw(REmployee RApprentice RFreelancer RBoss)],
                  "down");
   my @grpids=keys(%grp);
   if ($#grpids<5){
      return('%StdButtonBar(teamviewcontrol,print,search)%');
   }
   return($self->SUPER::getDefaultStdButtonBar());
}


sub Init
{
   my $self=shift;
   $self->{DataObj}=getModuleObject($self->getParent->Config,"base::workflow");
   return(0) if (!defined($self->{DataObj}));
   return(1);
}

sub getQueryTemplate
{
   my $self=shift;
   my $timelabel=$self->getParent->T("action timespan");
   my $timedrop=$self->getTimeRangeDrop("search_cdate",
                                        $self->getParent,
                                        qw(month));
   my $dd=$self->getDefaultStdButtonBar();
   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>\%name(label)\%:</td>
<td class=finput width=40% >\%name(search)\%</td>
<td class=fname width=10%>$timelabel:</td>
<td class=finput width=40%>$timedrop</td>
</tr>
<tr>
<td class=fname width=10%>\%class(label)\%:</td>
<td class=finput width=40% >\%class(search)\%</td>
<td class=fname>\%state(label)\%</td>
<td class=finput>\%stateid(search)\%</td>
</tr>
</table>
</div>
$dd
EOF
   return($d);
}


sub Result
{
   my $self=shift;
   my %q=$self->{DataObj}->getSearchHash();
   my $dc=Query->Param("EXVIEWCONTROL");
printf STDERR ("q=%s\n",Dumper(\%q));

   my $userid=$self->getParent->getCurrentUserId();
   $userid=-1 if (!defined($userid) || $userid==0);
   my %q1=%q;

   my $searchuser=[$userid];
   if ($dc eq "TEAM"){
      my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                                            ["REmployee","RChief"],
                                            "down");
      my @grpids=keys(%grp);
      if ($#grpids<5){
         @grpids=(qw(-1)) if ($#grpids==-1);
         my $lnk=getModuleObject($self->getParent->Config,"base::lnkgrpuser");
         $lnk->SetFilter({grpid=>\@grpids});
         my @l=$lnk->getHashList(qw(userid));
         if ($#l!=-1){
            $searchuser=[map({$_->{userid}} @l)];
         }
      }
   }
   $q1{id}=[-1];
   my $wfa=getModuleObject($self->getParent->Config,"base::workflowaction");
   if ($q{cdate} ne ""){
      $wfa->SetFilter({cdate=>$q{cdate},creatorid=>\$userid});
      my @l=$wfa->getHashList(qw(wfheadid));
      if ($#l!=-1){
         $q1{id}=[map({$_->{wfheadid}} @l)];
      }
   }
   delete($q1{cdate});

   $self->{DataObj}->ResetFilter();
   $self->{DataObj}->SecureSetFilter([\%q1]);
   $self->{DataObj}->setDefaultView(qw(eventend eventstart class state name));

   return($self->{DataObj}->Result(ExternalFilter=>1));
}




1;
