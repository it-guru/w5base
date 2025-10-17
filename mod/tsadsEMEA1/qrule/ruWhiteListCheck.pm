package tsadsEMEA1::qrule::ruWhiteListCheck;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This quality rule disables collegues from russa and activates them, if
they are on the whitelist from AD.


=head3 HINTS

[de:]

Überprüfung ob Kollegen aus Russland auf der Whitelist für
den "normalen" Zugriff auf Intranet-Resourcen steht.

Zur Überprüfung wird die AD Gruppe mit der ...

ObjectGUID: 4CD6B76F-6796-46E2-AF86-949E03635F61

... in der EMEA1 Domain verwendet.

Die Gruppe hat im AD zum Zeitpunkt der Implementation den ...

CN=GRP-FGR0000405-GRP_0_RUSCloud,
OU=Standard,
OU=Groups,
OU=DE,
DC=emea1,
DC=cds,
DC=t-internal,
DC=com

... distinguishedName.

Für die Pflege dieser Whitelist-Gruppe kann im Outlook Kontakt mit ...

DTIT Access Mgmt RUS <DTITAccessMgmtRUS@mg.telekom.de>

... aufgenommen werden.


=cut

#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
   return(["base::user"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   my $errorlevel=0;
   my $forcedupd={};
   my $wfrequest={};
   my @qmsg;
   my @dataissue;


   if ($rec->{cistatusid}<6){
      my $lastexternalseen=9999;
      if ($rec->{lastexternalseen} ne ""){
         my $d=CalcDateDuration($rec->{lastexternalseen},NowStamp("en"));
         if (defined($d)){
            $lastexternalseen=$d->{totaldays};
         }
      }
      if ($rec->{country} eq "RU" && $rec->{usertyp} eq "user" &&
          ($rec->{cistatusid}==4 || 
           ($rec->{cistatusid}==5 && $lastexternalseen<7))){
         my $adurec;
         my $adgrec;
         my $e2user=getModuleObject($self->getParent->Config,
                                    "tsadsEMEA2::aduser");
         if (!defined($adurec)){
            $e2user->ResetFilter();
            $e2user->SetFilter({email=>\$rec->{email}});
            my ($rec,$msg)=$e2user->getOnlyFirst(qw(account objectGUID 
                                                    distinguishedName));
            $adurec=$rec if (defined($rec));
         }

         if (!defined($adgrec)){
            my $e1grp=getModuleObject($self->getParent->Config,
                                        "tsadsEMEA1::adgroup");
            $e1grp->SetFilter({objectGUID=>
                               '4CD6B76F-6796-46E2-AF86-949E03635F61'});
            my ($rec,$msg)=$e1grp->getOnlyFirst(qw(member objectGUID 
                                                    distinguishedName));
            $adgrec=$rec if (defined($rec));
         }
         if (!defined($adurec)){
            #msg(ERROR,"russian collegue '".$rec->{email}.
            #          "' not found in active directory");
            return(undef,{qmsg=>'AD person record not found'});
         }
         if (!defined($adgrec)){
            msg(ERROR,"whitelist for russian collegues not found");
            return(undef,{qmsg=>'AD group not found'});
         }
         my $whitelist=$adgrec->{member};
         my %updrec;
         my @qmsg;
         if (in_array($whitelist,$adurec->{distinguishedName})){
            if ($rec->{cistatusid} eq "5"){
               $updrec{cistatusid}="4";
               push(@qmsg,
                    "reactivation of russion collegue - found on whitelist");
            }
         }
         else{
            if ($rec->{cistatusid} eq "4"){
               $updrec{cistatusid}="5";
               push(@qmsg,
                    "deactivation of russion collegue - not on whitelist");
            }
         }
         if (keys(%updrec)){
            $checksession->{EssentialsChanged}->{cistatusid}++;
            $checksession->{EssentialsChangedCnt}++;
            $dataobj->UpdateRecord(\%updrec,
                                   {userid=>\$rec->{userid}});
            $dataobj->StoreUpdateDelta("update",
               {cistatusid=>$rec->{cistatusid},
                userid=>$rec->{userid}},
               {cistatusid=>$updrec{cistatusid}},
                $self->Self().
                "\nrussian whitelist handling");
         }
         return(0,{qmsg=>\@qmsg});
      }
      else{
         return(undef,undef);
      }
   }
   return($errorlevel,undef);
}



1;
