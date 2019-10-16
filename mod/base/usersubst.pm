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
          "on $worktable.userid=contact.userid ");
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
#   msg(INFO,"isWriteValid in $self");
   return("ALL");
}

sub findtemplvar
{
   my $self=shift;
   my ($opt,$var,@param)=@_;
   my $fieldbase=$self->getFieldHash();
 
   if ($var eq "objecttitle"){
      return($opt->{current}->{account});
   }

   return($self->SUPER::findtemplvar($opt,$var,@param));
}


1;
