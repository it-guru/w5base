package itil::qrule::ClusterSystemCount;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

The quality rule checks if there are at least 1 cluster members
(logical systems) in status other than "disposed of waste", assigned to
a cluster in status "installed/active" or "available in project".
A dataissue is generated if the cluster creation date is at least 8 weeks
in the past.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

A cluster must have at least one system related in status other than
"disposed of waste".

[de:]

Einem Cluster muß mindestens ein System zugeordnet sein, das nicht
im Status "veraltet/gelöscht" ist.


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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
   return(["itil::itclust"]);
}

sub qcheckRecord
{  
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);

   my $duration=CalcDateDuration($rec->{cdate},NowStamp('en'));
   return(0,undef) if ($duration->{days}<56);

   if ($#{$rec->{systems}}<0) {
      my $msg='Insufficient systems related';
      return(3,{qmsg=>[$msg],dataissue=>[$msg]});
   }

   return(0,undef);
}































1;
