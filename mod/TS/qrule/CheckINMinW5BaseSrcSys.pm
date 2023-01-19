package TS::qrule::CheckINMinW5BaseSrcSys;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks incident assignementgroup in ci's with srcsys=w5base

=head3 IMPORTS

=head3 HINTS

A config-item which was created in Darwin and can or should be transferred to AssetManager, has to have a valid Incident Assignmentgroup.

Beware! If the intention is to "refer" to a config. item in AssetManager (i.e. the mentioned CI is under the main responsibility of the IT-Division, or is generally maintained in AssetManager), then the CI may NOT be created anew. For this particular case you should use the function "Assetmanager Import" in Darwin.

You can see whether a CI was created in Darwin or AssetManager based on the field "Source-System" under "Sourceinformations" on the CI (filled either with "w5base" or "AssetManager".



[de:]

Ein Config-Item das innerhalb von Darwin per Neueingabe erzeugt
wurde und nach AssetManager übertragen werden kann, muß eine
gültige Incident Assignmentgroup aufweisen.

ACHTUNG: Wenn auf Config-Item in AssetManager "verwiesen"
werden soll (d.h. das betreffende CI steht unter der Hauptverantwortung
der IT-Division oder wird generell federführend in AssetManager
dokumentiert), dann darf dies NICHT mittels Neueingabe erzeugt
werden. In einem solchen Fall ist die "AssetManager Import"
Funktion zu verwenden.

Ob ein CI in Darwin oder AssetManager angelegt wurde können Sie anhand des Feldes "Quellsystem" unter "Quellinformationen" an dem CI ermitteln (befüllt entweder mit . "w5base" oder "AssetManager".

=cut

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
   return([".*::(appl|system|asset)"]);
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

   if ($dataobj->Self=~m/::appl$/){
      return($errorlevel,undef) if ($rec->{businessteam} eq "Extern");
   }
   if ($rec->{srcsys} eq "w5base" &&
       exists($rec->{cistatusid}) && in_array([$rec->{cistatusid}],[3,4,5])){
      if ($dataobj->Self=~m/::system$/){
         if ($rec->{'systemtype'} eq "abstract"){  # INM Group makes only
            return(undef,undef); # sense, if the system can be transfered to AM
         }
      }
      # TS::appl    -> acinmassignmentgroupid
      # TS::system  -> acinmassignmentgroupid
      # TS::asset   -> acinmassignmentgroupid
      my $isnotneeded=0;
      my $acinmassingmentgroup=$rec->{acinmassingmentgroup};
      if ($acinmassingmentgroup=~m/^\s*$/){
         my $msg="missing valid incident assignmentgroup";
         push(@qmsg,$msg);
         if ($dataobj->Self=~m/::system$/){
            if (!($rec->{iscbreakdown} || $rec->{iscbreakdown} ||
                  $rec->{iseducation}  || $rec->{isapprovtest} ||
                  $rec->{isprod} ||
                  $rec->{isreference}) &&
                 ($rec->{istest} || $rec->{isdevel})){
               $isnotneeded=1;
            }
         }
         if ($isnotneeded){
            $errorlevel=1 if ($errorlevel<1); #= unschön
         }
         else{
            push(@dataissue,$msg);
            $errorlevel=3 if ($errorlevel<3);
         }
      }
      else{
         my $o=getModuleObject($self->getParent->Config,"tsacinv::group");
         my $flt={fullname=>\$acinmassingmentgroup};
         $o->SetFilter($flt);
         my ($grec)=$o->getOnlyFirst(qw(id deleted));
         if ($o->Ping()){
            if (!defined($grec) || $grec->{deleted}){
               my $m="refered incident assignmentgroup is deleted";
               push(@qmsg,$m);
               push(@dataissue,$m);
               $errorlevel=3 if ($errorlevel<3);
            }
         }
      }
      return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
   }
   return($errorlevel,undef);
}



1;
