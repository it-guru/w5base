package TS::qrule::ApplIncidentAGroup;
#######################################################################
=pod

=head3 PURPOSE

Checks if there is on an "installed/active" or "available" application
an incident assignmentgroup for assetcenter defined.
If there is no valid assignmentgroup defined, an error will be proceeded.

=head3 IMPORTS

NONE

=head3 HINTS

no english hints available

[de:]

Die Incident-Assignmentgroup ist zwingend, wenn der Datensatz nach
AssetManager exportiert werden soll/muss. Falls die Assignmentgroup
über ServiceManager angelegt wurde, ist es wichtig, dass diese dort
für den Export nach AssetManager markiert wurde. 
Ansonsten kann die Gruppe nicht ausgewählt werden - obwohl diese
u.U. in ServiceManager angezeigt wird.
Ansprechpartner für Assignmentgroups im Allgemeinen ist in der
TelekomIT ...

Wolfgang Pfisterer
https://darwin.telekom.de/darwin/auth/base/user/ById/13916949570000


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
   return($exitcode,$desc) if (($rec->{cistatusid}!=4 && 
                               $rec->{cistatusid}!=3) ||
                               $rec->{opmode} eq "license" ||
                               $rec->{businessteam} eq "Extern");
   my $acinmassingmentgroup=$rec->{acinmassingmentgroup};
   if ($acinmassingmentgroup=~m/^\s*$/){
      $exitcode=3 if ($exitcode<3);
      push(@{$desc->{qmsg}},
           'there is no incident assignmentgroup defined');
      push(@{$desc->{dataissue}},
           'there is no incident assignmentgroup defined');
   }
   else{
      my $o=getModuleObject($self->getParent->Config,"tsacinv::group");
      my $flt={fullname=>\$acinmassingmentgroup};
      $o->SetFilter($flt);
      my ($grec)=$o->getOnlyFirst(qw(id deleted));
      if ($o->Ping()){
         if (!defined($grec) || $grec->{deleted}){
            my $m="refered incident assignmentgroup is deleted";
            push(@{$desc->{qmsg}},$m);
            push(@{$desc->{dataissue}},$m);
            $exitcode=3 if ($exitcode<3);
         }
      }
   }
   return($exitcode,$desc);
}




1;
