package AL_TCom::qrule::ApplCheckOPM;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Every Application in CI-Status "installed/active","inactiv/stored" 
or "available", must have a 
Operation Manager (derived from itil::qrule::ApplCheckOPM)
The rule is deactivated, if the 
businessteam = DTAG.GHQ.VTS.TSI.ITDiv.GITO.SAPS.*

=head3 IMPORTS

NONE

=cut
#######################################################################
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
use itil::qrule::ApplCheckOPM;
@ISA=qw(itil::qrule::ApplCheckOPM);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   my $businessteam=$rec->{businessteam};
   if ($businessteam ne "" &&
       !($businessteam=~m/^DTAG\.GHQ\.VTS\.TSI\.ITDiv\.GITO\.SAPS\.{0,1}/i)){
      # https://darwin.telekom.de/darwin/auth/base/workflow/ById/14556937410001
      return(undef); 
   }
   return($self->SUPER::qcheckRecord($dataobj,$rec,$checksession))
}



1;
