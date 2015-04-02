package tssm::user;
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
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'UserID',
                dataobjattr   =>'contactsm1.contact_name'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                htmlwidth     =>'250',
                searchable    =>0,
                onRawValue    =>\&mkFullname,
                depend        =>['name','email','firstname','loginname']),

#      new kernel::Field::Text(
#                name          =>'acfullname',
#                label         =>'AC-Internal Fullname',
#                htmlwidth     =>'250',
#                ignorecase    =>1,
#                dataobjattr   =>'amempldept.fullname'),

      new kernel::Field::Text(
                name          =>'loginname',
                label         =>'User-Login',
                uppersearch   =>1,
                dataobjattr   =>'operatorm1.name'),

#      new kernel::Field::Text(
#                name          =>'contactid',
#                label         =>'ContactID',
#                lowersearch   =>1,
#                dataobjattr   =>'amempldept.contactid'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                ignorecase    =>1,
                dataobjattr   =>'contactsm1.last_name'),

      new kernel::Field::Text(
                name          =>'firstname',
                label         =>'Firstname',
                ignorecase    =>1,
                dataobjattr   =>'contactsm1.first_name'),

#      new kernel::Field::Boolean(
#                name          =>'islogonuser',
#                label         =>'is real logon user',
#                upperserarch  =>1,
#                dataobjattr   =>"decode(contactsm1.groupprgn,'YES',1,0)"),

      new kernel::Field::Text(
                name          =>'email',
                label         =>'E-Mail',
                ignorecase    =>1,
                dataobjattr   =>'contactsm1.email'),

      new kernel::Field::Phonenumber(
                name          =>'office_phone',
                group         =>'office',
                label         =>'Phonenumber',
                dataobjattr   =>'contactsm1.phone'),

      new kernel::Field::Text(
                name          =>'sclocation',
                label         =>'SC-Location',
                group         =>'office',
                ignorecase    =>1,
                dataobjattr   =>'contactsm1.location_name'),

      new kernel::Field::Text(
                name          =>'schomeassignment',
                label         =>'SC-HomeAssignment',
                group         =>'office',
                ignorecase    =>1,
                weblinkto     =>'tssm::group',
                weblinkon     =>['schomeassignment'=>'fullname'],
                dataobjattr   =>'operatorm1.home_assignment'),

      new kernel::Field::Text(
                name          =>'screspgroup',
                label         =>'SC-ResponsibleGroup',
                group         =>'source',
                ignorecase    =>1,
                weblinkto     =>'tssm::group',
                weblinkon     =>['screspgroup'=>'fullname'],
                dataobjattr   =>'operatorm1.resp_group'),

      new kernel::Field::Text(
                name          =>'sctimezone',
                label         =>'SC-Timezone',
                group         =>'office',
                ignorecase    =>1,
                dataobjattr   =>'operatorm1.time_zone'),




#      new kernel::Field::Text(
#                name          =>'ldapid',
#                label         =>'LDAPID',
#                lowersearch   =>1,
#                dataobjattr   =>'amempldept.ldapid'),

#      new kernel::Field::SubList(
#                name          =>'groups',
#                label         =>'Groups',
#                vjointo       =>'tsacinv::lnkusergroup',
#                vjoinon       =>['lempldeptid'=>'lempldeptid'],
#                vjoindisp     =>['group']),

#      new kernel::Field::Text(
#                name          =>'webpassword',
#                label         =>'WEB-Password',
#                group         =>'sec',
#                lowersearch   =>1,
#                dataobjattr   =>'amempldept.webpassword'),

      new kernel::Field::SubList(
                name          =>'groups',
                label         =>'Groups',
                group         =>'groups',
                vjointo       =>'tssm::lnkusergroup',
                vjoinon       =>['userid'=>'luser'],
                vjoindisp     =>['groupname']),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'contactsm1.external_system'),
                                                
      new kernel::Field::Link(
                name          =>'userid',
                label         =>'User-ID',
                upperserarch  =>1,
                dataobjattr   =>"operatorm1.name"),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'contactsm1.external_id'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'contactsm1.last_update'),


                                                   
   );
   $self->setDefaultView(qw(id loginname name firstname email));
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
   my $firstname=$current->{firstname};
   if ($firstname ne ""){
      $firstname=lc($firstname);
      $firstname=~tr/ÄÖÜ/äöü/;
      $firstname=~s/^([a-z])/uc($1)/ge;
      $firstname=~s/[\s-]([a-z])/uc($1)/ge;
   }
   $fullname.=$name;
   $fullname.=", " if ($fullname ne "" && $firstname ne "");
   $fullname.=$firstname;
   if ($current->{email} ne ""){
      $fullname.=" " if ($fullname ne "");
      $fullname.="(".lc($current->{email}).")";
   }
   if ($fullname=~m/^\s*$/){
      $fullname=$current->{loginname};
   }

   return($fullname);
}
sub initSqlWhere
{
   my $self=shift;
   my $where="operatorm1.name=contactsm1.user_id(+)";
            # " AND ".
            # "(contactsm1.email is not NULL OR ".
            # "contactsm1.groupprgn='YES')";
   return($where);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssm"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/user.jpg?".$cgi->query_string());
}
         

sub getSqlFrom
{
   my $self=shift;
   my $from="dh_operatorm1 operatorm1,dh_contctsm1 contactsm1";
   return($from);
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
   my $grp=shift;
   my %param=@_;
   return("header","default","office","groups","source");
}


sub initSearchQuery
{
   my $self=shift;

   if (!defined(Query->Param("search_islogonuser"))){
     Query->Param("search_islogonuser"=>$self->T("yes"));
   }
}




1;
