package itil::event::iprewrite;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}


sub iprewrite
{
   my $self=shift;

   my $e=getModuleObject($self->Config,'itil::ipaddress');
   my $op=$e->Clone();
   $e->SetFilter({name=>'*:*'});

   $e->SetCurrentView(qw(ALL));

   my ($rec,$msg)=$e->getFirst();
   if (defined($rec)){
      do{
         msg(INFO,"process object ".$e->Self." : $rec->{name}");
         my %newrec=(
            name=>$rec->{name},
            editor=>$rec->{editor},
            owner=>$rec->{owner},
            mdate=>$rec->{mdate}
         );
         
         $op->ValidatedUpdateRecord($rec,\%newrec,{id=>\$rec->{id}});
         ($rec,$msg)=$e->getNext();
      } until(!defined($rec));
   }



   return({exitcode=>0,msg=>'ok'});
}

1;
