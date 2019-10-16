package tsdina::system;
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
   #$param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'1%',
                label         =>'No.'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Systemname',
                ignorecase    =>1,
                dataobjattr   =>'w5map.servername'),

      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'DinaHostID',
                dataobjattr   =>"cfm.host_id"),

      new kernel::Field::Text(
                name          =>'w5baseid',
                label         =>'W5BaseID',
                weblinkto     =>'itil::system',
                weblinkon     =>['w5baseid'=>'id'],
                dataobjattr   =>'w5map.w5baseid'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                dataobjattr   =>'cfm.systemid'),

      new kernel::Field::Text(
                name          =>'assetid',
                label         =>'AssetID',
                dataobjattr   =>'cfm.assetid'),

      new kernel::Field::Text(
                name          =>'os_name',
                group         =>'os',
                label         =>'OS Name',
                dataobjattr   =>'cfm.os'),

      new kernel::Field::Text(
                name          =>'os_type',
                group         =>'os',
                label         =>'OS Type',
                dataobjattr   =>'cfm.os_type'),

      new kernel::Field::Text(
                name          =>'os_version',
                group         =>'os',
                label         =>'OS Version',
                dataobjattr   =>'cfm.os_version'),

      new kernel::Field::Text(
                name          =>'os_revison',
                group         =>'os',
                label         =>'OS Revison',
                dataobjattr   =>'cfm.os_revision'),

      new kernel::Field::Text(
                name          =>'platform',
                label         =>'Platform',
                group         =>'lpar',
                dataobjattr   =>'dina_asset_info_vw.software_system'),

      new kernel::Field::Text(
                name          =>'hwmodel',
                label         =>'Hardware Model',
                group         =>'sysenv',
                dataobjattr   =>'cfm.hw_model'),

      new kernel::Field::Text(
                name          =>'dinaagent',
                label         =>'DINA Agent',
                group         =>'sysenv',
                dataobjattr   =>'dina_asset_info_vw.dina_agent_version'),

      new kernel::Field::Text(
                name          =>'cpusockets',
                label         =>'CPU Socket count ',
                group         =>'sysenv',
                dataobjattr   =>'cfm.cpu_sockets'),

      new kernel::Field::Text(
                name          =>'cpucorespersocket',
                label         =>'CPU Cores per Socket',
                group         =>'sysenv',
                dataobjattr   =>'cfm.cpu_cores_per_socket'),

      new kernel::Field::Text(
                name          =>'corecount',
                label         =>'Core Count',
                group         =>'sysenv',
                dataobjattr   =>'cfm.cpu_cores'),

      new kernel::Field::Text(
                name          =>'smtcount',
                label         =>'SMT Count',
                group         =>'sysenv',
                dataobjattr   =>'cfm.threads'),

      new kernel::Field::Text(
                name          =>'memory_size',
                label         =>'Memory Size',
                unit          =>'MB',
                group         =>'sysenv',
                dataobjattr   =>'cfm.memory_size'),

      new kernel::Field::Text(
                name          =>'memory_size',
                label         =>'Memory Size',
                group         =>'sysenv',
                dataobjattr   =>
                   "CASE ".
                   "WHEN cfm.memory_unit='GB' ".
                   " THEN memory_size*1024 ".
                   "WHEN cfm.memory_unit='MB' ".
                   " THEN memory_size ".
                   "ELSE ".
                   " NULL ".
                   "END"),

      new kernel::Field::Text(
                name          =>'lpartype',
                group         =>'lpar',
                label         =>'LPAR Type',
                dataobjattr   =>'aixcfg.lpar_type'),

      new kernel::Field::Text(
                name          =>'lparmode',
                group         =>'lpar',
                selectfix     =>1,
                label         =>'LPAR Mode',
                dataobjattr   =>'aixcfg.lpar_mode'),

     new kernel::Field::Text(
                name          =>'ec',
                group         =>'lpar',
                label         =>'Entitled Capacity',
                dataobjattr   =>'aixcfg.entitled_capacity'),

      new kernel::Field::Text(
                name          =>'sharedpoolid',
                group         =>'lpar',
                label         =>'Shared Pool ID',
                dataobjattr   =>'aixcfg.shared_pool_id'),

      new kernel::Field::Number(
                name          =>'onlinevirtcpu',
                group         =>'lpar',
                label         =>'Online Virtual CPUs',
                dataobjattr   =>'aixcfg.online_virtual_cpus'),

      new kernel::Field::Text(
                name          =>'actphyscpusinsystem',
                group         =>'lpar',
                label         =>'Active physical CPUs in System',
                dataobjattr   =>'dina_asset_info_vw.active_physical_cpus_in_system'),

      new kernel::Field::Text(
                name          =>'actcpusinspool',
                group         =>'lpar',
                label         =>'Active CPUs in Pool',
                dataobjattr   =>'aixcfg.active_cpus_in_pool'),

      new kernel::Field::SubList(
                name          =>'swinstances',
                label         =>'Software instances',
                group         =>'swinstances',
                vjointo       =>'tsdina::swinstance',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>[qw(dinainstancename)],
                forwardSearch =>1,
      ),

   );
   $self->setDefaultView(qw(name systemid id platform));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsdina"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getSqlFrom
{
   my $self=shift;
   my $from="d2dw_system_config_vw cfm ".
            "left outer join dina_darwin_map_vw w5map ".
            "on cfm.host_id = w5map.host_id ".
            "left outer join d2dw_aix_config_vw aixcfg ".
            "on (cfm.host_id=aixcfg.host_id and ".
                "aixcfg.datetime = trunc(sysdate)) ".
            "left outer join dina_asset_info_vw ".
            "on cfm.host_id=dina_asset_info_vw.host_id";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="current_date between cfm.valid_from and cfm.valid_to";
   return($where);
}



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","os","sysenv","lpar","swinstances");
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @view=qw(header default sysenv os source);
   push (@view,'lpar') if (defined $rec->{lparmode});
   push (@view,'swinstances');
   return @view;
}

sub isUploadValid
{
   return(0);
}



1;
