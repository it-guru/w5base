package TS::qrule::HardwareLocation;
#######################################################################
=pod

=head3 PURPOSE

Every asset needs to have specified a location on which the hardware
is located.


=head3 IMPORTS

NONE

=head3 HINTS

The allocation of the location is normaly from AssetManager
imported automatically. So if no location be present,
so this may be because in Asset Manager no location
is detected.
If the location is not however be taken to Darwin, so
there may be a lack of mapping the location tables
are. This must then assinged as a admin request 
to the Darwin Administration.

[de:]

Die Zuordnung des Standortes wird i.d.R. aus AssetManager
automatisch importiert. Sollte also kein Standort vorhanden sein,
so kann dies daran liegen, das in AssetManager kein Standort 
erfasst ist.
Sollte der Standort dennoch nicht nach Darwin übernommen werden, so
kann dies an einem fehlenden Mapping der Standort-Tabellen 
liegen. Dies muß dann über einen Admin-Request an die Darwin
Administration gemeldet werden.

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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
use kernel::QRule;
use itil::qrule::HardwareLocation;
@ISA=qw(itil::qrule::HardwareLocation);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}






1;
