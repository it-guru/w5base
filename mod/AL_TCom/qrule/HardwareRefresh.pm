package AL_TCom::qrule::HardwareRefresh;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checking the age of hardware/asset items. This quality rules controles
the refresh of hardware items. The handling is aligned to a maximum
age of 60 months.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

This QualityRule is effective if the start of depreciation is 
after 2011-06-30.

The refresh quality rule is focused on the fact that the 
hardware asset is to be in use 60 months at the maximum. 
The counting is based on the start date of depreciation/amortization. 
Therefore it applies  for/to:

  DeadLine = start of depreciation + 60 months

  RefreshData = DeadLine or denyupdvalidto if denyupdvalidto is valid.

A DataIssue is generated when RefreshData - 6 months has been reached.

If the system is provided by a serverfarm, no notification to the
applicationmanager is done.

Further information or contacts can be found at ...
https://darwin.telekom.de/darwin/auth/faq/article/ById/14007521580001

[de:]

Diese QualityRule greift, wenn der Abschreibungsbeginn 
nach dem 30.06.2011 liegt.

Die Refresh QualityRule ist darauf ausgerichtet, dass ein 
Hardware-Asset max. 60 Monate im Einsatz sein darf. Die Berechnung
erfolgt auf Basis des Abschreibungsbeginns.
Somit gilt:

 DeadLine = Abschreibungsbeginn + 60 Monate

 RefreshData = DeadLine oder denyupdvalidto falls denyupdvalidto gültig ist.

Ein DataIssue wird erzeugt, wenn RefreshData - 6 Monate erreicht ist.

Handelt es sich um ein System, das über eine Serverfarm bereitgestellt
wird, erfolgt keine Benachrichtigung an den ApplicationManager.

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

   # check against start date
   return(0) if ($deprstart lt "2011-06-30 00:00:00");
   #######################################################################

   # Serverfarm Assets are special handled
   return(0) if ($rec->{itfarm} ne "");


   # check against "CLASSIC" system type
   my $o=getModuleObject($self->getParent->Config,"tsacinv::system");

   my $name=$rec->{name};

   $o->SetFilter({assetassetid=>\$name,
                  systemolaclass=>\'10',
                  status=>'"!out of operation"'});
   my @l=$o->getVal("systemid");
 
   return(0) if ($#l==-1);
   #######################################################################

   # check against costcenter saphier of logical systems
   my $o=getModuleObject($self->getParent->Config,"itil::system");
   my $aid=$rec->{id};
   $o->SetFilter({assetid=>\$aid,cistatusid=>[3,4]});
   my @colist=$o->getVal(qw(conumber));
   @colist=grep(!/^\s*$/,@colist);
   my @saphier;
   if ($#colist!=-1){
      my $o=getModuleObject($self->getParent->Config,"TS::costcenter");
      $o->SetFilter({name=>\@colist});
      foreach my $corec ($o->getHashList(qw(sappspentries sapcoentries))){
         foreach my $r (@{$corec->{sappspentries}},
                        @{$corec->{sapcoentries}}){
            if (!in_array(\@saphier,$r->{saphier})){
               push(@saphier,$r->{saphier});
            }
         }
      }
   }
   #######################################################################


   return(1);
}



sub finalizeNotifyParam
{
   my $self=shift;
   my $rec=shift;
   my $notifyparam=shift;
   my $mode=shift;

   if ($rec->{itfarm} eq ""){
      $notifyparam->{emailto}=[$self->getApplmgrUserIds($rec)];
   }
}







1;
