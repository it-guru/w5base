package itil::qrule::ApplCheckTSM;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Every Application in CI-Status "installed/active","inactive/stored" 
or "available" must have a Technical Solution Manager.

=head3 IMPORTS

NONE

=head3 HINTS

[de:]

Bitte hinterlegen Sie einen zuständigen Technical Solution Manager (TSM), 
der für die Applikationsumgebung zuständig ist. 

Bei Fragen wenden Sie sich bitte an den DARWIN Support:
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001


[en:]

Please enter the responsible Technical Solution Manager (TSM) 
for the application environment.

If you have any questions please contact the Darwin Support:
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

   return(0,undef) if ($rec->{cistatusid}!=3 && 
                       $rec->{cistatusid}!=4 &&
                       $rec->{cistatusid}!=5);
   if (!defined($rec->{tsm}) || $rec->{tsm} eq ""){
      return(3,{qmsg=>['no Technical Solution Manager defined'],
                dataissue=>['no Technical Solution Manager defined']});
   }
   return(0,undef);

}



1;
