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
use kernel::Universal;
@ISA=qw(kernel::Universal);


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
   my $searchtext=shift;
   my %param=@_;

   my $appl=getModuleObject($self->getParent->Config,"itil::system");
   $appl->SetFilter([{name=>"$searchtext"},{applications=>"$searchtext"},
                     {systemid=>"$searchtext"}]);
   my @l;
   foreach my $rec ($appl->getHashList(qw(name))){
      my $dispname=$rec->{name};
      push(@l,{group=>$self->getParent->T("itil::system","itil::system"),
               id=>$rec->{id},
               parent=>$self->Self,
               name=>$dispname});
   }
   return(@l);
}

sub QuickFindDetail
{
   my $self=shift;
   my $id=shift;
   my $htmlresult="?";

   my $appl=getModuleObject($self->getParent->Config,"itil::system");
   $appl->SetFilter({id=>\$id});
   my ($rec,$msg)=$appl->getOnlyFirst(qw(systemid adm adm2 applications));
   if (defined($rec)){
      $htmlresult="<table>";
      my @l=qw(systemid adm adm2 admteam);
      foreach my $v (@l){
         if ($rec->{$v} ne ""){
            my $name=$appl->getField($v)->Label();
            my $data=$appl->findtemplvar({current=>$rec,mode=>"HtmlDetail"},
                                         $v,"formated");
            $htmlresult.="<tr><td nowrap valign=top width=1%>$name:</td>".
                         "<td valign=top>$data</td></tr>";
         }
      }
      $htmlresult.="</table>";
   }
   return($htmlresult);
}



1;
