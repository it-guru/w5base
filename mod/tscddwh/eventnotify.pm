package tscddwh::eventnotify;
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
use base::workflow;
@ISA=qw(base::workflow);

# This Object is only for Replication of "openeventnotify" to W5Warehouse
# which will be used by aMore and CD-DWH (as of date 09/2014)

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->getField("state")->{searchable}=0;
   $self->getField("stateid")->{searchable}=0;
   $self->getField("mdate")->{searchable}=0;
   $self->getField("class")->{searchable}=0;
   return($self);
}


sub SetFilter
{
   my $self=shift;
   my @flt=@_;

   if ($#flt!=0 || ref($flt[0]) ne "HASH"){
      $self->LastMsg("ERROR","invalid Filter request on $self");
      return(undef);
   }

   my %f1=(%{$flt[0]});
   $f1{stateid}="21";
   $f1{mdate}=">now-365d";
   $f1{isdeleted}=\"0";
   $f1{class}=\"AL_TCom::workflow::eventnotify";

   my %f2=(%{$flt[0]});
   $f2{stateid}="!21";
   $f2{isdeleted}=\"0";
   $f2{class}=\"AL_TCom::workflow::eventnotify";

   my %f3=(%{$flt[0]});
   $f3{isdeleted}="1";
   $f3{mdate}=">now-365d";
   $f3{class}=\"AL_TCom::workflow::eventnotify";

   @flt=([\%f1,\%f2,\%f3]);
   return($self->SUPER::SetFilter(@flt));
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   if ($self->isDataInputFromUserFrontend()){
      if ($self->IsMemberOf("admin")){
         return("ALL");
      }
      return(undef);
   }

   return($self->SUPER::isViewValid($rec));
}


sub SetCurrentView  # hack to prevent needed wffields. prefix
{
   my $self=shift;
   my @f=@_;

   my @fl;
   foreach my $f (@f){
      if (!$self->getField($f)){ 
         push(@fl,"wffields.".$f);
      }
      else{
         push(@fl,$f);
      }
   }
   return($self->SUPER::SetCurrentView(@fl));
}





1;
