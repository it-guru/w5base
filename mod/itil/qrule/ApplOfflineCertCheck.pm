#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks the expiration of certificates on applications in cistate 
"installed/active" or "available/in project". 
If the expiration date is in lesser than 8 weeks, an one-time notification 
will be sent to write authorized contacts of the application.

A dataissue will be generated if the expiration date is in lesser than 2 week.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

This quality rule checks when a certificate expires. 
Information will be sent promptly based on the selected parameters.
A DataIssue is generated 14 days before the certificate expires.

To avoid restrictions they have to be renewed as soon as possible.

[de:]

Diese Qualitätsregel prüft, wann ein Zertifikat ausläuft. 
Entsprechend der gewählten Parameter wird zeitnah eine Information verschickt.
14 Tage vor Ablauf des Zertifikates wird ein DataIssue erzeugt.

Um Beeinträchtigungen zu vermeiden, müssen die aufgeführten
Zertifikate kurzfristig aktualisiert/erneuert werden.


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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
package itil::qrule::ApplOfflineCertCheck;
use strict;
use vars qw(@ISA);
use kernel;
use kernel::QRule;
use itil::lib::Listedit;

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

   return(0,undef) if ($rec->{'cistatusid'}<3);

   my $errorlevel=0;
   my @qmsg;
   my @dataissue;

   my $walletobj=getModuleObject($self->getParent->Config,'itil::applwallet');
   $walletobj->SetFilter({applid=>$rec->{id}});
   my @certs=$walletobj->getHashList(qw(ALL));


   my $dropAllCerts=0;

   if ($rec->{cistatusid}>5){
      my $d=CalcDateDuration(NowStamp("en"),$rec->{mdate});
      if ($d->{days}<-14){
         $dropAllCerts=1;
      }
   }

   foreach my $cert (@certs) {
      my $isdel=0;
      if ($cert->{enddate} ne ""){
         my $d=CalcDateDuration(NowStamp("en"),$cert->{enddate});
         if ($d->{days}<-7){
            my $op=$walletobj->Clone();
            $op->ValidatedDeleteRecord($cert);
            $isdel=1;
            my $desc={};
            push(@qmsg,'Certificate deleted due long expiration: '.
                          $cert->{name});
         }
      }
      if (!$isdel && $dropAllCerts){
         my $op=$walletobj->Clone();
         $op->ValidatedDeleteRecord($cert);
         $isdel=1;
         my $desc={};
         push(@qmsg,'Certificate deleted due application deleted: '.
                       $cert->{name});
      }

      if (!$isdel){
         my $ok=$self->itil::lib::Listedit::handleCertExpiration(
                                               $walletobj,$cert,$dataobj,$rec,
                                               \@qmsg,\@dataissue,\$errorlevel,
                                               {
               expnotifyfld=>'sslexpnotify1',
               expnotifyleaddays=>$cert->{expnotifyleaddays},
               expdatefld=>'enddate'
         });
         if (!$ok) {
            msg(ERROR,sprintf("QualityCheck of '%s' (%d) failed",
                              $walletobj->Self(),$cert->{id}));
         }
     }
   }


   if (@qmsg) {
      return($errorlevel,{qmsg=>\@qmsg,dataissue=>\@dataissue});
   }

   return(0,undef);
}



1;
