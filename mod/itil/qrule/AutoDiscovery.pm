package itil::qrule::AutoDiscovery;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Every Application in in CI-Status "installed/active" or "available", needs
to set a valid primary operation mode.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

How to handle the installation of installed software in IT inventory 
based on Autodiscovery data can be found in this FAQ article:

https://darwin.telekom.de/darwin/public/faq/article/ById/14845704850021

[de:]

Umgang mit der Übernahme von installierter Software ins IT Inventar 
auf Basis Autodiscovery-Daten finden Sie im FAQ Artikel:

https://darwin.telekom.de/darwin/public/faq/article/ById/14845704850021


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2007  Hartmut Vogler (it@guru.de)
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
   return(['itil::system','itil::swinstance']);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $dataobjname=$dataobj->SelfAsParentObject();

   return(0) if ($rec->{cistatusid}==6);

   my $ade=getModuleObject($dataobj->Config,"itil::autodiscengine");
   if (defined($ade)){ # itil:: seems to be installed
      my %missObj;
      $ade->SetFilter({localdataobj=>\$dataobjname,
                   #    addataobj=>\'HPSA::system',
                       cistatusid=>\'4'});

      foreach my $engine ($ade->getHashList(qw(ALL))){
         my $ado;
         eval('$ado=getModuleObject($dataobj->Config,$engine->{addataobj});');
         if (defined($ado)){
            if ($ado->isSuspended()){
               $missObj{$engine->{addataobj}}++;
            }
         }
         else{
            $missObj{$engine->{addataobj}}++;
         }
      }
      if (keys(%missObj)){
         return(undef,{
            qmsg=>'missing AutoDiscObjects '.join(",",sort(keys(%missObj)))
         });
      }

      my @AdPreData=();
      my %engines;
      $ade->ResetFilter();
      $ade->SetFilter({localdataobj=>\$dataobjname,
                   #    addataobj=>\'HPSA::system',
                       cistatusid=>\'4'});
      foreach my $engine ($ade->getHashList(qw(ALL))){  # found aktive Engine
         $engines{$engine->{id}}={
            id=>$engine->{id},
            name=>$engine->{name}
         };
         #print STDERR Dumper($engine);
         my $ado=getModuleObject($dataobj->Config,$engine->{addataobj});
         if (!exists($rec->{$engine->{localkey}})){
            # autodisc key data does not exists in local object
            msg(ERROR,"preQualityCheckRecord failed for $dataobjname ".
                      "local key $engine->{localkey} does not exists");
            next;
         }
         if ($rec->{$engine->{localkey}} ne ""){
            if (defined($ado)){  # check if autodisc object name is OK
               if ($ado->can("extractAutoDiscData")){
                  my $adokey=$ado->getField($engine->{adkey});
                  if (defined($adokey)){ # check if autodisc key is OK
                     $ado->SetFilter({
                        $engine->{adkey}=>\$rec->{$engine->{localkey}}
                     });
                     push(@AdPreData,map({
                        $_->{engineid}=$engine->{id};
                        $_;
                     } $ado->extractAutoDiscData()));
                  #   }
                  }
               }
               else{
                  msg(ERROR,"$ado is not AutoDiscovery compatibel : ".
                            "extractAutoDiscData");
               }
            }
         }
      }
      #print STDERR ("fifi 01 AutoDisc: %s\n",Dumper(\@AdPreData));
      #
      # create Software-Mappings and remove douplicate informations
      #
      $self->MapAutoDiscoveryPreData($dataobj,$rec,\@AdPreData); 


      #
      # load entry records based on engineids
      #
      #printf STDERR ("fifi AutoDisc 01.1 %s\n",Dumper(\@AdPreData));

      my %adentry=();
      {
         my $ade=getModuleObject($dataobj->Config,'itil::autodiscent');
         foreach my $adrec (grep({$_->{valid}} @AdPreData)){
            if (!exists($adentry{$adrec->{engineid}})){
               $ade->ResetFilter();
               $ade->SetFilter({
                  disc_on_systemid=>\$rec->{id},
                  engineid=>$adrec->{engineid}
               });
               my ($adent)=$ade->getOnlyFirst(qw(ALL));
              
               if (!defined($adent)){
                  if ($ade->ValidatedInsertRecord({
                         disc_on_systemid=>$rec->{id},
                         engineid=>$adrec->{engineid}
                      })){
                     ($adent)=$ade->getOnlyFirst(qw(ALL));
                  }
               }
               $adentry{$adrec->{engineid}}=$adent;
            }
         }
      }

      #
      # load old discovery entries
      #
      #printf STDERR ("fifi AutoDisc 02\n");


      my %oldrecs;
      my $ad=getModuleObject($dataobj->Config,'itil::autodiscrec');
      $ad->ResetFilter();
      $ad->SetFilter({
         disc_on_systemid=>\$rec->{id},
         #entryid=>[map({$_->{id}} values(%adentry))]
      });
      foreach my $r ($ad->getHashList(qw(ALL))){
         $oldrecs{$r->{id}}={
            state=>$r->{state},
            srcload=>$r->{srcload},
            misscount=>$r->{misscount},
            scanextra1=>$r->{scanextra1},
            scanextra2=>$r->{scanextra2},
            processable=>$r->{processable},
            forcesysteminst=>$r->{forcesysteminst}
         };
      }

      #printf STDERR ("fifi AutoDisc 03\n");
      #
      # process all autodiscovery entries
      #
      foreach my $adrec (grep({$_->{valid}} @AdPreData)){
         #print STDERR Dumper($adrec);
         next if (!$adrec->{valid});
         my $adent=$adentry{$adrec->{engineid}};
         $self->DiscoverData($ad,$rec,$adrec,$adent,
                             $engines{$adrec->{engineid}},\%oldrecs);
      }


      #
      # cleanup old autodiscovery entries
      #
      #printf STDERR ("oldrecs=%s\n",Dumper(\%oldrecs));

      foreach my $id (keys(%oldrecs)){
         if ($oldrecs{$id}->{misscount}>3){
            $ad->ResetFilter();
            $ad->SetFilter({id=>\$id});
            my ($oldadrec,$msg)=$ad->getOnlyFirst(qw(ALL));
            if (defined($oldadrec)){
               $ad->ValidatedDeleteRecord($oldadrec);
            }
         }
         else{
            # add misscount only, if last misscount mod is longer
            # then x hours ago (prevent multiple QualityChecks in Frontend 
            # as fast misscount up counting).
            # - this misscount braker only in prod enviroments - for better 
            #   testing of this feature

            if ($dataobj->Config->Param("W5BaseOperationMode") eq "normal"||
                $dataobj->Config->Param("W5BaseOperationMode") eq "online"){
               $ad->UpdateRecord({misscount=>\'misscount+1',
                                  mdate=>NowStamp("en"),
                                  srcload=>$oldrecs{$id}->{srcload}},
                                 {id=>\$id,
                                  mdate=>"<now-1h"});
            }
            else{
               $ad->UpdateRecord({misscount=>\'misscount+1',
                                  mdate=>NowStamp("en"),
                                  srcload=>$oldrecs{$id}->{srcload}},
                                 {id=>\$id});
            }
         }
      }



      #printf STDERR ("AdPreData:%s\n",Dumper(\@AdPreData));
   }
   return(0);
}

