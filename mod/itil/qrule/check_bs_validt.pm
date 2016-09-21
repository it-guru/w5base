package itil::qrule::check_bs_validt;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks if a Business-Service in "installed/active" state is between
the validfrom and validto range.

=head3 IMPORTS

NONE

=cut
#######################################################################
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
   return(["itil::businessservice"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my @msg;

   return(0,undef) if ($rec->{cistatusid}!=4);

   my $validfrom=$rec->{validfrom};
   my $validto=$rec->{validto};

   my $valid=1;
   if ($validfrom ne ""){
      my $duration=CalcDateDuration($validfrom,NowStamp("en"));
      if ($duration->{totalminutes}<0){
         $valid=0;
      }
      #print STDERR "from:".Dumper($duration); 
   }
   if ($validto ne ""){
      my $duration=CalcDateDuration(NowStamp("en"),$validto);
      if ($duration->{totalminutes}<0){
         $valid=0;
      }
      #print STDERR "to:".Dumper($duration); 
   }
   if (!$valid){
      push(@msg,"businessservice outside duration start/end ".
                "in state installed/active");
   }





   if ($#msg!=-1){
      return(3,{qmsg=>\@msg, dataissue=>\@msg});
   }
   return(0,undef);

}



1;
