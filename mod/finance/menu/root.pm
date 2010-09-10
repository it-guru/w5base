package finance::menu::root;
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

   $self->RegisterObj("finance",
                      "tmpl/welcome",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("finance.custcontract",
                      "finance::custcontract",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("finance.custcontract.new",
                      "finance::custcontract",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("finance.costcenter",
                      "finance::costcenter",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("finance.costcenter.new",
                      "finance::costcenter",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("invoice",
                      "tmpl/welcome",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.teamtools.costteamfixup",
                      "finance::costteamfixup",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.teamtools.costteamfixup.new",
                      "finance::costteamfixup",
                      func=>'New',
                      defaultacl=>['valid_user']);
   
   return($self);
}



1;
