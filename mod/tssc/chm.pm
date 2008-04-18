package tssc::chm;
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
                htmlwidth     =>'1%',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'changenumber',
                sqlorder      =>'desc',
                label         =>'Change No.',
                htmlwidth     =>'20',
                align         =>'left',
                dataobjattr   =>'cm3rm1.numberprgn'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Brief Description',
                ignorecase    =>1,
                dataobjattr   =>'cm3rm1.brief_description'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                htmlwidth     =>20,
                dataobjattr   =>'cm3rm1.status'),

      new kernel::Field::Text(
                name          =>'softwareid',
                htmlwidth     =>'100px',
                ignorecase    =>1,
                label         =>'SoftwareID',
                dataobjattr   =>'cm3rm1.program_name'),

      new kernel::Field::Text(
                name          =>'deviceid',
                htmlwidth     =>'100px',
                ignorecase    =>1,
                label         =>'DeviceID',
                dataobjattr   =>'cm3rm1.logical_name'),

      new kernel::Field::SubList(
                name          =>'software',
                label         =>'Software',
                group         =>'software',
                htmlwidth     =>'300px',
                vjointo       =>'tssc::chm_software',
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoindisp     =>[qw(name)]),

      new kernel::Field::SubList(
                name          =>'device',
                label         =>'Device',
                group         =>'device',
                htmlwidth     =>'300px',
                vjointo       =>'tssc::chm_device',
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoindisp     =>[qw(name)]),

      new kernel::Field::SubList(
                name          =>'approvalsreq',
                label         =>'Approvals Required',
                htmlwidth     =>'200px',
                group         =>'approvals',
                vjointo       =>'tssc::chm_approvereq',
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoindisp     =>[qw(name)]),

      new kernel::Field::SubList(
                name          =>'approved',
                label         =>'Approved Groups',
                htmlwidth     =>'200px',
                group         =>'approvals',
                vjointo       =>'tssc::chm_approvedgrp',
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoindisp     =>[qw(name)]),

      new kernel::Field::Date(
                name          =>'cdate',
                timezone      =>'CET',
                label         =>'Created',
                dataobjattr   =>'cm3rm1.orig_date_entered'),

      new kernel::Field::Date(
                name          =>'plannedstart',
                timezone      =>'CET',
                label         =>'Planed Start',
                dataobjattr   =>'cm3rm1.planned_start'),

      new kernel::Field::Date(
                name          =>'plannedend',
                timezone      =>'CET',
                label         =>'Planed End',
                dataobjattr   =>'cm3rm1.planned_end'),

      new kernel::Field::Duration(
                name          =>'plannedduration',
                label         =>'Planed Duration',
                depend        =>[qw(plannedstart plannedend)]),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description',
                searchable    =>0,
                vjointo       =>'tssc::chm_description',
                vjoinconcat   =>"\n",
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoindisp     =>'description'),

      new kernel::Field::Textarea(
                name          =>'fallback',
                label         =>'Fallback',
                searchable    =>0,
                vjointo       =>'tssc::chm_fallback',
                vjoinconcat   =>"\n",
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoindisp     =>'fallback'),

      new kernel::Field::Textarea(
                name          =>'resources',
                label         =>'Resources',
                searchable    =>0,
                dataobjattr   =>'cm3ra43.resources'),

      new kernel::Field::Text(
                name          =>'priority',
                group         =>'status',
                group         =>'status',
                label         =>'Pritority',
                dataobjattr   =>'cm3rm1.priority'),

      new kernel::Field::Text(
                name          =>'impact',
                group         =>'status',
                label         =>'Business Impact',
                dataobjattr   =>'cm3rm1.impact'),

      new kernel::Field::Text(
                name          =>'urgency',
                group         =>'status',
                label         =>'Urgency',
                dataobjattr   =>'cm3rm1.urgency'),

      new kernel::Field::Text(
                name          =>'reason',
                group         =>'status',
                label         =>'Reason',
                dataobjattr   =>'cm3rm1.reason'),

      new kernel::Field::Text(
                name          =>'category',
                group         =>'status',
                label         =>'Category',
                dataobjattr   =>'cm3rm1.category'),

      new kernel::Field::Text(
                name          =>'risk',
                group         =>'status',
                label         =>'Risk',
                dataobjattr   =>'cm3rm1.risk_assessment'),

      new kernel::Field::Text(
                name          =>'type',
                group         =>'status',
                label         =>'Type',
                dataobjattr   =>'cm3rm1.class_field'),

      new kernel::Field::Date(
                name          =>'sysmodtime',
                group         =>'status',
                timezone      =>'CET',
                label         =>'SysModTime',
                dataobjattr   =>'cm3rm1.sysmodtime'),

      new kernel::Field::Date(
                name          =>'createtime',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Create time',
                dataobjattr   =>'cm3rm1.orig_date_entered'),

      new kernel::Field::Date(
                name          =>'closetime',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Closeing time',
                dataobjattr   =>'cm3rm1.close_time'),

      new kernel::Field::Text(
                name          =>'closecode',
                group         =>'close',
                label         =>'Close Code',
                dataobjattr   =>'cm3rm1.close_code_accept'),

      new kernel::Field::Text(
                name          =>'srcid',
                label         =>'Extern Change ID',
                dataobjattr   =>'cm3rm1.ex_number'),

      new kernel::Field::Date(
                name          =>'workstart',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Work Start',
                dataobjattr   =>'cm3rm1.work_start'),

      new kernel::Field::Date(
                name          =>'workend',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Work End',
                dataobjattr   =>'cm3rm1.work_end'),

      new kernel::Field::Text(
                name          =>'workduration',
                depend        =>['status'],
                group         =>'close',
                label         =>'Work Duration',
                dataobjattr   =>'cm3rm1.work_duration'),

      new kernel::Field::Import($self,
                vjointo       =>'tssc::chm_closingcomments',
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoinconcat   =>"\n",
                group         =>"close",
                depend        =>['status'],
                fields        =>['closingcomments']),

      new kernel::Field::Text(
                name          =>'assignarea',
                group         =>'contact',
                label         =>'Assign Area',
                dataobjattr   =>'cm3rm1.assigned_area'),

      new kernel::Field::Text(
                name          =>'requestedby',
                group         =>'contact',
                label         =>'Requested By',
                dataobjattr   =>'cm3rm1.requested_by'),

      new kernel::Field::Text(
                name          =>'assignedto',
                uppersearch   =>1,
                group         =>'contact',
                label         =>'Assigned To',
                dataobjattr   =>'cm3rm1.assigned_to'),

      new kernel::Field::Text(
                name          =>'coordinator',
                uppersearch   =>1,
                group         =>'contact',
                label         =>'Coordinator',
                dataobjattr   =>'cm3rm1.coordinator'),

      new kernel::Field::Text(
                name          =>'editor',
                group         =>'contact',
                label         =>'Editor',
                dataobjattr   =>'cm3rm1.sysmoduser'),

      new kernel::Field::Text(
                name          =>'addgrp',
                sqlorder      =>"none",
                group         =>'contact',
                label         =>'Additional Groups',
                dataobjattr   =>'cm3rm1.additional_groups'),

   );

   $self->setDefaultView(qw(linenumber changenumber 
                            plannedstart plannedend 
                            status name));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssc"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   $self->{use_distinct}=0;
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),qw(status contact));
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/chm.jpg?".$cgi->query_string());
}

sub getSqlFrom
{
   my $self=shift;
   my $from="cm3rm1,cm3ra43";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="(cm3rm1.lastprgn='t' or cm3rm1.lastprgn is null) and ".
             "cm3rm1.numberprgn=cm3ra43.numberprgn(+)";
   return($where);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my $st;
   if (defined($rec)){
      $st=$rec->{status};
   }
   if ($st ne "closed" && $st ne "rejected" && $st ne "resolved"){
      return(qw(contact default status header software device approvals));
   }
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}


1;
