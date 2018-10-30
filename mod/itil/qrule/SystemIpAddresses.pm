package itil::qrule::SystemIpAddresses;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Every System in the CI-State "installed/active" or "available/in project" 
needs to have documented IP-Addresses.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

Please document all direct Ip-Adresses on the system. 
The loopback adress (127.0.0.1) doesn't have to be documented.

[de:]

Dokumentieren Sie alle direkt auf dem System konfigurierten
IP-Adressen. Die Loopback Adresse (127.0.0.1) braucht nicht
dokumentiert werden.


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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

sub isIpAddressCheckNeeded
{
   my $self=shift;
   my $rec=shift;

   return(0) if ($rec->{cistatusid}!=4 && 
                 $rec->{cistatusid}!=5 &&
                 $rec->{cistatusid}!=3);

   return(0) if (lc($rec->{srcsys}) ne "w5base");

   return(1);
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

   if (!$self->isIpAddressCheckNeeded($rec)){
      return(undef,undef);
   }
   if (ref($rec->{ipaddresses}) ne "ARRAY" || $#{$rec->{ipaddresses}}==-1){
      my $msg="missing ip addresses";
      $errorlevel=3;
      push(@dataissue,$msg);
      push(@qmsg,$msg);
   }

   my @result=$self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}



1;
