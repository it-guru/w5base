package tsotc::appagileurl;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
                label         =>'AppAgileUrlId',
                dataobjattr   =>"appagile_routes_on_otc4darwin_vw.id"),

      new kernel::Field::Link(
                name          =>'clusterid',
                label         =>'AppAgileClusterID',
                dataobjattr   =>"appagile_namespaces_on_otc4darwin_vw.".
                                "appagile_cluster"),

      new kernel::Field::Text(
                name          =>'namespaceid',
                label         =>'AppAgileNamespaceID',
                dataobjattr   =>"concat(appagile_namespaces_on_otc4darwin_vw.".
                                "appagile_cluster,'.',".
                                "appagile_namespaces_on_otc4darwin_vw.".
                                "namespace)"),

      new kernel::Field::Link(
                name          =>'fullname',
                label         =>'AppAgileUrl',
                dataobjattr   =>"concat(".
                                "appagile_namespaces_on_otc4darwin_vw.".
                                "appagile_cluster,'.',".
                                "appagile_namespaces_on_otc4darwin_vw.".
                                "namespace,': ',".
                                "appagile_routes_on_otc4darwin_vw.".
                                "dns_route_name)"),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'DNS-Name',
                dataobjattr   =>"appagile_routes_on_otc4darwin_vw.".
                                "dns_route_name"),
      
      new kernel::Field::Boolean(
                name          =>'isdnsnamevalid',
                label         =>'is DNS-Name valid',
                dataobjattr   =>"case ".
                                "when length(substring(".
                                      "dns_route_name,'([^.]*)\.'))<=63".
                                      " then '1' ".
                                "else '0' ".
                                "end"),

      new kernel::Field::Boolean(
                name          =>'ishttps',
                label         =>'https 443',
                dataobjattr   =>"appagile_routes_on_otc4darwin_vw.".
                                "is_https443"),

      new kernel::Field::Boolean(
                name          =>'ishttp',
                label         =>'http 80',
                dataobjattr   =>"appagile_routes_on_otc4darwin_vw.".
                                "is_http80"),

      new kernel::Field::Text(
                name          =>'urltype',
                label         =>'URL Type',
                dataobjattr   =>"appagile_routes_on_otc4darwin_vw.".
                                "url_type"),

     # new kernel::Field::Text(
     #           name          =>'fullname',
     #           htmldetail    =>0,
     #           label         =>'AppAgileNamespace',
     #           dataobjattr   =>"concat(appagile_cluster,'.',namespace)"),

      new kernel::Field::Date(
                name          =>'lastmondate',
                group         =>'source',
                timezone      =>'CET',
                label         =>'last monitor date',
                dataobjattr   =>"appagile_routes_on_otc4darwin_vw.".
                                "last_monitor_date"),

   );
   $self->setDefaultView(qw(name ishttps ishttp urltype lastmondate));
   $self->setWorktable("appagile_routes_on_otc4darwin_vw");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $selfasparent=$self->SelfAsParentObject();
   my $from="$worktable ".
       "join appagile_namespaces_on_otc4darwin_vw ".
       "on $worktable.namespace=".
           "appagile_namespaces_on_otc4darwin_vw.namespace and ".
          "$worktable.appagile_cluster=".
           "appagile_namespaces_on_otc4darwin_vw.appagile_cluster";

   return($from);
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

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/urlci.jpg?".$cgi->query_string());
}



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
