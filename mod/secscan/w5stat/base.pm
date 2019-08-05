package secscan::w5stat::base;
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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
use kernel::Universal;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}



sub processRecord
{
   my $self=shift;
   my $module=shift;
   my $month=shift;
   my $rec=shift;
   my %param=@_;



   if ($module eq "base::workflow::notfinished"){
      my $mdate=$rec->{mdate};
      my $age=0;
      if ($mdate ne ""){
         my $d=CalcDateDuration($mdate,NowStamp("en"));
         $age=$d->{totalminutes};
      }
      if ($rec->{class} eq "secscan::workflow::FindingHndl"){
         if ($rec->{stateid}<20 && defined($rec->{responsiblegrp})){

            foreach my $resp (@{$rec->{responsiblegrp}}){
               $self->getParent->storeStatVar("Group",$resp,{},
                                              "SecScan.Finding.open",1);
               $self->getParent->storeStatVar("Group",$resp,
                                 {maxlevel=>1,method=>'concat'},
                                 "SecScan.Finding.IdList.open",$rec->{id});
            }
         }
         $self->getParent->storeStatVar("Group",["admin"],{},
                                        "SecScan.Total.Finding.Active.Count",1);
      }
   }
}


1;
