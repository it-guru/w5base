package AL_TCom::businessserviceES;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
use kernel::Field;
use AL_TCom::businessservice;
@ISA=qw(AL_TCom::businessservice);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->getField("nature")->{searchable}=0;
   $self->getField("contextlist")->{vjoinon}=['id'=>'esid'];
   $self->getField("contextlist")->{uivisible}=1;
   $self->getField("contextaliases")->{vjoinon}=['id'=>'esid'];
   $self->getField("contextaliases")->{vjoinbase}={'taid'=>\undef};
   $self->getField("contextaliases")->{uivisible}=1;
   $self->getField("application")->{uivisible}=0;
   $self->getField("srcapplication")->{uivisible}=0;


   return($self);
}


sub SetFilter
{
   my $self=shift;
   $self->SetNamedFilter("NATURE",{nature=>\'ES'});

   return($self->SUPER::SetFilter(@_));
}






1;
