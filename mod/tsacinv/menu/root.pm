package tsacinv::menu::root;
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

   $self->RegisterObj("itu.ac",
                      "tmpl/welcome",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.ac.appl",
                      "tsacinv::appl",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.ac.appl.lnkapplappl",
                      "tsacinv::lnkapplappl",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.ac.appl.lnkapplsystem",
                      "tsacinv::lnkapplsystem",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.ac.system",
                      "tsacinv::system",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.ac.system.ipaddress",
                      "tsacinv::ipaddress",
                      defaultacl=>['admin']);

   $self->RegisterObj("itu.ac.system.swinstall",
                      "tsacinv::lnksystemsoftware",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.ac.system.lnksharednet",
                      "tsacinv::lnksharednet",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.ac.system.lnksharednet",
                      "tsacinv::lnksharednet",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.ac.system.noappsystem",
                      "tsacinv::noappsystem",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.ac.system.service",
                      "tsacinv::service",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.ac.itclust",
                      "tsacinv::itclust",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.ac.itclust.service",
                      "tsacinv::itclustservice",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.ac.shstorage",
                      "tsacinv::sharedstorage",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.ac.asset",
                      "tsacinv::asset",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.ac.asset.fixedasset",
                      "tsacinv::fixedasset",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.ac.asset.contract",
                      "tsacinv::contract",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.ac.asset.itfarm",
                      "tsacinv::itfarm",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.ac.license",
                      "tsacinv::license",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.ac.user",
                      "tsacinv::user",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.ac.user.groups",
                      "tsacinv::lnkusergroup",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.ac.group",
                      "tsacinv::group",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.ac.swinstance",
                      "tsacinv::swinstance",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.ac.krn",
                      "tmpl/welcome",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.ac.krn.model",
                      "tsacinv::model",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.ac.krn.osrelease",
                      "tsacinv::osrelease",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itu.ac.krn.osrelease.lnkw5b",
                      "tsacinv::lnkw5bosrelease",
                      func=>'MainWithNew',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.ac.krn.service",
                      "tsacinv::service",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.ac.krn.location",
                      "tsacinv::location",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.ac.krn.sclocation",
                      "tsacinv::sclocation",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itu.ac.krn.sclocation.invalid",
                      "tsacinv::invalid_sclocation",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itu.ac.krn.sclocation.ismitem",
                      "tsacinv::invalid_smitem",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itu.ac.krn.costcenter",
                      "tsacinv::costcenter",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.ac.krn.costcenter.dlvpartner",
                      "tsacinv::dlvpartner",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.ac.krn.customer",
                      "tsacinv::customer",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.ac.krn.accountno",
                      "tsacinv::accountno",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itu.ac.krn.dictonary",
                      "tsacinv::DBDataDiconary",
                      defaultacl=>['admin']);

   $self->RegisterObj("itts.appl.acimport",
                      "tsacinv::appl",
                      func=>'ImportAppl',
                      prio=>20000,
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.itclust.acimport",
                      "tsacinv::itclust",
                      func=>'ImportCluster',
                      prio=>20000,
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("TSSlovakia.itclust.acimport",
                      "tsacinv::itclust",
                      func=>'ImportCluster',
                      prio=>20000,
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itts.itclust.acimport",
                      "tsacinv::itclust",
                      func=>'ImportCluster',
                      prio=>20000,
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.ac.ad",
                      "tmpl/welcome",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itu.ac.ad.system",
                      "tsacinv::autodiscsystem",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.ac.ad.system.ipaddress",
                      "tsacinv::autodiscipaddress",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.ac.ad.system.softwareinst",
                      "tsacinv::autodiscsoftware",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itu.ac.schain",
                      "tsacinv::schain",
                      defaultacl=>['valid_user']);
   
   return(1);
}




1;
