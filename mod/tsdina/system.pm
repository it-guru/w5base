package tsdina::system;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
                dataobjattr   =>'servername'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'SystemID',
                dataobjattr   =>"systemid"),

      new kernel::Field::Text(
                name          =>'w5baseid',
                label         =>'W5BaseID',
                weblinkto     =>'itil::system',
                weblinkon     =>['w5baseid'=>'id'],
                dataobjattr   =>'w5baseid'),

      new kernel::Field::Text(
                name          =>'hostid',
                label         =>'HostID',
                htmldetail    =>0,
                dataobjattr   =>'host_id'),

      new kernel::Field::Text(
                name          =>'platform',
                label         =>'Platform',
                dataobjattr   =>'software_system'),

      new kernel::Field::Text(
                name          =>'t4dserverid',
                label         =>'TAD4D ServerID',
                dataobjattr   =>"CASE
                                  WHEN HW_IMPLEMENTATION IS NOT NULL
                                   AND VENDOR_SERIAL_NUMBER IS NOT NULL
                                  THEN
                                   'IBM'
                                   || ' '
                                   || SUBSTR (
                                       SUBSTR (HW_IMPLEMENTATION,
                                        INSTR (HW_IMPLEMENTATION,',')+1),1,
                                        INSTR (
                                         SUBSTR (HW_IMPLEMENTATION,
                                          INSTR (HW_IMPLEMENTATION,',')+1),'-',
                                          -1)
                                        - 1)
                                   || ' '
                                   || VENDOR_SERIAL_NUMBER
                                  ELSE NULL
                                 END"),

      new kernel::Field::Text(
                name          =>'dinaagent',
                label         =>'DINA Agent',
                dataobjattr   =>'dina_agent_version'),

      new kernel::Field::Text(
                name          =>'lpartype',
                group         =>'lpar',
                label         =>'LPAR Type',
                dataobjattr   =>'lpar_type'),

      new kernel::Field::Text(
                name          =>'lparmode',
                group         =>'lpar',
                label         =>'LPAR Mode',
                dataobjattr   =>'lpar_mode'),

     new kernel::Field::Text(
                name          =>'ec',
                group         =>'lpar',
                label         =>'Entitled Capacity',
                dataobjattr   =>'entitled_capacity'),

      new kernel::Field::Text(
                name          =>'sharedpoolid',
                group         =>'lpar',
                label         =>'Shared Pool ID',
                dataobjattr   =>'shared_pool_id'),

      new kernel::Field::Number(
                name          =>'onlinevirtcpu',
                group         =>'lpar',
                label         =>'Online Virtual CPUs',
                dataobjattr   =>'online_virtual_cpus'),

      new kernel::Field::Text(
                name          =>'actphyscpusinsystem',
                group         =>'lpar',
                label         =>'Active physical CPUs in System',
                dataobjattr   =>'active_physical_cpus_in_system'),

      new kernel::Field::Text(
                name          =>'actcpusinspool',
                group         =>'lpar',
                label         =>'Active CPUs in Pool',
                dataobjattr   =>'active_cpus_in_pool'),

      new kernel::Field::SubList(
                name          =>'swinstances',
                label         =>'Software instances',
                group         =>'swinstances',
                vjointo       =>'tsdina::swinstance',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>[qw(dinainstancename)],
                forwardSearch =>1,
      ),

   );
   $self->setDefaultView(qw(name id platform));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsdina"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getSqlFrom
{
   my $self=shift;
   my $from="dina_asset_info_vw";
   return($from);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","lpar","swinstances");
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
   my @view=qw(header default);
   push (@view,'lpar') if (defined $rec->{lparmode});
   push (@view,'swinstances');
   return @view;
}

sub isUploadValid
{
   return(0);
}



1;
