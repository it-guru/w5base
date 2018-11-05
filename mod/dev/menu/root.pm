package dev::menu::root;
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

   $self->RegisterObj("Tools.dev",
                      "tmpl/welcome",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.dev.io",
                      "base::interface",
                      func=>'io',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.dev.J5Base",
                      "../../../public/base/load/tmpl/welcome.j5base.html",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.dev.env",
                      "base::env",
                      defaultacl=>['admin']);

   $self->RegisterObj("Tools.dev.tztest",
                      "base::tztest",
                      defaultacl=>['admin']);

   $self->RegisterObj("Tools.dev.texttranslation",
                      "base::TextTranslation",
                      defaultacl=>['admin']);
   
   return($self);
}



1;
