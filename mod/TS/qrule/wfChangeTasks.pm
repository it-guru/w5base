package TS::qrule::wfChangeTasks;
#######################################################################
=pod

=head3 PURPOSE

Checks if there are tasks in ServiceCenter for the current
change workflow. If the type of the Change is "standard", there are
no tasks needed.

=head3 IMPORTS

NONE

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
   return(["AL_TCom::workflow::change"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $exitcode=0;
   my $desc={qmsg=>[],solvtip=>[]};

   #if ($rec->{srcid}=~m/^CHM.*$/){
   #   my $type="";
   #   if (ref($rec->{additional}) eq "HASH" &&
   #       ref($rec->{additional}->{ServiceCenterType}) eq "ARRAY"){
   #      $type=$rec->{additional}->{ServiceCenterType}->[0];
   #   }
   #   if ($type ne "standard"){    
   #      my $chmtask=getModuleObject($self->getParent->Config,"tssc::chmtask");
   #      if (defined($chmtask)){
   #         $chmtask->SetFilter({changenumber=>\$rec->{srcid}});
   #         if ($chmtask->CountRecords()==0){
   #            $exitcode=3 if ($exitcode<3);
   #            push(@{$desc->{qmsg}},
   #                 'there is are no change tasks in ServiceCenter');
   #         }
   #      }
   #   }
   #}

   return($exitcode,$desc);
}




1;
