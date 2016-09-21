package itil::qrule::ApplUsetime;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

For each Prio1-Application use times must be entered."

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

It is necessary for every TOP-Application (priority 1) 
to have the use-times defined. 
This can be defined for every day of the week separately by setting the letter 
for the use-time type (O=offline time, M=main time, S=secondary time) 
and after it the time span in form "hh:mm-hh:mm". 
If more than one time frame is needed for a particular day, 
the different time spans must be separated by a comma.

Example: S00:00-06:00, M06:00-17:00, S17:00-24:00

Accountable: Applicationmanager

For content questions, please contact the Change Management Telekom IT:
https://darwin.telekom.de/darwin/auth/base/user/ById/13721598690001

All other questions should be directed to the DARWIN Support, please:
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001


[de:]

Für jede TOP-Anwendung (Priorität 1) ist eine Angabe der 
Haupt- und Nebennutzungszeit zu hinterlegen. 
Dies kann für jeden Wochentag separat eingetragen werden, 
indem man den Buchstaben für die Nutzungszeitart angibt 
(O=Offline-Zeit, M=Hauptnutzungszeit, S= Nebennutzungszeit) 
und danach die Zeitspanne im Format "hh:mm-hh:mm" einträgt. 
Es können pro Tag auch mehrere Zeitfenster eingetragen werden.
Die einzelnen Angaben sind dabei durch Komma zu trennen. 

Beispiel: S00:00-06:00, M06:00-17:00, S17:00-24:00

Verantwortlich: Applicationmanager

Für inhaltliche Fragen wenden Sie sich bitte an das Changemanagement Telekom IT:
https://darwin.telekom.de/darwin/auth/base/user/ById/13721598690001

Alle anderen Fragen richten Sie bitte an den DARWIN Support:
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001


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
