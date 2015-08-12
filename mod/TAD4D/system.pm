package TAD4D::system;
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
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{use_distinct}=0;
   $self->{use_dirtyread}=1;

   
   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'TAD4D Computer scanid',
                dataobjattr   =>'adm.computer.computer_sys_id'),

      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Systemname',
                uivisible     =>0,
                dataobjattr   =>'adm.computer.computer_alias'),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                ignorecase    =>1,
                dataobjattr   =>'adm.computer.computer_alias'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                ignorecase    =>1,
                dataobjattr   =>'adm.agent.custom_data1'),

      new kernel::Field::Text(
                name          =>'osrelease',
                label         =>'OS-Release',
                ignorecase    =>1,
                dataobjattr   =>'adm.computer.os_name'),

      new kernel::Field::Text(
                name          =>'hwmodel',
                label         =>'Hardwaremodel',
                ignorecase    =>1,
                dataobjattr   =>'adm.computer.computer_model'),

      new kernel::Field::Text(
                name          =>'serialno',
                label         =>'Serialnumber',
                dataobjattr   =>'adm.computer.sys_ser_num'),

      new kernel::Field::Text(
                name          =>'agentversion',
                group         =>'agent',
                label         =>'Version',
                dataobjattr   =>'adm.agent.version'),

      new kernel::Field::Text(
                name          =>'agentip',
                group         =>'agent',
                label         =>'IP-Address',
                dataobjattr   =>'adm.agent.ip_address'),

      new kernel::Field::Text(
                name          =>'hostname',
                group         =>'agent',
                label         =>'Hostname',
                dataobjattr   =>'adm.agent.hostname'),

      new kernel::Field::SubList(
                name          =>'software',
                label         =>'Software',
                group         =>'software',
                forwardSearch =>1,
                vjointo       =>'TAD4D::software',
                vjoinon       =>['agentid'=>'agentid'],
                vjoinbase     =>{endtime=>\undef},
                vjoindisp     =>['software','version','isremote',
                                 'isfreeofcharge'],
                vjoininhash   =>['software','version','isremote','scope']),

      new kernel::Field::SubList(
                name          =>'nativesoftware',
                label         =>'native Software',
                group         =>'software',
                htmldetail    =>0,
                vjointo       =>'TAD4D::nativesoftware',
                vjoinon       =>['agentid'=>'agentid'],
                vjoindisp     =>['software','version']),

      new kernel::Field::Text(
                name          =>'nodeid',
                group         =>'source',
                label         =>'Node ID',
                dataobjattr   =>'adm.agent.node_id'),

      new kernel::Field::Text(
                name          =>'agentid',
                group         =>'source',
                label         =>'Agent ID',
                dataobjattr   =>'adm.agent.id'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'adm.computer.create_time'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'adm.computer.update_time'),

      new kernel::Field::Date(
                name          =>'scandate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Scan-Date',
                dataobjattr   =>'adm.agent.scan_time'),

   );
   $self->setWorktable("adm.computer");
   $self->setDefaultView(qw(systemname osrelease hwmodel agentversion scandate));
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tad4d"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_status"))){
#     Query->Param("search_status"=>"\"!out of operation\"");
#   }
#   if (!defined(Query->Param("search_tenant"))){
#     Query->Param("search_tenant"=>"CS");
#   }
#
#}




sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



         


sub getSqlFrom
{
   my $self=shift;
   my $from="adm.computer, adm.agent";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="adm.computer.computer_sys_id=adm.agent.id";
   return($where);
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
   return(qw(header default agent software 
             source));
}  

1;
