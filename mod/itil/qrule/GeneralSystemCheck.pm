package itil::qrule::GeneralSystemCheck;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

General base check of logical systems.

=head3 IMPORTS

NONE

=head3 HINTS

Some general structural information of logical systems are validated:

* a system name needs to be the correct system name which is 
configured on the host (not a full qualified DNS name!).

* a system which is based on a "host system" (f.e. virtualiziedSystem) 
needs to have a valid (and active) host system entry.


[de:]

Einige grundsätzliche Struktur-Informationen eines logischen Systems
werden überprüft:

* ein Systemname muß der korrekte Systemname sein, der auf dem Host
konfiguriert ist (nicht der vollqualifizierte DNS Name!)

* ein System das auf einem "Host-System" basiert (z.B. virualziedSystem)
braucht einen gültigen (und aktiven) "Host-System" Eintrag.


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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

   if ($rec->{cistatusid}>0 && $rec->{cistatusid}<6){
      if ($rec->{name}=~m/\./){
         my $msg="systemname seems to be a fullqualified dns name - this is not allowed";
         push(@qmsg,$msg);
         push(@dataissue,$msg);
         $errorlevel=3 if ($errorlevel<3);
      }
   }

   if ($rec->{cistatusid}>2 && $rec->{cistatusid}<6){
      my $vmtypes=$dataobj->needVMHost();
      if (in_array($vmtypes,$rec->{systemtype})){
         my $vhostsystemid=$rec->{vhostsystemid};
         if ($vhostsystemid eq "" || $vhostsystemid==0){
            my $msg="no Host-System documented";
            push(@qmsg,$msg);
            push(@dataissue,$msg);
            $errorlevel=3 if ($errorlevel<3);
         }
         else{
            if ($rec->{cistatusid}==4){
               my $sys=$dataobj->Clone();
               $sys->SetFilter({id=>\$vhostsystemid});
               my ($prec,$msg)=$sys->getOnlyFirst(qw(id cistatusid));
               if (!defined($prec) || $prec->{cistatusid}!=4){
                  my $msg="Host-System entry not active or invalid";
                  push(@qmsg,$msg);
                  push(@dataissue,$msg);
                  $errorlevel=3 if ($errorlevel<3);
               }
            }
         }
      }
   }




   my @result=$self->HandleQRuleResults($self->Self,
                  $dataobj,$rec,$checksession,
                  \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}



1;
