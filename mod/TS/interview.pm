package TS::interview;
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
use kernel::Field;
use base::interview;
@ISA=qw(base::interview);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Select(
                name          =>'resonsegroup',
                label         =>'response group',
                group         =>'attr',
                value         =>[qw( 
                                     RGROUP.itservice
                                     RGROUP.customer
                                 )],
                container     =>'additional'),

      new kernel::Field::Text(
                name          =>'questcluster',
                label         =>'question cluster',
                group         =>'attr',
                container     =>'additional'),

      new kernel::Field::Boolean(
                name          =>'effect_on_mttr',
                label         =>'effects on MTTR',
                group         =>'attr',
                htmlhalfwidth =>1,
                dataobjattr   =>'effectonmttr'),

      new kernel::Field::Boolean(
                name          =>'effect_on_mtbf',
                label         =>'effects on MTBF',
                htmlhalfwidth =>1,
                group         =>'attr',
                dataobjattr   =>'effectonmtbf')
   );
   return($self);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","irange","tech","attr","source");
}


sub isWriteValid
{
   my $self=shift;
   my @l=$self->SUPER::isWriteValid(@_);
   push(@l,"attr") if (in_array(\@l,['default','ALL']));
   return(@l);
}







1;
