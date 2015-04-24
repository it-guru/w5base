package tssm::menu::root;
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

   $self->RegisterObj("itu.sm",                                           # OK
                      "tmpl/welcome",
                      prio=>100,
                      defaultacl=>['admin',"support"]);
   
   $self->RegisterObj("itu.sm.change",                                    # OK
                      "tssm::chm",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.sm.change.task",
                      "tssm::chmtask",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.sm.change.task.pso",
                      "tssm::chm_pso",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.sm.change.relations",
                      "tssm::lnk",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.sm.change.software",
                      "tssm::chm_software",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.sm.change.device",
                      "tssm::chm_device",
                      defaultacl=>['admin',"support"]);
   
   $self->RegisterObj("itu.sm.change.timing",
                      "tssm::chm_timingcheck",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.sm.incident",
                      "tssm::inm",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.sm.incident.relations",
                      "tssm::lnk",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.sm.incident.assignment",
                      "tssm::inm_assignment",
                      defaultacl=>['admin',"support"]);
   
   $self->RegisterObj("itu.sm.problem",
                      "tssm::prm",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itu.sm.problem.relations",
                      "tssm::lnk",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itu.sm.krn",
                      "tmpl/welcome",
                      prio=>2000,
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itu.sm.krn.group.lnkuser",
                      "tssm::lnkusergroup",
                      defaultacl=>['admin']);

   $self->RegisterObj("itu.sm.krn.group",
                      "tssm::group",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itu.sm.krn.location",
                      "tssm::location",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itu.sm.krn.user",
                      "tssm::user",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itu.sm.krn.dev",
                      "tssm::dev",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itu.sm.krn.user.lnkgroup",
                      "tssm::lnkusergroup",
                      defaultacl=>['admin']);

   $self->RegisterObj("itu.sm.krn.Dump",
                      "tmpl/welcome",
                      prio=>10,
                      defaultacl=>['admin']);

   $self->RegisterObj("itu.sm.krn.Dump.dictonary",                        # OK
                      "tssm::DBDataDiconary",
                      defaultacl=>['admin']);

   $self->RegisterObj("itu.sm.krn.Dump.chmDataDump",                      # OK
                      "tssm::chmDumper",
                      defaultacl=>['admin']);

   $self->RegisterObj("itu.sm.krn.Dump.tskDataDump",                      # OK
                      "tssm::tskDumper",
                      defaultacl=>['admin']);

   $self->RegisterObj("itu.sm.krn.Dump.inmDataDump",                      # OK
                      "tssm::inmDumper",
                      defaultacl=>['admin']);

   $self->RegisterObj("itu.sm.krn.Dump.devDataDump",                      # OK
                      "tssm::devDumper",
                      defaultacl=>['admin']);

   return($self);
}



1;
