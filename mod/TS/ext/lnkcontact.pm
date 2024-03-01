package TS::ext::lnkcontact;
#  W5Base Framework
#  Copyright (C) 2020  Hartmut Vogler (it@guru.de)
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
use kernel::Universal;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub getPosibleRoles
{
   my $self=shift;
   my $field=shift;
   my $parentobj=shift;
   my $current=shift;
   my $newrec=shift;


   if ($parentobj=~m/^.+::vou$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::vou$/)){
      return(
             "write"           =>$self->getParent->T("write",
                                                     $self->Self),
             "RAdmin"          =>$self->getParent->T("RAdmin",
                                                     $self->Self),
             "rte"       =>$self->getParent->T("RTE (Release Train Engineer)",
                                               $self->Self),
             "spc"       =>$self->getParent->T("SPC (SAFe Programm Consultant)",
                                               $self->Self),
             "StabiOwner"=>$self->getParent->T("Stability Owner",
                                               $self->Self),
             "pm"        =>$self->getParent->T("PM (Product Manager)",
                                               $self->Self),
             "sa"        =>$self->getParent->T("SA (System Architect)",
                                               $self->Self),
             "rem"       =>$self->getParent->T("REM (Resourcemanager)",
                                               $self->Self),
            );
   }
   return();
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;
   my $parentobj=shift;
   my $refid=shift;
   my $app=$self->getParent();

   if (defined($newrec->{roles}) && $parentobj=~m/::vou$/){
      my $roles=$newrec->{roles};
      $roles=[$roles] if (ref($roles) ne "ARRAY");
      if (grep(/^StabiOwner$/,@$roles)){
         if ($app->isRoleMultiUsed({
               StabiOwner =>$self->getParent->T("Stability Owner")
               },$roles,$oldrec,$newrec,$parentobj,$refid)){
            return(0);
         }
      }
      if (in_array("StabiOwner",$roles)){
         if (effVal($oldrec,$newrec,"target") eq "base::grp"){
            $app->LastMsg(ERROR,
                "role Stability Owner cannot be assigned to groups");
            return(0);
         }
      }
   }

   return(1);
}



1;
