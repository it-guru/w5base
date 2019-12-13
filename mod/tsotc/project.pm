package tsotc::project;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'OTC-ProjectID',
                dataobjattr   =>"project_uuid"),

      new kernel::Field::Link(
                name          =>'domainid',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'DomainID',
                dataobjattr   =>"domain_uuid"),

      new kernel::Field::Text(
                name          =>'fullname',
                sqlorder      =>'desc',
                label         =>'OTC-Projectname',
                dataobjattr   =>"project_name"),

      new kernel::Field::Text(
                name          =>'name',
                sqlorder      =>'desc',
                label         =>'Name',
                dataobjattr   =>"regexp_replace(project_name,'^.*?_','')"),

      new kernel::Field::Text(
                name          =>'domain',
                sqlorder      =>'desc',
                label         =>'Domain',
                weblinkto     =>\'tsotc::domain',
                weblinkon     =>['domainid'=>'id'],
                dataobjattr   =>"tenant"),

      new kernel::Field::Text(
                name          =>'appl',
                sqlorder      =>'desc',
                label         =>'Application',
                vjointo       =>\'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                group         =>'systems',
                vjointo       =>\'tsotc::lnkprojectsystem',
                vjoinon       =>['id'=>'projectid'],
                vjoindisp     =>['systemname','state']),

      new kernel::Field::Number(
                name          =>'systemcount',
                label         =>'System count',
                group         =>'systems',
                htmldetail    =>0,
                dataobjattr   =>"(select count(*) from  ".
                                "otc4darwin_server_vw ".
                                "where otc4darwin_server_vw.project_uuid=".
                                      "otc4darwin_projects_vw.project_uuid)"),

      new kernel::Field::Text(
                name          =>'applid',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Application W5BaseID',
                dataobjattr   =>"cast(darwin_app_w5baseid as bigint)"),

      new kernel::Field::Date(
                name          =>'lastmondate',
                group         =>'source',
                timezone      =>'CET',
                label         =>'last monitoring date',
                dataobjattr   =>"last_monitoring_date"),

#      new kernel::Field::Text(
#                name          =>'description',
#                label         =>'Description',
#                dataobjattr   =>"tenant_description"),

   );
   $self->setDefaultView(qw(name id appl));
   $self->setWorktable("otc4darwin_projects_vw");
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsotc"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","systems","source");
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/appl.jpg?".$cgi->query_string());
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_lastmondate"))){
     Query->Param("search_lastmondate"=>">now-14d");
   }
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

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


1;
