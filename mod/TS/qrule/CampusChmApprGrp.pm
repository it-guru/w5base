package TS::qrule::CampusChmApprGrp;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks if there on an "installed/active" or "available" campus
a change approvergroup is specified.
If there is no valid approvergroup specified, an error will be procceeded.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

The Qrule checks if at least one valid Change Approvergroup is entered 
in the field 'Change approver'.

Enter the Approvergroup(s) which are used for Changes on this campus. 
If the Approvergroup was created in ServiceManager, 
it is important to make sure it was marked for Export to AssetManager. 
Otherwise it is not possible to enter the group, even though it might be 
displayed in ServiceManager.

If you have any questions please contact the W5Base/Darwin Support: 
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001


[de:]

Prüft, ob im Feld 'Change-Approver' mindestens eine gültige 
Change Approvergroup eingetragen ist.

Wählen Sie hier die Approvergroup(s), die bei Changes für diesen Campus 
verwendet werden müssen.
Falls die Approvergroup über ServiceManager angelegt wurde, 
ist es wichtig, dass diese dort für den Export nach AssetManager markiert wurde.
Ansonsten kann die Gruppe nicht ausgewählt werden, 
obwohl diese u.U. in ServiceManager angezeigt wird. 

Bei Fragen wenden Sie sich bitte an den W5Base/DARWIN Support:
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2017  Markus Zeis (w5base@zeis.email)
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
   return(["TS::campus"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if ($rec->{'cistatusid'}!=4 &&
                       $rec->{'cistatusid'}!=3);

   #if ($rec->{cdate} ne ""){
   #   my $now=NowStamp("en");
   #   my $d=CalcDateDuration($rec->{cdate},$now,"GMT");
   #   my $max=7*2;  # check only if application record is older than 2 weeks
   #   if ($d->{days}<$max){
   #      return($exitcode,$desc);
   #   }
   #}

   if ($#{$rec->{chmapprgroups}}==-1) {
      my $msg='No change approver group specified';

      return(3,{qmsg=>[$msg],dataissue=>[$msg]});
   }

   return(0,undef);
}



1;
