package tsotc::qrule::compareSystem;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This QualityRule compares a W5Base/Darwin logical system to an OTC 
logical system and updates the defined fields if necessary. Automated
imports are only done if the field "Allow automatic interface updates"
is set to "yes". 

=head3 IMPORTS

The fields Memory, CPU-Count, CO-Number, Description, Systemname
are imported from OTC. IP-Addresses can only be synced when the field 
"Allow automatic interface updates" is set to "yes". 

=head3 HINTS

[en:]


[de:]



=cut

#######################################################################
#
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
   return(["itil::system","AL_TCom::system"]);
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

   return(undef,undef) if ($rec->{srcsys} ne "OTC");

   my ($parrec,$msg);
   my $par=getModuleObject($self->getParent->Config(),"tsotc::system");
   return(undef,undef) if (!$par->Ping());


   #
   # Level 1
   #
   if (!defined($parrec)){      # pruefen ob wir bereits nach OTC geschrieben
      # try to find parrec by srcsys and srcid
      $par->ResetFilter();
      $par->SetFilter({id=>\$rec->{srcid}});
      ($parrec)=$par->getOnlyFirst(qw(ALL));
   }

   #
   # Level 3
   #
   # Das zurücksetzen der srcid bei veraltet/gelöschten Elementen ist
   # vielleicht doch keine so gute Idee
   #
   #if ($rec->{cistatusid}>5){
   #   if ($rec->{srcid} ne ""){
   #      $forcedupd->{srcid}=undef;
   #      $forcedupd->{srcload}=undef;
   #   }
   #}
   if ($rec->{cistatusid}==6 && defined($parrec)){
      # das kann auftreten, wenn die OTC Datenbank temporär Rotz-Daten 
      # hatte (d.h. es fehlten einfach Systeme, die in Wirklichkeit noch
      # da waren.
      $forcedupd->{cistatusid}=4;
   }
   if ($rec->{cistatusid}==4 || $rec->{cistatusid}==3 ||
       $rec->{cistatusid}==5 ||
       (exists($forcedupd->{cistatusid}) && $forcedupd->{cistatusid}==4)){
      if ($rec->{srcid} ne "" && $rec->{srcsys} eq "OTC"){
         if (!defined($parrec)){
            return(undef,undef) if (!$par->Ping());
            $forcedupd->{cistatusid}=6;
            push(@qmsg,
               'set system CI-Status to disposed of waste due missing on OTC');
         }
         else{
            my @sysname=();
            my $sysname=lc($parrec->{name});
            $sysname=~s/\s.*$//;
            $sysname=~s/\..*$//;
            $sysname=~s/[^a-z0-9_-]/_/g;
            if ($sysname ne "" && length($sysname)>3){
               push(@sysname,$sysname);
            }
            push(@sysname,$parrec->{altname});
            push(@sysname,$parrec->{id});

            my %sysiface;
            my @sysiface;
            my %parip;
            my @parip;
            for(my $ii=0;$ii<=$#{$parrec->{ipaddresses}};$ii++){
               if ($parrec->{ipaddresses}->[$ii]->{hwaddr} ne ""){
                  my $ifname=$parrec->{ipaddresses}->[$ii]->{hwaddr};
                  $sysiface{$ifname}=$ifname;
               }
               if ($parrec->{ipaddresses}->[$ii]->{name} ne ""){
                  $parip{$parrec->{ipaddresses}->[$ii]->{name}}++;
               }
            }
            @parip=sort(keys(%parip));
            my $sysiface=0;
            my $ifnamepattern='eth%d';
            foreach my $hwaddr (sort(keys(%sysiface))){
               my $ifname=sprintf($ifnamepattern,$sysiface);
               $sysiface++;
               $sysiface{$hwaddr}=$ifname;
               push(@sysiface,{
                  name=>$ifname,
                  mac=>$hwaddr
               });
            }
            my %internetip;
            if ($#parip!=-1){
               my $iip=getModuleObject($self->getParent->Config(),
                                       "tsotc::inipaddress");
               $iip->SetFilter({name=>\@parip});
               foreach my $iiprec ($iip->getHashList(qw(name))){
                  $internetip{$iiprec->{name}}++;
               }
            }

            my @ipaddresses;            
            foreach my $otciprec (@{$parrec->{ipaddresses}}){
               my $ifname;
               my $ip={
                  name=>$otciprec->{name},
                  netareatag=>"ISLAND"
               };
               if (exists($internetip{$otciprec->{name}})){
                  $ip->{netareatag}="INTERNET";
               }
               if ($otciprec->{name}=~m/^10\./){
                  $ip->{netareatag}="CNDTAG";
               }
               if ($otciprec->{hwaddr} ne "" && 
                   exists($sysiface{$otciprec->{hwaddr}})){
                  $ifname=$sysiface{$otciprec->{hwaddr}};
               }
               if ($ifname){
                  $ip->{ifname}=$ifname;
               }
               push(@ipaddresses,$ip);
            }

            my %syncData=(
               id=>$parrec->{idpath},
               name=>\@sysname,
               cpucount=>$parrec->{cpucount},
               memory=>$parrec->{memory},
            #   osrelease=>$parrec->{image_name},
               sysiface=>\@sysiface,
               ipaddresses=>\@ipaddresses
            );

            my $w5itcloudarea;
            if ($parrec->{projectid} ne ""){
               msg(INFO,"try to add CloudArea to system ".$rec->{name});
               my $cloudarea=getModuleObject($self->getParent->Config,
                                             "itil::itcloudarea");
               $cloudarea->SetFilter({srcsys=>\'tsotc::project',
                                      srcid=>\$parrec->{projectid}
               });
               my ($w5cloudarearec,$msg)=$cloudarea->getOnlyFirst(qw(ALL));
               if (defined($w5cloudarearec)){
                  $w5itcloudarea=$w5cloudarearec;
                  if ($w5cloudarearec->{cistatusid} eq "4" &&
                      $w5cloudarearec->{applid} ne ""){
                     $syncData{itcloudareaid}=$w5cloudarearec->{id};
                  }
               }
               else{
                  msg(ERROR,"found OTC System $rec->{name} ".
                            "on invalid CloudArea");
               }
            }

            if (!($parrec->{availability_zone}=~m/^eu[0-9a-z-]{3,10}$/)){
               my $msg='invalid availability zone from OTC';
               push(@qmsg,$msg);
               push(@dataissue,$msg);
               $errorlevel=3 if ($errorlevel<3);
            }
            else{
               $syncData{availabilityZone}=$parrec->{availability_zone}; 
            }

            $dataobj->QRuleSyncCloudSystem("OTC",
               $self,
               $rec,$par,\%syncData,
               $autocorrect,$forcedupd,
               \@qmsg,\@dataissue,\$errorlevel,$wfrequest
            );
        }
     }
   }

   if (keys(%$forcedupd)){
      if ($dataobj->ValidatedUpdateRecord($rec,$forcedupd,{id=>\$rec->{id}})){
         my @fld=grep(!/^srcload$/,keys(%$forcedupd));
         if ($#fld!=-1){
            push(@qmsg,"all desired fields has been updated: ".join(", ",@fld));
            $checksession->{EssentialsChangedCnt}++;
            map({$checksession->{EssentialsChanged}->{$_}++} @fld);
         }
      }
      else{
         push(@qmsg,$self->getParent->LastMsg());
         $errorlevel=3 if ($errorlevel<3);
      }
   }
   if (keys(%$wfrequest)){
      my $msg="different values stored in OTC: ";
      push(@qmsg,$msg);
      push(@dataissue,$msg);
      $errorlevel=3 if ($errorlevel<3);
   }
   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}



1;
