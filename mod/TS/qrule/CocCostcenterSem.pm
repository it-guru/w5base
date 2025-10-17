package TS::qrule::CocCostcenterSem;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks if there is a Customer Business Manager defined in the costcenter object
in SAP P01.
If not and this record is related with application(s), an error will be procceded.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

The Customer Business Manager of the related costcenter object is missing in SAP P01.

As a result the application cannot be transmitted to Asset Manager and will therefore get the status "marked as delete". Afterwards the application is not selectable as configuration item in the tools supporting the process.


[de:]

Im zugehörigen Kontierungsobjekt in SAP P01 ist kein Customer Business Manager eingetragen.

Das kann dazu führen, dass die Anwendung nicht nach AssetManager
übertragen werden kann und deshalb dort als "deleted" markiert
wird. In prozessunterstützenden Tools ist die Anwendung dann nicht
mehr als ConfigItem auswählbar.


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

   return(0,undef) if (($rec->{cistatusid}!=3 && 
                        $rec->{cistatusid}!=4 &&
                        $rec->{cistatusid}!=5) ||
                       $rec->{costcentertype} ne 'pspelement');

   my $sapobj=getModuleObject($self->getParent->Config,"tssapp01::psp");
   $sapobj->SetFilter({name=>$rec->{name}});

   my $smwiw=$sapobj->getVal('smwiw');
   if ($smwiw eq '' &&
       $#{$rec->{applications}}>-1) {
         return(3,{qmsg     =>['no CBM (Customer Business Manager) '.
                               'defined in the costcenter object in SAP P01'],
                   dataissue=>['no CBM (Customer Business Manager) '.
                               'defined in the costcenter object in SAP P01']});
   }

   return(0,undef);
}



1;
