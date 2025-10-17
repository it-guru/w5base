package ewu2::contract;
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

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>"Fullname",
                htmldetail    =>0,
                searchable    =>0,
                dataobjattr   =>"\"CONTRACTS\".\"UNAME\""),

      new kernel::Field::Text(
                name          =>'uname',
                label         =>"Name",
                dataobjattr   =>"\"CONTRACTS\".\"UNAME\""),

      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>"DevLabContractID",
                dataobjattr   =>"\"CONTRACTS\".\"CONTRACT_ID\""),

      new kernel::Field::TextDrop(
                name          =>'project',
                label         =>"Project",
                vjointo       =>'ewu2::project',
                vjoinon       =>['devlabprojectid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'owner',
                label         =>"Owner",
                vjointo       =>'ewu2::contact',
                vjoinon       =>['ownerid'=>'id'],
                searchable    =>0,
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'ownerid',
                label         =>"Owner ID",
                dataobjattr   =>"\"CONTRACTS\".\"OWNER_ID\""),

      new kernel::Field::TextDrop(
                name          =>'owner2id',
                label         =>"Deputy Owner",
                htmldetail    =>'NotEmpty',
                vjointo       =>'ewu2::contact',
                vjoinon       =>['owner2id'=>'id'],
                searchable    =>0,
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'owner2',
                label         =>"Deputy Owner ID",
                dataobjattr   =>"\"CONTRACTS\".\"OWNER2_ID\""),

      new kernel::Field::Link(
                name          =>'devlabprojectid',
                label         =>"DevLabProjectID",
                dataobjattr   =>"\"CONTRACTS\".\"PROJEKT_ID\""),


      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                group         =>'systems',
                vjointo       =>'ewu2::lnksystemcontract',
                vjoinon       =>['id'=>'devlabcontractid'],
                vjoinbase     =>{systemdeleted=>\'0'},
                vjoindisp     =>[qw(systemname systemstatus )]),

      new kernel::Field::Text(
                name          =>'servicelevel',
                label         =>"Service Level",
                dataobjattr   =>"\"CONTRACTS\".\"SERVICE_LEVEL\""),

      new kernel::Field::Textarea(
                name          =>'text',
                label         =>"Text",
                dataobjattr   =>"\"CONTRACTS\".\"TEXT\""),

      new kernel::Field::Text(
                name          =>'lockversion',
                uivisible     =>0,
                label         =>"Lock Version",
                dataobjattr   =>"\"CONTRACTS\".\"LOCK_VERSION\""),

      new kernel::Field::CDate(
                name          =>'cdate',
                timezone      =>'CET',
                group         =>"source",
                label         =>"Creation-Date",
                dataobjattr   =>"\"CONTRACTS\".\"CREATED_AT\""),

      new kernel::Field::MDate(
                name          =>'mdate',
                timezone      =>'CET',
                group         =>"source",
                label         =>"Modification-Date",
                dataobjattr   =>"\"CONTRACTS\".\"UPDATED_AT\""),

      new kernel::Field::Date(
                name          =>'ddate',
                group         =>"source",
                timezone      =>'CET',
                htmldetail    =>'NotEmpty',
                label         =>"Deletion-Date",
                dataobjattr   =>"\"CONTRACTS\".\"DELETED_AT\""),

   );
   $self->{use_distinct}=0;
   $self->setDefaultView(qw(linenumber uname id ownerid));
   $self->setWorktable("\"CONTRACTS\"");
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



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","systems","source");
}





sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
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

