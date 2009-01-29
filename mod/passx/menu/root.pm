package passx::menu::root;
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

   
   $self->RegisterObj("Tools.passx",
                      "passx::mgr",
                      func=>'UserFrontend',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.passx.connector",
                      "passx::mgr",
                      prio=>1,
                      func=>'Connector',
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.passx.key",
                      "passx::key",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.passx.entry",
                      "passx::entry",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.passx.log",
                      "passx::log",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.passx.entry.new",
                      "passx::entry",
                      func=>'New',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.passx.entry.acl",
                      "passx::acl",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.passx.mgrmain",
                      "passx::mgr",
                      defaultacl=>['admin']);

   $self->RegisterObj("Tools.passx.new",
                      "passx::entry",
                      func=>'New',
                      defaultacl=>['valid_user']);
   
   
   return($self);
}



1;
