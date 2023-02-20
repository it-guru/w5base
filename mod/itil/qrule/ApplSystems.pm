package itil::qrule::ApplSystems;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Every Application in CI-Status "installed/active" or "available", needs
at least 1 logical system linked. If there are no logical systems assigned,
this will produce an error.
In some cases (applications which ships licenses f.e.) you can set the
flag "application has no systems". In this case, this rule produces an
error, if logical systems are assigned.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

An application usually runs on at least one logical system or CloudArea. 

Step 1: Please make sure that the logical systems are already created in W5Base/Darwin.

Step 2: Link the logical system with the application in the block 'systems' 
on the application, by entering the name of the system and 
confirming by pressing the 'add' button.

Attention: If the application does not have any logical systems you can set 
the field 'Application has no system components' under 
'Control-/Authomationinformations' to 'yes'. It is only allowed to set 
the field to 'yes' if the application doesn't have any systems!
The technical responsible of the application (TSM) usually knows which 
systems were comissioned.

A CloudArea will be only tread as "system", if it is marked 
as "installed/active".

In case of questions regarding handling W5Base/Darwin you can turn 
to the Support of Darwin:
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001

[de:]

Eine Anwendung läuft im Regelfall auf mindestens einem 
logischen System oder einer CloudArea.

Schritt 1: Überprüfen Sie bitte, ob die Systeme in W5Base/Darwin bereits angelegt sind.

Schritt 2: Verknüpfen Sie das logische System mit der Anwendung, 
indem Sie im Block 'Systeme' an der Anwendung den Namen des Systems 
hinterlegen und mit 'hinzufügen' bestätigen.

Achtung: Falls es keine logischen Systeme zu dieser Anwendung gibt, 
bitte unter 'Steuerungs-/Automationsdaten' 
'Anwendung hat keine System Komponenten' auf 'ja' setzen. 
Das Feld darf nur auf 'ja' gesetzt werden, wenn die Anwendung keine Systeme 
hinterlegt hat! Der technische Verantwortliche der Anwendung (TSM) 
weiß in der Regel welche Systeme beauftragt wurden.

Eine CloudArea wird nur als "System" angesehen, wenn diese 
als "installiert/aktiv" markiert ist.

Bei Fragen zum Umgang mit dem Tool können Sie sich 
an den Darwin-Support wenden:
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001


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

   my $systemcnt=0;
   my $cloudacnt=0;
   if (ref($rec->{systems}) eq "ARRAY" && $#{$rec->{systems}}!=-1){
      $systemcnt=$#{$rec->{systems}}+1;
   }
   if (ref($rec->{itcloudareas}) eq "ARRAY" && $#{$rec->{itcloudareas}}!=-1){
      foreach my $cloudarea (@{$rec->{itcloudareas}}){
         if ($cloudarea->{cistatusid}==4){
            $cloudacnt++;
         }
      }
   }

   if (!$rec->{isnosysappl}){
      if ($systemcnt==0 && $cloudacnt==0){
         return(3,{qmsg=>['no system or cloud relations'],
                   dataissue=>['no system or cloud relations']});
      }
   }
   else{
      if ($systemcnt!=0 || $cloudacnt!=0){
         return(3,{qmsg=>['superfluous system or cloud relations'],
                   dataissue=>['superfluous system or cloud relations']});
      }
   }
   return(0,undef);

}



1;
