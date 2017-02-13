package base::userquerybreak;
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                uivisible     =>0,
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'userquerybreak.id'),
                                                  
      new kernel::Field::Contact(
                name          =>'user',
                htmldetail    =>0,
                readonly      =>1,
                label         =>'Contact',
                vjoinon       =>'userid'),

      new kernel::Field::Link(
                name          =>'userid',
                readonly      =>1,
                dataobjattr   =>'userquerybreak.userid'),

      new kernel::Field::Text(
                name          =>'dataobj',
                label         =>'Dataobject',
                readonly      =>1,
                dataobjattr   =>'userquerybreak.dataobj'),

      new kernel::Field::Number(
                name          =>'tbreak',
                label         =>'Break after duration',
                unit          =>'sec',
                readonly      =>1,
                dataobjattr   =>'userquerybreak.duration'),

      new kernel::Field::Text(
                name          =>'clientip',
                label         =>'Client-IP',
                readonly      =>1,
                dataobjattr   =>'userquerybreak.clientip'),

      new kernel::Field::CDate(
                name          =>'cdate',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'userquerybreak.createdate'),
   );
   $self->setDefaultView(qw(linenumber cdate user dataobj clientip tbreak));
   $self->setWorktable("userquerybreak");
   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cdate"))){
      Query->Param("search_cdate"=>">now-30d");
   }
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default");
}








1;
