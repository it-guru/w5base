package tsbflexx::menu::root;
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

   $self->RegisterObj("bflexx",
                      "tmpl/welcome",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("bflexx.bill",
                      "tsbflexx::custbill",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("bflexx.bill.mod",
                      "tsbflexx::orderedmod",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("bflexx.bill.invoice",
                      "tsbflexx::invoice",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("bflexx.crudedata",
                      "tsbflexx::crudedata",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("bflexx.p800iface",
                      "tsbflexx::p800iface",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("bflexx.p800iface.new",
                      "tsbflexx::p800iface",
                      func=>'New',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("bflexx.p800sonder",
                      "tsbflexx::p800sonder",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("bflexx.p800sonder.new",
                      "tsbflexx::p800sonder",
                      func=>'New',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("bflexx.wfreview",
                      "tsbflexx::wfreview",
                      defaultacl=>['admin']);
   
   return($self);
}



1;
