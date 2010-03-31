package itil::MyW5Base::openeventinfo;
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
   my $m1=$self->getParent->T("enclose all not finshed eventnotifications");
   my $showallsel;
   $showallsel="checked" if (Query->Param("SHOWALL"));
   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>\%affectedapplication(label)\%:</td>
<td class=finput width=40%>\%affectedapplication(search)\%</td>
<td class=fname width=10%>\%affectedcontract(label)\%:</td>
<td class=finput width=40%>\%affectedcontract(search)\%</td>
</tr>
<tr>
<td class=fname width=10%>&nbsp;</td>
<td class=finput width=40%>&nbsp;</td>
<td class=fname colspan=2><input type=checkbox $showallsel name=SHOWALL>$m1</td>
</tr>
</table>
</div>
%StdButtonBar(bookmark,search)%
EOF
   return($d);
}


sub Result
{
   my $self=shift;
   my %q=$self->{DataObj}->getSearchHash();

   if ($ENV{REMOTE_USER} eq "anonymous"){
      $q{id}=\"-1";
   }
   my $userid=$self->getParent->getCurrentUserId();
   $userid=-1 if (!defined($userid) || $userid==0);

   my %q1=%q;
   my %q2=%q;
   my %q3=%q;
   $self->{DataObj}->ResetFilter();
   if (Query->Param("SHOWALL")){
      $q1{stateid}='<20';
      $q1{isdeleted}=\'0';
      $q1{class}=[grep(/^.*::eventnotify$/,
                  keys(%{$self->{DataObj}->{SubDataObj}}))];
      $self->{DataObj}->SecureSetFilter([\%q1]);
   }
   else{
      $q1{stateid}='<20';
      $q1{isdeleted}=\'0';
      $q1{eventend}="[EMPTY]";
      $q1{class}=[grep(/^.*::eventnotify$/,
                       keys(%{$self->{DataObj}->{SubDataObj}}))];
      $q2{stateid}='<20';
      $q2{isdeleted}=\'0';
      $q2{eventend}=">now";
      $q2{class}=[grep(/^.*::eventnotify$/,
                       keys(%{$self->{DataObj}->{SubDataObj}}))];

      $q3{stateid}='<20';
      $q3{isdeleted}=\'0';
      $q3{eventend}="<now AND >now-60m";
      $q3{class}=[grep(/^.*::eventnotify$/,
                       keys(%{$self->{DataObj}->{SubDataObj}}))];
      $self->{DataObj}->SecureSetFilter([\%q1,\%q2,\%q3]);
   }


   $self->{DataObj}->setDefaultView(qw(linenumber eventstart name  
                                       eventduration state));
   my %param=(ExternalFilter=>1,
              Limit=>50);
   return($self->{DataObj}->Result(%param));
}



1;
