package AL_TCom::ext::DataIssue;
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
use kernel::Universal;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub getControlRecord
{
   my $self=shift;
   my $d=[ 
           {
             dataobj   =>'AL_TCom::appl',
             target    =>'name',
             targetid  =>'id'
           },
           {
             dataobj   =>'AL_TCom::custcontract',
             target    =>'name',
             targetid  =>'id'
           },
           {
             dataobj   =>'AL_TCom::system',
             target    =>'name',
             targetid  =>'id'
           },
           {
             dataobj   =>'AL_TCom::itcloud',
             target    =>'fullname',
             targetid  =>'id'
           },
           {
             dataobj   =>'AL_TCom::businessservice',
             target    =>'fullname',
             targetid  =>'id'
           },
           {
             dataobj   =>'AL_TCom::asset',
             target    =>'name',
             targetid  =>'id'
           },
         ];
   return($d);
}




1;
