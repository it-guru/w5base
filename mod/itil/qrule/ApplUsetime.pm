package itil::qrule::ApplUsetime;
#######################################################################
=pod

=head3 PURPOSE

For each Prio1-Application use times must be entered."

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

In timespan field "use-times"
at least one entry is expected per weekday.

[de:]

Im Zeitbereichsfeld "Nutzungszeiten"
wird pro Wochentag mindestens ein Eintrag erwartet.

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

   return(0,undef) if ($rec->{customerprio}!=1 || 
                       ($rec->{cistatusid}!=4 &&
                        $rec->{cistatusid}!=5));

   my $daymap=$dataobj->getField('usetimes')->tspandaymap();
   my @usetimes=split(/\+/,$rec->{usetimes});

   foreach my $i (0..$#{$daymap}) {
      if ($daymap->[$i] && (
          !defined($usetimes[$i]) || 
          $usetimes[$i] eq "" || 
          $usetimes[$i]=~m/\(\)/ ) ) {
         my $msg='entries in use times incomplete';
         return(3,{qmsg=>$msg,dataissue=>$msg});
      }
   }

   return(0,undef);
}



1;
