package tssnow::inm;
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
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB tssnow::lib::io);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'1%',
                label         =>'No.'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'Sys-Id',
                group         =>'source',
                align         =>'left',
                dataobjattr   =>'incident.sys_id'),

      new kernel::Field::Text(
                name          =>'incidentnumber',
                sqlorder      =>'desc',
                searchable    =>1,
                label         =>'Incident No.',
                htmlwidth     =>'20',
                align         =>'left',
                dataobjattr   =>'incident.number_'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Brief Description',
                sqlorder      =>'none',
                ignorecase    =>1,
                dataobjattr   =>'incident.SHORT_DESCRIPTION'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                htmlwidth     =>20,
                dataobjattr   =>'incident.state'),

      new kernel::Field::Text(
                name          =>'deviceid',
                label         =>'DeviceID',
                dataobjattr   =>'incident.cmdb_ci'),

      new kernel::Field::Text(
                name          =>'devicename',
                label         =>'Devicename',
                weblinkto     =>\'tssnow::dev',
                weblinkon     =>['deviceid'=>'id'],
                dataobjattr   =>'cmdb_ci.name'),

      new kernel::Field::Text(
                name          =>'cassignment',
                label         =>'Current Assignment',
                dataobjattr   =>'incident.ASSIGNMENT_GROUP_DISP'),

      new kernel::Field::Date(
                name          =>'sysmodtime',
                group         =>'source',
                label         =>'SysModTime',
                dataobjattr   =>'incident.sys_updated_on'),

      new kernel::Field::Date(
                name          =>'createtime',
                label         =>'Create time',
                dataobjattr   =>'incident.opened_at'),

      new kernel::Field::Date(
                name          =>'closetime',
                label         =>'Closing time',
                dataobjattr   =>'incident.closed_at'),

      new kernel::Field::Date(
                name          =>'cdate',
                label         =>'Created',
                group         =>'source',
                dataobjattr   =>'incident.opened_at'),
                                # alternativ waere da noch SYS_CREATED_ON
   );
   $self->{use_distinct}=0;

   $self->setDefaultView(qw(incidentnumber 
                            createtime closetime
                            status name));
   return($self);
}


sub isUploadValid
{
   my $self=shift;

   return(0);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/inm.jpg?".$cgi->query_string());
}

sub initSearchQuery
{
   my $self=shift;

   if (!defined(Query->Param("search_sysmodtime"))){
     Query->Param("search_sysmodtime"=>">now-14d");
   }

}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssnow"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");

   return(1) if (defined($self->{DB}));
   return(0);
}

sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return(qw(header default status relations contact close 
             w5basedata source));
}



sub getSqlFrom
{
   my $self=shift;

   my $from="incident ".
            "left outer join cmdb_ci ".
            "on incident.cmdb_ci=cmdb_ci.sys_id";
   return($from);
}


#sub initSqlWhere
#{
#   my $self=shift;
#   my $where;
#   if ($ENV{REMOTE_USER} ne "dummy/admin"){
#      $where=SELpref."probsummarym1.tsi_mandant in (".
#         join(",",map({"'".$_."'"} MandantenRestriction())).")";
#   }
#   return($where);
#}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @l=qw(header default status relations contact close source);

   return(@l);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




#sub getValidWebFunctions
#{
#   my $self=shift;
#   return("Manager",
#          "inmFinish","inmResolv","inmClose","inmAddNote","inmReopen",
#          "Process",
#          $self->SUPER::getValidWebFunctions());
#}


1;
