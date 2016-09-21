package itil::qrule::ApplOpmode;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Every Application in CI-Status "installed/active" or "available" needs
to set a valid primary operation mode.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

It is necessary to fill the field 'primary operation mode' to declare 
the operation mode of the application, e.g. to enable the assignment 
of criticality and priority.

Please choose the proper operation mode from the possibilities provided 
in a drop-down menu, according to the nature of the application. 
E.g. in the case of a production environment, choose the operation mode 
'Production', in case of test environment choose 'Test', etc.

If you have any questions please contact the Darwin Support:

https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001


[de:]

Das Feld 'vorwiegende Betriebsart' ist zwingend zu befüllen, 
um die Betriebsart der Anwendung bekannt zu geben, 
z.B. für die Festlegung der Kritikalität und Priorität.

Bitte wählen Sie aus den hinterlegten Wertevorräten eine Betriebsart aus, 
welche auf die Umgebung der Anwendung zutrifft. Z.B. wenn es sich um eine 
produktive Umgebung handelt, wählen Sie die Betriebsart 'Produktion', 
für Testumgebungen 'Test', usw.

Bei Fragen wenden Sie sich bitte an den Darwin Support:
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
   if ($rec->{opmode} eq ""){
      return(3,{qmsg=>['no primary operation mode selected'],
                dataissue=>['no primary operation mode selected']});
   }
   return(0,undef);

}



1;
