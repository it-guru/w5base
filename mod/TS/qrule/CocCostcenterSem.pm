package TS::qrule::CocCostcenterSem;
#######################################################################
=pod

=head3 PURPOSE

Checks if there is a Servicemanager defined in the costcenter record
in AssetManager.
If not and this record is related with application(s), an error will be procceded.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

The servicemanager of the related costcenter record in AssetManager is missing.
The probably reason is a missing entry in SAP P01.

This can result in "marking as delete" of applications in AssetManager, 
which are using this costcenter, which is inolving that this applications 
are no more selectable in the process supporting tools as configuration item.

[de:]

Der Servicemanager am zugehörigen costcenter Datensatz in AssetManager fehlt.
Wahrscheinliche Ursache ist ein fehlender Eintrag in SAP P01.

Das kann dazu führen, dass Anwendungen, die dieses Kontierungsobjekt nutzen,
in AssetManager als "deleted" markiert werden, was wiederum zur Folge hat,
dass diese Anwendungen in prozessunterstützenden Tools nicht 
mehr als ConfigItem auswählbar sind.


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
   return(["itil::costcenter"]);
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
  
   if ($amcoc->getVal('sem') eq '' &&
       $#{$rec->{applications}}>-1) {
         return(3,{qmsg     =>["no service manager in SAP P01"],
                   dataissue=>["no service manager in SAP P01"]});
   }

   return(0,undef);
}



1;
