package finance::ext::lnkcontact;
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

   if ($parentobj=~m/^.+::custcontract/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::custcontract$/)){
      return(
             "write"           =>$self->getParent->T("write contract",
                                                     $self->Self),
             "read"            =>$self->getParent->T("read contract",
                                                     $self->Self),
             "customer"        =>$self->getParent->T("Customer Contact",
                                                     $self->Self));
   }
   if ($parentobj=~m/^.+::costcenter/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::costcenter$/)){
      return(
             "write"           =>$self->getParent->T("write costcenter",
                                                     $self->Self));
   }
   return();
}




1;
