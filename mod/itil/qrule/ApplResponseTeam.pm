package itil::qrule::ApplResponseTeam;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Every Application in CI-Status "installed/active" or "available", must
have a defined response team.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

An entry for either 'IT-Servicemanagement Team' or 
'Customer Business Management Team' has to be available.

The IT-SeM Team is the organizational Team of the IT-Service Manager. 
You can find it in the contacts of the IT-Service Manager under 
'Group Memberships'.
The CBM Team is the organizational Team of the Customer Business Manager. 
You can find it in the contacts of the CBM under 'Group Memberships'.

The CBM and their team can be edited directly on the Application under 
'Customer contact / Contract management'. 
The IT-Service Manager and their Team has to be entered at the CO-Number 
directly and is automatically mirrored from there.

[de:]

Es muss entweder ein Eintrag für 'IT-Servicemanagement Team' oder
'Customer Business Management Team' vorhanden sein.

Das IT-SeM Team ist das organisatorische Team des IT Servicemanagers - 
dieses finden Sie im Kontakt des IT-Servicemanagers unter 
'Gruppenmitgliedschaften'.
Das CBM Team ist das organisatorische Team des Customer Business Managers - 
dieses finden Sie im Kontakt des CBMs unter 'Gruppenmitgliedschaften'.

Ein Customer Business Manager und sein Team können direkt an der Anwendung 
unter 'Kundenbetreuung/Vertragsgestaltung' eingetragen werden.
Ein IT-Servicemanager und sein Team müssen direkt am Kontierungsobjekt 
eingetragen sein und werden von diesem automatisch an die Anwendung übertragen.


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2007  Hartmut Vogler (it@guru.de)
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

   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);
   if (!$rec->{conumberexists} ||       # CO-Nummer ist als Objekt vorhanden
       ($rec->{conumberexists} &&       # und dort ist ein DeliveryManager
        $rec->{conumber_delmgrid} ne "")){  # eingetragen
      if (!defined($rec->{responseteam}) || $rec->{responseteam} eq ""){
         return(3,{
            qmsg=>['no responseteam/IT-Servicemanagement team defined'],
            dataissue=>['no responseteam/IT-Servicemanagement team defined']
         });
      }
   }
   else{
      return(undef);
   }
   return(0,undef);

}



1;
