package OSY::menu::root;
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

   $self->RegisterObj("osy",
                      "tmpl/welcome",
                      defaultacl=>['admin']);
   
#   $self->RegisterObj("osy.custcontract",
#                      "itil::custcontract",
#                      defaultacl=>['admin','valid_user']);
#   
#   $self->RegisterObj("osy.custcontract.new",
#                      "itil::custcontract",
#                      func=>'New',
#                      defaultacl=>['admin']);
#
#   $self->RegisterObj("osy.custcontract.lnkappl",
#                      "itil::lnkapplcustcontract",
#                      defaultacl=>['admin']);
#
#   $self->RegisterObj("osy.custcontract.lnkappl.new",
#                      "itil::lnkapplcustcontract",
#                      func=>'New',
#                      defaultacl=>['admin']);
   $self->RegisterObj("osy.system",
                      "OSY::system",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("osy.system.new",
                      "itil::system",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("osy.system.ipaddress",
                      "itil::ipaddress",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("osy.system.ipaddress.new",
                      "itil::ipaddress",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("osy.system.jobs",
                      "itil::systemjob",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("osy.system.jobs.new",
                      "itil::systemjob",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("osy.system.systemnfsnas",
                      "itil::systemnfsnas",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("osy.system.systemnfsnas.new",
                      "itil::systemnfsnas",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("osy.system.systemnfsnas.clients",
                      "itil::lnksystemnfsnas",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("osy.system.lnksystemcontact",
                      "itil::lnksystemcontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("osy.asset",
                      "itil::asset",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("osy.asset.new",
                      "itil::asset",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("osy.asset.lnkassetcontact",
                      "itil::lnkassetcontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("osy.kern",
                      "tmpl/welcome");
   
   $self->RegisterObj("osy.kern.network",
                      "itil::network",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("osy.kern.network.new",
                      "itil::network",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("osy.kern.osrelease",
                      "itil::osrelease",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("osy.kern.osrelease.new",
                      "itil::osrelease",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("osy.kern.platform",
                      "itil::platform",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("osy.kern.platform.new",
                      "itil::platform",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("osy.kern.software",
                      "itil::software",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("osy.kern.software.new",
                      "itil::software",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("osy.kern.producer",
                      "itil::producer",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("osy.kern.producer.new",
                      "itil::producer",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("osy.kern.hwmodel",
                      "itil::hwmodel",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("osy.kern.hwmodel.new",
                      "itil::hwmodel",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("osy.kern.location",
                      "base::location",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("osy.kern.location.new",
                      "base::location",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("osy.kern.projectroom",
                      "OSY::projectroom",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("osy.kern.projectroom.new",
                      "OSY::projectroom",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("osy.appl",
                      "itil::appl",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("osy.appl.new",
                      "itil::appl",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("osy.appl.lnksystem",
                      "itil::lnkapplsystem",
                      defaultacl=>['admin']);

   $self->RegisterObj("osy.appl.lnksystem.new",
                      "itil::lnkapplsystem",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("osy.liccontract",
                      "itil::liccontract",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("osy.liccontract.new",
                      "itil::liccontract",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("osy.projectroom",
                      "OSY::projectroom",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("osy.projectroom.new",
                      "OSY::projectroom",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj('OSY::workflow::diary$',
                      "base::workflow",
                      func=>'New',
                      param=>'WorkflowClass=OSY::workflow::diary',
                      defaultacl=>['admin']);

   return($self);
}



1;
