package tsacinv::customer;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use Data::Dumper;
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
                label         =>'UnitID',
                dataobjattr   =>'amtsiaccsecunit.lunitid'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                uppersearch   =>1,
                dataobjattr   =>'amtsiaccsecunit.identifier'),

      new kernel::Field::Text(      
                name          =>'fullname',
                ignorecase    =>1,
                label         =>'Description',
                dataobjattr   =>'amtsiaccsecunit.description'),

      new kernel::Field::TextDrop(
                name          =>'delmgr',
                searchable    =>0,
                label         =>'Delivery Manager',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['delmgrid'=>'lempldeptid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'delmgrid',
                dataobjattr   =>'amtsiaccsecunit.ldeliverymanagerid'),

      new kernel::Field::Text(
                name          =>'code',
                label         =>'Code',
                dataobjattr   =>'amtsiaccsecunit.code'),

      new kernel::Field::TextDrop(
                name          =>'defaultsclocation',
                label         =>'Default SC Location',
                vjoinon       =>['defaultsclocationid'=>'id'],
                vjointo       =>'tsacinv::sclocation',
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'defaultsclocationid',
                label         =>'defaultsclocationid',
                dataobjattr   =>'amtsiaccsecunit.ldefaultsclocationid'),

      new kernel::Field::Date(
                name          =>'mdate',
                timezone      =>'CET',
                label         =>'Modification date',
                dataobjattr   =>'amtsiaccsecunit.dtlastmodif'),
   );
   $self->setDefaultView(qw(linenumber id name fullname));
   $self->setWorktable("amtsiaccsecunit");
   return($self);
}

sub Initialize
{
   my $self=shift;
   
   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="amtsiaccsecunit.lunitid<>0 ";
   return($where);
}


         


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

1;
