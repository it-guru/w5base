package itil::event::recreateReleasekey;
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
use kernel::Event;
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


   $self->RegisterEvent("recreateReleasekey","recreateReleasekey");
   return(1);
}

sub recreateReleasekey
{
   my $self=shift;
   my $lnk=getModuleObject($self->Config,"itil::lnksoftware");
   $lnk->SetCurrentOrder(qw(NONE));
   $lnk->SetCurrentView(qw(ALL));

   if ($_[0] ne ""){
      $lnk->SetFilter({id=>\$_[0]});
   }
   my $s=$lnk->Clone();

   my ($swi,$msg)=$lnk->getFirst(unbuffered=>1);
   if (defined($swi)){
      do{
         if ($swi->{version} ne ""){
            msg(DEBUG,"check %s",$swi->{id});
            my %newrec=(mdate=>$swi->{mdate},
                        editor=>$swi->{editor},
                        realeditor=>$swi->{realeditor},
                        version=>$swi->{version},
                        owner=>$swi->{owner});
            delete($swi->{version});
            $s->ValidatedUpdateRecord($swi,\%newrec,
                                         {id=>\$swi->{id}});
            
         }
         ($swi,$msg)=$lnk->getNext();
      }until(!defined($swi));
   }

   return({exitcode=>0,msg=>'ok'});
}

1;
