package tsotc::qrule::CheckOTCProjects;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Validate if there are all projects in OTC Cloud are linkt to valid
applications and all active projects have CloudArea entries.

=head3 IMPORTS

NONE

=head3 HINTS
No english hint

[de:]

Alle Projekte der OTC müssen gültige Anwendungszuordnungen
besitzen. Fehlen diese, so müssen die betreffenden Projekte
in der OTC gelöscht bzw. die korrekte Anwendungszuordnung
ermittelt und nachgetragen werden.

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
   return(["itil::itcloud"]);
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


   my $now=NowStamp("en");
   return(undef,undef) if ($rec->{name} ne "OTC");

   my $otcp=getModuleObject($dataobj->Config,"tsotc::project");
   my $appl=getModuleObject($dataobj->Config,"itil::appl");

   return(undef,undef) if ($otcp->isSuspended());
   if (!$otcp->Ping()){
      msg(ERROR,"no ping on tsotc::project in QC"); # maybe mail to OTC AppMgr??
      return(undef,undef);
   }





   $otcp->SetFilter({lastmondate=>">now-24h"});
   my @plst=$otcp->getHashList(qw(name fullname applid id));

   my %usedApplIds=();

   foreach my $p (@plst){
      if ($p->{applid} ne ""){
         $usedApplIds{$p->{applid}}++;
      }
   }
   my $arec;
   if (keys(%usedApplIds)){
      $appl->SetFilter({id=>[keys(%usedApplIds)],cistatusid=>"<6"});
      $appl->SetCurrentView(qw(name cistatusid id));
      $arec=$appl->getHashIndexed("id");
   }
   foreach my $p (@plst){
      if ($p->{applid} eq ""){
         my $msg="missing application in project: ".$p->{fullname}.
                    " (".$p->{id}.")";
         push(@qmsg,$msg);
         push(@dataissue,$msg);
         $errorlevel=3 if ($errorlevel<3);
      }
      else{
         if (!exists($arec->{id}->{$p->{applid}})){
            my $msg="invalid application in project: ".$p->{fullname}.
                    " (".$p->{id}.")";
            push(@qmsg,$msg);
            push(@dataissue,$msg);
            $errorlevel=3 if ($errorlevel<3);
         }
      }
   }
   my @result=$self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}




1;
