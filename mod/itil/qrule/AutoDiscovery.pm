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

To handle the installation of installed software in IT inventory 
based on Autodiscovery data, please refer to the FAQ article:

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

sub qenrichRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;

   return($self->qcheckRecord($dataobj,$rec,$checksession));
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
      my @AdPreData=();
      my %engines;
      $ade->SetFilter({localdataobj=>\$dataobjname,
                   #    addataobj=>\'TAD4D::system',
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
            misscount=>$r->{misscount},
            scanextra1=>$r->{scanextra1},
            scanextra2=>$r->{scanextra2},
            processable=>$r->{processable}
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
         if ($oldrecs{$id}->{misscount}>2){
            $ad->BulkDeleteRecord({id=>\$id});
         }
         else{
            $ad->UpdateRecord({misscount=>\'misscount+1'},{id=>\$id});
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
   }

   my %paths;
   foreach my $ad (@{$AdPreData}){    # Level2: Mögliche Pfade detectieren
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
      srcload=>NowStamp("en")
   };

   if (exists($adrec->{scanextra1})){
      my $scanextra1=limitlen($adrec->{scanextra1},128,1);
      $flt->{scanextra1}=\$scanextra1;
      $newrec->{scanextra1}=$scanextra1;
   }
   if (exists($adrec->{scanextra2})){
      $newrec->{scanextra2}=$adrec->{scanextra2};
   }
   $ad->ResetFilter();
   $ad->SetFilter($flt);
   my @l=$ad->getHashList(qw(ALL));
   if ($#l==-1){
      $ad->ValidatedInsertRecord($newrec);
   }
   else{
      foreach my $r (@l){
         my %updrec=();
         next if ($r->{engineid} ne $adrec->{engineid});
         if ($oldrecs->{$r->{id}}->{misscount}>0){
            $updrec{misscount}=0;
         }
         if ($oldrecs->{$r->{id}}->{scanextra2} ne $adrec->{scanextra2}){
            $updrec{scanextra2}=$adrec->{scanextra2};
         }
         if ($oldrecs->{$r->{id}}->{processable} ne $adrec->{processable}){
            $updrec{processable}=$adrec->{processable};
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
