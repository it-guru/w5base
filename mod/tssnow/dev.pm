package tssnow::dev;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
use tssm::lib::io;

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
#   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'Sys-Id',
                group         =>'source',
                align         =>'left',
                dataobjattr   =>'cmdb_ci.sys_id'),


#ASSET
#ASSIGNMENT_GROUP
#ASSIGNMENT_GROUP_DISP
#CATEGORY
#COMMENTS
#COMPANY
#INSTALL_STATUS
#LOCATION
#MANUFACTURER
#MODEL_ID
#NAME
#OPERATIONAL_STATUS
#SHORT_DESCRIPTION
#SYS_CREATED_ON
#SYS_ID
#SYS_UPDATED_ON
#U_DATA_SOURCE
#U_EXTERNAL_ID
#U_NUMBER
#VENDOR
#X_TSIGH_INT_UCMDB_SLA
#DMA_DML_TIME


      new kernel::Field::Text(
                name          =>'fullname',
                searchable    =>0,
                htmldetail    =>0,
                label         =>'CI fullname',
                dataobjattr   =>'cmdb_ci.name'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'CI-Name',
                ignorecase    =>1,
                dataobjattr   =>'cmdb_ci.name'),

      new kernel::Field::Text(
                name          =>'shortdesc',
                label         =>'short description',
                dataobjattr   =>'cmdb_ci.short_description'),

      new kernel::Field::Text(
                name          =>'istatus',
                label         =>'install Status',
                dataobjattr   =>'cmdb_ci.INSTALL_STATUS'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                dataobjattr   =>'cmdb_ci.OPERATIONAL_STATUS'),

      new kernel::Field::Text(
                name          =>'model',
                label         =>'Model',
                searchable    =>0,
                dataobjattr   =>'cmdb_ci.MODEL_ID'),

      new kernel::Field::Text(
                name          =>'location',
                label         =>'Location',
                dataobjattr   =>'cmdb_ci.location'),

      new kernel::Field::Text(
                name          =>'iassignmentgroup',
                label         =>'Incident Assignmentgroup',
                dataobjattr   =>'cmdb_ci.ASSIGNMENT_GROUP_DISP'),

#      new kernel::Field::Text(
#                name          =>'ucmdbid',
#                label         =>'uCMDB ID',
#                group         =>'source',
#                dataobjattr   =>SELpref.'device2m1.ucmdb_id'),
#
#      new kernel::Field::Text(
#                name          =>'mandantkey',
#                label         =>'MSS Key',
#                group         =>'source',
#                dataobjattr   =>SELpref.'device2m1.tsi_mandant'),
#
#      new kernel::Field::Text(
#                name          =>'mandantname',
#                label         =>'MSS Mandant',
#                group         =>'source',
#                dataobjattr   =>SELpref.'device2m1.tsi_mandant_name'),

      new kernel::Field::MDate(
                name          =>'mdate',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                group         =>'source',
                dataobjattr   =>'cmdb_ci.SYS_UPDATED_ON'),

     new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'cmdb_ci.SYS_CREATED_ON'),
   );
   $self->setDefaultView(qw(fullname model));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssnow"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getSqlFrom
{
   my $self=shift;
   my $from="cmdb_ci";
   return($from);
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

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","source");
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}







1;
