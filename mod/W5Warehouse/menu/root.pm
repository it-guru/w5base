package W5Warehouse::menu::root;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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

   $self->RegisterObj("itu.W5Warehouse",
                      "tmpl/welcome",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.W5Warehouse.itemsummary",
                      "W5Warehouse::itemsum_debug",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.W5Warehouse.system",
                      "W5Warehouse::system",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itu.W5Warehouse.Rep",
                      "tmpl/welcome",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itu.W5Warehouse.Rep.AppSysAss",
                      "W5Warehouse::AppSysAss",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itu.W5Warehouse.Rep.Systemhardening",
                      "W5Warehouse::Systemhardening",
                      defaultacl=>['admin']);

   $self->RegisterObj("itu.W5Warehouse.Rep.IT_SeM",
                      "tmpl/welcome",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itu.W5Warehouse.Rep.ApplFarm",
                      "W5Warehouse::appl_itfarm",
                      defaultacl=>['admin']);

   $self->RegisterObj("itu.W5Warehouse.Rep.IT_SeM.System",
                      "W5Warehouse::itsem_sys",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itu.W5Warehouse.Rep.UserGroupRelation",
                      "W5Warehouse::UserGroupRelation",
                      defaultacl=>['admin']);

   $self->RegisterObj("itu.W5Warehouse.Rep.ExtOperationUser",
                      "W5Warehouse::ExtOperationUser",
                      defaultacl=>['admin','support']);

   $self->RegisterObj("itu.W5Warehouse.Rep.SWInstanceExtOperationUser",
                      "W5Warehouse::SWInstanceExtOperationUser",
                      defaultacl=>['admin','support']);

   $self->RegisterObj("itu.W5Warehouse.Rep.SystemExtOperationUser",
                      "W5Warehouse::SystemExtOperationUser",
                      defaultacl=>['admin','support']);

   $self->RegisterObj("itu.W5Warehouse.Rep.ApplExtOperationUser",
                      "W5Warehouse::ApplExtOperationUser",
                      defaultacl=>['admin','support']);

   $self->RegisterObj("itu.W5Warehouse.Rep.W5USULICMGMT_system",
                      "W5Warehouse::W5USULICMGMT_SYSTEM",
                      defaultacl=>['admin','support']);

   $self->RegisterObj("itu.W5Warehouse.Rep.MViewMonitor",
                      "W5Warehouse::MViewMonitor",
                      defaultacl=>['admin']);

   $self->RegisterObj("itu.W5Warehouse.Rep.ItemSummaryDebug",
                      "W5Warehouse::ItemSummaryDebug",
                      defaultacl=>['admin']);

   $self->RegisterObj("itu.W5Warehouse.krn",
                      "tmpl/welcome",
                      prio=>10000,
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.W5Warehouse.krn.views",
                      "W5Warehouse::uview",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.W5Warehouse.krn.fields",
                      "W5Warehouse::ufield",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.W5Warehouse.krn.objectsnap",
                      "W5Warehouse::objectsnap",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.W5Warehouse.krn.DBService",
                      "W5Warehouse::dbservice",
                      defaultacl=>['admin']);
   
   return($self);
}



1;
