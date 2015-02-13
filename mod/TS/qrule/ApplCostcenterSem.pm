package TS::qrule::ApplCostcenterSem;
#######################################################################
=pod

=head3 PURPOSE

Checks if there is a Servicemanager defined in the costcenter record
in AssetManager related to an "installed/active" or "available"
application.
If not, an error will be procceded.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

The servicemanager of the related costcenter record in AssetManager is missing.

This can result in "marking as delete" the application in AssetManager, involving
that the application is no more selectable in the process supporting tools.

The probably reason is a missing entry in SAP P01.

Responsible to maintenance this record in SAP P01 is the databoss 
from the costcenter of the application.

[de:]

Der Servicemanager am zugehörigen costcenter Datensatz in AssetManager fehlt.

Das kann dazu führen, dass die Anwendung in AssetManager als "deleted" markiert 
wird, was z.B. zur Folge hat, dass sie in prozessunterstützenden Tools nicht 
mehr als ConfigItem auswählbar ist.

Wahrscheinliche Ursache ist ein fehlender Eintrag in SAP P01.

Zuständig für die Pflege dieses Datensatzes in SAP P01 ist der
Datenverantwortliche des Kontierungsobjektes der Anwendung.

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

   return(0,undef) if ($rec->{cistatusid}!=3 && 
                       $rec->{cistatusid}!=4 &&
                       $rec->{cistatusid}!=5);

   my $amcoc=getModuleObject($self->getParent->Config,"tsacinv::costcenter");
   $amcoc->SetFilter({name=>$rec->{conodenumber}});
  
   if ($amcoc->getVal('sem') eq '') {
      my $itilcoc=getModuleObject($self->getParent->Config,"itil::costcenter");
      $itilcoc->SetFilter({name=>$rec->{conumber}});
      my $boss=$itilcoc->getVal('databoss');
      return(3,{qmsg     =>['MSG01'],
                dataissue=>["MSG02: ".$itilcoc->getVal('databoss')]});
   }

   return(0,undef);
}



1;
