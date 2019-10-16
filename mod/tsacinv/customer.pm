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
use tsacinv::lib::tools;

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB tsacinv::lib::tools);

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
                dataobjattr   =>'"id"'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                uppersearch   =>1,
                dataobjattr   =>'"name"'),

      new kernel::Field::Text(      
                name          =>'fullname',
                ignorecase    =>1,
                label         =>'Description',
                dataobjattr   =>'"fullname"'),

      new kernel::Field::TextDrop(
                name          =>'delmgr',
                searchable    =>0,
                label         =>'Delivery Manager',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['delmgrid'=>'lempldeptid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'delmgrid',
                dataobjattr   =>'"delmgrid"'),

      new kernel::Field::Text(
                name          =>'code',
                label         =>'Code',
                dataobjattr   =>'"code"'),

      new kernel::Field::TextDrop(
                name          =>'defaultsclocation',
                label         =>'Default SC Location',
                vjoinon       =>['defaultsclocationid'=>'id'],
                vjointo       =>'tsacinv::sclocation',
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'defaultsclocationid',
                label         =>'defaultsclocationid',
                dataobjattr   =>'"defaultsclocationid"'),

      new kernel::Field::Date(
                name          =>'mdate',
                timezone      =>'CET',
                label         =>'Modification date',
                dataobjattr   =>'"mdate"'),
   );
   $self->setDefaultView(qw(linenumber id name fullname));
   $self->setWorktable("customer");
   return($self);
}

sub Initialize
{
   my $self=shift;
   
   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   $self->amInitializeOraSession();
   return(1) if (defined($self->{DB}));
   return(0);
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
