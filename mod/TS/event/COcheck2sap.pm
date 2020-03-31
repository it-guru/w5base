package TS::event::COcheck2sap;
#  W5Base Framework
#  Copyright (C) 2020  Hartmut Vogler (it@guru.de)
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
use finance::costcenter;
@ISA=qw(kernel::Event);

our %src;
our %dst;


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub COcheck2sap
{
   my $self=shift;
   my $exitcode=0;

   $self->{costcenter}=getModuleObject($self->Config,"finance::costcenter");
   $self->{appl}=getModuleObject($self->Config,"itil::appl");
   $self->{system}=getModuleObject($self->Config,"itil::system");
   $self->{asset}=getModuleObject($self->Config,"itil::asset");

   $self->{sappsp}=getModuleObject($self->Config,"tssapp01::psp");
   $self->{sapco}=getModuleObject($self->Config,"tssapp01::costcenter");

   $self->{sappsp}->SetFilter({});
   $self->{sappsp}->SetCurrentView("name");
   $self->{psp}=$self->{sappsp}->getHashIndexed(qw(name));
   msg(INFO,"SAP PSP Load done");
   $self->{sapco}->SetFilter({});
   $self->{sapco}->SetCurrentView("name");
   $self->{co}=$self->{sapco}->getHashIndexed(qw(name));
   msg(INFO,"SAP CO Load done");
   $self->{bad}={};



   $self->chkobj($self->{appl},"conumber","name");
   $self->chkobj($self->{system},"conumber","name");
   $self->chkobj($self->{asset},"conumber","name");
   $self->chkobj($self->{costcenter},"name","name");


   printf("\n\nBadList:\n");

   foreach my $co (sort(keys(%{$self->{bad}}))){
      printf("%-25s %s\n",$co,join(",",@{$self->{bad}->{$co}}));
   }

   return({exitcode=>$exitcode});
}


sub chkobj
{
   my $self=shift;
   my $o=shift;
   my $cofieldname=shift;
   my $recordname=shift;

   my @view=($recordname,"cistatusid",$cofieldname);
   $o->SetFilter({cistatusid=>"<6"});
   $o->SetCurrentView(@view);


   my ($rec,$msg)=$o->getFirst();
   if (defined($rec)){
      do{
         my $name=$rec->{$recordname};
         my $co=$rec->{$cofieldname};
         if ($co ne "" && 
             !exists($self->{co}->{name}->{$co}) &&
             !exists($self->{psp}->{name}->{$co})){
            printf STDERR ("%-25s %s\n",$name,$co);
            if ($name ne $co){
               push(@{$self->{bad}->{$co}},$name);
            }
            else{
               if (!exists($self->{bad}->{$co})){
                  $self->{bad}->{$co}=[];
               }
            }
         }
         ($rec,$msg)=$o->getNext();
      } until(!defined($rec));
   }



}


1;
