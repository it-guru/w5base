package TS::qrule::ApplDRClass;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks whether an "installed/active" or "available/in project"
application with primary operation mode "Production" or
"Disaster Recovery" has a "Disaster Recovery Class" defined,
otherwise an errror message is output.
From a Disaster Recovery Class of "4" and more it will checked
whether the "Application switch-over behaviour" is defined and
the "SLA number Disaster-Recovery test interval" is at least
"1 test every 2 years", otherwise an error message is output.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

A "Disaster Recovery Class" must be defined.

On "Disaster Recovery Class" >= 4 the definitions of
"Application switch-over behaviour" are mandatory,
the fields under "Disaster-Recovery" have to be maintained and
minimum 1 Disaster-Recovery test every 2 years has to be assured.

If you have any questions please contact the Darwin Support: 
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001


[de:]

Eine "Disaster Recovery Class" muss definiert sein.

Bei "Disaster Recovery Class" >= 4 müssen
"Definitionen zur Umschalt/Schwenk/Recovery Strategie"
vorhanden sein, die entsprechenden Datenfelder unter
"Disaster-Recovery" müssen gepflegt werden und
es muss mindstens 1 Disaster-Recovery Test alle 2Jahre zugesichert werden.

Bei Fragen wenden Sie sich bitte an den DARWIN Support:
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001


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
   return(["TS::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if ($rec->{cistatusid}!=4 &&
                       $rec->{cistatusid}!=3);

   if ($rec->{drclass} eq '' &&
       ($rec->{opmode} eq 'prod' ||
        $rec->{opmode} eq 'cbreakdown')) {
      my $msg="no Disaster Recovery Class defined";
      return(3,{qmsg=>[$msg],dataissue=>[$msg]});
   }

   if ($rec->{drclass}>3) {
      if (!$rec->{sodefinition}) {
         my $msg="no Application switch-over behaviour defined";
         return(3,{qmsg=>[$msg],dataissue=>[$msg]});
      }

      if ($rec->{soslanumdrtests}<0.5) {
         my $msg="Minimum Disaster-Recovery test interval: ".
                 $self->T('DRTESTPERYEAR.0.5','itil::appl');
         return(3,{qmsg=>[$msg],dataissue=>[$msg]});
      }
   }

   return(0,undef);
}



1;
