package w5v1inv::user;
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
use base::workflow::mailsend;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5v1"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   $self->setWorktable("user");

   $self->AddFields(
      new kernel::Field::Id(      name       =>'id',
                                  label      =>'W5BaseID',
                                  size       =>'10',
                                  dataobjattr=>'user.id'),

      new kernel::Field::Text(    name       =>'account',
                                  label      =>'account',
                                  dataobjattr=>'user.account'),

      new kernel::Field::Text(    name       =>'email',
                                  label      =>'email',
                                  dataobjattr=>'user.email'),

      new kernel::Field::Text(    name       =>'surname',
                                  label      =>'surname',
                                  dataobjattr=>'user.name'),

      new kernel::Field::Text(    name       =>'givenname',
                                  label      =>'givenname',
                                  dataobjattr=>'user.vorname'),

      new kernel::Field::Text(    name       =>'office_street',
                                  label      =>'office_street',
                                  dataobjattr=>'user.strasse'),

      new kernel::Field::Text(    name       =>'office_zipcode',
                                  label      =>'office_zipcode',
                                  dataobjattr=>'user.plz'),

      new kernel::Field::Text(    name       =>'office_location',
                                  label      =>'office_location',
                                  dataobjattr=>'user.ort'),

      new kernel::Field::Text(    name       =>'office_phone',
                                  label      =>'office_phone',
                                  dataobjattr=>'user.tel'),

      new kernel::Field::Text(    name       =>'office_mobile',
                                  label      =>'office_mobile',
                                  dataobjattr=>'user.mobil'),

      new kernel::Field::Text(    name       =>'private_street',
                                  label      =>'private_street',
                                  dataobjattr=>'user.privstrasse'),

      new kernel::Field::Text(    name       =>'private_zipcode',
                                  label      =>'private_zipcode',
                                  dataobjattr=>'user.privplz'),

      new kernel::Field::Text(    name       =>'private_location',
                                  label      =>'private_location',
                                  dataobjattr=>'user.privort'),

      new kernel::Field::Text(    name       =>'private_phone',
                                  label      =>'private_phone',
                                  dataobjattr=>'user.privtel'),

      new kernel::Field::Text(    name       =>'private_mobile',
                                  label      =>'private_mobile',
                                  dataobjattr=>'user.privmobil'),

      new kernel::Field::Text(    name       =>'alias1',
                                  label      =>'alias1',
                                  dataobjattr=>'user.alias1'),

      new kernel::Field::Text(    name       =>'alias2',
                                  label      =>'alias2',
                                  dataobjattr=>'user.alias2'),

      new kernel::Field::Text(    name       =>'alias3',
                                  label      =>'alias3',
                                  dataobjattr=>'user.alias3'),

      new kernel::Field::Text(    name       =>'emailchecked',
                                  label      =>'ldapid',
                                  dataobjattr=>'user.mail_checked'),

      new kernel::Field::Text(    name       =>'lockwarncount',
                                  label      =>'lockwarncount',
                                  dataobjattr=>'user.lockwarncount'),
   );
   $self->setDefaultView(qw(id account email emailchecked));
   return($self);
}

sub Initialize
{  
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5v1"));
   return(@result) if (defined($result[0]) eq "InitERROR");
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
   return(undef);
}


1;
