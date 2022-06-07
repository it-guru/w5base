#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Validates the existence of a SPOC IT Stability in virtual org units.

=head3 IMPORTS

NONE

=head3 HINTS

Check assignment of "SPOC IT Stability" in a virtual org unit.

[de:]

Prüft die Vergabe von "SPOC IT Stability" in einer virtuellen Org-Einheit.

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
package TS::qrule::vouCheckSPOCITStab;
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
   return(["TS::vou"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;


   return(undef,undef) if ($rec->{cistatusid}<3 || $rec->{cistatusid}>5);

   my $ITStabFound=0;

   foreach my $crec (@{$rec->{contacts}}){
      my $roles=$crec->{roles};
      $roles=[$roles] if (ref($roles) ne "ARRAY");
      if (in_array($roles,"ITstabillity")){
         $ITStabFound++;
      }
   }
   if (!$ITStabFound){
      $errorlevel=3 if ($errorlevel<3);
      my $msg="missing role assignment SPOC IT Stability in contacts";
      push(@qmsg,$msg);
      push(@dataissue,$msg);
   }


   my @result=$self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}


1;
