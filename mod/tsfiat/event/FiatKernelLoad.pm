package tsfiat::event::FiatKernelLoad;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
@ISA=qw(kernel::Event);



# Modul to detect expiered SSL Certs based on Qualys scan data
sub FiatKernelLoad
{
   my $self=shift;
   my $queryparam=shift;

   my $obj=getModuleObject($self->Config,"tsfiat::firewall");

   return({exitcode=>1,exitmsg=>'suspended'}) if ($obj->isSuspended());

   my $start=NowStamp("en");
   my $d=$obj->getFirewallTable();
   foreach my $rec (@$d){
       $obj->ValidatedInsertOrUpdateRecord($rec,{id=>$rec->{id}}); 

   }
   $obj->BulkDeleteRecord({srcload=>'<"'.$start.' GMT"'});
   
   #print STDERR ("rec=%s\n",Dumper($d));





   return({exitcode=>0,exitmsg=>'ok'});
}


1;
