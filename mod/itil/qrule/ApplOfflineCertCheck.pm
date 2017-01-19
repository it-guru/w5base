#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks the expiration of certificates on applications in cistate 
"installed/active" or "available/in project". 
If the expiration date is in lesser than 8 weeks, an one-time notification 
will be sent to write authorized contacts of the application.

A dataissue will be generated if the expiration date is in lesser than 1 week.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

Listet certificates expires in a few days or has already expired.
To avoid incidents they have to renew in a short-term.

[de:]

Aufgelistete Zertifikate laufen in wenigen Tagen ab,
oder sind bereits abgelaufen.
Um Beeinträchtigungen zu vermeiden,
müssen diese kurzfristig aktualisiert werden.


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

   return(0,undef) if ($rec->{'cistatusid'}!=4 && 
                       $rec->{'cistatusid'}!=3);

   my $errorlevel=0;
   my @qmsg;
   my @dataissue;

   my $walletobj=getModuleObject($self->getParent->Config,'itil::applwallet');
   $walletobj->SetFilter({applid=>$rec->{id}});

   foreach my $cert ($walletobj->getHashList(qw(ALL))) {
      my $ok=$self->itil::lib::Listedit::handleSSLExpiration(
                                            $walletobj,$cert,
                                            $dataobj,$rec,
                                            \@qmsg,\@dataissue,\$errorlevel,
                                            {notifyfld=>'sslexpnotify1'});
      if (!$ok) {
         msg(ERROR,sprintf("QualityCheck of '%s' (%d) failed",
                           $walletobj->Self(),$cert->{id}));
      }
   }

   if ($#qmsg!=-1) {
      return($errorlevel,{qmsg=>\@qmsg,dataissue=>\@dataissue});
   }

   return(0,undef);
}



1;
