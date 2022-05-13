package base::usersubstusage;
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

   $self->setWorktable("usersubstusage");

   $self->AddFields(
      new kernel::Field::Id(  name       =>'usersubstusageid',
                              label      =>'UsageID',
                              size       =>'10',
                              dataobjattr     =>'usersubstusage.usersubstusageid'),

      new kernel::Field::TextDrop( name       =>'fullname',
                                   label      =>'Fullname',
                                   vjointo    =>'base::user',
                                   vjoinon    =>['userid'=>'userid'],
                                   vjoindisp  =>'fullname'),

      new kernel::Field::TextDrop( name       =>'dstaccount',
                                   label      =>'Used Account',
                                   vjointo    =>'base::useraccount',
                                   vjoinon    =>['account'=>'account'],
                                   vjoindisp  =>'account'),

      new kernel::Field::Link(     name       =>'userid',
                                   label      =>'UserId',
                                   dataobjattr     =>'usersubstusage.userid'),

      new kernel::Field::Link(     name       =>'account',
                                   label      =>'Used Account',
                                   htmlwidth  =>'200px',
                                   dataobjattr     =>'usersubstusage.account'),


   );
   $self->setDefaultView(qw(fullname dstaccount));
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


1;
