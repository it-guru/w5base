package TS::qrule::MandatorRules;
#######################################################################
=pod

=head3 PURPOSE

REGEL ist noch in der Testphase !!!
Switches the mandator relation based on the defined t-systems ruleset

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

REGEL ist noch in der Testphase !!!
Not documented

[de:]

REGEL ist noch in der Testphase !!!


Die Mandaten von Anwendungen werden basierend auf der im angegebenen
Kontierungsobjekt definierten SAP-Hierarchie zugeordnet.


9TS_ES.9DTIT.9ECS     ist gleich CSO
9TS_ES.9DTIT.9EMC     ist gleich MCS
9TS_ES.9DTIT.9ESSI    ist gleich TSI
9TS_ES.9DTIT.9ESIL    ist gleich TSI
9TS_ES.9DTIT.9EGS     ist gleich GSO
9TS_ES.9DTIT.9ETS     ist gleich TSO


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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
   return(["itil::appl","itil::swinstance","itil::system","itil::asset"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if ($rec->{cistatusid}==6);

   if ($dataobj->SelfAsParentObject() eq "itil::appl"){
#      printf STDERR ("fifi Application Mandator RuleSet\n");
   }
   elsif ($dataobj->SelfAsParentObject() eq "itil::swinstance"){
#      printf STDERR ("fifi SW-Instanze Mandator RuleSet\n");
   }
   elsif ($dataobj->SelfAsParentObject() eq "itil::system"){
#      printf STDERR ("fifi System Mandator RuleSet\n");
   }
   elsif ($dataobj->SelfAsParentObject() eq "itil::asset"){
#      printf STDERR ("fifi Asset Mandator RuleSet\n");
   }

#   my $sapobj=getModuleObject($self->getParent->Config,"tssapp01::psp");
#   $sapobj->SetFilter({name=>$rec->{name}});
#
#   my $smwiw=$sapobj->getVal('smwiw');
#   if ($smwiw eq '' &&
#       $#{$rec->{applications}}>-1) {
#         return(3,{qmsg     =>['no CBM (Customer Business Manager) '.
#                               'defined in the costcenter object in SAP P01'],
#                   dataissue=>['no CBM (Customer Business Manager) '.
#                               'defined in the costcenter object in SAP P01']});
#   }

   return(0,undef);
}



1;
