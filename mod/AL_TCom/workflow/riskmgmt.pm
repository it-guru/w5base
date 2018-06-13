package AL_TCom::workflow::riskmgmt;
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
use kernel::WfClass;
use itil::workflow::riskmgmt;
use Text::Wrap qw($columns &wrap);

@ISA=qw(itil::workflow::riskmgmt);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;

   return($self->InitFields(
      $self->SUPER::getDynamicFields(@_),
      new kernel::Field::Text(    name          =>'extdesctelekomask',
                                  label         =>'Whats going wron in TelekomIT?',
                                  group         =>'riskdesc',
                                  container     =>'headref'),


      ));

}




1;
