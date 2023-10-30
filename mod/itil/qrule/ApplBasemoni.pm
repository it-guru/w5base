package itil::qrule::ApplBasemoni;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Every Application in CI-Status "installed/active" or "available" needs
to set an application base monitoring.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

Please enter in the block "Monitoring and SLA":

a) In the field "Application Base Monitoring", enter the tool used for monitoring.

b) In the field "Application Base Monitoring Status" whether this tool is used with or without an auto-ticket function.


[de:]

Bitte tragen Sie im Block Monitoring und SLA/Überwachung:

a) im Feld Anwendungs Basismonitoring das zum Monitoring verwendete Tool aus.

b) Im Feld Anwendungs Basismonitoring Status ob dieses Tool mit oder ohne einer Autoticket Funktion genutzt wird.


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return(["itil::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(undef,undef) if ($rec->{cistatusid}!=4);
   if ($rec->{opmode} eq "prod"){
      my @msg;
      if ($rec->{applbasemoniname} eq ""){
         my $msg="no application base monitoring selected";
         push(@msg,$msg);
      }
      if ($rec->{applbasemonistatus} eq ""){
         my $msg="no application base monitoring status selected";
         push(@msg,$msg);
      }
      if ($#msg!=-1){
         return(3,{qmsg=>\@msg, dataissue=>\@msg});
      }
      return(0,undef);
   }
   return(undef,undef);
}



1;
