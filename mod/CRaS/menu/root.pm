package CRaS::menu::root;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
use kernel::MenuRegistry;
@ISA=qw(kernel::MenuRegistry);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub Init
{
   my $self=shift;

   $self->RegisterObj("Tools.CRaS",
                      "CRaS::csr",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.CRaS.new",
                      "CRaS::csr",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.CRaS.csteam",
                      "CRaS::csteam",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.CRaS.csteam.ResponseHandler",
                      "CRaS::csr",
                      func=>'CAresponseHandler',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.CRaS.csteam.new",
                      "CRaS::csteam",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("Tools.CRaS.ca",
                      "CRaS::ca",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

   return($self);
}



1;
