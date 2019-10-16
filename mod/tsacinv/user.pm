package tsacinv::user;
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
   $param{MainSearchFieldLines}=5;
   my $self=bless($type->SUPER::new(%param),$type);

   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'lempldeptid',
                label         =>'UserID',
                searchable    =>0,
                dataobjattr   =>'"lempldeptid"'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                htmlwidth     =>'250',
                searchable    =>0,
                onRawValue    =>\&mkFullname,
                depend        =>['name','email','firstname','deleted']),

      new kernel::Field::Text(
                name          =>'acfullname',
                label         =>'AC-Internal Fullname',
                htmlwidth     =>'250',
                ignorecase    =>1,
                dataobjattr   =>'"acfullname"'),

      new kernel::Field::Boolean(
                name          =>'deleted',
                htmldetail    =>0,
                label         =>'marked as delete',
                dataobjattr   =>'"deleted"'),

      new kernel::Field::Text(
                name          =>'loginname',
                label         =>'User-Login',
                lowersearch   =>1,
                dataobjattr   =>'"loginname"'),

      new kernel::Field::Text(
                name          =>'contactid',
                label         =>'ContactID',
                lowersearch   =>1,
                dataobjattr   =>'"contactid"'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                ignorecase    =>1,
                dataobjattr   =>'"name"'),

#      new kernel::Field::Text(
#                name          =>'tenant',
#                label         =>'Tenant',
#                group         =>'source',
#                dataobjattr   =>'"tenant"'),
#
#      new kernel::Field::Interface(
#                name          =>'tenantid',
#                label         =>'Tenant ID',
#                group         =>'source',
#                dataobjattr   =>'"tenantid"'),

      new kernel::Field::Text(
                name          =>'firstname',
                label         =>'Firstname',
                ignorecase    =>1,
                dataobjattr   =>'"firstname"'),

      new kernel::Field::Text(
                name          =>'surname',
                label         =>'Surname',
                ignorecase    =>1,
                dataobjattr   =>'"surname"'),

      new kernel::Field::Text(
                name          =>'givenname',
                label         =>'Givenname',
                ignorecase    =>1,
                dataobjattr   =>'"givenname"'),

      new kernel::Field::Text(
                name          =>'email',
                label         =>'E-Mail',
                lowersearch   =>1,
                dataobjattr   =>'"email"'),

      new kernel::Field::Text(
                name          =>'ldapid',
                label         =>'LDAPID',
                lowersearch   =>1,
                dataobjattr   =>'"ldapid"'),

      new kernel::Field::SubList(
                name          =>'groups',
                label         =>'Groups',
                vjointo       =>'tsacinv::lnkusergroup',
                vjoinon       =>['lempldeptid'=>'lempldeptid'],
                vjoindisp     =>['group']),

      new kernel::Field::Text(
                name          =>'idno',
                label         =>'IDNo',
                dataobjattr   =>'"idno"'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'"srcsys"'),
                                                
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'"srcid"'),
                                                   
   );
   $self->setDefaultView(qw(lempldeptid fullname name ldapid idno srcsys srcid));
   $self->setWorktable("usr");

   return($self);
}

sub mkFullname
{
   my $self=shift;
   my $current=shift;

   my $fullname="";
   my $name=$current->{name};
   if ($name ne ""){
      $name=lc($name);
      $name=~tr/ÄÖÜ/äöü/;
      $name=~s/^([a-z])/uc($1)/ge;
      $name=~s/[\s-]([a-z])/uc($1)/ge;
   }
   $fullname.=$name;
   $fullname.=", " if ($fullname ne "" && $current->{firstname} ne "");
   $fullname.=$current->{firstname};
   if ($current->{email} ne ""){
      $fullname.=" " if ($fullname ne "");
      $fullname.="(".lc($current->{email}).")";
   }
   if ($current->{deleted}){
      $fullname.="[0]";
   }

   return($fullname);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   $self->amInitializeOraSession();
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/user.jpg?".$cgi->query_string());
}
         

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   
   return("ALL") if ($self->IsMemberOf("admin"));
   return("default","source","header");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_deleted"))){
     Query->Param("search_deleted"=>$self->T("no"));
   }
  # if (!defined(Query->Param("search_tenant"))){
  #   Query->Param("search_tenant"=>"CS");
  # }
}



1;
