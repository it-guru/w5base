package itil::menu::root;
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

   $self->RegisterObj("itil",
                      "tmpl/welcome",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itil.custcontract",
                      "itil::custcontract",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.custcontract.new",
                      "itil::custcontract",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.custcontract.lnkappl",
                      "itil::lnkapplcustcontract",
                      defaultacl=>['admin']);

   $self->RegisterObj("itil.custcontract.lnkappl.new",
                      "itil::lnkapplcustcontract",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("itil.appl",
                      "itil::appl",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.appl.new",
                      "itil::appl",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("itil.appl.lnkapplappl",
                      "itil::lnkapplappl",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.appl.lnkapplappl.new",
                      "itil::lnkapplappl",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("itil.appl.lnkcustcontract",
                      "itil::lnkapplcustcontract",
                      defaultacl=>['admin']);

   $self->RegisterObj("itil.appl.lnkcustcontract.new",
                      "itil::lnkapplcustcontract",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("itil.appl.lnksystem",
                      "itil::lnkapplsystem",
                      defaultacl=>['admin']);

   $self->RegisterObj("itil.appl.lnksystem.new",
                      "itil::lnkapplsystem",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("itil.appl.lnkaccountingno",
                      "itil::lnkaccountingno",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.appl.lnkapplcontact",
                      "itil::lnkapplcontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.system",
                      "itil::system",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.system.new",
                      "itil::system",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.system.ipaddress",
                      "itil::ipaddress",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.system.ipaddress.new",
                      "itil::ipaddress",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("itil.system.systemnfsnas",
                      "itil::systemnfsnas",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.system.systemnfsnas.new",
                      "itil::systemnfsnas",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.system.systemnfsnas.clients",
                      "itil::lnksystemnfsnas",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.system.systemnfsnas.ipclients",
                      "itil::lnknfsnasipnet",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.system.software",
                      "itil::lnksoftwaresystem",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.system.software.new",
                      "itil::lnksoftwaresystem",
                      func=>'New',
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.system.jobs",
                      "itil::systemjob",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.system.jobs.new",
                      "itil::systemjob",
                      func=>'New',
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.system.jobs.lnkjobs",
                      "itil::lnksystemjobsystem",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itil.system.jobs.lnkjobs.new",
                      "itil::lnksystemjobsystem",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("itil.system.jobs.timing",
                      "itil::systemjobtiming",
                      func=>'MainWithNew',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itil.system.lnksystemcontact",
                      "itil::lnksystemcontact",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.asset",
                      "itil::asset",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.asset.new",
                      "itil::asset",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.asset.lnkassetcontact",
                      "itil::lnkassetcontact",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.liccontract",
                      "itil::liccontract",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.liccontract.new",
                      "itil::liccontract",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.liccontract.sys",
                      "itil::lnklicsystem",
                      func=>'Main',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.liccontract.appl",
                      "itil::lnklicappl",
                      func=>'Main',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.liccontract.appl.new",
                      "itil::lnklicappl",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.swinstance",
                      "itil::swinstance",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.swinstance.new",
                      "itil::swinstance",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.swinstance.lnksystem",
                      "itil::lnkswinstancesystem",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.kern",
                      "tmpl/welcome");
   
   $self->RegisterObj("itil.kern.network",
                      "itil::network",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.kern.network.new",
                      "itil::network",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.kern.osrelease",
                      "itil::osrelease",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.kern.osrelease.new",
                      "itil::osrelease",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.kern.platform",
                      "itil::platform",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.kern.platform.new",
                      "itil::platform",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.kern.software",
                      "itil::software",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.kern.software.new",
                      "itil::software",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.kern.producer",
                      "itil::producer",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.kern.producer.new",
                      "itil::producer",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.kern.hwmodel",
                      "itil::hwmodel",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.kern.hwmodel.new",
                      "itil::hwmodel",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.kern.servicesupport",
                      "itil::servicesupport",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.kern.servicesupport.new",
                      "itil::servicesupport",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.kern.location",
                      "base::location",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.kern.location.new",
                      "base::location",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itil.kern.bp",
                      "itil::businessprocess",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itil.kern.bp.new",
                      "itil::businessprocess",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("itil.kern.bp.lnksys",
                      "itil::lnkbprocesssystem",
                      defaultacl=>['admin']);

   $self->RegisterObj("itil.kern.bp.lnkappl",
                      "itil::lnkbprocessappl",
                      defaultacl=>['admin']);

   $self->RegisterObj("itil.kern.costcenter",
                      "itil::costcenter",
                      defaultacl=>['valid_user']);

   $self->RegisterObj('itil::workflow::eventnotify$',
                      "base::workflow",
                      func=>'New',
                      param=>'WorkflowClass=itil::workflow::eventnotify',
                      defaultacl=>['admin']);

   $self->RegisterObj('itil::QuickFind::appl$',
                      "itil::QuickFind::appl",
                      defaultacl=>['valid_user']);

   $self->RegisterObj('itil::QuickFind::system$',
                      "itil::QuickFind::system",
                      defaultacl=>['valid_user']);

   $self->RegisterObj('itil::QuickFind::asset$',
                      "itil::QuickFind::asset",
                      defaultacl=>['valid_user']);

   $self->RegisterObj('itil::QuickFind::costcenter$',
                      "itil::QuickFind::costcenter",
                      defaultacl=>['valid_user']);

   $self->RegisterObj('itil::QuickFind::swinstance$',
                      "itil::QuickFind::swinstance",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.analytics.itilfault",
                      "itil::FaultAnalytics",
                      defaultacl=>['admin']);

   return($self);
}



1;
