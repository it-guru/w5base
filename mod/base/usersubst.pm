package base::usersubst;
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
use Data::Dumper;
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
   
   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5base"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");

   $self->setWorktable("usersubst");

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(       
                name          =>'usersubstid',
                label         =>'SubstitiutionID',
                size          =>'10',
                dataobjattr   =>'usersubst.usersubstid'),

      new kernel::Field::TextDrop( 
                name          =>'fullname',
                label         =>'Fullname',
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Text(
                name          =>'srcaccount',
                label         =>'Account',
                readonly      =>1,
                vjointo       =>'base::useraccount',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'account'),

      new kernel::Field::Link(
                name          =>'dstaccount',
                label         =>'Substitutable by',
                htmlwidth     =>'200px',
                dataobjattr   =>'usersubst.account'),

      new kernel::Field::Link(
                name          =>'userid',
                selectfix     =>1,
                label         =>'UserId',
                dataobjattr   =>'usersubst.userid'),

      new kernel::Field::Select(
                name          =>'active',
                label         =>'Active',
                htmleditwidth =>'50%',
                value         =>['1','0'],
                dataobjattr   =>'usersubst.active'),

      new kernel::Field::TextDrop(
                name          =>'useraccount',
                label         =>'Useraccount',
                vjointo       =>'base::useraccount',
                vjoinon       =>['dstaccount'=>'account'],
                vjoindisp     =>'account'),

      new kernel::Field::Text(
                name          =>'usersubstcontactusertyp',
                label         =>'subst contact usertyp',
                dataobjattr   =>'substcontact.usertyp'),

      new kernel::Field::Text(
                name          =>'usersubstcontactcistatusid',
                label         =>'subst contact cistatusid',
                dataobjattr   =>'substcontact.cistatus'),

      new kernel::Field::CDate(
                name          =>'cdate',
                label         =>'Creation-Date',
                dataobjattr   =>'usersubst.createdate'),
                                  
   );
   $self->setDefaultView(qw(fullname srcaccount dstaccount active));
   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   return("$worktable left outer join contact ".
          "on $worktable.userid=contact.userid ".
          "left outer join useraccount ".
          "on $worktable.account=useraccount.account ".
          "left outer join contact as substcontact ".
          "on useraccount.userid=substcontact.userid");
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $userid=effVal($oldrec,$newrec,"userid");
   my $olduserid=$userid;
   if (defined($oldrec)){
      $olduserid=$oldrec->{userid};
   }
   my $o=getModuleObject($self->Config,"base::user"); 
   $o->SetFilter({userid=>$olduserid});
   my ($urec,$msg)=$o->getOnlyFirst(qw(creator usertyp));
   if (!defined($urec)){
      $self->LastMsg(ERROR,"invalid urec refernce $olduserid");
      return(0);
   }

   if (effVal($oldrec,$newrec,"dstaccount") eq $ENV{REAL_REMOTE_USER} &&
       $ENV{REAL_REMOTE_USER} ne $ENV{REMOTE_USER}){
      $self->LastMsg(ERROR,"not allowed to modify current substitution");
      return(0);
   }

   my $curuserid=$self->getCurrentUserId();
   if ((!$self->IsMemberOf("admin")) &&
       (!($urec->{usertyp} eq "genericAPI" && $urec->{creator} eq $curuserid))){
      if ($userid ne $curuserid || $userid ne $olduserid){
         $self->LastMsg(ERROR,
                        "you are not authorized to create or modifiy ".
                        "this user substitution");
         return(0);
      }
   }

   return(1);
}



sub ValidateDelete
{
   my $self=shift;
   my $rec=shift;

   if ($rec->{dstaccount} eq $ENV{REAL_REMOTE_USER} &&
       $ENV{REAL_REMOTE_USER} ne $ENV{REMOTE_USER}){
      $self->LastMsg(ERROR,"not allowed to modify current substitution");
      return(0);
   }

   return(1);
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
   return("ALL") if (!defined($rec));
   my $userid=$self->getCurrentUserId();
   return(undef) if ($userid ne $rec->{userid} && !$self->IsMemberOf("admin"));
   return("default");
}


1;
