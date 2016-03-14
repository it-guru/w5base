package TS::qrule::ApplChangeAGroup;
#######################################################################
=pod

=head3 PURPOSE

Checks if there is on an "installed/active" or "available" application
a change approvergroup for technical side is defined.
If there is no valid approvergroup defined, an error will be procceeded.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

Checks if in field 'Change Approvergroup technical' 
a valid Change Approvergroup is entered. 

Enter the Approvergroup which is to be used for Changes on this application 
from the technical point of view. Generally, it is the Approvergroup of the 
respective Business Team. If the Approvergroup was created in ServiceManager, 
it is important to make sure it was marked for Export to AssetManager. 
Otherwise it is not possible to enter the group, even though it might be 
displayed in ServiceManager.

The contact for Assignmentgroups in general is the TelekomIT SPOC:
https://darwin.telekom.de/darwin/auth/base/user/ById/14526036310001

If you have any questions please contact the Darwin Support: 
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001


[de:]

Prüft, ob im Feld 'Change Approvergroup technisch' eine gültige 
Change Approvergroup eingetragen ist.

Wählen Sie hier die Approvergroup, die bei Changes für diese Anwendung 
aus technischer Sicht verwendet werden muss. Dies ist in der Regel 
die Approvergroup des betreffenden Betriebsteams. Falls die Approvergroup 
über ServiceManager angelegt wurde, ist es wichtig, dass diese dort für 
den Export nach AssetManager markiert wurde. Ansonsten kann die Gruppe 
nicht ausgewählt werden, obwohl diese u.U. in ServiceManager angezeigt wird. 

Ansprechpartner für Assignmentgroups im Allgemeinen ist der SPOC TelekomIT:
https://darwin.telekom.de/darwin/auth/base/user/ById/14526036310001

Bei Fragen wenden Sie bitte an den DARWIN Support:
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
   return(["TS::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $exitcode=0;
   my $desc={qmsg=>[],solvtip=>[]};

   if ($rec->{cdate} ne ""){
      my $now=NowStamp("en");
      my $d=CalcDateDuration($rec->{cdate},$now,"GMT");
      my $max=7*2;  # check only if application record is older than 2 weeks
      if ($d->{days}<$max){
         return($exitcode,$desc);
      }
   }
   return($exitcode,$desc) if (($rec->{cistatusid}!=4 && 
                                $rec->{cistatusid}!=3) ||
                               $rec->{opmode} eq "license" ||
                               $rec->{businessteam} eq "Extern");
   if (trim($rec->{scapprgroup}) eq ""){
      $exitcode=3 if ($exitcode<3);
      push(@{$desc->{qmsg}},
           'there is no technical change approvergroup defined');
      push(@{$desc->{dataissue}},
           'there is no technical change approvergroup defined');
   }

   return($exitcode,$desc);
}




1;
