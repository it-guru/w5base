package TS::lnkorgdom;
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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

   $self->{use_distinct}=1; 

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                label         =>'LnkID',
                dataobjattr   =>'lnkorgdom.id'),

      new kernel::Field::Text(
                name          =>'orgdomid',
                label         =>'OrgDomainID',
                dataobjattr   =>'lnkorgdom.orgdomid'),

      new kernel::Field::Text(
                name          =>'ictono',
                htmldetail    =>0,
                uploadable    =>0,
                label         =>'ICTO-ID',
                dataobjattr   =>'lnkorgdom.ictono'),

      new kernel::Field::Text(
                name          =>'ictoid',
                htmldetail    =>0,
                uploadable    =>0,
                label         =>'ICTO internal ID',
                dataobjattr   =>'lnkorgdom.ictoid'),

      new kernel::Field::Percent(
                name          =>'fraction',
                label         =>'Fraction',
                searchable    =>0,
                default       =>'100',
                htmlwidth     =>'60px',
                dataobjattr   =>'lnkorgdom.fraction'),

      new kernel::Field::Text(
                name          =>'vouid',
                label         =>'VouID',
                dataobjattr   =>'lnkorgdom.vouid'),
   );
   $self->setDefaultView(qw(orgdomid ictono ictoid vouid));
   $self->setWorktable("lnkorgdom");
   return($self);
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
   return("header","default") if (!defined($rec));
   return("ALL");
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
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default source ));
}



1;
