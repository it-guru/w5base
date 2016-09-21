package itil::qrule::ApplCustomer;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Every Application in CI-Status "installed/active" or "available" must
have a defined customer.

=head3 IMPORTS

NONE

=head3 HINTS

[de:]

Bitte hinterlegen Sie einen Kunden an der Anwendung.
Falls Sie die exakte Schreibweise des Kunden nicht kennen, 
tragen Sie 'DTAG.*' ein, um alle Kunden von DTAG 
in einer Drop-Down-Liste aufgelistet zu bekommen. 
Wenn Sie einen vorhandenen Kundeneintrag löschen oder 
einen veralteten Kunden eingetragen haben, 
werden Sie diese Änderungen nicht speichern können, 
solange Sie nicht einen gültigen Kunden eintragen.

Verantwortlich: Datenverantwortlicher

Bei Fragen wenden Sie sich bitte an den DARWIN Support: 
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001


[en:]

Please enter the customer of the application. 
If you do not know the exact naming of the customer, 
if you enter DTAG.*, you will get a list of all available customers 
of DTAG in a drop-down menu. If you delete the previous customer entry 
or the customer is deactivated, you will not be able to save the changes 
until a valid customer is entered.

Accountable: Databoss

If you have any questions please contact the Darwin Support:
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
   if (!defined($rec->{customer}) || $rec->{customer} eq ""){
      return(3,{qmsg=>['no customer defined'],
                dataissue=>['no customer defined']});
   }
   return(0,undef);

}



1;
