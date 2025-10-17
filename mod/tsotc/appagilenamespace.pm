package tsotc::appagilenamespace;
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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
      new kernel::Field::Id(
                name          =>'id',
                label         =>'AppAgileNamespaceID',
                dataobjattr   =>"concat(appagile_cluster,'.',namespace)"),

      new kernel::Field::Link(
                name          =>'clusterid',
                label         =>'AppAgileClusterID',
                dataobjattr   =>"appagile_cluster"),

      new kernel::Field::Text(
                name          =>'fullname',
                htmldetail    =>0,
                label         =>'AppAgileNamespace',
                dataobjattr   =>"concat(appagile_cluster,'.',namespace)"),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                htmlwidth     =>'120',
                dataobjattr   =>"namespace"),

      new kernel::Field::TextDrop(
                name          =>'cluster',
                label         =>'AppAgile Cluster',
                weblinkto     =>\'tsotc::appagilecluster',
                weblinkon     =>['clusterid','id'],
                dataobjattr   =>"appagile_cluster"),

      new kernel::Field::Text(
                name          =>'appl',
                sqlorder      =>'desc',
                htmlwidth     =>'110',
                label         =>'Application',
                vjointo       =>\'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name'),

     new kernel::Field::Text(
                name          =>'applid',
                group         =>'source',
                label         =>'Application W5BaseID',
                dataobjattr   =>"darwin_w5baseid"),

      new kernel::Field::Date(
                name          =>'firstmondate',
                group         =>'source',
                timezone      =>'CET',
                label         =>'first monitor date',
                dataobjattr   =>"first_monitor_date"),

      new kernel::Field::Date(
                name          =>'lastmondate',
                group         =>'source',
                timezone      =>'CET',
                label         =>'last monitor date',
                dataobjattr   =>"last_monitor_date"),

   );
   $self->setDefaultView(qw(fullname appl lastmondate));
   $self->setWorktable("appagile_namespaces_on_otc4darwin_vw");
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
   return("header","default","source");
}

#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/base/load/location.jpg?".$cgi->query_string());
#}

#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_cistatus"))){
#     Query->Param("search_cistatus"=>
#                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
#   }
#}

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
