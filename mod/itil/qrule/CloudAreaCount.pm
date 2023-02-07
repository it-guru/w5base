package itil::qrule::CloudAreaCount;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

The quality rule checks if there are CloudAreas in a Cloud.
If the Cloud is in State "available in project" or "installed/active", the
Cloud needs at least one CloudArea. In other cases, no CloudAreas are
allowed and a DataIssue will be created.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

If the Cloud is in State "available in project" or "installed/active", the
Cloud needs at least one CloudArea. In other cases, no CloudAreas are
allowed and a DataIssue will be created.

[de:]

Eine Cloud im CI-Status "verfügbar/in Projektierung" oder "installiert/aktiv"
muss min. eine CloudArea aufweisen. In allen anderen CI-Status, sind keine
CloudArea Zuordnungen zugelassen. In diesen Fällen wird dann ein DataIssue
erstellt.


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2020  Hartmut Vogler (it@guru.de)
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
   return(["itil::itcloud"]);
}

sub qcheckRecord
{  
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(undef,undef) if ($rec->{cistatusid}>5);

   #my $duration=CalcDateDuration($rec->{cdate},NowStamp('en'));
   #return(0,undef) if ($duration->{days}<28);

   my $n=$#{$rec->{cloudareas}}+1;

   if ($rec->{cistatusid} eq "3" || 
       $rec->{cistatusid} eq "4" ||
       $rec->{cistatusid} eq "5"){
      if ($n==0){
         my $msg='missing CloudArea relations';
         return(3,{qmsg=>[$msg],dataissue=>[$msg]});
      }
   }
   else{
      if ($n!=0){
         my $msg='CloudArea relations are not allowed in current CI-Status';
         return(3,{qmsg=>[$msg],dataissue=>[$msg]});
      }
   }
   return(0,undef);
}































1;
