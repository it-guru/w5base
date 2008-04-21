package AL_TCom::event::removeUnusedLoc;
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
use kernel::date;
use kernel::Event;
use kernel::database;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;


   $self->RegisterEvent("removeUnusedLoc","removeUnusedLoc");
   return(1);
}

sub removeUnusedLoc
{
   my $self=shift;
   my $loc=getModuleObject($self->Config,"base::location");
   my $ac=getModuleObject($self->Config,"itil::asset");
   $loc->SetCurrentOrder("NONE");
   $loc->SetCurrentView(qw(ALL));
   my ($rec,$msg)=$loc->getFirst();
   if (defined($rec)){
      do{
         msg(INFO,"process $rec->{name}");
         $ac->ResetFilter();
         $ac->SetFilter({locationid=>\$rec->{id}});
         my ($acrec,$msg)=$ac->getOnlyFirst(qw(id));
         if (!defined($acrec)){
            msg(INFO,"delete $rec->{name}");
            $loc->ValidatedDeleteRecord($rec);
         }
         ($rec,$msg)=$loc->getNext();
         
      } until(!defined($rec));
   }

   return({exitcode=>0});
}

1;
