package base::qrule::CIStatusTime;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Validates CI-Status of Config-Itmes. A record will be viewed as
invalid, if an item in status ...
 - reserved             (cistatusid=1) longer than 8 weeks
 - on order             (cistatusid=2) longer than 8 weeks
 - available/in project (cistatusid=3) longer than 12 weeks
 - inactiv/stored       (cistatusid=5) longer than 12 weeks
... is unmodified (the modification date will be the check reference).

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

This QualityRule checks if Config-Items in the state 'reserved', 'on order', 
'available/in project' or 'inactive/stored' have gone unmodified for a 
predefined period of time. 

Make sure the CI-State is correct and up-to-date. If not, change the CI-State 
to the correct one. If the CI-State is correct despite the elapsed 
time-period, consider possibilities of updating the CI, e.g. by adding 
a comment regarding the CI-State on the CI itself. 

[de:]

Es wird geprüft, ob  Config-Items im CI-Status 'reserviert', 
'bestellt/angefordert', 'verfügbar/in Projektierung' und 
'zeitweise inaktiv' über einen längeren Zeitraum nicht mehr verändert wurden.

Prüfen Sie, ob der eingetragene CI-Status richtig und aktuell ist. 
Falls nicht, ändern Sie den CI-Status auf den korrekten Wert. 
Falls der eingetragene CI-Status immer noch zutrifft, 
aktualisieren Sie das CI, z.B. indem Sie eine Bemerkung 
über den CI-Status hinzufügen.

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
   return([".*"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if (!exists($rec->{cistatusid}) || 
                       !exists($rec->{mdate}) ||
                       $rec->{mdate} eq "");

   my $now=NowStamp("en");
   my $d=CalcDateDuration($rec->{mdate},$now,"GMT");
   my @failmsg;
   if ($d->{days}>56 && $rec->{cistatusid}==1){
      push(@failmsg,"config item in ci-state 'reserved' and no changes have been done for 8 weeks");
   }
   if ($d->{days}>56 && $rec->{cistatusid}==2){
      push(@failmsg,"config item in ci-state 'on order' and no changes have been done for 8 weeks");
   }
   if ($d->{days}>84 && $rec->{cistatusid}==3){
      push(@failmsg,"config item in ci-state 'available/in project' and no changes have been done for 12 weeks");
   }
   if ($d->{days}>84 && $rec->{cistatusid}==5){
      push(@failmsg,"config item in ci-state 'inactiv/stored' and no changes have been done for 12 weeks");
   }

   if ($#failmsg!=-1){
      #printf STDERR ("check fail:%s\n",Dumper(\@failmsg));
      return(3,{qmsg=>[@failmsg],
                dataissue=>[@failmsg]});
   }
   
   return(0,undef);
}



1;
