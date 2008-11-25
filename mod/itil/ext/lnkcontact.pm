package itil::ext::lnkcontact;
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
   my $current=shift;
   my $newrec=shift;

   my $parentobj=effVal($current,$newrec,"parentobj");


   if ($parentobj=~m/^.+::appl$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::appl$/)){
      return("developer"       =>$self->getParent->T("Developer",
                                                     $self->Self),
             "developerboss"   =>$self->getParent->T("Chief Developer",
                                                 $self->Self),
             "businessemployee"=>$self->getParent->T("Business Employee",
                                                 $self->Self),
             "orderin1"        =>$self->getParent->T("Order acceptation",
                                                     $self->Self),
             "orderin2"        =>$self->getParent->T("Order acceptation deputy",
                                                     $self->Self),
             "customer"        =>$self->getParent->T("Customer Contact",
                                                     $self->Self),
             "techcontact"     =>$self->getParent->T("Technical Contact",
                                                     $self->Self),
             "read"            =>$self->getParent->T("read application",
                                                     $self->Self),
             "privread"        =>$self->getParent->T("privacy read",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write application",
                                                     $self->Self),
             "support"         =>$self->getParent->T("Support",
                                                     $self->Self));
   }
   if ($parentobj=~m/^.+::swinstance$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::swinstance$/)){
      return(
             "read"            =>$self->getParent->T("read instance",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write instance",
                                                     $self->Self));
   }
   if ($parentobj=~m/^.+::liccontract$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::liccontract$/)){
      return(
             "read"            =>$self->getParent->T("read contract",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write contract",
                                                     $self->Self),
             "privread"        =>$self->getParent->T("privacy read",
                                                     $self->Self));
   }
   if ($parentobj=~m/^.+::network$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::network$/)){
      return(
             "techcontact"     =>$self->getParent->T("Technical Contact",
                                                     $self->Self));
   }
   if ($parentobj=~m/^.+::system$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::system$/)){
      return("read"            =>$self->getParent->T("read system",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write system",
                                                     $self->Self),
            );
   }
   if ($parentobj=~m/^.+::asset$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::asset$/)){
      return("read"            =>$self->getParent->T("read system",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write system",
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

   if (defined($newrec->{roles}) && $parentobj=~m/::appl$/){
      my $roles=$newrec->{roles};
      $roles=[$roles] if (ref($roles) ne "ARRAY");
      if (grep(/^developerboss$/,@$roles) ||
          grep(/^orderin1$/,@$roles)){
         if ($app->isRoleMultiUsed({developerboss=>
                                     $self->getParent->T("Chief Developer"),
                                    orderin1=>
                                     $self->getParent->T("Order acceptation")
                                   },$roles,$oldrec,$newrec,$parentobj,$refid)){
            return(0);
         }
      }
   }

   return(1);
}




1;
