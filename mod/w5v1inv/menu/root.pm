package w5v1inv::menu::root;
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

   $self->RegisterObj("w5v1",
                      "tmpl/welcome",
                      defaultacl=>['admin','support']);
   
   $self->RegisterObj("w5v1.contract",
                      "w5v1inv::contract",
                      defaultacl=>['admin','support']);
   
   $self->RegisterObj("w5v1.application",
                      "w5v1inv::application",
                      defaultacl=>['admin','support']);
   
   $self->RegisterObj("w5v1.system",
                      "w5v1inv::system",
                      defaultacl=>['admin','support']);
   
   $self->RegisterObj("w5v1.lnksystem2application",
                      "w5v1inv::lnksystem2application",
                      defaultacl=>['admin','support']);
   
   $self->RegisterObj("w5v1.orgarea",
                      "w5v1inv::orgarea",
                      defaultacl=>['admin','support']);
   
   $self->RegisterObj("w5v1.location",
                      "w5v1inv::location",
                      defaultacl=>['admin','support']);
   
   $self->RegisterObj("w5v1.ipaddress",
                      "w5v1inv::ipaddress",
                      defaultacl=>['admin','support']);
   
   $self->RegisterObj("w5v1.software",
                      "w5v1inv::software",
                      defaultacl=>['admin','support']);
   
   $self->RegisterObj("w5v1.lnksoftware2system",
                      "w5v1inv::lnksoftware2system",
                      defaultacl=>['admin','support']);
   
   $self->RegisterObj("w5v1.producer",
                      "w5v1inv::producer",
                      defaultacl=>['admin','support']);
   
   $self->RegisterObj("w5v1.faq",
                      "w5v1inv::faq",
                      defaultacl=>['admin','support']);
   
   return(1);
}



1;
