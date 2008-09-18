package itil::MyW5Base::itilwfreport;
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
use kernel::Field;
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

   $self->{Field}->{from}=new kernel::Field::Date(
                Parent        =>$self,
                name          =>'from',
                label         =>'From');

   $self->{Field}->{to}=new kernel::Field::Date(
                Parent        =>$self, 
                name          =>'to',
                label         =>'To');

   $self->{Val}->{wfclass}=["",qw(problem change incident eventnotify)];

   $self->{Val}->{refto}=[qw(eventend eventstart createdate mdate closedate)];

   return(0) if (!defined($self->{DataObj}));
   return($self->SUPER::Init(@_));
}

sub doAutoSearch
{
   my $self=shift;

   return(0);
}


sub isSelectable
{
   my $self=shift;
   my %param=@_;
 
   my $u=$param{user};
   if (ref($u->{groups}) eq "ARRAY"){  
      foreach my $grprec (@{$u->{groups}}){ 
         if (ref($grprec->{roles}) eq "ARRAY"){
            return(1) if (grep(/^(RINManager|RCHManager|RPRManager|RAuditor)$/,
                          @{$grprec->{roles}}));
         }
      }
   }
   return(1) if ($self->getParent->IsMemberOf("admin"));
   return(0);
}



sub getQueryTemplate
{
   my $self=shift;

   #######################################################################
   my @wfclass=@{$self->{Val}->{wfclass}};

   my $reptyp="<select name=search_wfclass style=\"width:100%\">";
   my $oldval=Query->Param("search_wfclass");
   foreach my $wfclass (@wfclass){
      $reptyp.="<option value=\"$wfclass\"";
      $reptyp.=" selected" if ($wfclass eq $oldval);
      $reptyp.=">".$self->T($wfclass)."</option>";
   }
   $reptyp.="</select>";
   #######################################################################
   my @refto=@{$self->{Val}->{refto}};

   my $refsel="<select name=search_refto style=\"width:100%\">";
   my $oldval=Query->Param("search_refto");
   foreach my $refto (@refto){
      $refsel.="<option value=\"$refto\"";
      $refsel.=" selected" if ($refto eq $oldval);
      $refsel.=">".$self->T($refto)."</option>";
   }
   $refsel.="</select>";
   #######################################################################

   my $m1=$self->getParent->T("enclose all not finshed eventnotifications");
   my $showallsel;
   $showallsel="checked" if (Query->Param("SHOWALL"));

   
   my $froml=$self->{Field}->{from}->label;
   my $froms=$self->{Field}->{from}->FormatedSearch();

   my $tol=$self->{Field}->{to}->label;
   my $tos=$self->{Field}->{to}->FormatedSearch();


   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>Workflow Klasse:</td>
<td class=finput width=40%>$reptyp</td>
<td class=fname width=10%>Bezugsfeld:</td>
<td class=finput width=40%>$refsel</td>
</tr>
<tr>
<td class=fname width=10%>$froml:</td>
<td class=finput width=40%>$froms</td>
<td class=fname width=10%>$tol:</td>
<td class=finput width=40%>$tos</td>
</tr>
<tr>
<td class=fname width=10%>\%affectedapplication(label)\%:</td>
<td class=finput width=40%>\%affectedapplication(search)\%</td>
<td class=fname width=10%>&nbsp;</td>
<td class=finput width=40%>&nbsp;</td>
</tr>
<tr>
<td class=fname width=10%>\%state(label)\%:</td>
<td class=finput width=40%>\%state(search)\%</td>
<td class=fname width=10%>\%prio(label)\%:</td>
<td class=finput width=40%>\%prio(search)\%</td>
</tr>
</table>
</div>
%StdButtonBar(bookmark,search)%
EOF
   return($d);
}


sub SetFilter
{
   my $self=shift;
   my $dataobj=$self->getDataObj();



}




sub Result
{
   my $self=shift;
   my %q=$self->getDataObj()->getSearchHash();

   return(undef) if (!(my $f=$self->{Field}->{from}->Unformat($q{from})));
   $q{from}=$f->{from};

   return(undef) if (!(my $f=$self->{Field}->{to}->Unformat($q{to})));
   $q{to}=$f->{to};

   $q{duration}=CalcDateDuration($q{from},$q{to},"GMT");
   if ($q{duration}->{totalseconds}<0){
      $self->LastMsg(ERROR,"from is later then to");
      return(undef);
   }
   if (!grep(/^$q{refto}$/,@{$self->{Val}->{refto}}) ||
       !grep(/^$q{wfclass}$/,@{$self->{Val}->{wfclass}})){
      $self->LastMsg(ERROR,"invalid request for this module");
      return(undef);
   }
   if ($q{wfclass} eq "" || $q{to} eq "" || $q{from} eq ""){
      $self->LastMsg(ERROR,"missing query param to prozess this request");
      return(undef);
   }

printf STDERR ("fifi parent of DataObj=%s\n",$self->getDataObj()->getParent());
printf STDERR ("fifi parent of meine=%s\n",$self->getParent());
printf STDERR ("fifi search=%s\n",Dumper(\%q));
   

   return(undef);

#   my $userid=$self->getParent->getCurrentUserId();
#   $userid=-1 if (!defined($userid) || $userid==0);
#
#   my %q1=%q;
#   my %q2=%q;
#   if (Query->Param("SHOWALL")){
#      $q1{stateid}='<20';
#      $q1{class}=[grep(/^.*::eventnotify$/,
#                  keys(%{$self->{DataObj}->{SubDataObj}}))];
#   }
#   else{
#      $q1{stateid}='<20';
#      $q1{eventend}="[EMPTY]";
#      $q1{class}=[grep(/^.*::eventnotify$/,
#                       keys(%{$self->{DataObj}->{SubDataObj}}))];
#      $q2{stateid}='<20';
#      $q2{eventend}=">now";
#      $q2{class}=[grep(/^.*::eventnotify$/,
#                       keys(%{$self->{DataObj}->{SubDataObj}}))];
#   }
#
#
#   $self->{DataObj}->ResetFilter();
#   $self->{DataObj}->SecureSetFilter([\%q1,\%q2]);
#   $self->{DataObj}->setDefaultView(qw(linenumber eventstart name  
#                                       eventduration state));
   my %param=(ExternalFilter=>1,
              Limit=>50);
   return($self->{DataObj}->Result(%param));
}



1;
