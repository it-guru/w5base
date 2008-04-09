package tsacinv::event::loadsox;
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
use Data::Dumper;
use kernel;
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


   $self->RegisterEvent("loadsox","LoadSOX");
   return(1);
}


sub LoadSOX
{
   my $self=shift;
   my $app=$self->getParent;

   my $acappl=getModuleObject($self->Config,"tsacinv::appl");
   my $appl=getModuleObject($self->Config,"itil::appl");
   $acappl->SetCurrentView(qw(applid name issoxappl));
   $acappl->SetFilter({issoxappl=>\'YES'});


   my ($rec,$msg)=$acappl->getFirst();
   if (defined($rec)){
      do{
         last if (!defined($rec));
         $appl->ResetFilter();
         $appl->SetFilter({applid=>\$rec->{applid}});
         my ($oldrec,$msg)=$appl->getOnlyFirst(qw(ALL));
         if (defined($oldrec)){
            $appl->ValidatedUpdateRecord($oldrec,{issoxappl=>'1'},
                                                 {id=>\$oldrec->{id}});

         }
         ($rec,$msg)=$acappl->getNext();
      } until(!defined($rec));
   }
   return({exicode=>0});
}



1;
