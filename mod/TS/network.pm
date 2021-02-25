package TS::network;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler
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
use kernel::Field;
use itil::network;
@ISA=qw(itil::network);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getTaggedNetworkAreaId
{
   my $self=shift;
   my %netarea=();


   $netarea{CNDTAG}=$self->findNetworkAreaId({
         addDefaultIsland=>1
      },
      'Corporate Network DTAG (CNDTAG)', # zuk�nftig!
      'Deutsche Telekom HitNet',
   );

   $netarea{ISLAND}=$self->findNetworkAreaId({
      addDefaultIsland=>1
   });

   $netarea{INTERNET}=$self->findNetworkAreaId({
         addDefaultIsland=>1
      },
      'Internet',
   );
   $netarea{TSIADMINLAN}=$self->findNetworkAreaId({
         addDefaultIsland=>1
      },
      'T-Systems Admin-LAN',
   );
   $netarea{TSIBACKUPLAN}=$self->findNetworkAreaId({
         addDefaultIsland=>1
      },
      'T-Systems Datensicherungs/Backup LAN',
   );
   $netarea{TSISTORLAN}=$self->findNetworkAreaId({
         addDefaultIsland=>1
      },
      'T-Systems Storage/NAS LAN',
   );
   $netarea{AWSINTERN}=$self->findNetworkAreaId({
         addDefaultIsland=>1
      },
      'AWS Internal Networks',
   );

   return(\%netarea);
}



1;
