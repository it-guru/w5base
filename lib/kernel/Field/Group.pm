package kernel::Field::Group;
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
@ISA    = qw(kernel::Field::TextDrop);


sub new
{
   my $type=shift;
   my %param=@_;
   if (ref($param{vjoinon}) ne "ARRAY"){
      $param{vjoinon}=[$param{vjoinon}=>'grpid'];
   }
   $param{vjointo}='base::grp'  if (!defined($param{vjointo}));
  # $param{vjoindisp}='fullname'  if (!defined($param{vjoindisp}));
   if (!defined($param{vjoindisp})){
      $param{vjoindisp}=['fullname'];
   }
   if (!defined($param{vjoineditbase})){
      $param{vjoineditbase}={'cistatusid'=>[3,4]};
   }
   if (!defined($param{htmlwidth})){
      $param{htmlwidth}='300px';
   }

   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}


1;
