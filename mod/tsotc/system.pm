package tsotc::system;
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
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'OTC-SystemID',
                dataobjattr   =>"otc4darwin_server_vw.server_uuid"),

      new kernel::Field::Text(
                name          =>'name',
                sqlorder      =>'desc',
                label         =>'Systemname',
                dataobjattr   =>"server_name"),

      new kernel::Field::Email(
                name          =>'contactemail',
                label         =>'Contact email',
                dataobjattr   =>"lower(".
                                "case when ".
                                "otc4darwin_ias_srv_metadata_vw.asp is null ".
                                "then otc4darwin_iac_srv_metadata_vw.asp ".
                                "else otc4darwin_ias_srv_metadata_vw.asp ".
                                "end)"),

      new kernel::Field::Text(
                name          =>'projectname',
                label         =>'Project',
                weblinkto     =>\'tsotc::project',
                weblinkon     =>['projectid'=>'id'],
                dataobjattr   =>"otc4darwin_projects_vw.project_name"),

      new kernel::Field::Text(
                name          =>'availability_zone',
                label         =>'Availability Zone',
                dataobjattr   =>"availability_zone"),

      new kernel::Field::Text(
                name          =>'flavor_name',
                label         =>'Flavor',
                dataobjattr   =>"flavor_name"),

      new kernel::Field::Text(
                name          =>'image_name',
                label         =>'Image',
                dataobjattr   =>"image_name"),

      new kernel::Field::Text(
                name          =>'cpucount',
                label         =>'CPU-Count',
                dataobjattr   =>"vcpus"),

      new kernel::Field::Number(
                name          =>'memory',
                label         =>'Memory',
                unit          =>'MB',
                dataobjattr   =>'ram'),

      new kernel::Field::Link(
                name          =>'projectid',
                label         =>'OTC-ProjectID',
                dataobjattr   =>'otc4darwin_server_vw.project_uuid'),

      new kernel::Field::SubList(
                name          =>'iaascontacts',
                label         =>'IaaS Contacts',
                group         =>'iaascontacts',
                vjointo       =>\'tsotc::lnksystemiaascontact',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['contact','w5contact']),

      new kernel::Field::SubList(
                name          =>'iaccontacts',
                label         =>'IaC Contacts',
                group         =>'iaccontacts',
                vjointo       =>\'tsotc::lnksystemiaccontact',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['contact','w5contact']),

      new kernel::Field::SubList(
                name          =>'ipaddresses',
                label         =>'IP-Addresses',
                group         =>'ipaddresses',
                vjointo       =>\'tsotc::ipaddress',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['name',"hwaddr"]),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                timezone      =>'CET',
                dataobjattr   =>"date_created"),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                timezone      =>'CET',
                dataobjattr   =>"date_updated"),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                timezone      =>'CET',
                dataobjattr   =>"otc4darwin_server_vw.db_timestamp"),

   );
   $self->setDefaultView(qw(name projectname id availability_zone ));
   $self->setWorktable("otc4darwin_server_vw");
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
       "join otc4darwin_projects_vw ".
       "on $worktable.project_uuid=otc4darwin_projects_vw.project_uuid ".
       "left outer join otc4darwin_ias_srv_metadata_vw ".
       "on $worktable.server_uuid=otc4darwin_ias_srv_metadata_vw.server_uuid ".
       "left outer join otc4darwin_iac_srv_metadata_vw ".
       "on $worktable.server_uuid=otc4darwin_iac_srv_metadata_vw.server_uuid";

   return($from);
}



sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsotc"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","iaascontacts","iaccontacts","ipaddresses",
          "source");
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
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
