package AL_TCom::event::philipscleanup;
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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


   $self->RegisterEvent("philipscleanup","philipscleanup");
   return(1);
}

sub philipscleanup
{
   my $self=shift;
   my $loc=getModuleObject($self->Config,"base::location");
   my $locop=$loc->Clone();
   $loc->SetFilter({name=>"*.philips",cistatusid=>\'4'});
   $loc->SetCurrentView("ALL");

   my ($rec,$msg)=$loc->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         msg(INFO,"prozess location $rec->{name}");
         my $newrec={};
         my %oldrec=%{$rec};
         if ($rec->{location}=~m/[A-Z]{2}/){
            my $n=$rec->{location};
            $n=~s/([A-Z])([A-Z]+)/\1\L\2\E/g;
            msg(INFO,"01 translate %s to %s",$rec->{location},$n);
            $newrec->{location}=$n;
            $rec->{location}=$n;
         }
         if ($rec->{address1}=~m/[A-Za-z][-_][0-9]/){
            my $n=$rec->{address1};
            $n=~s/([A-Za-z])[-_]([0-9])/\1 \2/g;
            msg(INFO,"02 translate %s to %s",$rec->{address1},$n);
            $newrec->{address1}=$n;
            $rec->{address1}=$n;
         }
         if ($rec->{address1}=~m/[A-Z]{2}/){
            my $n=$rec->{address1};
            $n=~s/([A-Z])([A-Z]+)/\1\L\2\E/g;
            msg(INFO,"03 translate %s to %s",$rec->{address1},$n);
            $newrec->{address1}=$n;
            $rec->{address1}=$n;
         }
         if ($rec->{address1}=~m/str[ _]/){
            my $n=$rec->{address1};
            $n=~s/(str)[ _]/\1. /g;
            msg(INFO,"04 translate %s to %s",$rec->{address1},$n);
            $newrec->{address1}=$n;
            $rec->{address1}=$n;
         }

       #  if ($rec->{location}=~m/^[A-Z]+-[A-Z]+$/){
       #     my $n=$rec->{location};
       #     $n=~s/^([A-Z])([A-Z]+)-([A-Z])([A-Z]+)$/\1\L\2\E-\3\L\E/;
       #     msg(INFO,"02 translate %s to %s",$rec->{location},$n);
       #     $newrec->{location}=$n;
       #  }

         if (keys(%$newrec)){
            $locop->ValidatedUpdateRecord(\%oldrec,$newrec,{id=>\$rec->{id}});
         }
         ($rec,$msg)=$loc->getNext();
      } until(!defined($rec));
   }


   return({exitcode=>0,msg=>'ok'});
}

;
