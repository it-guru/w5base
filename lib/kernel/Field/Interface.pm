package kernel::Field::Interface;
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

#
# This field is for internal references. In diffrent to "Link" the field
# is accessable by W5API and XML download.
#

use strict;
use vars qw(@ISA);
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self={@_};
   $self->{searchable}=0 if (!defined($self->{searchable}));
   $self->{htmldetail}=0 if (!defined($self->{htmldetail}));
   $self->{xlsnumformat}='@' if (!defined($self->{xlsnumformat}));
   $self->{uivisible}=sub {
      my $self=shift;
      if ($self->getParent->can("IsMemberOf")){
         return(1) if ($self->getParent->IsMemberOf("admin"));
      }
      if ($self->getParent->can("getParent") && 
          defined($self->getParent->getParent())){
         return(1) if ($self->getParent->getParent->IsMemberOf("admin"));
      }
      return(0);
   } if (!defined($self->{uivisible}));
   $self=bless($type->SUPER::new(%$self),$type);
   return($self);
}


1;
