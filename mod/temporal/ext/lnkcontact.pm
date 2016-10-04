package temporal::ext::lnkcontact;
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


   if ($parentobj=~m/^.+::plan$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::plan$/)){
      return(
         "read"            =>$self->getParent->T("read",
                                                 $self->Self),
         "write"           =>$self->getParent->T("write",
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
   my $plan=$self->getParent();

  # if (defined($newrec->{roles}) && $parentobj=~m/::plan$/){
  #    my $roles=$newrec->{roles};
  #    $roles=[$roles] if (ref($roles) ne "ARRAY");
  #    if (grep(/^developerboss$/,@$roles) ||
  #        grep(/^developercoord$/,@$roles) ||
  #        grep(/^orderin1$/,@$roles)){
  #       if ($app->isRoleMultiUsed({
  #             developerboss =>$self->getParent->T("Chief Developer"),
  #             orderin1      =>$self->getParent->T("Order acceptation"),
  #             developercoord=>$self->getParent->T("Development coordination")
  #             },$roles,$oldrec,$newrec,$parentobj,$refid)){
  #          return(0);
  #       }
  #    }
  # }

   return(1);
}




1;
