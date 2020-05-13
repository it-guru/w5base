package base::MyW5Base::mywfclosed;
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
                                         ["REmployee","RChief"],
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

   $self->{Field}->{trangefield}=new kernel::Field::Text(
                Parent        =>$self,
                name          =>'trangefield',
                selectsearch  =>sub{
                   my $self=shift;
                   my @l;
                   push(@l,
                      ["eventend","Ereignisende"],
                      ["eventstart","Ereignisbegin"]
                   );
                   return(@l);
                },
                value         =>[qw(eventstart eventend)],
                label         =>'time of event');
   $self->{Field}->{trangefield}->setParent($self);

   $self->{Field}->{trange}=new kernel::Field::Date(
                Parent        =>$self,
                name          =>'trange',
                label         =>'point of time');
   $self->{Field}->{trange}->setParent($self);




   return(1);
}

sub getQueryTemplate
{
   my $self=shift;
   my $timelabel=$self->getParent->T("Change end time");;
   my $dd=$self->getDefaultStdButtonBar();

   if (!defined(Query->Param("search_trange"))){
      Query->Param("search_trange"=>"currentmonth");
   }


   my $trangefieldl=$self->{Field}->{trangefield}->Label;
   my $trangefields=$self->{Field}->{trangefield}->FormatedSearch();

   my $trangel=$self->{Field}->{trange}->Label;
   my $tranges=$self->{Field}->{trange}->FormatedSearch();


   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>\%name(label)\%:</td>
<td class=finput width=40% >\%name(search)\%</td>
<td class=fname width=10%>\%class(label)\%:</td>
<td class=finput width=40% >\%class(search)\%</td>
</tr>
<tr>
<td class=fname width=10%>$trangefieldl:</td>
<td class=finput width=40% >$trangefields</td>
<td class=fname width=10%>$trangel:</td>
<td class=finput width=40% >$tranges</td>
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


   #printf STDERR "Q=".Query->Dumper();
   #printf STDERR Dumper(\%q);
   if ($q{trangefield} ne "eventstart" &&
       $q{trangefield} ne "eventend"){
      $self->LastMsg(ERROR,"invalid range field selected");
      return(undef);
   }
   if ($q{trange} eq ""){
      $self->LastMsg(ERROR,"missing timerange filter");
      return(undef);
   }
   $q{$q{trangefield}}=$q{trange};
   delete($q{trangefield});
   delete($q{trange});



   my $userid=$self->getParent->getCurrentUserId();
   $userid=-1 if (!defined($userid) || $userid==0);
   my %q1=%q;

   my $searchuser=[$userid];
   if ($dc eq "TEAM"){
      my $useracc=$ENV{REMOTE_USER};
      my %grp=$self->getParent->getGroupsOf($useracc,[orgRoles()],"down");
      my @grpids=keys(%grp);
      if ($#grpids<11){
         @grpids=(qw(-1)) if ($#grpids==-1);
         my $lnk=getModuleObject($self->getParent->Config,"base::lnkgrpuser");
         $lnk->SetFilter({grpid=>\@grpids});
         my @l=$lnk->getHashList(qw(userid));
         if ($#l!=-1){
            $searchuser=[map({$_->{userid}} @l)];
         }
      }
   }
   $q1{openuser}=$searchuser;

   if ($q1{stateid} eq ""){
      $q1{stateid}=">16";
   }
   else{
      $q1{stateid}=$q1{stateid}." AND >16"
   }

   $self->{DataObj}->ResetFilter();
   $self->{DataObj}->SecureSetFilter([\%q1]);

   my $n=$self->{DataObj}->CountRecords();

   if ($n>500){
      $self->LastMsg(ERROR,"query not selective enough");
      return(undef);
   }



   $self->{DataObj}->setDefaultView(qw(eventend eventstart class state name));


   return($self->{DataObj}->Result(ExternalFilter=>1));
}




1;
