package tscape::qrule::CapeBasedMandatorRules;
#######################################################################
=pod

=head3 PURPOSE

REGEL ist noch in der Testphase !!!
Switches the mandator relation based on the defined t-systems ruleset

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

The mandators of applications are assigned based on
the SAP hierarchy defined in the affiliated Costcenters.

* 9TS_ES.9DTIT.9ECS     is equal to CSO 

* 9TS_ES.9DTIT.9EMC     is equal to MCS 

* 9TS_ES.9DTIT.9ESSI    is equal to TSI 

* 9TS_ES.9DTIT.9ESIL    is equal to TSI 

* 9TS_ES.9DTIT.9EGS     is equal to GSO 

* 9TS_ES.9DTIT.9ETS     is equal to TSO 

The mapping is done only on config items in the following CI-States:

available/in project |  installed/active | inactive/stored

If the mandator of logical systems, software instances and assets is the same
as the one on the superordinate CI, this mandator is used.
If there are multiple different mandators, but they are TelekomIT_* mandators,
the mandator "TelekomIT" is selected.
In all other cases no mandator replacement takes place. 

[de:]

Die Mandanten von Anwendungen werden basierend auf der im angegebenen
Kontierungsobjekt definierten SAP-Hierarchie zugeordnet.

* 9TS_ES.9DTIT.9ECS     ist gleich CSO 

* 9TS_ES.9DTIT.9EMC     ist gleich MCS 

* 9TS_ES.9DTIT.9ESSI    ist gleich TSI 

* 9TS_ES.9DTIT.9ESIL    ist gleich TSI 

* 9TS_ES.9DTIT.9EGS     ist gleich GSO 

* 9TS_ES.9DTIT.9ETS     ist gleich TSO 

Das Mapping wird nur bei Config-Items im Status ...

 verfügbar/in Projektierung  |  installiert/aktiv | zeitweise inaktiv

... durchgeführt.

Bei logischen Systemen, Software-Instanzen und Assets wird der Mandant
aus dem übergeordneten CI übernommen, wenn dieser immer auf den
gleichen Mandanten verweist. Ist er unterschiedlich, aber immer in
der TelekomIT_*, dann wird der Mandant "TelekomIT" gewählt. 
In allen anderen Fällen erfolgt keine Mandantenanpassung.


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
use strict;
use vars qw(@ISA);
use kernel;
use kernel::QRule;
@ISA=qw(kernel::QRule);


sub mapCapeOrgToMandGrp
{
   my $curmandator=shift; 
   my $org=shift; 
   my $grp;

   if (my ($sol)=$org=~m/^TS LBU DE T-IT E-([A-Z]{3}).*$/){
      $grp="DTAG.GHQ.VTS.TSI.TI.E-".$sol;
   }
   return($grp);
}



sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return(["itil::appl","itil::swinstance","itil::system","itil::asset"]);
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


   return(0,undef) if ($rec->{cistatusid}==6 ||
                       $rec->{cistatusid}==1 ||
                       $rec->{cistatusid}==2);

   my $curmandator=$rec->{mandator};
   my $curmandatorid=$rec->{mandator};
   my $dstmandator;
   my $dstmandatorid;
   if ($dataobj->SelfAsParentObject() eq "itil::appl"){
      my $saphier;
      my $icto=$rec->{ictono};
      if ($icto ne "" && 
          ($rec->{opmode} eq "prod" || $rec->{opmode} eq "cbreakdown")){
         my $grp;
         my $i=getModuleObject($dataobj->Config,"tscape::archappl");
         $i->SetFilter({archapplid=>\$icto});
         my ($ictor)=$i->getOnlyFirst(qw(organisation archapplid));
         if (defined($ictor) && $ictor->{organisation} ne ""){
            $grp=mapCapeOrgToMandGrp($curmandatorid,$ictor->{organisation});
         }
         if ($grp ne ""){  # try to find target based on saphier
            if ($grp ne ""){
               my $m=getModuleObject($dataobj->Config,"base::mandator");
               $m->SetFilter({groupname=>\$grp,cistatusid=>\'4'});
               my ($mrec)=$m->getOnlyFirst(qw(name grpid));
               if (!defined($mrec)){ 
                  msg(ERROR,"can not identify mandator for group '$grp'");
                  return(0,undef);
               }
               if ($curmandator ne $mrec->{name}){
                  $dstmandator=$mrec->{name};
                  $dstmandatorid=$mrec->{grpid};
               }
               else{
                  msg(INFO,"mandant '$curmandator' passt");
               }
            }
         }
      }
   }
   elsif ($dataobj->SelfAsParentObject() eq "itil::swinstance"){
      my $applid=$rec->{applid};
      if ($applid ne ""){
         my $appl=getModuleObject($dataobj->Config,"itil::appl");
         $appl->SetFilter({id=>\$applid});
         my ($applrec)=$appl->getOnlyFirst(qw(mandator mandatorid));
         if (defined($applrec)){
            if ($applrec->{mandator} ne $curmandator){
               $dstmandator=$applrec->{mandator};
               $dstmandatorid=$applrec->{mandatorid};
            }
            else{
               msg(INFO,"mandant '$curmandator' passt");
            }
         }
      }
   }
   elsif ($dataobj->SelfAsParentObject() eq "itil::system"){
      my @applid;
      foreach my $arec (@{$rec->{applications}}){
         push(@applid,$arec->{applid});
      }
      if ($#applid!=-1){
         my $appl=getModuleObject($dataobj->Config,"itil::appl");
         $appl->SetFilter({id=>\@applid});
         my %m;
         foreach my $arec ($appl->getHashList(qw(mandator mandatorid))){
            $m{$arec->{mandator}}=$arec->{mandatorid};
         }
         if (keys(%m)==0){  # kein Anwendungsmandant gefunden
            # no change of Mandator
         }
         elsif (keys(%m)==1){  # alle Anwendungen laufen auf einem Mandaten
            my $ma=(keys(%m))[0];
            if ($ma ne $rec->{mandator}){
               $dstmandator=(keys(%m))[0];
               $dstmandatorid=(values(%m))[0];
            }
         }
         else{
            if (grep(!/^TelekomIT/,keys(%m))){ # auch nicht TelekomIT
                                               # Anwendungen vorhanden
               # no change of Mandator
            }
            else{
               my $m=getModuleObject($dataobj->Config,"base::mandator");
               $m->SetFilter({groupname=>\"DTAG.TSI.TI",cistatusid=>\'4'});
               my ($mrec)=$m->getOnlyFirst(qw(name grpid));
               if (defined($mrec)){
                  if ($mrec->{name} ne $rec->{mandator}){
                     $dstmandator=$mrec->{name};
                     $dstmandatorid=$mrec->{grpid};
                  }
               }
            }
         }
      }
   }
   elsif ($dataobj->SelfAsParentObject() eq "itil::asset"){
      my @sysid;
      foreach my $srec (@{$rec->{systems}}){
         push(@sysid,$srec->{id});
      }
      if ($#sysid!=-1){
         my $sys=getModuleObject($dataobj->Config,"itil::system");
         $sys->SetFilter({id=>\@sysid});
         my %m;
         foreach my $srec ($sys->getHashList(qw(mandator mandatorid))){
            $m{$srec->{mandator}}=$srec->{mandatorid};
         }
         if (keys(%m)==0){  # kein Systemmandanten gefunden
            # no change of Mandator
         }
         elsif (keys(%m)==1){  # alle Systeme laufen auf einem Mandaten
            my $ma=(keys(%m))[0];
            if ($ma ne $rec->{mandator}){
               $dstmandator=(keys(%m))[0];
               $dstmandatorid=(values(%m))[0];
            }
         }
         else{
            if (grep(!/^TelekomIT/,keys(%m))){ # auch nicht TelekomIT
                                               # Systeme vorhanden
               # no change of Mandator
            }
            else{
               my $m=getModuleObject($dataobj->Config,"base::mandator");
               $m->SetFilter({groupname=>\"DTAG.TSI.TI",cistatusid=>\'4'});
               my ($mrec)=$m->getOnlyFirst(qw(name grpid));
               if (defined($mrec)){
                  if ($mrec->{name} ne $rec->{mandator}){
                     $dstmandator=$mrec->{name};
                     $dstmandatorid=$mrec->{grpid};
                  }
               }
            }
         }
      }
   }
   if ($dstmandator ne "" && $dstmandatorid ne ""){
      msg(INFO,"transfer $rec->{name} from '$curmandator' to '$dstmandator'");
      $forcedupd->{mandatorid}=$dstmandatorid;
      $forcedupd->{mandator}=$dstmandator;
   }
   if (keys(%$forcedupd)){
      $dataobj->NotifiedValidatedUpdateRecord({
         datasource=>'SACM Mandanten-Ruleset',
         mode=>'QualityCheck'
      },$rec,$forcedupd,{id=>\$rec->{id}});
   }
   return(0,undef);
}



1;
