package TS::qrule::ApplDRClass;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks whether an "installed/active" or "available/in project" application with primary operation mode "Production" or "Disaster Recovery" has:

-  "Disaster Recovery Class" defined,

-  corresponding "SLA number Disaster-Recovery test interval" defined, 

-  whether the "Application switch-over behaviour" is defined, 

otherwise an error message is output.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

A "Disaster Recovery Class" (DR) must be defined for each productive application.

For non-productive applications the parameter "Disaster Recovery Class" is not mandatory.
The value can be set to not defined to avoid DataIssue connected to this QRule.

The corresponding SLA number Disaster-Recovery test interval: must be defined, too. 

For the DR process the following timeslots are relevant  depending on a set Disaster Recovery Class:

- Disaster Recovery Classes 0-3: 1 test every 12 months

- Disaster Recovery Classes 4-7: 1 test every 24 months

- Disaster Recovery Classes 11-18: 1 test every 12 months

Tests can be performed even more frequently, for example twice in 12 months. 
The selection within the field SLA number Disaster-Recovery test interval: is then considered as mandatory and test must be performed within the set time interval.


Further information you can find on Disaster Recovery FAQ site at intranet:

https://yam-united.telekom.com/pages/problem-management-telekom-it/apps/wiki/dr-faq/list/view/435cc4fa-558c-4354-9d43-2cd19482000b


In case of any questions you can contact our FMB:

mailto:DR_Disaster_Recovery_Test@telekom.de


[de:]

Eine "Disaster Recovery Class" muss für jede Produktive Applikation definiert sein.

Für non-Produktive Systeme ist das Parameter "Disaster Recovery Class" nicht verpflichtend. Um DataIssue verbunden mit dieser Q-Regel zu vermeiden, ist der Wert auf nicht definiert zu setzen.

Entsprechend muss auch das Parameter SLA Anzahl zugesicherter Disaster-Recovery Tests: gesetzt sein.

Der DR Prozess sieht 2 Zeitfenster für DR Test vor  abhängig von der gesetzten Disaster Recovery Class:

- Disaster Recovery Classes 0-3: 1 Test alle 12 Monate

- Disaster Recovery Classes 4-7: 1 Test alle 24 Monate

- Disaster Recovery Classes 11-18: 1 Test alle 12 Monate

Es besteht die Möglichkeit, auch häufiger zu testen, z.B. 2-mal in 12 Monaten. 
Die Wahl im Fenster SLA Anzahl zugesicherter Disaster-Recovery Tests: wird dann als verbindlich angesehen und muss termingetreu umgesetzt werden.


Weiterführende Informationen finden Sie auch auf unserer FAQ Seite im Intranet:

https://yam-united.telekom.com/pages/problem-management-telekom-it/apps/wiki/dr-faq/list/view/435cc4fa-558c-4354-9d43-2cd19482000b


Bei Fragen wenden Sie sich bitte an unsere FMB:

mailto:DR_Disaster_Recovery_Test@telekom.de


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
   return(["TS::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if ($rec->{cistatusid}!=4 &&
                       $rec->{cistatusid}!=3);

   if ($rec->{drclass} eq '' &&
       ($rec->{opmode} eq 'prod' ||
        $rec->{opmode} eq 'cbreakdown')) {
      my $msg="no Disaster Recovery Class defined";
      return(3,{qmsg=>[$msg],dataissue=>[$msg]});
   }

   if ($rec->{drclass} ne ""){
      if ($rec->{drclass}>3 && $rec->{drclass}<8) {
         if ($rec->{soslanumdrtests}<0.5) {
            my $msg="Minimum Disaster-Recovery test interval: ".
                    $self->T('DRTESTPERYEAR.0.5','itil::appl');
            return(3,{qmsg=>[$msg],dataissue=>[$msg]});
         }
      }
      else{
         if ($rec->{soslanumdrtests}<1) {
            my $msg="Minimum Disaster-Recovery test interval: ".
                    $self->T('DRTESTPERYEAR.1','itil::appl');
            return(3,{qmsg=>[$msg],dataissue=>[$msg]});
         }
      }
   }

   return(0,undef);
}



1;
