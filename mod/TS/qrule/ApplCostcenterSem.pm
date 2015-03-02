package TS::qrule::ApplCostcenterSem;
#######################################################################
=pod

=head3 PURPOSE

Checks if the given costcenter object is valid in AssetManager.
If not, an error will be procceded.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

The given costcenter has no Service Manager entry in AssetManager.

As a result the application cannot be transmitted to Asset Manager and will therefore get the status "marked as delete". Afterwards the application is not selectable as configuration item in the tools supporting the process.

Please check, if the costcenter is entered correctly. For inquiries contact the databoss of the affected costcenter.


[de:]

Das angegebene Kontierungsobjekt enthält keinen 
Servicemanager-Eintrag in AssetManager.

Das kann dazu führen, dass die Anwendung nicht nach AssetManager 
übertragen werden kann und deshalb dort als "deleted" markiert 
wird. In prozessunterstützenden Tools ist die Anwendung dann nicht 
mehr als ConfigItem auswählbar.

Bitte prüfen, ob das Kontierungsobjekt korrekt angegeben wurde.
Für Rückfragen wenden Sie sich bitte an den Datenverantwortlichen 
des Kontierungsobjektes.


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
      return(3,{qmsg     =>['no servicemanager entry in the '.
                            'costcenter object in AssetManager'],
                dataissue=>['no servicemanager entry in the '.
                            'costcenter object in AssetManager']});
   }

   return(0,undef);
}



1;
