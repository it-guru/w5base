package base::MyW5Base::wfmyjobs;
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
   return(0) if (!defined($self->{DataObj}));
   return(1);
}

sub getDefaultStdButtonBar
{
   my $self=shift;
   return('%StdButtonBar(deputycontrol,print,search)%');
}

sub getQueryTemplate
{
   my $self=shift;
   my $bb=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>\%name(label)\%:</td>
<td class=finput width=50% >\%name(search)\%</td>
<td class=fname width=10%>\%prio(label)\%:</td>
<td class=finput width=30%>\%prioid(search)\%</td>
</tr>
<tr>
<td class=fname width=10%>\%class(label)\%:</td>
<td class=finput width=50% >\%class(search)\%</td>
<td class=fname width=10%>\%state(label)\%:</td>
<td class=finput width=30%>\%stateid(search)\%</td>
</tr>
</table>
</div>
<script language="JavaScript">
setEnterSubmit(document.forms[0],document.DoSearch);
</script>

EOF

   $bb.=$self->getDefaultStdButtonBar();
   return($bb);
}


sub isSelectable
{
   my $self=shift;

   return(1);
}

sub Result
{
   my $self=shift;
   my %q=$self->{DataObj}->getSearchHash();

   my $userid=$self->getParent->getCurrentUserId();
   my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},"RMember","both");
   my @grpids=keys(%grp);
   @grpids=(qw(NONE)) if ($#grpids==-1);

   $userid=-1 if (!defined($userid) || $userid==0);
   my $dc=Query->Param("EXVIEWCONTROL");
   my @q=();
   if ($dc eq "ADDDEP" || $dc eq "DEPONLY"){
      my %q1=%q;
      my %q2=%q;
      $q1{fwddebtargetid}=\$userid;
      $q1{fwddebtarget}=\'base::user';
      $q1{stateid}.=" AND " if ($q1{stateid} ne "");
      $q1{stateid}.="<20";
      $q2{fwddebtargetid}=\@grpids;
      $q2{fwddebtarget}=\'base::grp';
      $q2{stateid}.=" AND " if ($q2{stateid} ne "");
      $q2{stateid}.="<20";
      push(@q,\%q1,\%q2);
   }
   if ($dc ne "DEPONLY"){
      my %q1=%q;
      my %q2=%q;
      my %q3=%q;
      $q1{fwdtargetid}=\$userid;
      $q1{fwdtarget}=\'base::user';
      $q1{stateid}.=" AND " if ($q1{stateid} ne "");
      $q1{stateid}.="<20";
      $q2{fwdtargetid}=\@grpids;
      $q2{fwdtarget}=\'base::grp';
      $q2{stateid}.=" AND " if ($q2{stateid} ne "");
      $q2{stateid}.="<20";

      my %id=();  # this hack prevents searches over two keys (this is bad)
      $self->{DataObj}->SetFilter([\%q1,\%q2]);
      my @l=$self->{DataObj}->getHashList(qw(id));
      map({$id{$_->{id}}=1} @l);

      $q3{owner}=\$userid;
      $q3{stateid}.=" AND " if ($q3{stateid} ne "");
      $q3{stateid}.="<=6";

      $self->{DataObj}->SetFilter([\%q3]);
      my @l=$self->{DataObj}->getHashList(qw(id));
      map({$id{$_->{id}}=1} @l);

      my $ws=$self->getParent->getPersistentModuleObject("base::workflowws");
      $ws->SetFilter([{fwdtargetid=>\$userid,fwdtarget=>\'base::user'},
                      {fwdtargetid=>\@grpids,fwdtarget=>\'base::grp'}]); 
      map({$id{$_->{wfheadid}}=1;} $ws->getHashList(qw(wfheadid)));

      push(@q,{id=>[keys(%id)]});
   }
   $self->{DataObj}->ResetFilter();
   $self->{DataObj}->SecureSetFilter(\@q);
   $self->{DataObj}->setDefaultView(qw(prio mdate state class name editor));
   
   return($self->{DataObj}->Result(ExternalFilter=>1));
}




1;
