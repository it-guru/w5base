package kernel::Field::Databoss;
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
@ISA    = qw(kernel::Field::Contact);


sub new
{
   my $type=shift;
   my %param=@_;
   $param{name}='databoss'       if (!defined($param{name}));
   $param{label}='Databoss'      if (!defined($param{label}));
   $param{vjoinon}='databossid'  if (!defined($param{vjoinon}));
   $param{AllowEmpty}='0'        if (!defined($param{AllowEmpty}));
   $param{SoftValidate}='1'      if (!defined($param{SoftValidate}));
   if (!defined($param{vjoineditbase})){
      $param{vjoineditbase}={
         'cistatusid'=>[3,4,5],
         'usertyp'=>['user','service']
      };
   }


   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}




1;
