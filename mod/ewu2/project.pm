package ewu2::project;
#  W5Base Framework
#  Copyright (C) 118  Hartmut Vogler (it@guru.de)
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
   $param{MainSearchFieldLines}=3;

   my $self=bless($type->SUPER::new(%param),$type);
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>"DevLabProjectID",
                dataobjattr   =>"\"PROJECTS\".\"PROJEKT_ID\""),

      new kernel::Field::Text(
                name          =>'name',
                label         =>"Projectname",
                dataobjattr   =>"\"PROJECTS\".\"UNAME\""),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>"Longname",
                dataobjattr   =>"\"PROJECTS\".\"LANGNAME\""),

      new kernel::Field::Link(
                name          =>'parentprojektid',
                label         =>"Parent Projekt Id",
                dataobjattr   =>"\"PROJECTS\".\"PARENT_PROJEKT_ID\""),

      new kernel::Field::SubList(
                name          =>'contracts',
                label         =>'Contracts',
                group         =>'contracts',
                vjointo       =>'ewu2::contract',
                vjoinon       =>['id'=>'devlabprojectid'],
                vjoindisp     =>[qw(fullname)]),

      new kernel::Field::Text(
                name          =>'lockversion',
                label         =>"Lock Version",
                uivisible     =>0,
                dataobjattr   =>"\"PROJECTS\".\"LOCK_VERSION\""),

      new kernel::Field::TextDrop(
                name          =>'manager',
                label         =>"Manager",
                vjointo       =>'ewu2::contact',
                vjoinon       =>['managerid'=>'id'],
                searchable    =>0,
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'managerid',
                label         =>"Manager Id",
                dataobjattr   =>"\"PROJECTS\".\"MANAGER_ID\""),

      new kernel::Field::TextDrop(
                name          =>'manager2',
                label         =>"Deputy Manager",
                htmldetail    =>'NotEmpty',
                vjointo       =>'ewu2::contact',
                vjoinon       =>['manager2id'=>'id'],
                searchable    =>0,
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'manager2id',
                label         =>"Manager2 Id",
                dataobjattr   =>"\"PROJECTS\".\"MANAGER2_ID\""),

      new kernel::Field::Textarea(
                name          =>'text',
                label         =>"Text",
                dataobjattr   =>"\"PROJECTS\".\"TEXT\""),

      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                group         =>'systems',
                vjointo       =>'ewu2::lnksystemcontract',
                vjoinon       =>['id'=>'devlabprojectid'],
                vjoinbase     =>{systemdeleted=>\'0'},
                vjoindisp     =>[qw(systemname systemstatus contractname)]),

      new kernel::Field::CDate(
                name          =>'cdate',
                label         =>"Creation-Date",
                timezone      =>'CET',
                group         =>'source',
                dataobjattr   =>"\"PROJECTS\".\"CREATED_AT\""),

      new kernel::Field::MDate(
                name          =>'mdate',
                label         =>"Modification-Date",
                timezone      =>'CET',
                group         =>'source',
                dataobjattr   =>"\"PROJECTS\".\"UPDATED_AT\""),

      new kernel::Field::Date(
                name          =>'ddate',
                label         =>"Deletion-Date",
                timezone      =>'CET',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"\"PROJECTS\".\"DELETED_AT\""),

   );
   $self->{use_distinct}=0;
   $self->setDefaultView(qw(name fullname manager));
   $self->setWorktable("\"PROJECTS\"");
   return($self);
}



sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"ewu2"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","contracts","systems","source");
}








#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
#}



sub initSearchQuery
{
   my $self=shift;
#   if (!defined(Query->Param("search_cistatus"))){
#     Query->Param("search_cistatus"=>
#                  ""!".$self->T("CI-Status(6)","base::cistatus").""");
#   }
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   return("ALL");
}


1;

