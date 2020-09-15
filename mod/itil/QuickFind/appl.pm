package itil::QuickFind::appl;
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
use kernel::QuickFind;
@ISA=qw(kernel::QuickFind);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub CISearchResult
{
   my $self=shift;
   my $stag=shift;
   my $tag=shift;
   my $searchtext=shift;
   my %param=@_;

   my @l;
   if (grep(/^ci$/,@$stag) &&
       (!defined($tag) || grep(/^$tag$/,qw(ag appl anwendung application)))){
      my $flt=[{name=>"*$searchtext*", cistatusid=>"<=5"},
               {applid=>\"$searchtext",cistatusid=>"<=5"}];
      if ($searchtext=~m/^[0-9]{2,20}$/){
         $flt=[{id=>\"$searchtext",cistatusid=>"<=5"}];
      }
      if ($tag ne "application"){
         push(@$flt,{systems=>"$searchtext",cistatusid=>"<=5"});
      }
      if ($searchtext=~m/^\d{3,20}$/){
         push(@$flt,{conumber=>\"$searchtext",
                     cistatusid=>"<=5"});
      }
      my $appl=getModuleObject($self->getParent->Config,"itil::appl");
      $appl->SetFilter($flt);
      if ($tag eq "application"){
         $appl->Limit(29);
      }
      foreach my $rec ($appl->getHashList(qw(name customer cistatusid))){
         my $dispname=$rec->{name};
         if ($rec->{customer} ne ""){
            $dispname.=' @ '.$rec->{customer};
         }
         push(@l,{group=>$self->getParent->T("itil::appl","itil::appl"),
                  id=>$rec->{id},
                  parent=>$self->Self,
                  shortname=>$rec->{name},
                  cistatusid=>$rec->{cistatusid},
                  name=>$dispname});
      }
   }
   return(@l);
}

sub QuickFindDetail
{
   my $self=shift;
   my $id=shift;
   my $htmlresult="?";

   my $appl=getModuleObject($self->getParent->Config,"itil::appl");
   $appl->SetFilter({id=>\$id});
   my @view=qw(mandator delmgr delmgr2 conumber cistatus
               applmgr
               sem sem2 tsm tsm2 databoss
               itsem itsem2
               systemnames
               customerprio phonenumbers
               description businessteam);
   my ($rec,$msg)=$appl->getOnlyFirst(@view);
   $appl->ResetFilter();
   $appl->SecureSetFilter([{id=>\$id}]);
   my ($secrec,$msg)=$appl->getOnlyFirst(qw(id));

   if (defined($rec)){
      $htmlresult="";
      if (defined($secrec)){
         $htmlresult.=$self->addDirectLink($appl,{search_id=>$id});
      }
      $htmlresult.=$appl->HtmlPublicDetail($rec,0);
   }
   return($htmlresult);
}



1;
