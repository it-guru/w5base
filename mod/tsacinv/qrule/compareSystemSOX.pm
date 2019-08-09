package tsacinv::qrule::compareSystemSOX;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This QualityRule compares a W5Base/Darwin logical system to an AssetManager
logical system and checks for differences between the SOX state of the system.
Only logical systems in W5Base/Darwin with the CI-State different than 
"reserved" and "disposed of waste" are checked.

=head3 IMPORTS

NOTHING

=head3 HINTS

[en:]

The SOX flag is inherited from W5Base/Darwin by default from a 
field on the application: "Application is mangaged by rules of SOX or ICS".

If this value differs from the value stored in AssetManager, the 
IT-SeM has to create a request to system operation, so that the 
SOX-compliant transaction is implemented and then the data is 
maintained in AssetManager.

[de:]

Das SOX-Flag wird in W5Base/Darwin standardmäßig aus einem Feld der 
Anwendung geerbt: "Nach ICS oder SOX Richtlinien zu betreuen:".
Wenn sich dieser Wert von dem in AssetManager hinterlegten Wert 
unterscheidet, muss durch den IT-SeM ein Auftrag an den Systembetrieb 
erfolgen, damit der SOX-konforme Berieb umgesetzt und dann die Daten 
in AssetManager gepflegt werden.

Der Anstoss dazu erfolgt üblicherweise durch den Application-Manager, 
dessen Entscheidung hat Vorrang gegenüber Empfehlungen aus 
Delivery-Einheiten!  

=cut
#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   return(undef,undef) if (lc($rec->{srcsys}) ne "assetmanager");
   return(0,undef) if ($rec->{cistatusid}<=1 || $rec->{cistatusid}>=6);
   if ($rec->{systemid} ne ""){
      my $par=getModuleObject($self->getParent->Config(),"tsacinv::system");
      $par->SetFilter({systemid=>\$rec->{systemid}});
      my ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      return(undef,undef) if (!$par->Ping());
      if ($parrec->{assignmentgroup} eq "CS.DPS.DE.MSY" ||
          ($parrec->{assignmentgroup}=~m/^CS\.DPS\.DE\.MSY\..*$/) ||
          $parrec->{assignmentgroup} eq "C.DPS.INT.MSY"  ||
          ($parrec->{assignmentgroup}=~m/^C\.DPS\.INT\.MSY\..*$/) ){
       # CS.DPS.DE.MSY Pflegt das SOX Flag in AM nicht
       # siehe: 
       # https://darwin.telekom.de/darwin/auth/base/workflow/ById/14072395420001

       # C.DPS.INT.MSY genauso
       # siehe:
       # https://darwin.telekom.de/darwin/auth/base/workflow/ById/15290484890001
         return(undef);
      }
      if (defined($parrec) && !$parrec->{sas70relevant}){ # only if no SAS70 is
         my $issox=$dataobj->getField("issox")->RawValue($rec); # set in AM
         if ($issox!=$parrec->{sas70relevant}){
            my %appls;
            my $isallsap=0;
            # SAP erzeugt keine DataIssues based on 

       # https://darwin.telekom.de/darwin/auth/base/workflow/ById/14848210180001
            if (ref($rec->{applications}) eq "ARRAY" && 
                $#{$rec->{applications}}!=-1){
               foreach my $appl (@{$rec->{applications}}){
                  $appls{$appl->{applid}}++;
               }
               if (keys(%appls)){
                  my $o=getModuleObject($self->getParent->Config(),
                                        "itil::appl");
                  $o->SetFilter({id=>[keys(%appls)]});
                  my @l=$o->getHashList(qw(mgmtitemgroup));
                  my $sapcnt=0;
                  foreach my $a (@l){
                     if (!ref($a->{mgmtitemgroup})){
                        $a->{mgmtitemgroup}=[$a->{mgmtitemgroup}];
                     }
                     if (in_array($a->{mgmtitemgroup},"SAP")){
                        $sapcnt++;
                     }
                  }
                  if ($sapcnt>0 && $sapcnt==$#l+1){
                     $isallsap=1;
                  }
               }
            }
            if (!$isallsap){
               my $msg="SOX relevance does not match the AM presets!".
                       " - please check your order";
               push(@qmsg,$msg);
               push(@dataissue,$msg);
               $errorlevel=3 if ($errorlevel<3);
            }
         }
      }
   }

   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}



1;
