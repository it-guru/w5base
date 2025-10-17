package TSHungary::menu::root;
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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

   $self->RegisterObj("TSHungary",
                      "tmpl/welcome",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("TSHungary.applgrp",
                      "itil::applgrp",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.applgrp.new",
                      "itil::applgrp",
                      func=>'New',
                      defaultacl=>['admin']);

#   $self->RegisterObj("TSHungary.appl.adv",
#                      "TS::appladv",
#                      defaultacl=>['valid_user']);
#
#   $self->RegisterObj("TSHungary.appl.nor",
#                      "TS::applnor",
#                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.appl",
                      "TSHungary::appl",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSHungary.appl.new",
                      "TSHungary::appl",
                      func=>'New',
                      prio=>1,
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.appl.lnkapplurl",
                      "itil::lnkapplurl",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.appl.lnkapplurl.new",
                      "itil::lnkapplurl",
                      prio=>1,
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.appl.applwallet",
                      "itil::applwallet",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.appl.applwallet.new",
                      "itil::applwallet",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.appl.lnkapplappl",
                      "itil::lnkapplappl",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.appl.lnkapplappl.new",
                      "itil::lnkapplappl",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("TSHungary.appl.lnksystem",
                      "itil::lnkapplsystem",
                      defaultacl=>['admin']);

   $self->RegisterObj("TSHungary.appl.lnksystem.new",
                      "itil::lnkapplsystem",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("TSHungary.appl.lnkapplcontact",
                      "itil::lnkapplcontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.appl.lnkapplinteranswer",
                      "itil::lnkapplinteranswer",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.itclust",
                      "TS::itclust",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSHungary.itclust.new",
                      "TS::itclust",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.itclust.lnkitclustsvc",
                      "itil::lnkitclustsvc",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.itclust.lnkitclustsvc.appl",
                      "itil::lnkitclustsvcappl",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.itclust.lnkitclustsvc.sw",
                      "itil::lnksoftwareitclustsvc",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.itclust.lnkitclustcontact",
                      "itil::lnkitclustcontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.system",
                      "TS::system",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSHungary.system.new",
                      "TS::system",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.system.ipaddress",
                      "itil::ipaddress",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSHungary.system.ipaddress.new",
                      "itil::ipaddress",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("TSHungary.system.dnsalias",
                      "itil::dnsalias",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.system.lnksystemcontact",
                      "itil::lnksystemcontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.system.software",
                      "itil::lnksoftwaresystem",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.system.lnksysteminteranswer",
                      "itil::lnksysteminteranswer",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.asset",
                      "TS::asset",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSHungary.asset.new",
                      "TS::asset",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.asset.core",
                      "itil::assetphyscore",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.asset.cpu",
                      "itil::assetphyscpu",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.asset.lnkassetcontact",
                      "itil::lnkassetcontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.liccontract",
                      "itil::liccontract",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.liccontract.new",
                      "itil::liccontract",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.liccontract.sys",
                      "itil::lnklicsystem",
                      func=>'Main',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.liccontract.appl",
                      "itil::lnklicappl",
                      func=>'Main',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.swinstance",
                      "TS::swinstance",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.swinstance.new",
                      "itil::swinstance",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.swinstance.lnksystem",
                      "itil::lnkswinstancesystem",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.swinstance.lnkswinstancecontact",
                      "itil::lnkswinstancecontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.swinstance.param",
                      "itil::lnkswinstanceparam",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.swinstance.lnkswinstance",
                      "itil::lnkswinstanceswinstance",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.swinstance.lnkswinstance.new",
                      "itil::lnkswinstanceswinstance",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.swinstance.rule",
                      "itil::swinstancerule",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSHungary.swinstance.rule.new",
                      "itil::swinstancerule",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.kern",
                      "tmpl/welcome");
   
   $self->RegisterObj("TSHungary.kern.osrelease",
                      "itil::osrelease",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSHungary.kern.osrelease.new",
                      "itil::osrelease",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.kern.software",
                      "itil::software",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSHungary.kern.software.new",
                      "itil::software",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.kern.producer",
                      "itil::producer",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSHungary.kern.producer.new",
                      "itil::producer",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.kern.hwmodel",
                      "itil::hwmodel",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSHungary.kern.costcenter",
                      "TS::costcenter",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSHungary.kern.costcenter.new",
                      "TS::costcenter",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.kern.costcenter.contacts",
                      "finance::lnkcostcentercontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSHungary.kern.servicesupport",
                      "itil::servicesupport",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSHungary.kern.servicesupport.new",
                      "itil::servicesupport",
                      func=>'New',
                      defaultacl=>['valid_user']);

   return(1);
}



1;
