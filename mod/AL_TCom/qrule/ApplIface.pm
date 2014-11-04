package AL_TCom::qrule::ApplIface;
#######################################################################
=pod

=head3 PURPOSE

Every Application in in CI-Status "installed/active" or "available", needs
at least 1 interface, if the flag "application has no intefaces" is not 
true.
Loop interfaces from the current to the current application are not allowed.
In special case against the parent rule itil::qrule::ApplIface, in this
rule Applications in the mgmtitemgroup SAP are always treated as OK.

=head3 IMPORTS

NONE

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
use itil::qrule::ApplIface;
@ISA=qw(itil::qrule::ApplIface);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   my $mgmtitemgroup=$rec->{mgmtitemgroup};
   if (ref($mgmtitemgroup) ne "ARRAY"){
      $mgmtitemgroup=[$mgmtitemgroup];
   }
   if (in_array($mgmtitemgroup,"SAP")){
      return(0,undef);
   } 
   return($self->SUPER::qcheckRecord($dataobj,$rec,$checksession));
}






1;
