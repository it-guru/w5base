package azure::skus;
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
use MIME::Base64;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);


   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'id',
                dataobjattr   =>'azure_skus.id'),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                dataobjattr   =>'azure_skus.fullname'),

      new kernel::Field::Text(
                name          =>'location',
                label         =>'Location',
                dataobjattr   =>'azure_skus.location'),

      new kernel::Field::Text(
                name          =>'resourcetype',
                label         =>'ResourceType',
                dataobjattr   =>'azure_skus.resourcetype'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'azure_skus.name'),

      new kernel::Field::Number(
                name          =>'maxsizegib',
                htmldetail    =>'NotEmpty',
                label         =>'MaxSizeGiB',
                dataobjattr   =>'azure_skus.maxsizegib'),

      new kernel::Field::Number(
                name          =>'minsizegib',
                htmldetail    =>'NotEmpty',
                label         =>'MinSizeGiB',
                dataobjattr   =>'azure_skus.minsizegib'),

      new kernel::Field::Number(
                name          =>'memorygb',
                htmldetail    =>'NotEmpty',
                label         =>'MemoryGB',
                dataobjattr   =>'azure_skus.memorygb'),

      new kernel::Field::Number(
                name          =>'memory',
                htmldetail    =>'NotEmpty',
                label         =>'Memory',
                dataobjattr   =>'(azure_skus.memorygb*1024)'),

      new kernel::Field::Text(
                name          =>'cpuarchitecturetype',
                htmldetail    =>'NotEmpty',
                label         =>'CpuArchitectureType',
                dataobjattr   =>'azure_skus.cpuarchitecturetype'),

      new kernel::Field::Number(
                name          =>'vcpus',
                htmldetail    =>'NotEmpty',
                label         =>'vCPUs',
                dataobjattr   =>'azure_skus.vcpus'),

      new kernel::Field::Number(
                name          =>'vcpuspercore',
                htmldetail    =>'NotEmpty',
                label         =>'vCPUsPerCore',
                dataobjattr   =>'azure_skus.vcpuspercore'),

      new kernel::Field::Number(
                name          =>'vcpusavailable',
                htmldetail    =>'NotEmpty',
                label         =>'vCPUsAvailable',
                dataobjattr   =>'azure_skus.vcpusavailable'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'azure_skus.comments'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'azure_skus.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'azure_skus.modifydate'),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'azure_skus.srcload'),

   );
   $self->setDefaultView(qw(fullname id name mdate));
   $self->setWorktable("azure_skus");
   return($self);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","soure");
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_isexcluded"))){
#     Query->Param("search_isexcluded"=>$self->T("no"));
#   }
#}













1;
