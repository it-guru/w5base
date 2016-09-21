#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks if the related application, logical system and software installation
to the current instance is "active" and valid.

An aktiv software instance need to have a link to a valid logical system 
or cluster service. Also there is need to have a valid link to a software
installation. If the swnature is SAP/R2 or SAP/R3 no referenced software
installation is mandatory.

=head3 IMPORTS

NONE

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
package AL_TCom::qrule::SWInstanceRefCheck;
use strict;
use vars qw(@ISA);
use kernel;
use itil::qrule::SWInstanceRefCheck;
@ISA=qw(itil::qrule::SWInstanceRefCheck);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return(["itil::swinstance"]);
}



sub isValidSoftwareInstallationMandatory
{
   my $self=shift;
   my $rec=shift;

   if ($rec->{swnature} eq "SAP/R3" ||
       $rec->{swnature} eq "SAP/R2"){
      msg(INFO,"no check needed on SAP Instances");
      return(0);
   }
   return(1);

}




1;
