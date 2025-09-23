package TeamLeanIX::qrule::BasedMandatorRules;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Switches the mandator relation based on the organisation relation
at the ICTO-Object in T.EAM.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

The mandators of applications are determined based on the org. unit of 
the listed ICTO object.

The mapping is done only on applications with primary operation mode 
"production" and "disaster recovery" and only in the following CI-States:
 
available/in project | installed/active | inactive/stored

Mandator of applications with other primary operation mode 
(test, developmnet, etc.) should correspond with the org. unit of the 
application manager.

(Example : If the AM is in solution E-DTO then the application should 
have the mandator E-DTO)
 
If the mandator of logical systems, software instances and assets is the same 
as the one on the superordinate CI, this mandator is used. 
If there are multiple different mandators, but they are TelekomIT_* mandators, 
the mandator "TelekomIT" is selected. In all other cases no 
mandator replacement takes place.

[de:]

Die Mandanten von Anwendungen werden basierend auf der im angegebenen
ICTO-Objekt definierten Organisations-Zuordnung zugeordnet.

Das Mapping wird nur bei Anwendungen mit vorwiegender Betriebsart 
"Produktion" oder "Katastrophenfall" und nur in den folgenden CI-Status 
durchgeführt:

verfügbar/in Projektierung  |  installiert/aktiv | zeitweise inaktiv

Der Mandant einer Anwendung mit anderer vorwiegender Betriebsart 
(Test, Entwicklung, usw.) soll der org. Einheit des Application Managers 
entsprechen.

(Beispiel: Ist der AM in der Solution E-DTO soll die Anwendung 
den Mandanten E-DTO haben)

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
      msg(INFO,"ICTO self='".$dataobj->SelfAsParentObject()."'");
      my $saphier;
      my $icto=$rec->{ictono};
      msg(INFO,"ICTO ictono='".$rec->{ictono}."'");
      msg(INFO,"ICTO ictoid='".$rec->{ictoid}."'");
      msg(INFO,"ICTO appl opmode='".$rec->{opmode}."'");
      if ($icto ne "" && 
          ($rec->{opmode} eq "prod" || $rec->{opmode} eq "cbreakdown")){
         my $m=getModuleObject($dataobj->Config,"base::mandator");
         my $grp;
         my $i=getModuleObject($dataobj->Config,"TeamLeanIX::gov");
         return(undef,undef) if ($i->isSuspended());
         return(undef,undef) if (!$i->Ping());
         $i->SetFilter({ictoNumber=>\$icto});
         my ($ictor)=$i->getOnlyFirst(qw(ALL));
         return(undef,undef) if (!$i->Ping());
         if (defined($ictor) && $ictor->{organisation} ne ""){
            $grp=$ictor->{orgareaid};
         }
         if ($ictor->{orgarea}=~m/\.DTIT\.Hub\./i){ # seems a hub
            $grp="200"; # map all TelIT Hubs to Mandator TelekomIT group
         }
         msg(INFO,"ICTO organisation '".$ictor->{organisation}."'");
         msg(INFO,"ICTO orgarea '".$ictor->{orgarea}."'");
         msg(INFO,"ICTO grp '".$grp."'");


         if ($grp ne ""){
            $m->ResetFilter();
            $m->SetFilter({grpid=>\$grp,cistatusid=>['3','4','5']});
            my ($mrec)=$m->getOnlyFirst(qw(name grpid));
            if (!defined($mrec)){ 
               msg(ERROR,"no usable mandator for ".
                         "organisation '$ictor->{organisation}' ".
                         "(grp=$ictor->{orgarea}) ".
                         "as requested ".
                         "from T.EAM in '$icto' - id=$rec->{id}");
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
         else{
            return(0,undef);
         }
      }
   }
   elsif ($dataobj->SelfAsParentObject() eq "itil::swinstance"){
      my $applid=$rec->{applid};
      if ($applid ne ""){
         my $appl=getModuleObject($dataobj->Config,"itil::appl");
         return(undef,undef) if ($appl->isSuspended());
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
         return(undef,undef) if ($appl->isSuspended());
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
               $m->SetFilter({groupname=>\"DTAG.GHQ.VTI.DTIT",
                              cistatusid=>\'4'});
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
         return(undef,undef) if ($sys->isSuspended());
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
               $m->SetFilter({groupname=>\"DTAG.GHQ.VTS.TSI.TI",
                              cistatusid=>\'4'});
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
     # $forcedupd->{mandator}=$dstmandator;
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
