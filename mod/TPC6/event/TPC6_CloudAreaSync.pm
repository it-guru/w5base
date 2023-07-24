package TPC6::event::TPC6_CloudAreaSync;
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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
use kernel::Event;
use kernel::QRule;
use tpc::lib::Listedit;
@ISA=qw(kernel::Event);



sub Init
{
   my $self=shift;


   $self->RegisterEvent("TPC6_CloudAreaSync","TPC6_CloudAreaSync",timeout=>500);
   return(1);
}


sub TPC6_CloudAreaSync
{
   my $self=shift;
   my $queryparam=shift;


   return(tpc::lib::Listedit::TPC_CloudAreaSync($self,"TPC6",$queryparam));
}


1;
