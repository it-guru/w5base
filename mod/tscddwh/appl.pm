package tscddwh::appl;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
use AL_TCom::appl;
@ISA=qw(AL_TCom::appl);

# This Object is only for Replication of "itemsummary" to W5Warehouse

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->getField("mandator")->{searchable}=0;
   $self->getField("cistatus")->{searchable}=0;
   $self->getField("mdate")->{searchable}=0;
   return($self);
}


sub SetFilter
{
   my $self=shift;
   my @flt=@_;

   if ($W5V2::OperationContext eq "W5Replicate"){
      if ($#flt!=0 || ref($flt[0]) ne "HASH"){
         $self->LastMsg("ERROR","invalid Filter request on $self");
         return(undef);
      }

      my %f1=(%{$flt[0]});
      $f1{cistatusid}=['3','4','5'];

      my %f2=(%{$flt[0]});
      $f2{cistatusid}=['6'];
      $f2{mdate}=">now-28d";

      @flt=([\%f1,\%f2]);
   }
   return($self->SUPER::SetFilter(@flt));
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   if ($self->isDataInputFromUserFrontend()){
      return(undef);
   }

   return($self->SUPER::isViewValid($rec));
}





1;
