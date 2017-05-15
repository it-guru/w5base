package tsacinv::swinstance;
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
use tsacinv::lib::tools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB tsacinv::lib::tools);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{use_distinct}=1;

   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'full CI-Name',
                searchable    =>0,
                uppersearch   =>1,
                htmldetail    =>0,
                htmlwidth     =>'100px',
                align         =>'left',
                dataobjattr   =>"concat(amportfolio.name,concat(' ('".
                                ",concat(amportfolio.assettag,')')))"),

      new kernel::Field::Text(
                name          =>'scfullname',
                label         =>'ServiceCenter Instance fullname',
                searchable    =>0,
                uppersearch   =>1,
                htmldetail    =>0,
                htmlwidth     =>'100px',
                align         =>'left',
                dataobjattr   =>"concat(amportfolio.name,concat(' ('".
                                ",concat(amportfolio.code,')')))"),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Instance name',
                uppersearch   =>1,
                size          =>'16',
                dataobjattr   =>'amportfolio.name'),

      new kernel::Field::Id(
                name          =>'swinstanceid',
                label         =>'SWInstanceID',
                size          =>'13',
                searchable    =>1,
                uppersearch   =>1,
                align         =>'left',
                dataobjattr   =>'amportfolio.assettag'),

      new kernel::Field::TextDrop(
                name          =>'assignmentgroup',
                label         =>'Assignment Group',
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lassignmentid'=>'lgroupid'],
                vjoindisp     =>'name'),

#      new kernel::Field::TextDrop(
#                name          =>'assignmentgroupsupervisor',
#                label         =>'Assignment Group Supervisor',
#                htmldetail    =>0,
#                searchable    =>0,
#                vjointo       =>'tsacinv::group',
#                vjoinon       =>['lassignmentid'=>'lgroupid'],
#                vjoindisp     =>'supervisor'),
#
#      new kernel::Field::TextDrop(
#                name          =>'assignmentgroupsupervisoremail',
#                label         =>'Assignment Group Supervisor E-Mail',
#                htmldetail    =>0,
#                vjointo       =>'tsacinv::group',
#                vjoinon       =>['lassignmentid'=>'lgroupid'],
#                vjoindisp     =>'supervisoremail'),

      new kernel::Field::TextDrop(
                name          =>'iassignmentgroup',
                label         =>'Incident Assignment Group',
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lincidentagid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lassignmentid',
                label         =>'AC-AssignmentID',
                dataobjattr   =>'amportfolio.lassignmentid'),

      new kernel::Field::Link(
                name          =>'lincidentagid',
                label         =>'AC-Incident-AssignmentID',
                dataobjattr   =>'amportfolio.lincidentagid'),

      new kernel::Field::Text(
                name          =>'conumber',
                label         =>'CO-Number',
                size          =>'15',
                weblinkto     =>'tsacinv::costcenter',
                weblinkon     =>['lcostcenterid'=>'id'],
                dataobjattr   =>'amcostcenter.trimmedtitle'),

      new kernel::Field::Link(
                name          =>'lcostcenterid',
                label         =>'CostCenterID',
                dataobjattr   =>'amcostcenter.lcostid'),

      new kernel::Field::Link(
                name          =>'altbc',
                label         =>'Alternate BC',
                dataobjattr   =>'amcostcenter.alternatebusinesscenter'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                dataobjattr   =>'amtsiswinstance.status'),

      new kernel::Field::Text(
                name          =>'tenant',
                label         =>'Tenant',
                group         =>'source',
                dataobjattr   =>'amtenant.code'),

      new kernel::Field::Interface(
                name          =>'tenantid',
                label         =>'Tenant ID',
                group         =>'source',
                dataobjattr   =>'amtenant.ltenantid'),

      new kernel::Field::Text(
                name          =>'monname',
                label         =>'Monitoring name',
                dataobjattr   =>'amtsiswinstance.monitoringname'),

#      new kernel::Field::SubList(
#                name          =>'applications',
#                label         =>'Applications',
#                group         =>'applications',
#                vjointo       =>'tsacinv::lnkapplsystem',
#                vjoinon       =>['lportfolioitemid'=>'lchildid'],
#                vjoindisp     =>[qw(parent applid)]),

      new kernel::Field::Text(
                name          =>'portfolioid',
                group         =>'source',
                label         =>'AssetManager PortfolioID',
                dataobjattr   =>'amtsiswinstance.lportfolioid'),

      new kernel::Field::Date(
                name          =>'mdate',
                timezone      =>'CET',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'amportfolio.dtlastmodif'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'amportfolio.externalsystem'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'amportfolio.externalid'),


   );
   $self->setDefaultView(qw(fullname swinstanceid status assignmentgroup));
   return($self);
}

sub initSearchQuery
{
   my $self=shift;
#   if (!defined(Query->Param("search_name"))){
#     Query->Param("search_name"=>"*DARWIN* Q4DE8NCO967*");
#   }
   if (!defined(Query->Param("search_status"))){
     Query->Param("search_status"=>"!\"out of operation\"");
   }
   if (!defined(Query->Param("search_tenant"))){
     Query->Param("search_tenant"=>"CS");
   }
}



sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/swinstance.jpg?".$cgi->query_string());
}
         

sub getSqlFrom
{
   my $self=shift;
   my $from=
      "amtsiswinstance, ".
      "(select amportfolio.* from amportfolio ".
      " where amportfolio.bdelete=0) amportfolio,ammodel,".
      "(select amcostcenter.* from amcostcenter ".
      " where amcostcenter.bdelete=0) amcostcenter, amtenant";

   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where=
      "amportfolio.lportfolioitemid=amtsiswinstance.lportfolioid ".
      "and amportfolio.lmodelid=ammodel.lmodelid ".
      "and amportfolio.ltenantid=amtenant.ltenantid ".
      "and amportfolio.lcostid=amcostcenter.lcostid(+) ";
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
   return(qw(header default services systems source));
}  


sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),qw(ImportCluster));
}  


   




1;
