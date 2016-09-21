package base::qrule::WorkflowUntouched3;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks if a workflow is longer the 3 months unmodified.

=head3 IMPORTS

NONE

=cut
#######################################################################
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
   return([".*::workflow::.*"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my @failmsg;

   return(0,undef) if (!exists($rec->{mdate}));

   if ($rec->{mdate} eq ""){
      push(@failmsg,"invalid modification date in in workflow - ".
                    "contact the w5base admin");
   }

   my $now=NowStamp("en");
   my $d=CalcDateDuration($rec->{mdate},$now,"GMT");
   my @failmsg;
   if ($d->{days}>90 && $rec->{state}<20){
      push(@failmsg,"workflow is longer then 3 months untouched");
   }
   if ($#failmsg!=-1){
      return(3,{qmsg=>[@failmsg]});
   }

   return(0,undef);
}



1;
