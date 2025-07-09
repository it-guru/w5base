package W5Warehouse::event::CheckW5WarehouseDBService;
#  W5Base Framework
#  Copyright (C) 2026  Hartmut Vogler (it@guru.de)
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
no warnings;
use kernel;
use kernel::Event;
use kernel::QRule;
@ISA=qw(kernel::Event);


sub CheckW5WarehouseDBService
{
   my $self=shift;
   my @chkService=@_;

   my @missed;
   my $dobj=getModuleObject($self->Config,"W5Warehouse::dbservice");

   foreach my $chk (@chkService){
      $dobj->ResetFilter();
      $dobj->SetFilter({name=>\$chk,blocked=>\'NO'});
      my @l=$dobj->getHashList(qw(id));
      if ($#l!=0){
         push(@missed,$chk);
      }
   }
   if ($#missed!=-1){
      my $emsg='missed non_blocked services: '.join(", ",@missed);
      msg(ERROR,$emsg);
      return({
         exitcode=>1,
         exitmsg=>$emsg
      });
   }
   return({exitcode=>0,exitmsg=>'OK'});
}


1;
