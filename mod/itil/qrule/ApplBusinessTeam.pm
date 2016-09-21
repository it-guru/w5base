package itil::qrule::ApplBusinessTeam;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Every Application in CI-Status "installed/active" or "available", must
have a defined business team.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

Please enter an active Business Team. A non-active Business Team can be 
identified by a number in square brackets in the name of the group. 
Usually a Business Team is the organisational team 
of the technical solution manager (TSM).

In case of further questions, please contact the Darwin Support:
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001

[de:]

Bitte hinterlegen Sie ein aktives/gültiges Betriebsteam. 
Ein ungültiges Betriebsteam können Sie an einer Nummer in eckigen Klammern 
im Namen erkennen. In der Regel ist das Betriebsteam das Team, 
in dem sich der TSM organisatorisch befindet.

Bei Fragen wenden Sie sich bitte an den Darwin Support:
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001


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
   return(["itil::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);
   if (!defined($rec->{businessteam}) || $rec->{businessteam} eq ""){
      return(3,{qmsg=>['no businessteam defined'],
                dataissue=>['no businessteam defined']});
   }
   return(0,undef);

}



1;
