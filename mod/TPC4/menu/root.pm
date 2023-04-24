package TPC4::menu::root;
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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

   $self->RegisterObj("itu.cloud.tpc.TPC4",
                      "tmpl/welcome",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itu.cloud.tpc.TPC4.project",
                      "TPC4::project",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itu.cloud.tpc.TPC4.machine",
                      "TPC4::machine",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itu.cloud.tpc.TPC4.kernel",
                      "tmpl/welcome",
                      prio=>9999,
                      defaultacl=>['admin']);

   $self->RegisterObj("itu.cloud.tpc.TPC4.kernel.depl",
                      "TPC4::deployment",
                      defaultacl=>['valid_user']);

   return($self);
}



1;
