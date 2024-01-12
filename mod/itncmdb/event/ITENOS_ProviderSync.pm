package itncmdb::event::ITENOS_ProviderSync;
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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
@ISA=qw(kernel::Event);


sub ITENOS_ProviderSync
{
   my $self=shift;
   my $queryparam=shift;

   my @O=qw(
      itil::asset itil::system 
      itncmdb::asset itncmdb::system
   );
   my $O={};

   foreach my $objname (@O){
      msg(INFO,"load object $objname");
      my $o=getModuleObject($self->Config,$objname);
      if ($o->isSuspended()){ 
         return({exitcode=>0,exitmsg=>'ok'});
      }
      if (!$o->Ping()){
         my $infoObj=getModuleObject($self->Config,"itil::lnkapplappl");
         if ($infoObj->NotifyInterfaceContacts($o)){
            return({exitcode=>0,exitmsg=>'Interface notified'});
         }
         return({
            exitcode=>1,
            exitmsg=>'not all dataobjects available - miss $objname'
         });
      }
      $O->{$objname}=$o;
   }




   $O->{'itncmdb::system'}->ResetFilter();
   $O->{'itncmdb::system'}->SetFilter({});
   my @remoteSys=$O->{'itncmdb::system'}->getHashList(qw(id applw5baseid));
   print Dumper(\@remoteSys);





   return({exitcode=>0,exitmsg=>'ok'});
}


1;
