package timetool::timetool::resplan;
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
use timetool::timetool::oncallplan;

@ISA=qw(timetool::timetool::oncallplan);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub getCalendars
{
   my $self=shift;
   my @l;
   my $timeplan=$self->getParent->getPersistentModuleObject(
                                                    "timetool::timeplan");
   my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
   $timeplan->SetFilter({mandatorid=>\@mandators,rawtmode=>$self->Self.";*",
                         cistatusid=>[3,4]});
   my @tl=$timeplan->getHashList(qw(name id));
   foreach my $tp (@tl){
      push(@l,$self->Self().";".$tp->{id},10,$tp->{name});
   }
   return(@l);
}

sub getCalendarModes
{
   my $self=shift;
   my $s=$self->Self;

   return($s.";room"=>'Raumbelegungsplan',
          $s.";telko"=>"Telefonkonferenz");
}

sub LoadTimeplanRec
{
   my $self=shift;
   my $id=shift;

   if (defined($id) && $id ne ""){
      my $tp=$self->getParent->getPersistentModuleObject("timetool::timeplan");
      $tp->SetFilter({id=>\$id});
      my ($tprec,$msg)=$tp->getOnlyFirst(qw(ALL));
      if (defined($tprec)){
         return($tprec);
      }
   }
   return(undef);
}



sub AddLineLabels
{
   my $self=shift;
   my $vbar=shift;
   my $id=shift;
   my $myuserid=$self->getParent->getCurrentUserId();

   my %user;
   my $con=$self->Context();
   $con->{uid}=[];
   $con->{timeplan}=$self->LoadTimeplanRec($id);

   if (defined($con->{timeplan})){
      my $c=0;
      foreach my $entry (split(/\s*;\s*/,$con->{timeplan}->{data})){
         $vbar->SetLabel($entry,$entry,{order=>$c});
         $c++;
      }
   }
}




1;
