package AL_TCom::event::cleanuplocation;
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


   $self->RegisterEvent("cleanuplocation","cleanuplocation");
   return(1);
}

sub cleanuplocation
{
   my $self=shift;
   my $loc=getModuleObject($self->Config,"base::location");
   my $locop=$loc->Clone();

   $loc->SetFilter({country=>"!de",cistatusid=>\'4'});
   $loc->SetCurrentView(qw(ALL));
   my ($rec,$msg)=$loc->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         msg(INFO,"process $rec->{id}: $rec->{name}");
         $locop->ResetFilter();
         $locop->SetFilter({location=>\$rec->{location},
                            address1=>\$rec->{address1}});
         foreach my $locrec ($locop->getHashList(qw(country id name))){
            next if (uc($locrec->{country}) ne "DE");
            msg(ERROR,"$locrec->{name}");
         }
          
         ($rec,$msg)=$loc->getNext();
      } until(!defined($rec));
   }
   return({exitcode=>0});
}

1;
