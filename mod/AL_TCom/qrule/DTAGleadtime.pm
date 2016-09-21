package AL_TCom::qrule::DTAGleadtime;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

If there is an customercontract affected from the workflow to check,
there is P800 cause need to qualify. The cause "undefined Service" isn't
allowed.
P800 rules are only needed, if one of the affected applications of
the workflow is based on a P800 customer contract and these contract
is for customer DTAG.*

=head3 IMPORTS

NONE

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2007  Hartmut Vogler (it@guru.de)
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
   return(["AL_TCom::workflow::businesreq"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $exitcode=0;
   my $desc={qmsg=>[],solvtip=>[]};
   my @msg;

   if ($rec->{stateid}<17){  # check only closed records
      my $t=$rec->{extdescdesstart};
      $t=$rec->{extdescdesend} if ($t eq "");
      if ($t ne ""){
         my $d=CalcDateDuration($rec->{eventstart},$t);
         if ($d->{totaldays}<5){
            push(@msg,'precarriage time is not sufficient');
            $exitcode=2;
         }
      }
      
   }
   if ($#msg!=-1){
  #    push(@msg,"please contact Mr. Grewing Burkhard, ".
  #              "if you got questions to this messages");
      push(@{$desc->{qmsg}},@msg);
      push(@{$desc->{dataissue}},@msg);
   }

   return($exitcode,$desc);
}




1;
