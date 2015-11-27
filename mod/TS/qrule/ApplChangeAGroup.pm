package TS::qrule::ApplChangeAGroup;
#######################################################################
=pod

=head3 PURPOSE

Checks if there is on an "installed/active" or "available" application
a change approvergroup for technical side is defined.
If there is no valid approvergroup defined, an error will be proceeded.

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
   return(["TS::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $exitcode=0;
   my $desc={qmsg=>[],solvtip=>[]};

   if ($rec->{cdate} ne ""){
      my $now=NowStamp("en");
      my $d=CalcDateDuration($rec->{cdate},$now,"GMT");
      my $max=7*2;  # check only if application record is older than 2 weeks
      if ($d->{days}<$max){
         return($exitcode,$desc);
      }
   }
   return($exitcode,$desc) if (($rec->{cistatusid}!=4 && 
                                $rec->{cistatusid}!=3) ||
                               $rec->{opmode} eq "license" ||
                               $rec->{businessteam} eq "Extern");
   if (trim($rec->{scapprgroup}) eq ""){
      $exitcode=3 if ($exitcode<3);
      push(@{$desc->{qmsg}},
           'there is no technical change approvergroup defined');
      push(@{$desc->{dataissue}},
           'there is no technical change approvergroup defined');
   }

   return($exitcode,$desc);
}




1;
