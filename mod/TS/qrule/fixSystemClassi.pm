package TS::qrule::fixSystemClassi;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This quality rule corrects wrong system classifications

=head3 IMPORTS

- name of cluster

=head3 HINTS

This rule corrects obvious misclassification of logical
systems, among other things, on the basis of the documented operating system.

All "VMWARE ESXi*" and "AIX HMC*" systems are to be regarded as infrastructure.
Infrastructure systems cannot be application servers.

These rules were defined by the central SACM process management.

[de:]

Diese Regel korrigiert offensichtliche Fehlklassifizierung von logischen
Systemen u.a. anhand des eingetragenen Betriebssystems.

Alle "VMWARE ESXi*" und "AIX HMC*" Systeme sind als Infrastruktur anzusehen.
Infrastruktursysteme können keine Applikationsserver sein.

Diese Regeln wurden vom zentralen SACM Prozessmanagement festgelegt.

=cut
#######################################################################
#
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

   return(undef,undef) if (!($rec->{cistatusid}==2 || 
                             $rec->{cistatusid}==3 ||
                             $rec->{cistatusid}==4 ||
                             $rec->{cistatusid}==5));

   my %am_soll;
   my @notifymsg;

   my $isinfrastruct=0;
   if (($rec->{osrelease}=~m/^VMWARE ESXI.*/i) ||
       ($rec->{osrelease}=~m/^AIX HMC.*/i)){
      $isinfrastruct=1;
   }
   if (($isinfrastruct) && !($rec->{isinfrastruct})){
      $forcedupd->{isinfrastruct}=1;
      if ($rec->{isapplserver}){
         $forcedupd->{isapplserver}=0;
      }
   }
   if (!($isinfrastruct) && ($rec->{isinfrastruct})){
      $forcedupd->{isinfrastruct}=0;
   }
   if (($rec->{isinfrastruct}) && ($rec->{isapplserver})){
      $forcedupd->{isapplserver}=0;
   }

   my $partnerlabel=$self->Self;

   my @result=$self->HandleQRuleResults($partnerlabel,
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}




1;
