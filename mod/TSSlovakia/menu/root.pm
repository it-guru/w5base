package TSSlovakia::menu::root;
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

   $self->RegisterObj("TSSlovakia",
                      "tmpl/welcome",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("TSSlovakia.applgrp",
                      "itil::applgrp",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.applgrp.new",
                      "itil::applgrp",
                      func=>'New',
                      defaultacl=>['admin']);

#   $self->RegisterObj("TSSlovakia.appl.adv",
#                      "TS::appladv",
#                      defaultacl=>['valid_user']);
#
#   $self->RegisterObj("TSSlovakia.appl.nor",
#                      "TS::applnor",
#                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.appl",
                      "TSSlovakia::appl",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSSlovakia.appl.new",
                      "TSSlovakia::appl",
                      func=>'New',
                      prio=>1,
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.appl.lnkapplurl",
                      "itil::lnkapplurl",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.appl.lnkapplurl.new",
                      "itil::lnkapplurl",
                      prio=>1,
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.appl.applwallet",
                      "itil::applwallet",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.appl.applwallet.new",
                      "itil::applwallet",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.appl.lnkapplappl",
                      "itil::lnkapplappl",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.appl.lnkapplappl.new",
                      "itil::lnkapplappl",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("TSSlovakia.appl.lnksystem",
                      "itil::lnkapplsystem",
                      defaultacl=>['admin']);

   $self->RegisterObj("TSSlovakia.appl.lnksystem.new",
                      "itil::lnkapplsystem",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("TSSlovakia.appl.lnkapplcontact",
                      "itil::lnkapplcontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.appl.lnkapplinteranswer",
                      "itil::lnkapplinteranswer",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.itclust",
                      "TS::itclust",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSSlovakia.itclust.new",
                      "TS::itclust",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.itclust.lnkitclustsvc",
                      "itil::lnkitclustsvc",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.itclust.lnkitclustsvc.appl",
                      "itil::lnkitclustsvcappl",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.itclust.lnkitclustsvc.sw",
                      "itil::lnksoftwareitclustsvc",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.itclust.lnkitclustcontact",
                      "itil::lnkitclustcontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.system",
                      "TS::system",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSSlovakia.system.new",
                      "TS::system",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.system.ipaddress",
                      "itil::ipaddress",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSSlovakia.system.ipaddress.new",
                      "itil::ipaddress",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("TSSlovakia.system.dnsalias",
                      "itil::dnsalias",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.system.lnksystemcontact",
                      "itil::lnksystemcontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.system.software",
                      "itil::lnksoftwaresystem",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.system.lnksysteminteranswer",
                      "itil::lnksysteminteranswer",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.system.Import",
                      "itil::system",
                      func=>'Import',
                      prio=>20000,
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.asset",
                      "TS::asset",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSSlovakia.asset.new",
                      "TS::asset",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.asset.core",
                      "itil::assetphyscore",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.asset.cpu",
                      "itil::assetphyscpu",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.asset.lnkassetcontact",
                      "itil::lnkassetcontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.liccontract",
                      "itil::liccontract",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.liccontract.new",
                      "itil::liccontract",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.liccontract.sys",
                      "itil::lnklicsystem",
                      func=>'Main',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.liccontract.appl",
                      "itil::lnklicappl",
                      func=>'Main',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.swinstance",
                      "TS::swinstance",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.swinstance.new",
                      "itil::swinstance",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.swinstance.lnksystem",
                      "itil::lnkswinstancesystem",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.swinstance.lnkswinstancecontact",
                      "itil::lnkswinstancecontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.swinstance.param",
                      "itil::lnkswinstanceparam",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.swinstance.lnkswinstance",
                      "itil::lnkswinstanceswinstance",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.swinstance.lnkswinstance.new",
                      "itil::lnkswinstanceswinstance",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.swinstance.rule",
                      "itil::swinstancerule",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSSlovakia.swinstance.rule.new",
                      "itil::swinstancerule",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.cloud",
                      "TSSlovakia::itcloud",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.cloud.new",
                      "TSSlovakia::itcloud",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.cloud.area",
                      "TSSlovakia::itcloudarea",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.cloud.area.new",
                      "TSSlovakia::itcloudarea",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.kern",
                      "tmpl/welcome");
   
   $self->RegisterObj("TSSlovakia.kern.osrelease",
                      "itil::osrelease",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSSlovakia.kern.osrelease.new",
                      "itil::osrelease",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.kern.software",
                      "itil::software",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSSlovakia.kern.software.new",
                      "itil::software",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.kern.producer",
                      "itil::producer",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSSlovakia.kern.producer.new",
                      "itil::producer",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.kern.hwmodel",
                      "itil::hwmodel",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSSlovakia.kern.costcenter",
                      "TS::costcenter",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSSlovakia.kern.costcenter.new",
                      "TS::costcenter",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.kern.costcenter.contacts",
                      "finance::lnkcostcentercontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.kern.servicesupport",
                      "itil::servicesupport",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSSlovakia.kern.servicesupport.new",
                      "itil::servicesupport",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.asset.itfarm",
                      "TS::itfarm",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.asset.itfarm.new",
                      "TS::itfarm",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.asset.itfarm.lnkitfarmasset",
                      "TS::lnkitfarmasset",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.appl.lnkchmapprgrp",
                      "TS::lnkapplchmapprgrp",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.kern.platform",
                      "itil::platform",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSSlovakia.kern.platform.new",
                      "itil::platform",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.kern.location",
                      "base::location",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.kern.location.new",
                      "base::location",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.kern.interview",
                      "TS::interview",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.proc",
                      "tmpl/welcome",
                      prio=>20000);

   $self->RegisterObj("TSSlovakia.proc.vou",
                      "TS::vou",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("TSSlovakia.proc.vou.new",
                      "TS::vou",
                      func=>'New',
                      defaultacl=>['valid_user']);


   return(1);
}



1;
