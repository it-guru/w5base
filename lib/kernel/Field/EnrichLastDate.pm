package kernel::Field::EnrichLastDate;
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
@ISA    = qw(kernel::Field::Date);


sub new
{
   my $type=shift;
   my $self={@_};

   $self->{group}='qc'                      if (!defined($self->{qc}));
   $self->{name}='lastqenrich'              if (!defined($self->{name}));
   $self->{label}='Quality enrich last date' if (!defined($self->{label}));
   $self->{searchable}=1                    if (!defined($self->{searchable}));
   $self->{history}=0;
   $self->{readonly}=1;
   $self->{htmldetail}=0 if (!exists($self->{htmldetail}));

   my $self=bless($type->SUPER::new(%$self),$type);

   return($self);
}


sub Uploadable
{
   my $self=shift;

   return(0);
}







1;
