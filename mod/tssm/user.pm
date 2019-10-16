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
use tssm::lib::io;

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
                label         =>'ID',
                dataobjattr   =>SELpref.'contactsm1.contact_name'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Contact name',
                htmlwidth     =>'250',
                searchable    =>0,
                onRawValue    =>\&mkFullname,
                depend        =>['name','email','firstname','loginname']),


      new kernel::Field::Text(
                name          =>'loginname',
                label         =>'User-Login',
                uppersearch   =>1,
                weblinkto     =>'tssm::useraccount',
                weblinkon     =>['loginname'=>'loginname'],
                group         =>'account',
                dataobjattr   =>SELpref.'operatorm1.name'),

      new kernel::Field::Text(
                name          =>'userid',
                label         =>'User-ID',
                weblinkto     =>'tssm::useraccount',
                weblinkon     =>['userid'=>'loginname'],
                uppersearch   =>1,
                dataobjattr   =>SELpref."contactsm1.user_id"),

      new kernel::Field::Interface(
                name          =>'contactkey',
                label         =>'Contact Key',
                dataobjattr   =>SELpref.'contactsm1.contact_name'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                ignorecase    =>1,
                dataobjattr   =>SELpref.'contactsm1.last_name'),

      new kernel::Field::Text(
                name          =>'firstname',
                label         =>'Firstname',
                ignorecase    =>1,
                dataobjattr   =>SELpref.'contactsm1.first_name'),

      new kernel::Field::Boolean(
                name          =>'islogonuser',
                label         =>'is real logon user',
                searchable    =>0,
                htmldetail    =>0,
                group         =>'account',
                selectfix     =>1,
                upperserarch  =>1,
                dataobjattr   =>"decode(".SELpref."operatorm1.name,NULL,0,1)"),

      new kernel::Field::Text(
                name          =>'email',
                label         =>'E-Mail',
                ignorecase    =>1,
                dataobjattr   =>SELpref.'contactsm1.email'),

#      new kernel::Field::Phonenumber(
#                name          =>'office_phone',
#                group         =>'office',
#                label         =>'Phonenumber',
#                dataobjattr   =>SELpref.'contactsm1.phone'),

      new kernel::Field::Text(
                name          =>'company',
                label         =>'Company',
                ignorecase    =>1,
                dataobjattr   =>SELpref.'contactsm1.company'),

      new kernel::Field::Text(
                name          =>'companycode',
                label         =>'Company Code',
                ignorecase    =>1,
                dataobjattr   =>SELpref.'contactsm1.company_code'),

      new kernel::Field::Text(
                name          =>'location',
                label         =>'Location',
                ignorecase    =>1,
                dataobjattr   =>SELpref.'contactsm1.location_full_name'),

      new kernel::Field::Text(
                name          =>'locationcode',
                label         =>'Location Code',
                ignorecase    =>1,
                dataobjattr   =>SELpref.'contactsm1.location'),

      new kernel::Field::Text(
                name          =>'homeassignment',
                label         =>'HomeAssignment',
                group         =>'account',
                ignorecase    =>1,
                weblinkto     =>'tssm::group',
                weblinkon     =>['homeassignment'=>'fullname'],
                dataobjattr   =>SELpref.'operatorm1.tsi_home_assignment'),

#      new kernel::Field::Text(
#                name          =>'screspgroup',
#                label         =>'SC-ResponsibleGroup',
#                group         =>'source',
#                ignorecase    =>1,
#                weblinkto     =>'tssm::group',
#                weblinkon     =>['screspgroup'=>'fullname'],
#                dataobjattr   =>SELpref.'operatorm1.resp_group'),

      new kernel::Field::Text(
                name          =>'sctimezone',
                label         =>'SC-Timezone',
                group         =>'account',
                ignorecase    =>1,
                dataobjattr   =>SELpref.'operatorm1.time_zone'),




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

      new kernel::Field::SubList(
                name          =>'secgroups',
                label         =>'SecurityGroups',
                group         =>'secgroups',
                vjointo       =>'tssm::secgroup',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>['secgroup']),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>SELpref.'contactsm1.sysmodtime'),

      new kernel::Field::Date(
                name          =>'lastlogin',
                group         =>'source',
                searchable    =>sub{
                   my $self=shift;
                   my $app=$self->getParent;
                   return(1) if ($app->IsMemberOf("admin"));
                   return(0);
                },
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   if ($mode eq "ViewEditor"){
                      return(0);
                   }
                   return(1);
                },
                label         =>'Last Login Date',
                dataobjattr   =>SELpref.'operatorm1.last_login'),

      new kernel::Field::TextDrop(
                name          =>'editor',
                group         =>'source',
                weblinkto     =>'tssm::useraccount',
                weblinkon     =>['editor'=>'loginname'],
                label         =>'Editor Account',
                dataobjattr   =>SELpref.'contactsm1.sysmoduser'),
   );
   $self->setDefaultView(qw(id loginname name firstname email));
   return($self);
}

sub isQualityCheckValid
{
   return(0);
}


sub initSearchQuery
{
   my $self=shift;

   my $userid=$self->getCurrentUserId();
   my $user=getModuleObject($self->Config,"base::user");
   $user->SetFilter({userid=>\$userid});
   my ($urec,$msg)=$user->getOnlyFirst(qw(posix));
   if (defined($urec) && $urec->{posix} ne ""){
      if (!defined(Query->Param("search_userid"))){
        Query->Param("search_userid"=>$urec->{posix});
      }
   }
   if (!defined(Query->Param("search_islogonuser"))){
     Query->Param("search_islogonuser"=>$self->T("yes"));
   }
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
   my $where=SELpref."contactsm1.operator_id=".SELpref."operatorm1.name(+)";
   return($where);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssm"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
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
   my $from="smadm1.operatorm1 ".SELpref."operatorm1,".
            TABpref."contctsm1 ".SELpref."contactsm1";
   return($from);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @l=qw(default header account groups secgroups source);
   if ($rec->{islogonuser}){
      push(@l,"account");
   }
   return(@l);
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
   return("header","default","account","groups","secgroups","source");
}




1;
