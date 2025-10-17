package tsadopt::vfarm;
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
                label         =>'vFarmID',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>"virtual_farm_id"),

      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'200px',
                label         =>'virtual Farm Name',
                dataobjattr   =>"virtual_farm_name"),

      new kernel::Field::Text(
                name          =>'clusterassettag',
                label         =>'ClusterAssetTag',
                dataobjattr   =>"cluster_assetTag"),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description',
                dataobjattr   =>"description"),

      new kernel::Field::Text(
                name          =>'state',
                label         =>'State',
                dataobjattr   =>"virtual_farm_state"),

      new kernel::Field::Boolean(
                name          =>'isshared',
                group         =>'state',
                label         =>'is shared',
                dataobjattr   =>"case when shared_farm='true' then ".
                                "1 else 0 END"),

      new kernel::Field::Boolean(
                name          =>'isadmin',
                group         =>'state',
                label         =>'is admin',
                dataobjattr   =>"case when admin_farm='true' then ".
                                "1 else 0 END"),

      new kernel::Field::Number(
                name          =>'vsyscount',
                precision     =>0,
                group         =>'state',
                htmldetail    =>0,
                label         =>'virtualized system count',
                dataobjattr   =>"(select count(*) ".
                   "from view_darwin_logical_system ".
                   "where view_darwin_virtual_farm.virtual_farm_id=".
                          "view_darwin_logical_system.virtual_farm_id)"),

      new kernel::Field::Number(
                name          =>'vhostcount',
                precision     =>0,
                group         =>'state',
                htmldetail    =>0,
                label         =>'virtualisation host count',
                dataobjattr   =>"(select count(*) ".
                   "from view_darwin_abstract_compute ".
                   "where view_darwin_virtual_farm.virtual_farm_id=".
                          "view_darwin_abstract_compute.virtual_farm_id)"),

      new kernel::Field::Text(
                name          =>'vhostassets',
                label         =>'virtualisation Host Assets',
                readonly      =>1,
                group         =>'vhostassets',
                vjointo       =>'tsadopt::vhost',
                vjoinon       =>['id'=>'vfarmid'],
                sortvalue     =>'asc',
                weblinkto     =>'NONE',
                vjoindisp     =>'assetid'),


      new kernel::Field::SubList(
                name          =>'vhosts',
                label         =>'virtualisation Hosts',
                readonly      =>1,
                group         =>'vhosts',
                vjointo       =>'tsadopt::vhost',
                vjoinon       =>['id'=>'vfarmid'],
                vjoindisp     =>['name','type']),

      new kernel::Field::SubList(
                name          =>'vsyss',
                label         =>'virtualized Systems',
                readonly      =>1,
                group         =>'vsyss',
                vjointo       =>'tsadopt::vsys',
                vjoinon       =>['id'=>'vfarmid'],
                vjoindisp     =>['name','systemid','ostype','vcores','slices']),

      new kernel::Field::Boolean(
                name          =>'operational',
                htmldetail    =>0,
                label         =>'operational (deprecated)',
                dataobjattr   =>"case when operational='true' then ".
                                "1 else 0 END"),

      new kernel::Field::Link(
                name          =>'teamid',
                label         =>'team id',
                dataobjattr   =>"team_id"),

      new kernel::Field::Link(
                name          =>'typeid',
                label         =>'vFarm type id',
                dataobjattr   =>"virtual_farm_type_id"),

   );
   $self->{use_distinct}=0;
   #$self->{useMenuFullnameAsACL}=$self->Self;
   $self->setDefaultView(qw(name state description));
   $self->setWorktable("view_darwin_virtual_farm");
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

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_state"))){
     Query->Param("search_state"=>"\"!inactive\"");
   }
}



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default",'state',"vhostassets","vhosts",'vsyss');
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/tsadopt/load/vfarm.jpg?".$cgi->query_string());
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

         



1;
