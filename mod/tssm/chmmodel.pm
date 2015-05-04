package tssm::chmmodel;
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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
use kernel::App::Web;
use kernel::DataObj::DB;
use tssm::chm;
use kernel::Field;
use tssm::lib::io;
@ISA=qw(tssm::chm);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->setDefaultView(qw(changenumber name));
   $self->getField("plannedstart")->{uivisible}=0;
   $self->getField("plannedend")->{uivisible}=0;
   $self->getField("plannedduration")->{uivisible}=0;
   $self->getField("modelid")->{uivisible}=0;
   $self->getField("phase")->{uivisible}=0;

   return($self);
}

sub getStateFilter
{
   my $self=shift;

   return(qw(tsi.cm.view.model));

}

sub initSearchQuery
{
   my $self=shift;
   my $nowlabel=$self->T("now","kernel::App");

#   if (!defined(Query->Param("search_plannedend"))){
#     Query->Param("search_plannedend"=>">$nowlabel-1d AND <$nowlabel+14d");
#   }

#   if (!defined(Query->Param("search_changenumber"))){
#     Query->Param("search_changenumber"=>"C000191883 C000146354 C000002274 ".
#                                         "C000222842 C000188772");
#   }

}

1;
