package itil::qrule::SystemCPUcount;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Every system has to have at least one (1) CPU to work. A DataIssue is 
generated if there is either no or 0 CPU-count defined on a logical 
system in CI-State "installed/active" or "available".

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

Please enter a non-zero CPU count in the field "CPU-Count" under 
"logical Systemdata".

[de:]

Bitte tragen Sie eine CPU-Anzahl in das Feld "CPU-Anzahl" im Block 
"logische Systemdaten" ein. Der Wert darf nicht "0" sein.


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
   return(["itil::system"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};



   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);
   if ($rec->{cpucount}<=0){
      my $msg='no cpu count defined';
      return(3,{qmsg=>[$msg],dataissue=>[$msg]});
   }
   return(0,undef);

}




1;
