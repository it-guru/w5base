package AL_TCom::qrule::CheckOldAutoDisc;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks if old, unprocessed AutoDiscovery Data exists on an logical
system (in CI-State "installed/active" or "available/in project").

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

This Q-Rule checks the processing based on the date of the scan 
plus 12 weeks. If the data was not processed during this 
time-period, a breach of quality will be displayed for the 
corresponding System, and a DataIssue will be addressed to the 
Databoss of the System.

If there are only GDU SAP applications on the system, no check is done.

Link FAQ: https://darwin.telekom.de/darwin/public/faq/article/ById/14845704850021


[de:]

Diese Qualitätsregel prüft die Bearbeitung anhand des Scan-Datums 
plus 12 Wochen. Wurde in dieser Zeitspanne keine Bearbeitung 
durchgeführt, so wird für das entsprechende System eine Qualitätsverletzung 
angezeigt, welches in einem DataIssue an den betreffenden 
Datenverantwortlichen adressiert wird.

Wenn auf dem logischen System NUR GDU SAP Anwendungen bereitgestellt werden, entfällt die Prüfung.

Link FAQ : https://darwin.telekom.de/darwin/public/faq/article/ById/14845704850021


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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
use itil::qrule::CheckOldAutoDisc;

@ISA=qw(itil::qrule::CheckOldAutoDisc);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}


sub isAutodiscDataNeedToBeProcessed
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);

   my %applid=();
   foreach my $arec (@{$rec->{applications}}){
      $applid{$arec->{applid}}++; 
   }
   my @applid=keys(%applid);

   my %sapgrp=();

   if ($#applid!=-1){
      my $appl=getModuleObject($self->getParent->Config,"itil::appl");

      $appl->SetFilter({id=>\@applid});

      my @l=$appl->getHashList(qw(id mgmtitemgroup));

      foreach my $arec (@l){
         my $g=$arec->{mgmtitemgroup};
         if (ref($g) ne "ARRAY"){
            $g=[$g];
         }
         if (in_array($g,"SAP")){
            $sapgrp{$arec->{id}}++;
         }
      }
      if (keys(%applid)==keys(%sapgrp)){
         return(0);   # Alles ist SAP Rotz (und brauch nicht gut sein)
      }
   }

   return(1);
}




1;
