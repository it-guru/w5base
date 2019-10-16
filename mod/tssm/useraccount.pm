package tssm::useraccount;
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
                label         =>'LoginID',
                dataobjattr   =>SELpref.'operatorm1.name'),


      new kernel::Field::Interface(
                name          =>'contactkey',
                label         =>'Contact Key',
                dataobjattr   =>SELpref.'operatorm1.contact_name'),

      new kernel::Field::Text(
                name          =>'loginname',
                label         =>'Loginname',
                uppersearch   =>1,
                dataobjattr   =>SELpref.'operatorm1.name'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Name',
                ignorecase    =>1,
                dataobjattr   =>SELpref.'operatorm1.full_name'),

      new kernel::Field::Text(
                name          =>'email',
                label         =>'E-Mail',
                ignorecase    =>1,
                dataobjattr   =>SELpref.'operatorm1.email'),

      new kernel::Field::Text(
                name          =>'homeassignment',
                label         =>'HomeAssignment',
                ignorecase    =>1,
                weblinkto     =>'tssm::group',
                weblinkon     =>['homeassignment'=>'fullname'],
                dataobjattr   =>SELpref.'operatorm1.tsi_home_assignment'),

      new kernel::Field::Text(
                name          =>'responsiblegroup',
                label         =>'AdminGroup',
                uppersearch   =>1,
               # weblinkto     =>'tssm::group',
               # weblinkon     =>['homeassignment'=>'fullname'],
                dataobjattr   =>SELpref.'operatorm1.tsi_responsible_group'),

      new kernel::Field::Text(
                name          =>'username',
                label         =>'Contact name',
                vjointo       =>'tssm::user',
                vjoinon       =>['contactkey'=>'contactkey'],
                vjoindisp     =>'fullname',
                searchable    =>'0'),


      new kernel::Field::SubList(
                name          =>'groups',
                label         =>'Groups',
                group         =>'groups',
                vjointo       =>'tssm::lnkusergroup',
                vjoinon       =>['loginname'=>'luser'],
                vjoindisp     =>['groupname']),

      new kernel::Field::SubList(
                name          =>'secgroups',
                label         =>'SecurityGroups',
                group         =>'secgroups',
                vjointo       =>'tssm::secgroup',
                vjoinon       =>['loginname'=>'userid'],
                vjoindisp     =>['secgroup']),

      new kernel::Field::Text(
                name          =>'profile_change',
                label         =>'Profile Change',
                group         =>'profile',
                sqlorder      =>'NONE',
                dataobjattr   =>SELpref.'operatorm1.profile_change'),

      new kernel::Field::Text(
                name          =>'profile_contract',
                label         =>'Profile Contract',
                group         =>'profile',
                dataobjattr   =>SELpref.'operatorm1.profile_contract'),

      new kernel::Field::Text(
                name          =>'profile_incident',
                label         =>'Profile Incident',
                group         =>'profile',
                dataobjattr   =>SELpref.'operatorm1.profile_incident'),

      new kernel::Field::Text(
                name          =>'profile_inventory',
                label         =>'Profile Inventory',
                group         =>'profile',
                dataobjattr   =>SELpref.'operatorm1.profile_inventory'),

      new kernel::Field::Text(
                name          =>'profile_rootcause',
                label         =>'Profile Rootcause',
                group         =>'profile',
                dataobjattr   =>SELpref.'operatorm1.profile_rootcause'),

      new kernel::Field::Text(
                name          =>'profile_service',
                label         =>'Profile Service',
                group         =>'profile',
                dataobjattr   =>SELpref.'operatorm1.profile_service'),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>SELpref.'operatorm1.sysmodtime'),

      new kernel::Field::Date(
                name          =>'lastlogin',
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
                group         =>'source',
                label         =>'Last Login Date',
                dataobjattr   =>SELpref.'operatorm1.last_login'),

      new kernel::Field::TextDrop(
                name          =>'editor',
                group         =>'source',
                weblinkto     =>'tssm::useraccount',
                weblinkon     =>['editor'=>'loginname'],
                label         =>'Editor Account',
                dataobjattr   =>SELpref.'operatorm1.sysmoduser'),

   );
   $self->setDefaultView(qw(loginname email username));
   $self->{use_distinct}=0;
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssm"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
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
      if (!defined(Query->Param("search_loginname"))){
        Query->Param("search_loginname"=>$urec->{posix});
      }
   }
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
   my $from="smadm1.operatorm1 ".SELpref."operatorm1";
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
   return("header","default",'profile',"groups","secgroups","source");
}

sub isQualityCheckValid
{
   return(0);
}






1;
