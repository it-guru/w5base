package base::qrule::ProjectroomLifetime;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks if a project room is installed/active outside the timerange
durationstart and durationend.

=head3 IMPORTS

NONE

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
use kernel::QRule;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return([".*::projectroom"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my @failmsg;

   my $cistatusid=$rec->{cistatusid};
   if ($cistatusid==4 || $cistatusid==3){
      my $s=$rec->{durationstart};
      if ($s ne ""){
         my $d=CalcDateDuration($s,NowStamp("en"),"GMT");
         if ($d->{totalseconds}<=0){
            push(@failmsg,
                 "projectroom is avalilable or active before start date");
         }
      }
      my $s=$rec->{durationend};
      if ($s ne ""){
         my $d=CalcDateDuration($s,NowStamp("en"),"GMT");
         if ($d->{totalseconds}>=0){
            push(@failmsg,
                 "projectroom is avalilable or active after end date");
         }
      }
   }

   if ($#failmsg!=-1){
      return(3,{qmsg=>[@failmsg],dataissue=>[@failmsg]});
   }

   return(0,undef);
}



1;
