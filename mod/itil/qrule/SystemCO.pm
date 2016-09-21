package itil::qrule::SystemCO;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks whether a Costcenter in the CI-State "installed/active" is entered
on every logical system in the CI-State "installed/active" or
"available/in project". A data issue is created when no valid Costcenter
is entered.

If the logical system is a workstation, the Costcenter is not needed.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

A logical system must have a valid Costcenter in the field "Costcenter"
in the block "Miscellaneous". If a Costcenter is entered and this 
DataIssue is still present even after a QualityCheck, please make sure 
that the Costcenter itself is available in Darwin.
One way to do this is to click on the entered Costcenter - when you get 
a "record not found" error it means that the Costcenter is not available 
in Darwin and has to be created manually. To do this, go under 
"IT-Inventory -> Basedata -> Costcenter -> New" and create the Costcenter.

[de:]

Am logischen System muss im Feld "Kontierungsobjekt" im Block "Sonstiges"
ein Kontierungsobjekt hinterlegt sein. Falls ein Kontierungsobjekt 
hinterlegt ist und das DataIssue nach dem Auslösen des QualityChecks 
weiterhin besteht, vergewissern Sie sich, dass das Kontierungsobjekt 
in W5Base/Darwin angelegt ist. 
Wenn Sie das Kontierungsobjekt anklicken und die Meldung 
"Datensatz nicht gefunden" bekommen, ist das Kontierungsobjekt noch nicht 
in W5Base/Darwin vorhanden. Es muss unter
"IT-Inventar -> Stammdaten -> Kontierungsobjekt -> Neueingabe"
manuell angelegt werden.


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
   return(["itil::system"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);
   return(0,undef) if ($rec->{isworkstation});
   my $coobj=getModuleObject($self->getParent->Config,"itil::costcenter");
   if ($rec->{conumber} eq "" ||
       !($coobj->ValidateCONumber($dataobj->Self,"conumber",$rec,undef))){
      return(3,{qmsg=>['no valid costcenter'],
                dataissue=>['no valid costcenter']});
   }
#   else{
#      $coobj->SetFilter({cistatusid=>4,name=>\$rec->{conumber}});
#      my ($rec,$msg)=$coobj->getOnlyFirst(qw(id));
#      if (!defined($rec)){
#         return(3,{qmsg=>['costcenter object is empty or record not installed/active'],
#            dataissue=>['costcenter object is empty or record not installed/active']});
#      }
#   }
   return(0,undef);

}



1;
