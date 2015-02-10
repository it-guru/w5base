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

Check servicemanager entry in SAP P01!

[de:]

Eintrag Servicemanager in SAP P01 prüfen!

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

   return(0,undef) if ($rec->{cistatusid}!=4 && 
                       $rec->{cistatusid}!=3);

   my $cocobj=getModuleObject($self->getParent->Config,"tsacinv::costcenter");
   $cocobj->SetFilter({name=>$rec->{conodenumber}});

   if (!$cocobj->getVal('sem')) {
      return(3,{qmsg     =>['MSG01'],
                dataissue=>['MSG01']});
   }

   return(0,undef);
}



1;
