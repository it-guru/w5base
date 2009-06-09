package tssc::inm;
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
                name          =>'incidentnumber',
                sqlorder      =>'desc',
                searchable    =>1,
                label         =>'Incident No.',
                htmlwidth     =>'20',
                align         =>'left',
                dataobjattr   =>'problemm1.numberprgn'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Brief Description',
                ignorecase    =>1,
                dataobjattr   =>'problemm1.brief_description'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                htmlwidth     =>20,
                dataobjattr   =>'problemm1.status'),

      new kernel::Field::Text(
                name          =>'softwareid',
                label         =>'SoftwareID',
                dataobjattr   =>'problemm1.sw_name'),

      new kernel::Field::Text(
                name          =>'deviceid',
                label         =>'DeviceID',
                dataobjattr   =>'problemm1.logical_name'),

      new kernel::Field::Text(
                name          =>'custapplication',
                label         =>'Customer Application',
                dataobjattr   =>'probsummarym1.dsc_service'),

      new kernel::Field::Date(
                name          =>'cdate',
                timezone      =>'CET',
                label         =>'Created',
                dataobjattr   =>'probsummarym1.open_time'),

      new kernel::Field::Date(
                name          =>'downtimestart',
                timezone      =>'CET',
                label         =>'Downtime Start',
                dataobjattr   =>'problemm1.downtime_start'),

      new kernel::Field::Date(
                name          =>'downtimeend',
                timezone      =>'CET',
                label         =>'Downtime End',
                dataobjattr   =>'problemm1.downtime_end'),

      new kernel::Field::Textarea(
                name          =>'action',
                label         =>'Description',
                dataobjattr   =>'probsummarym1.action'),

      new kernel::Field::Textarea(
                name          =>'actionlog',
                label         =>'Actions',
                searchable    =>0,
                dataobjattr   =>'probsummarya5.update_action'),

      new kernel::Field::Textarea(
                name          =>'resolution',
                label         =>'Resolution',
                searchable    =>0,
                dataobjattr   =>'probsummarya1.resolution'),

      new kernel::Field::SubList(
                name          =>'history',
                label         =>'History',
                vjointo       =>'tssc::inm_assignment',
                vjoinon       =>['incidentnumber'=>'incidentnumber'],
                vjoininhash   =>['assignment','status'],
                vjoindisp     =>[qw(assignment status sysmodtime)]),

      new kernel::Field::Text(
                name          =>'hassignment',
                group         =>'status',
                label         =>'Home Assignment',
                dataobjattr   =>'problemm1.home_assignment'),

      new kernel::Field::Text(
                name          =>'iassignment',
                group         =>'status',
                label         =>'Initial Assignment',
                dataobjattr   =>'problemm1.initial_assignment'),

      new kernel::Field::Text(
                name          =>'rassignment',
                searchable    =>0,
                group         =>'status',
                depend        =>["history"],
                onRawValue    =>\&getResolvAssignment,
                label         =>'Resolved Assignment'),

      new kernel::Field::Text(
                name          =>'involvedassignment',
                searchable    =>0,
                group         =>'status',
                depend        =>["history"],
                onRawValue    =>\&getInvolvedAssignment,
                label         =>'Involved Assignment'),

      new kernel::Field::Text(
                name          =>'cassignment',
                group         =>'status',
                label         =>'Current Assignment',
                dataobjattr   =>'problemm1.assignment'),

      new kernel::Field::Text(
                name          =>'priority',
                group         =>'status',
                label         =>'Priority',
                dataobjattr   =>'problemm1.priority_code'),

      new kernel::Field::Select(
                name          =>'impact',
                group         =>'status',
                value         =>[qw(0 1 2 3 4)],
                transprefix   =>'impact.',
                label         =>'Business Impact',
                dataobjattr   =>'problemm1.business_impact'),
     
      new kernel::Field::Text(
                name          =>'causecode',
                group         =>'status',
                label         =>'Cause Code',
                dataobjattr   =>'problemm1.cause_code'),

      new kernel::Field::Text(
                name          =>'reason',
                group         =>'status',
                label         =>'Reason',
                dataobjattr   =>'problemm1.reason_type'),

      new kernel::Field::Text(
                name          =>'reasonby',
                group         =>'status',
                label         =>'Reason by',
                dataobjattr   =>'problemm1.reason_causedby'),

      new kernel::Field::Date(
                name          =>'sysmodtime',
                group         =>'status',
                timezone      =>'CET',
                label         =>'SysModTime',
                dataobjattr   =>'problemm1.sysmodtime'),

      new kernel::Field::Date(
                name          =>'createtime',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Create time',
                dataobjattr   =>'problemm1.open_time'),

      new kernel::Field::Date(
                name          =>'closetime',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Closeing time',
                dataobjattr   =>'problemm1.close_time'),

      new kernel::Field::Date(
                name          =>'workstart',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Work Start',
                dataobjattr   =>'problemm1.work_start'),

      new kernel::Field::Date(
                name          =>'workend',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Work End',
                dataobjattr   =>'problemm1.work_end'),

      new kernel::Field::Text(
                name          =>'reportedby',
                uppersearch   =>1,
                group         =>'contact',
                label         =>'Reported by',
                dataobjattr   =>'problemm1.reported_by'),

      new kernel::Field::Text(
                name          =>'editor',
                uppersearch   =>1,
                group         =>'contact',
                label         =>'Editor',
                dataobjattr   =>'problemm1.sysmoduser'),

      new kernel::Field::Text(
                name          =>'contactlastname',
                ignorecase    =>1,
                group         =>'contact',
                label         =>'Contact Lastname',
                dataobjattr   =>'problemm1.contact_lastname'),

      new kernel::Field::Text(
                name          =>'contactname',
                ignorecase    =>1,
                group         =>'contact',
                label         =>'Contact Name',
                dataobjattr   =>'problemm1.contact_name'),

      new kernel::Field::Link(
                name          =>'page',
                dataobjattr   =>'problemm1.page'),
   );
   $self->{use_distinct}=0;

   $self->setDefaultView(qw(linenumber incidentnumber 
                            downtimestart downtimeend status name));
   return($self);
}

sub getResolvAssignment
{
   my $self=shift;
   my $current=shift;
   my $fo=$self->getParent->getField("history");
   my $l=$fo->RawValue($current);
   my $a;
   foreach my $rec (@$l){
      $a=$rec->{assignment} if ($rec->{status} eq "closed");
   }
   return($a); 
}

sub SetFilterForQualityCheck
{
   my $self=shift;
   my @view=@_;
   return(undef);
}



sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/inm.jpg?".$cgi->query_string());
}

sub getInvolvedAssignment
{
   my $self=shift;
   my $current=shift;
   my $fo=$self->getParent->getField("history");
   my $l=$fo->RawValue($current);
   my %a;
   foreach my $rec (@$l){
      $a{$rec->{assignment}}=1;
   }
   return([sort(keys(%a))]); 
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssc"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   return(1) if (defined($self->{DB}));
   return(0);
}

sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),qw(status contact));
}



sub getSqlFrom
{
   my $self=shift;
   my $from="problemm1,probsummarym1,probsummarya1,probsummarya5";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="problemm1.numberprgn=probsummarym1.numberprgn AND ".
             "problemm1.numberprgn=probsummarya1.numberprgn AND ".
             "problemm1.numberprgn=probsummarya5.numberprgn AND ".
             "problemm1.lastprgn='t'";
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
   #if ($st ne "closed" && $st ne "rejected"){
   #   return(qw(contact default status header software device));
   #}
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}


1;
