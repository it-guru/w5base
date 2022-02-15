package tsadopt::vsys;
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
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'vSysID',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>"logical_system_id"),

      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'200px',
                label         =>'virtual Hostname',
                dataobjattr   =>"system_name"),

      new kernel::Field::Text(
                name          =>'state',
                label         =>'system state',
                dataobjattr   =>"system_state"),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                dataobjattr   =>"sger"),

      new kernel::Field::Text(
                name          =>'assetid',
                label         =>'AssetID',
                dataobjattr   =>"ager"),

      new kernel::Field::TextDrop(
                name          =>'vfarm',
                label         =>'virtual Farm',
                vjointo       =>'tsadopt::vfarm',
                vjoinon       =>['vfarmid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'vfarmid',
                label         =>'vfarm id',
                dataobjattr   =>"virtual_farm_id"),

      new kernel::Field::Text(
                name          =>'os',
                label         =>'operating system',
                dataobjattr   =>"operating_system"),

      new kernel::Field::Text(
                name          =>'ostype',
                label         =>'operating system type',
                dataobjattr   =>"operating_system_type"),

      new kernel::Field::Text(
                name          =>'vcores',
                label         =>'vcores',
                dataobjattr   =>"vcores"),

      new kernel::Field::Number(
                name          =>'slices',
                label         =>'slices',
                dataobjattr   =>"slices"),

      new kernel::Field::Number(
                name          =>'drslices',
                label         =>'DR slices',
                dataobjattr   =>"dr_slices"),

      new kernel::Field::Text(
                name          =>'landscape',
                label         =>'landscape',
                dataobjattr   =>"landscape"),

      new kernel::Field::Text(
                name          =>'delivery_order',
                label         =>'DO number',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"delivery_order"),

      new kernel::Field::Text(
                name          =>'datastoreclustername',
                label         =>'Data store Cluster',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"datastore_cluster_name"),

      new kernel::Field::Text(
                name          =>'remark',
                label         =>'Remark',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"remark"),

      new kernel::Field::Text(
                name          =>'datacentername',
                htmldetail    =>'NotEmpty',
                label         =>'Data center name',
                dataobjattr   =>"data_center_name"),

      new kernel::Field::Text(
                name          =>'datacenternameshort',
                label         =>'Data center shortname',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"data_center_name_short"),

   );
   $self->{use_distinct}=0;
   #$self->{useMenuFullnameAsACL}=$self->Self;
   $self->setDefaultView(qw(name systemid assetid ostype vfarm));
   $self->setWorktable("view_darwin_logical_system");
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsadopt"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub initSqlWhere
{
   my $self=shift;
   my $where="virtual_farm_id is not null";
   return($where);
}



#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_operational"))){
#     Query->Param("search_operational"=>"\"".$self->T("yes")."\"");
#   }
#}



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default");
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/tsadopt/load/vsys.jpg?".$cgi->query_string());
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

         



1;
