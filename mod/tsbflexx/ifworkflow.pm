package tsbflexx::ifworkflow;
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
                autogen       =>0,
                searchable    =>0,
                sqlorder      =>'desc',
                label         =>'RecordID',
                dataobjattr   =>'TBL_ICTO_WORKFLOWS.id'),
                                  
      new kernel::Field::Text(    
                name          =>'w5baseid',
                label         =>'W5BaseID',
                dataobjattr   =>'TBL_ICTO_WORKFLOWS.w5baseid'),

      new kernel::Field::Text(    
                name          =>'name',
                sqlorder      =>'NONE',
                label         =>'Short-Description',
                dataobjattr   =>'TBL_ICTO_WORKFLOWS.shortdescription'),

      new kernel::Field::Text(    
                name          =>'class',
                sqlorder      =>'NONE',
                label         =>'Class',
                dataobjattr   =>'TBL_ICTO_WORKFLOWS.wfclass'),

      new kernel::Field::Textarea(    
                name          =>'description',
                sqlorder      =>'NONE',
                label         =>'Description',
                dataobjattr   =>'TBL_ICTO_WORKFLOWS.description'),

      new kernel::Field::Date(
                name          =>'eventend',
                sqlorder      =>'desc',
                label         =>'Event End',
                dataobjattr   =>'TBL_ICTO_WORKFLOWS.eventend'),

      new kernel::Field::Text(    
                name          =>'appl',
                sqlorder      =>'NONE',
                label         =>'Application',
                dataobjattr   =>'TBL_ICTO_WORKFLOWS.application'),

      new kernel::Field::Text(    
                name          =>'custcontract',
                sqlorder      =>'NONE',
                label         =>'Customer Contract',
                dataobjattr   =>'TBL_ICTO_WORKFLOWS.custcontract'),

      new kernel::Field::Text(    
                name          =>'tcomcodcause',
                label         =>'P800 Cause',
                dataobjattr   =>'TBL_ICTO_WORKFLOWS.tcomcodcause'),

      new kernel::Field::Text(    
                name          =>'tcomcodcomments',
                sqlorder      =>'NONE',
                label         =>'P800 Comments',
                dataobjattr   =>'TBL_ICTO_WORKFLOWS.tcomcodcomments'),

      new kernel::Field::Text(    
                name          =>'tcomexternalid',
                label         =>'P800 ExternalID',
                dataobjattr   =>'TBL_ICTO_WORKFLOWS.externalid'),

      new kernel::Field::Number(
                name          =>'tcomworktime',
                unit          =>'min',
                label         =>'Worktime',
                dataobjattr   =>'TBL_ICTO_WORKFLOWS.tcomworktime'),

      new kernel::Field::Text(
                name          =>'month',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'P800 Month',
                dataobjattr   =>'TBL_ICTO_WORKFLOWS.month'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'TBL_ICTO_WORKFLOWS.mdate'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'TBL_ICTO_WORKFLOWS.createdatetime'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'TBL_ICTO_WORKFLOWS.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'TBL_ICTO_WORKFLOWS.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'TBL_ICTO_WORKFLOWS.srcload'),
   );
   $self->setDefaultView(qw(linenumber name 
                            eventend appl custcontract));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsbflexx"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("TBL_ICTO_WORKFLOWS");
   $self->{use_distinct}=0;
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
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}

1;
