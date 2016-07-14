package tssapofi::psp;
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
                dataobjattr   =>'ofi_wbs_import.objectid'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                nowrap        =>1,
                label         =>'PSP Element',
                uppersearch   =>1,
                dataobjattr   =>'ofi_wbs_import.name'),

      new kernel::Field::Boolean(
                name          =>'isdeleted',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'marked as deleted',
                dataobjattr   =>'ofi_wbs_import.deleted'),

      new kernel::Field::Text(
                name          =>'companycode',
                nowrap        =>1,
                label         =>'Company Code',
                dataobjattr   =>'ofi_wbs_import.company_code'),

      new kernel::Field::Text(
                name          =>'description',
                label         =>'Description',
                ignorecase    =>1,
                dataobjattr   =>'ofi_wbs_import.description'),

      new kernel::Field::Text(
                name          =>'supervisor_ciamid',
                label         =>'supervisor ciamid',
                group         =>'contacts',
                dataobjattr   =>'ofi_wbs_import.supervisor_ciamid'),

      new kernel::Field::Text(
                name          =>'servicemgr_ciamid',
                label         =>'servicemgr ciamid',
                group         =>'contacts',
                dataobjattr   =>'ofi_wbs_import.servicemgr_ciamid'),

      new kernel::Field::Text(
                name          =>'delivermgr_ciamid',
                label         =>'delivermgr ciamid',
                group         =>'contacts',
                dataobjattr   =>'ofi_wbs_import.delivermgr_ciamid'),

      new kernel::Field::Text(
                name          =>'saphier',
                label         =>'SAP Hierarchy',
                uppersearch   =>1,
                weblinkto     =>'tssapofi::saphier',
                weblinkon     =>['saphierid'=>'id'],
                dataobjattr   =>'ofi_saphier_import.fullname'),

      new kernel::Field::Link(
                name          =>'saphierid',
                label         =>'SAP Hierarchy ID',
                dataobjattr   =>'ofi_wbs_import.saphierid'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'ofi_wbs_import.dcreatedate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'ofi_wbs_import.dmodifydate'),

#      new kernel::Field::Text(
#                name          =>'srcsys',
#                group         =>'source',
#                label         =>'Source-System',
#                dataobjattr   =>'ofi_wbs_import.srcsys'),
#
#      new kernel::Field::Text(
#                name          =>'srcid',
#                group         =>'source',
#                label         =>'Source-Id',
#                dataobjattr   =>'ofi_wbs_import.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'ofi_wbs_import.dsrcload'),

   );
   $self->setDefaultView(qw(name description cdate mdate));
   $self->setWorktable("ofi_wbs_import");
   return($self);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_isdeleted"))){
     Query->Param("search_isdeleted"=>"\"".$self->T("boolean.false")."\"");
   }
}



sub getSqlFrom
{
   my $self=shift;
   my $from="ofi_wbs_import ".
            "left outer join ofi_saphier_import ".
            "     on ofi_wbs_import.saphierid=ofi_saphier_import.objectid";
   return($from);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
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
   return(qw(header default contacts saphier source));
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
