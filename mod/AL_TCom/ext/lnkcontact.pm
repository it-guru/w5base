package AL_TCom::ext::lnkcontact;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
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
use Data::Dumper;
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

   if ($parentobj=~m/^.+::custcontract$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^AL_TCom::custcontract$/)){
      return("vk"=>$self->getParent->T("T-Com:VK Vertragskoordinator",$self->Self));
   }
   if ($parentobj=~m/^.+::businessservice$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->SelfAsParentObject() eq 
          "itil::businessservice")){
      return(
         "requestor"=>$self->getParent->T("requestor",$self->Self),
         "procmgr"  =>$self->getParent->T("process designer",$self->Self),
         "slmgr"    =>$self->getParent->T("service level manager",$self->Self),
         "evmgr"    =>$self->getParent->T("event manager",$self->Self));
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
   
   if (defined($newrec->{roles}) && $parentobj=~m/::appl$/){
      my $roles=$newrec->{roles};
      $roles=[$roles] if (ref($roles) ne "ARRAY");
      if (grep(/^wbv$/,@$roles) ||
          grep(/^eb$/,@$roles)){
         if ($app->isRoleMultiUsed({
                                    wbv=>
                                     $self->getParent->T("T-Com:WBV"),
                                    eb=>
                                     $self->getParent->T("T-Com:EB"),
                                   },$roles,$oldrec,$newrec,$parentobj,$refid)){
            return(0);
         }
      }
   }

   if (defined($newrec->{roles}) && $parentobj=~m/::businessservice$/){
      my $roles=$newrec->{roles};
      $roles=[$roles] if (ref($roles) ne "ARRAY");
      if (grep(/^requestor$/,@$roles) ){
         if ($app->isRoleMultiUsed({
               procmgr     =>$self->getParent->T("process designer"),
               slmgr       =>$self->getParent->T("service level manager"),
               requestor     =>$self->getParent->T("requestor")
               },$roles,$oldrec,$newrec,$parentobj,$refid)){
            return(0);
         }
      }
   }


   return(1);
}






1;
