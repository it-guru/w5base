package tscape::Explore::ictoform;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
use kernel::ExploreApplet;
@ISA=qw(kernel::ExploreApplet);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   $self->{formular}=1;
   return($self);
}

sub getObjectHiddenState
{
   my $self=shift;
   my $app=shift;

   return(0) if ($app->IsMemberOf("admin"));

   return(1);
}


1;
