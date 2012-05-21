package kernel::SubDataObj;
#  W5Base Framework
#  Copyright (C) 2002  Hartmut Vogler (hartmut.vogler@epost.de)
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
use vars qw(@ISA);
use strict;
use kernel;
use kernel::DataObj;

@ISA=qw(kernel::DataObj);

sub new
{
   my $type=shift;
   my $self=bless({@_},$type);
   return($self);
}

sub Init
{
   my $self=shift;
   return(1);
}

sub getDetailBlockPriority                # posibility to change the block order
{
   return();
}

sub IdField
{
   my $self=shift;
   my $p=$self->getParent;
   return() if (!defined($p));
   return($self->getParent->IdField());
}

sub SetNamedFilter
{
   my $self=shift;
   return($self->getParent->SetNamedFilter(@_));
}

sub InstallIntoParent
{
   return(1);
}

sub AddGroup
{
   my $self=shift;
   my $name=shift;
   my %param=@_;
   my $parent=$self->getParent();
   $param{translation}=(caller())[0] if (!defined($param{translation}));
   return($parent->AddGroup($name,%param)) if (defined($parent));
}



1;

