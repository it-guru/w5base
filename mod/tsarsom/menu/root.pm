package tsarsom::menu::root;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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

   $self->RegisterObj("itu.arsom",
                      "tmpl/welcome",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.arsom.system",
                      "tsarsom::system",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.arsom.asset",
                      "tsarsom::asset",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.arsom.location",
                      "tsarsom::location",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.arsom.kern",
                      "tmpl/welcome",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.arsom.kern.db",
                      "tsarsom::DBDataDiconary",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.arsom.kern.user",
                      "tsarsom::user",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.arsom.kern.group",
                      "tsarsom::group",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.arsom.kern.costcenter",
                      "tsarsom::costcenter",
                      defaultacl=>['valid_user']);
   
   return(1);
}




1;
