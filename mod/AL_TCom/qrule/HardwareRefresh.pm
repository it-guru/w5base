package AL_TCom::qrule::HardwareRefresh;
#######################################################################
=pod

=head3 PURPOSE

Checking the age of hardware/asset items. This quality rules controles
the refresh of hardware items. The handling is aligned to a maximum
age of 60 months.

=head3 IMPORTS

NONE

=head3 HINTS

no english hints avalilable

[de:]

Die Refresh QualityRule ist darauf ausgerichtet, dass ein 
Hardware-Asset max. 60 Monate im Einsatz sein darf. Die Berechnung
erfolgt auf Basis des Abschreibungsbeginns.
Somit gilt:

 DeadLine = Abschreibungsbeginn + 60 Monate

 RefreshData = DeadLine oder denyupdvalidto falls denyupdvalidto gültig ist.

Ein DataIssue wird erzeugt, wenn RefreshData - 6 Monate erreicht ist.

Weitere Infos bzw. Ansprechpartner finden Sie unter ...
https://darwin.telekom.de/darwin/auth/faq/article/ById/14007521580001



=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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
use itil::qrule::HardwareRefresh;
@ISA=qw(itil::qrule::HardwareRefresh);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub isHardwareRefreshCheckNeeded
{
   my $self=shift;
   my $rec=shift;


   return(0) if ($rec->{cistatusid}<=2 || $rec->{cistatusid}>=5);

   my $deprstart=$rec->{deprstart};

   return(0) if ($deprstart eq "");

   return(0) if ($deprstart lt "2011-06-30 00:00:00");

   my $o=getModuleObject($self->getParent->Config,"tsacinv::system");

   my $name=$rec->{name};

   $o->SetFilter({assetassetid=>\$name,
                  systemolaclass=>\'10',
                  status=>'"!out of operation"'});
   my @l=$o->getVal("systemid");
 
   return(0) if ($#l==-1);

   return(1);
}



sub finalizeNotifyParam
{
   my $self=shift;
   my $rec=shift;
   my $notifyparam=shift;
   my $mode=shift;

   $notifyparam->{emailto}=[$self->getApplmgrUserIds($rec)];
   $notifyparam->{emailcc}=[12855121480002]; # Günther F. 
}







1;
