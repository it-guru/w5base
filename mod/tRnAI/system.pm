package tRnAI::system;
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
use itil::lib::Listedit;
use tRnAI::lib::Listedit;
@ISA=qw(use itil::lib::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->{useMenuFullnameAsACL}="1";

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'tRnAI_system.id'),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Systemname',
                dataobjattr   =>'tRnAI_system.systemname'),

      new kernel::Field::Text(
                name          =>'serviceid',
                label         =>'ServiceID',
                dataobjattr   =>'tRnAI_system.serviceid'),

      new kernel::Field::Text(
                name          =>'ipaddress',
                label         =>'IP-Address',
                dataobjattr   =>'tRnAI_system.ipaddress'),

      new kernel::Field::Text(
                name          =>'usbsrvport',
                label         =>'USB-Server Port',
                htmldetail    =>'NotEmpty',
                readonly      =>1,
                vjointo       =>\'tRnAI::usbsrvport',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Select(
                name          =>'opmode',
                label         =>'operation mode',
                value         =>['prod','nonprod'],
                default       =>'nonprod',
                dataobjattr   =>'tRnAI_system.opmode'),

      new kernel::Field::Select(
                name          =>'customer',
                label         =>'Customer',
                group         =>'customer',
                allowfree     =>1,
                allowempty    =>1,
                weblinkto     =>'none',
                htmleditwidth =>'300px',
                vjointo       =>\'tRnAI::customer',
                vjoindisp     =>'name',
                vjoinon       =>['rawcustomer'=>'name']),

      new kernel::Field::Link(
                name          =>'rawcustomer',
                label         =>'Customer raw',
                group         =>'customer',
                dataobjattr   =>'tRnAI_system.customer'),

      new kernel::Field::Select(
                name          =>'department',
                label         =>'Department',
                group         =>'customer',
                allowfree     =>1,
                allowempty    =>1,
                weblinkto     =>'none',
                htmleditwidth =>'300px',
                vjointo       =>\'tRnAI::department',
                vjoindisp     =>'name',
                vjoinon       =>['rawdepartment'=>'name']),

      new kernel::Field::Link(
                name          =>'rawdepartment',
                label         =>'Department raw',
                group         =>'customer',
                dataobjattr   =>'tRnAI_system.department'),

      new kernel::Field::SubList(
                name          =>'useraccounts',
                label         =>'AD-Accounts',
                forwardSearch =>1,
                group         =>'useraccounts',
                subeditmsk    =>'subedit.useraccounts',
                vjointo       =>\'tRnAI::lnkuseraccountsystem',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['useraccount','reltyp','email','comments']),

      new kernel::Field::Text(
                name          =>'costcenter',
                label         =>'Costcenter/Acc. Area',
                dataobjattr   =>'tRnAI_system.costcenter'),

      new kernel::Field::Text(
                name          =>'costcentermgr',
                label         =>'Costcenter/Manager',
                dataobjattr   =>'tRnAI_system.costcentermgr'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'tRnAI_system.comments'),

      new kernel::Field::Email(
                name          =>'contactemail',
                group         =>'add',
                label         =>'Contact E-Mail',
                dataobjattr   =>'tRnAI_system.contactemail'),

      new kernel::Field::Text(
                name          =>'tools',
                group         =>'add',
                label         =>'Tools',
                dataobjattr   =>'tRnAI_system.tools'),

      new kernel::Field::Text(
                name          =>'bpver',
                group         =>'add',
                label         =>'BP-Version',
                dataobjattr   =>'tRnAI_system.bpver'),

      new kernel::Field::Text(
                name          =>'addsoft',
                group         =>'add',
                label         =>'Additional Software',
                dataobjattr   =>'tRnAI_system.addsoft'),

      new kernel::Field::SubList(
                name          =>'instances',
                label         =>'Instances',
                group         =>'instances',
                subeditmsk    =>'subedit.instances',
                vjointo       =>\'tRnAI::lnkinstlic',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['instance']),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'tRnAI_system.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'tRnAI_system.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'tRnAI_system.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'tRnAI_system.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'tRnAI_system.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'tRnAI_system.realeditor'),
   

   );
   $self->setDefaultView(qw(name serviceid customer department cdate mdate));
   $self->setWorktable("tRnAI_system");
   return($self);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}


#sub getSqlFrom
#{
#   my $self=shift;
#   my ($worktable,$workdb)=$self->getWorktable();
#   my $from="$worktable ".
#            "left outer join xxx on yyy=zzz";
#   return($from);
#}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ((!defined($oldrec) || exists($newrec->{name})) &&
       (($newrec->{name}=~m/^\s*$/) || 
         haveSpecialChar($newrec->{name}) ||
         length($newrec->{name})<3)){
      $self->LastMsg(ERROR,"invalid system name specified");
      return(0);
   }
   if ((!defined($oldrec) || exists($newrec->{serviceid})) &&
       (($newrec->{serviceid}=~m/^\s*$/) || 
         haveSpecialChar($newrec->{serviceid}) ||
         length($newrec->{serviceid})<5)){
      $self->LastMsg(ERROR,"invalid serviceid specified");
      return(0);
   }
   foreach my $vname (qw(name serviceid)){
      if (exists($newrec->{$vname})){
         my $v=uc($newrec->{$vname});
         if ($v ne $newrec->{$vname}){
            $newrec->{$vname}=$v;
         }
      } 
   }


   my $ipaddress=trim(effVal($oldrec,$newrec,"ipaddress"));
   $ipaddress=~s/\s//g;

   if ($ipaddress=~m/\./){
      $ipaddress=~s/^[0]+([1-9])/$1/g;
      $ipaddress=~s/\.[0]+([1-9])/.$1/g;
   }
   my $chkipaddress=lc($ipaddress);

   my $errmsg;
   my $type=$self->IPValidate($chkipaddress,\$errmsg);
   if ($type ne "IPv4" && $type ne "IPv6"){
      $self->LastMsg(ERROR,$self->T($errmsg,"itil::lib::Listedit"));
      return(0);
   }
   if (!$self->isValidClientIP($ipaddress)){
      $self->LastMsg(ERROR,$self->T("invalid Client IP Address - Blacklisted",
                                    "itil::ipaddress"));
      return(0);
   }



   return(1);
}



sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default customer add instances useraccounts source));
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my @wrgrp=qw(default customer useraccounts add);

   return(@wrgrp) if ($self->tRnAI::lib::Listedit::isWriteValid($rec));
   return(undef);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default","customer") if (!defined($rec));
   return("ALL") if ($self->tRnAI::lib::Listedit::isViewValid($rec));
   my @l=$self->SUPER::isViewValid($rec);
   return("ALL") if (in_array(\@l,[qw(default ALL)]));
   return(undef);
}

sub initSearchQuery
{
   my $self=shift;
#   if (!defined(Query->Param("search_cistatus"))){
#     Query->Param("search_cistatus"=>
#                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
#   }
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}





1;
