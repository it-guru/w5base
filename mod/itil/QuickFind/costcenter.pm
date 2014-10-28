package itil::QuickFind::costcenter;
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
       ($searchtext=~m/^\d{3,20}$/)){
      my $flt=[{name=>\"$searchtext"}];
      my $dataobj=getModuleObject($self->getParent->Config,"itil::costcenter");
      $dataobj->SetFilter($flt);
      foreach my $rec ($dataobj->getHashList(qw(name fullname))){
         my $dispname=$rec->{name};
         if ($rec->{fullname} ne ""){
            $dispname.=' ; '.$rec->{fullname};
         }
         push(@l,{group=>$self->getParent->T("itil::costcenter",
                                             "itil::costcenter"),
                  id=>$rec->{id},
                  parent=>$self->Self,
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

   my $dataobj=getModuleObject($self->getParent->Config,"itil::costcenter");
   $dataobj->SetFilter({id=>\$id});
   my ($rec,$msg)=$dataobj->getOnlyFirst(qw(fullname delmgr delmgr2));
   $dataobj->ResetFilter();
   $dataobj->SecureSetFilter([{id=>\$id}]);
   my ($secrec,$msg)=$dataobj->getOnlyFirst(qw(id));

   if (defined($rec)){
      $htmlresult="";
      if (defined($secrec)){
         $htmlresult.=$self->addDirectLink($dataobj,{search_id=>$id});
      }
      $htmlresult.="<table>";
      my @l=qw(fullname delmgr delmgr2);
      foreach my $v (@l){
         if ($rec->{$v} ne ""){
            my $name=$dataobj->getField($v)->Label();
            my $data=$dataobj->findtemplvar({current=>$rec,mode=>"HtmlDetail"},
                                         $v,"formated");
            $htmlresult.="<tr><td nowrap valign=top width=1%>$name:</td>".
                         "<td valign=top>$data</td></tr>";
         }
      }
   }
   return($htmlresult);
}



1;
