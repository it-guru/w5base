package itil::qrule::ApplCO;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks whether a Costcenter in the CI-State 'installed/active' is entered 
on every application in the CI-State 'installed/active' 
or 'available/in project'. 
A data issue is created when no valid Costcenter is entered.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

In the block 'Application-Informations' in the field 'Costcenter' 
a valid Costcenter must be entered.

If a Costcenter is entered on an application and this DataIssue is still 
present even after a QualityCheck, please make sure that the Costcenter 
itself is available in Darwin. One way to do this is to click on the entered 
Costcenter - when get a record not found error it means that the Costcenter 
is not available in Darwin and has to be created manually. 

[de:]

Im Block 'Anwendung-Daten' muss im Feld 'Kontierungsobjekt' ein gültiges
Kontierungsobjekt eingetragen sein.

Falls das DataIssue nach dem Auslösen eines QualityChecks weiterbesteht,
obwohl ein Kontierungsobjekt hinterlegt ist, vergewissern Sie sich, dass das 
angegebene Kontierungsobjekt in Darwin angelegt ist. 
Wenn Sie das Kontierungsobjekt anklicken und die Meldung 
'Datensatz nicht gefunden' bekommen, ist das Kontierungsobjekt in Darwin nicht 
vorhanden und muss manuell angelegt werden. 


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
   my $coobj=getModuleObject($self->getParent->Config,"itil::costcenter");
   if (!($coobj->ValidateCONumber($dataobj->Self,"conumber",$rec,undef))){
      return(3,{qmsg=>['no valid costcenter'],
                dataissue=>['no valid costcenter']});
   }
   else{
      $coobj->SetFilter({cistatusid=>4,name=>\$rec->{conumber}});
      my ($rec,$msg)=$coobj->getOnlyFirst(qw(id));
      if (!defined($rec)){
         return(3,{qmsg=>['costcenter is not installed/active'],
                   dataissue=>['costcenter is not installed/active']});
      }
   }
   return(0,undef);

}



1;
