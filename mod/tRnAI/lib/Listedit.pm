package tRnAI::lib::Listedit;
#  W5Base Framework
#  Copyright (C) 2020  Hartmut Vogler (it@guru.de)
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


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;


   return(1) if ($self->IsMemberOf(["w5base.RnAI.inventory","admin"]));
   return(0);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   if ($self->IsMemberOf("w5base.RnAI.inventory",undef,"up") ||
       $self->IsMemberOf("admin")){
      return(1);
   }
   return(0);
}


1;
