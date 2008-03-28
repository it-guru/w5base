package kernel::Field::Fulltext;
#  W5Base Framework
#  Copyright (C) 2008  Hartmut Vogler (it@guru.de)
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
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self={@_};
   $self->{htmldetail}=0      if (!defined($self->{htmldetail}));
   $self->{searchable}=1      if (!defined($self->{searchable}));
   $self->{uivisible}=0       if (!defined($self->{uivisible}));
   $self->{name}="ftext"      if (!defined($self->{name}));
   $self->{label}="Fulltext"  if (!defined($self->{label}));
   $self->{uivisible}=sub{
                         my $self=shift;
                         my $mode=shift;
                         return(1) if ($mode eq "SearchMask");
                         return(0);
                      };
   my $self=bless($type->SUPER::new(%$self),$type);
   return($self);
}









1;