sub MapAutoDiscoveryPreData
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $AdPreData=shift;

   my @flt;

   foreach my $ad (@{$AdPreData}){
      $ad->{valid}=1;
      if ($ad->{section} eq "SOFTWARE"){
         if ($ad->{scanextra1}=~m#^/mnt/#){
            $ad->{valid}=0;  # ignore software on /mnt mount point
         }
         push(@flt,{
            engineid=>\$ad->{engineid},
            scanname=>\$ad->{scanname},
            softwareid=>'![EMPTY]'
         });
      }
   }
   my %ADMAP;

   if ($#flt!=-1){
      my $admap=getModuleObject($dataobj->Config,'itil::autodiscmap');
      $admap->SetFilter(\@flt);
      $admap->SetCurrentView(qw(id engineid scanname));
      foreach my $m ($admap->getHashList(qw(engineid scanname softwareid))){
         my $k=$m->{engineid}.";".$m->{scanname};
         if (!exists($ADMAP{$k})){
            $ADMAP{$k}=[$m->{softwareid}];
         }
         else{
            push(@{$ADMAP{$k}},$m->{softwareid});
         }
      }
   }
   foreach my $ad (@{$AdPreData}){    # Level1: Filtern der gemappten Software
      my $k=$ad->{engineid}.";".$ad->{scanname};
      if ($ad->{section} eq "SOFTWARE"){ # software needs a mappging
         if (!exists($ADMAP{$k})){
            $ad->{valid}=0;
         }
         else{
            $ad->{alt}=$ADMAP{$k};
         }
      }
      if ($ad->{section} eq "SYSTEMNAME"){ 
         if ($ad->{scanname}=~m/\./){  # systemname with dots are not allowed
            $ad->{valid}=0;
         }
         if ($rec->{name} eq lc($ad->{scanname})){  #system already ok
            $ad->{valid}=0;
         }
      }
      if ($ad->{section} eq "SOFTWARE" &&
          exists($ad->{alt})){
         foreach my $alt (@{$ad->{alt}}){
            $ad->{token}->{$ad->{section}."@".$alt}++;
         } 
      }
      else{
         $ad->{token}->{$ad->{section}."@".$ad->{scanname}}++;
      }
   }


   # Next filter: remove ads with existing token with lower quality then
   # current quality
   foreach my $ad (@{$AdPreData}){   
      next if (!$ad->{valid});
      foreach my $token (keys(%{$ad->{token}})){
         foreach my $altad (@{$AdPreData}){   
            next if (!$altad->{valid});
            if (in_array($token,[keys(%{$altad->{token}})])){
               if ($ad->{quality}>$altad->{quality}){
                  $altad->{valid}=0; # for this altad-rec, a better ad-rec 
                                     # (higher quality) record exists.
               }
            }
         }
      }
   }

   

   my %paths;
   foreach my $ad (@{$AdPreData}){    # Level3: Mögliche Pfade detectieren
      next if (!$ad->{valid});
      my @targets=($ad->{scanname});
      if (exists($ad->{alt})){
         @targets=@{$ad->{alt}};
      }
      foreach my $target (@targets){
         my $t=$target;
         #my $t=$ad->{scanname}." - ".$target;
         if ($ad->{scanextra1} ne ""){
            $t.=" @ ".$ad->{scanextra1};
         }
         if (!exists($paths{$t})){
            $paths{$t}=$ad;
         }
         else{
            if ($paths{$t}->{quality}==$ad->{quality} &&   # Gleiche Engine
                $paths{$t}->{engineid}==$ad->{engineid} && # mit untersch.
                $paths{$t}->{scanextra1} ne $ad->{scanextra1}){ # produkten
                $paths{$t}=$ad;
            }
            else{
               if ($paths{$t}->{quality}<$ad->{quality}){
                  $paths{$t}=$ad;
               }
            }
         }
      }
   }


   @{$AdPreData}=values(%paths);   # for the future, only use valid path recs
   #printf STDERR ("\npaths1:\n%s\n",Dumper(\%paths));
   #printf STDERR ("preData:\n%s\n",Dumper($AdPreData));
   #print STDERR Dumper(\%ADMAP);
}






