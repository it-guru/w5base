package AL_TCom::qrule::ApplIface;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Every application in CI-Status "installed/active" or "available" needs
at least 1 interface, if the flag "application has no intefaces" is not 
true.
Loop interfaces from the current to the current application are not allowed.
In special case against the parent rule itil::qrule::ApplIface, in this
rule applications in the mgmtitemgroup "SAP" are always treated as OK.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

This quality rule checks if at least one interface is entered on applications. 
One or more interfaces can be entered on the application under the 
field 'interfaces'. When entering an interface, additional parameters like 
'interfacetype', 'interfacemode' and 'interfaceprotocol' have to be specified 
as well. If an application has no interfaces to other applications, 
the field 'Application has no interfaces' under 
'Control-/Automationinformations' should be set to 'yes'. 
Should this field be set to 'yes', despite having interfaces documented on 
the application, a dataissue will be generated.

In case of questions regarding the interfaces for the application you are 
responsible for, please contact your application operation team.
Please make sure that the technical interfaces are accurately defined in 
W5Base/Darwin based on reality.

If the application is in the responsibility of GDU SAP and you are receiving 
this dataissue or have additional questions you can contact DARWIN Support.
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001

[de:]

Diese Qualitätsregel prüft, ob mindestens eine Schnittstelle an einer 
Anwendung hinterlegt ist. Eine, oder mehrere Schnittstellen können 
unter der Anwendung im Feld 'Schnittstellen' hinterlegt werden. 
Beim Eingeben müssen auch Parameter wie 'Modus', 'Protokoll' 
und 'Schnittstellentyp' definiert werden. 
Wenn eine Anwendung keine Schnittstellen zu anderen Anwendungen hat, 
muss das Feld 'Anwendung hat keine Schnittstellen' unter 
'Steuerungs-/Automationsdaten' auf 'ja' gesetzt werden. 
Wenn das Feld trotz eingetragener Schnittstellen auf 'ja' steht 
wird ein DataIssue erzeugt!

Bei Fragen zu den Schnittstellen der von Ihnen verantworteten Anwendungen, 
wenden Sie sich bitte an Ihren AO Betrieb.
Sorgen Sie bitte dafür, dass die in der Realität vorhandenen 
technischen Schnittstellen in W5Base/Darwin abgebildet werden.

Sollten Sie dieses DataIssue bekommen, obwohl es sich hierbei um eine 
von der GDU SAP betreute Anwendung handelt, oder Sie weitere Fragen haben, 
können Sie sich an den DARWIN Support wenden.
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001


=cut

#######################################################################
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
use itil::qrule::ApplIface;
@ISA=qw(itil::qrule::ApplIface);

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

   my $mgmtitemgroup=$rec->{mgmtitemgroup};
   if (ref($mgmtitemgroup) ne "ARRAY"){
      $mgmtitemgroup=[$mgmtitemgroup];
   }
   if (in_array($mgmtitemgroup,"SAP")){
      return(0,undef);
   } 
   return($self->SUPER::qcheckRecord($dataobj,$rec,$checksession));
}






1;
