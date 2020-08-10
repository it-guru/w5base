package tsacinv::lib::tools;
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


sub amInitializeOraSession
{
   my $self=shift;

   if (defined($self->{DB})){
      $self->{DB}->do("alter session set optimizer_features_enable='11.2.0.1'");
     # $self->{DB}->do("alter session set optimizer_max_permutations=100");
      $self->{DB}->do("alter session set cursor_sharing=force");
   }
}


1;