sub DiscoverData
{
   my $self=shift;
   my $ad=shift;
   my $rec=shift;
   my $adrec=shift;
   my $adent=shift;
   my $engine=shift;
   my $oldrecs=shift;


   my $flt={
      section=>\$adrec->{section},
      scanname=>\$adrec->{scanname},
      entryid=>\$adent->{id}
   };
   my $newrec={
      section=>$adrec->{section},
      scanname=>$adrec->{scanname},
      processable=>$adrec->{processable},
      entryid=>$adent->{id},
      srcsys=>$engine->{name},
      srcload=>NowStamp("en"),
      backendload=>$adrec->{backendload},
      autodischint=>$adrec->{autodischint}
   };

   if ($adrec->{forcesysteminst}){
      if ($adent->{disc_on_systemid} eq ""){
         print STDERR Dumper($adrec);
         die("missing disc_on_systemid with forcesysteminst rec");
      }
      else{
        $newrec->{lnkto_system}=$adent->{disc_on_systemid};
        $newrec->{forcesysteminst}='1';
      }
   }

   if (exists($adrec->{scanextra1})){     # scandata and scanextra1 need unique
      my $scanextra1=limitlen($adrec->{scanextra1},128,1);
      $flt->{scanextra1}=\$scanextra1;
      $newrec->{scanextra1}=$scanextra1;
   }
   if (exists($adrec->{scanextra2})){    # scanextra2 is aditional
      $newrec->{scanextra2}=$adrec->{scanextra2};
   }
   $ad->ResetFilter();
   $ad->SetFilter($flt);
   my @l=$ad->getHashList(qw(ALL));
   if ($#l==-1){
      $ad->ValidatedInsertRecord($newrec);
   }
   else{
      my $cnt=0;
      foreach my $r (@l){
         my %updrec=();
         next if ($r->{engineid} ne $adrec->{engineid});
         $cnt++;
         if ($cnt>1){  # double Record found
            msg(WARN,"double adrec detected");
            msg(WARN,"l=".Dumper(\@l));
            msg(WARN,"adrec=".Dumper($adrec));
            msg(WARN,"(This message is only for debugging and ".
                     "needs to be removed in ".
                     "the future by development)");
            msg(WARN,"======");
            next;
         }
         if ($oldrecs->{$r->{id}}->{misscount}>0){
            $updrec{misscount}=0;
         }
         foreach my $cmpvar (qw(scanextra2 processable backendload
                                autodischint)){
            if ($oldrecs->{$r->{id}}->{$cmpvar} ne $adrec->{$cmpvar}){
               $updrec{$cmpvar}=$adrec->{$cmpvar};
            }
         }
         $updrec{srcload}=NowStamp("en");
         if (keys(%updrec)){
            # printf STDERR ("Start Update in $ad %s\n",Dumper(\%updrec));
            $ad->ValidatedUpdateRecord($r,\%updrec,{id=>$r->{id}});
         }
         delete($oldrecs->{$r->{id}});
      }
   }
}

1;
