package itil::QuickFind::system;
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
   if (in_array("ci",$stag) &&
       (!defined($tag) || in_array($tag,[qw(system sys server)]))){
      my $flt=[{name=>"$searchtext",cistatusid=>"<=5"},
               {systemid=>"$searchtext"}];
      push(@$flt,{applications=>"$searchtext",cistatusid=>"<=5"});
      if ($searchtext=~m/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/){
         push(@$flt,{ipaddresses=>"$searchtext"});
      }
      elsif ($searchtext=~m/^[a-f,0-9]{2}(:[a-f,0-9]{2}){5}$/){
         push(@$flt,{macadresses=>"$searchtext"});
      }
      else{
         if (!in_array($tag,[qw(system sys server)])){
            if ($searchtext=~m/\./){
               push(@$flt,{dnsnamelist=>\"$searchtext"});
            }
            else{
               push(@$flt,{dnsnamelist=>"$searchtext.*"});
            }
         }
      }
      if ($searchtext=~m/^\d{3,20}$/){
         push(@$flt,{conumber=>\"$searchtext",
                     cistatusid=>"<=5"});
      }
      my $dataobj=getModuleObject($self->getParent->Config,"itil::system");
      $dataobj->SetFilter($flt);
      if ($tag eq "system"){
         $dataobj->Limit(29);
      }
      foreach my $rec ($dataobj->getHashList(qw(name cistatusid))){
         my $dispname=$rec->{name};
         push(@l,{group=>$self->getParent->T("itil::system","itil::system"),
                  id=>$rec->{id},
                  parent=>$self->Self,
                  name=>$dispname,
                  cistatusid=>$rec->{cistatusid},
                  shortname=>$dispname});
      }
   }
   return(@l);
}

sub QuickFindDetail
{
   my $self=shift;
   my $id=shift;
   my $htmlresult="?";

   my $system=getModuleObject($self->getParent->Config,"itil::system");
   $system->SetFilter({id=>\$id});
   my ($rec,$msg)=$system->getOnlyFirst(qw(mandator
                                           name systemid adm adm2 databoss
                                           phonenumbers adminteam
                                           applications));
   $system->ResetFilter();
   $system->SecureSetFilter([{id=>\$id}]);
   my ($secrec,$msg)=$system->getOnlyFirst(qw(id));

   if (defined($rec)){
      $htmlresult="";
      if (defined($secrec)){
         $htmlresult.=$self->addDirectLink($system,{search_id=>$id});
      }
      $htmlresult.=$system->HtmlPublicDetail($rec,0);
   }
   return($htmlresult);
}



1;
