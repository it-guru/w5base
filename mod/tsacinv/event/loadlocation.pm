package tsacinv::event::loadlocation;
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


   $self->RegisterEvent("loadlocation","LoadLocation");
   $self->RegisterEvent("loadaclocation","LoadLocation");
   return(1);
}


sub LoadLocation
{
   my $self=shift;
   my $app=$self->getParent;

   my $loc=getModuleObject($self->Config,"tsacinv::location");
   $loc->SetCurrentView(qw(ALL));
   $loc->SetFilter({locationtype=>\'Site'});

   $self->{loc}=getModuleObject($self->Config,"base::location");
   my $loadstart=$self->getParent->ExpandTimeExpression("now","en","GMT");

   my ($rec,$msg)=$loc->getFirst();
   if (defined($rec)){
      do{
         last if (!defined($rec));
         if ($rec->{address1} ne ""){
            my $label="";
            my %newrec=(address1=>$rec->{address1},
                        label=>$label,
                        zipcode=>$rec->{zip},
                        country=>$rec->{country},
                        location=>$rec->{location},
                        refcode2=>"AC-".$rec->{locationid},
                        cistatusid=>4,
                        srcload=>$loadstart,
                        owner=>0,
                        creator=>0,
                        mdate=>scalar($app->ExpandTimeExpression(
                                      $rec->{mdate},"en","GMT")),
                        cdate=>scalar($app->ExpandTimeExpression(
                                      $rec->{mdate},"en","GMT")),
                        srcsys=>"AC",
                      );
                     #  srcid=>$rec->{locationid},
            delete($newrec{zipcode}) if ($newrec{zipcode} eq "");
            delete($newrec{roomexpr}) if ($newrec{roomexpr} eq "");
            my $locid=$self->{loc}->getLocationByHash(%newrec);
            print Dumper($rec);
         }
         ($rec,$msg)=$loc->getNext();
      } until(!defined($rec));
   }
   # cleanup
  # $self->{loc}->SetFilter(srcload=>"\"<$loadstart\"",srcsys=>\"AC");
  # $self->{loc}->ForeachFilteredRecord(sub{
  #     $self->{loc}->ValidatedUpdateRecord($_,{cistatusid=>6},{id=>$_->{id}});
  # });
   return({exicode=>0});
}



1;
