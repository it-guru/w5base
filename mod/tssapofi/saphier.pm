package tssapofi::saphier;
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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
                sqlorder      =>'desc',
                label         =>'ObjectID',
                dataobjattr   =>'ofi_saphier_import.objectid'),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                nowrap        =>1,
                uppersearch   =>1,
                label         =>'hierarchy path',
                dataobjattr   =>'ofi_saphier_import.fullname'),

      new kernel::Field::SubList(
                name          =>'psps',
                label         =>'PSP Elements',
                group         =>'psps',
                vjointo       =>'tssapofi::psp',
                vjoinon       =>['id'=>'saphierid'],
                vjoindisp     =>[qw(name)]),

      new kernel::Field::SubList(
                name          =>'costcenters',
                label         =>'costcenters',
                group         =>'costcenters',
                vjointo       =>'tssapofi::costcenter',
                vjoinon       =>['id'=>'saphierid'],
                vjoindisp     =>[qw(name)]),

      new kernel::Field::Boolean(
                name          =>'isdeleted',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'marked as deleted',
                dataobjattr   =>'ofi_saphier_import.deleted'),
                                                  
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'ofi_saphier_import.dcreatedate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'ofi_saphier_import.dmodifydate'),

#      new kernel::Field::Text(
#                name          =>'srcsys',
#                group         =>'source',
#                label         =>'Source-System',
#                dataobjattr   =>'ofi_saphier_import.srcsys'),
#
#      new kernel::Field::Text(
#                name          =>'srcid',
#                group         =>'source',
#                label         =>'Source-Id',
#                dataobjattr   =>'ofi_saphier_import.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'ofi_saphier_import.dmodifydate'),

   );
   $self->setDefaultView(qw(fullname cdate mdate));
   $self->setWorktable("ofi_saphier_import");
   return($self);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_isdeleted"))){
     Query->Param("search_isdeleted"=>"\"".$self->T("boolean.false")."\"");
   }
}




sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(0);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default costcenters psps source));
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
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
