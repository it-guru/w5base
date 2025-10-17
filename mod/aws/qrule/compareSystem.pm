package aws::qrule::compareSystem;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This QualityRule compares a W5Base/Darwin logical system to an AWS 
logical system and updates the defined fields if necessary. Automated
imports are only done if the field "Allow automatic interface updates"
is set to "yes". 

=head3 IMPORTS

The fields Memory, CPU-Count, CO-Number, Description, Systemname
are imported from AWS. IP-Addresses can only be synced when the field 
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

   return(undef,undef) if ($rec->{srcsys} ne "AWS");

   my $awsacc=getModuleObject($self->getParent->Config(),"aws::account");

   my ($awsid,$awsacccountid,$awsregion)=
      $rec->{srcid}=~m/^(\S+)\@([0-9]+)\@(\S+)$/;
   my ($parrec,$msg);
   my $par=getModuleObject($self->getParent->Config(),"aws::system");

   if ($awsacc->isSuspended() ||
       $par->isSuspended()){
      return(undef,{qmsg=>'suspended'});
   }

   return(undef,undef) if (!$par->Ping());


   my $cloudarea=getModuleObject($self->getParent->Config,"itil::itcloudarea");
   #
   # Check if cloudarea is not "disposed of wasted"
   # (Check on an AWS Account creates an access error - if account is not
   #  accessable or does not exists anymore)
   #
   my $cloudareaok=1;
   if ($rec->{itcloudareaid} ne ""){
      $cloudarea->ResetFilter();
      $cloudarea->SetFilter({id=>\$rec->{itcloudareaid}});
      my ($w5cloudarearec,$msg)=$cloudarea->getOnlyFirst(qw(ALL));
      if (defined($w5cloudarearec)){
         if ($w5cloudarearec->{cistatusid}>4){
            if ($rec->{cistatusid}<$w5cloudarearec->{cistatusid}){
               $forcedupd->{cistatusid}=$w5cloudarearec->{cistatusid};
            }
            if ($w5cloudarearec->{cistatusid}>5){
               $cloudareaok=0;
            }
         } 
         if ($rec->{cistatusid} eq "5" && $w5cloudarearec->{cistatusid} eq "4"){
            $forcedupd->{cistatusid}="4";
         }
      }
   }

   #
   # Level 1
   #
   if ($cloudareaok){      # pruefen ob wir bereits nach AWS geschrieben
      # validate AWS AccountID in CloudAreas
      $cloudareaok=0;
      if ($awsacccountid ne ""){
         $cloudarea->ResetFilter();
         $cloudarea->SetFilter({srcid=>\$awsacccountid,cloud=>\'AWS'});
         my ($w5cloudarearec,$msg)=$cloudarea->getOnlyFirst(qw(ALL));
         if (defined($w5cloudarearec) && $w5cloudarearec->{cistatusid}<6){
            $cloudareaok=1;
         }
      }

      # try to find parrec by srcsys and srcid
      if ($cloudareaok){
         $par->ResetFilter();
         my $flt={
            id=>$awsid,
            accountid=>$awsacccountid,
            region=>$awsregion
         };
         $par->SetFilter($flt);
         ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      }
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
      # das kann auftreten, wenn die AWS Datenbank temporär Rotz-Daten 
      # hatte (d.h. es fehlten einfach Systeme, die in Wirklichkeit noch
      # da waren.
      $forcedupd->{cistatusid}=4;
   }
   if ($rec->{cistatusid}==4 || $rec->{cistatusid}==3 ||
       $rec->{cistatusid}==5 ||
       (exists($forcedupd->{cistatusid}) && $forcedupd->{cistatusid}==4)){
      if ($rec->{srcid} ne "" && $rec->{srcsys} eq "AWS"){
         if (!defined($parrec)){
            return(undef,undef) if (!$par->Ping());
            $forcedupd->{cistatusid}=6;
            push(@qmsg,
               'set system CI-Status to disposed of waste due missing on AWS');
         }
         else{
            my @sysname=();
            my $sysname=lc($parrec->{name});
            if (($parrec->{name} eq "" || ($parrec->{name}=~m/[^a-z0-9-]/i)) &&
                $parrec->{autoscalinggroup} ne ""){
               my $autoscalinggroup=$parrec->{autoscalinggroup};
               $autoscalinggroup=~s/[^a-z0-9-]/_/g;
               $sysname=$parrec->{id}.'@'.$autoscalinggroup;
            }
           

            if ($sysname ne ""){
               push(@sysname,$sysname);
            }
            push(@sysname,$parrec->{id});

            my %sysiface;
            my %ipaddresses;
            foreach my $iprec (@{$parrec->{ipaddresses}}){
               $ipaddresses{$iprec->{name}}=$iprec;  # name ifname
               if ($iprec->{ifname} ne ""){
                  $sysiface{$iprec->{ifname}}={
                     mac=>$iprec->{mac},
                     name=>$iprec->{ifname}
                  };
               }
            }
            my @sysiface;
            my @ipaddresses;
            @sysiface=sort({$a->{name} cmp $b->{name}} values(%sysiface));
            @ipaddresses=sort({$a->{name} cmp $b->{name}} values(%ipaddresses));

            my %syncData=(
               id=>$parrec->{idpath},
               name=>\@sysname,
               cpucount=>$parrec->{cpucount},
               autoscalinggroup=>$parrec->{autoscalinggroup},
               memory=>$parrec->{memory},
               osrelease=>$parrec->{image_name},
               sysiface=>\@sysiface,
               ipaddresses=>\@ipaddresses,
            );
            if ($parrec->{platform}=~m/linux/i){
               $syncData{osclass}="LINUX";
            }
            elsif ($parrec->{platform}=~m/win/i){
               $syncData{osclass}="WIN";
            }
            if (($parrec->{imagename}=~m/^DevSecOps-eks-node-/) &&
                ($parrec->{imageowner} eq "784159863720")){
               $syncData{isclosedosenv}=1
            }
            if (exists($parrec->{tags})){
               if (exists($parrec->{tags}->{'eks:nodegroup-name'}) &&
                   $parrec->{tags}->{'eks:nodegroup-name'} ne ""){ 
                  $syncData{autoscalingsubgroup}=
                       $parrec->{tags}->{'eks:nodegroup-name'};
                  if ($sysname eq ""){
                     $sysname=$parrec->{tags}->{'eks:nodegroup-name'};
                     unshift(@{$syncData{name}},$sysname);
                  }
               }
            }
            if ($sysname eq "" && $syncData{autoscalinggroup} ne ""){
               $sysname=$syncData{autoscalinggroup};
               unshift(@{$syncData{name}},$sysname);
            }
               
            
            if ($parrec->{azoneid}=~m/^eu/){
               $syncData{availabilityZone}=$parrec->{azoneid};
            }
            else{
               my $msg='invalid availability zone from AWS: '.
                       $parrec->{azoneid};
               push(@qmsg,$msg);
               push(@dataissue,$msg);
               $errorlevel=3 if ($errorlevel<3);
            }

            my $w5itcloudarea;
            if ($parrec->{accountid} ne ""){
               $cloudarea->ResetFilter();
               $cloudarea->SetFilter({
                  cloud=>'AWS',
                  srcid=>$parrec->{accountid}
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
                  msg(ERROR,"found AWS System $rec->{name} ".
                            "on invalid CloudArea");
                  die();
               }
            }


            $dataobj->QRuleSyncCloudSystem("AWS",
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
      my $msg="different values stored in AWS: ";
      push(@qmsg,$msg);
      push(@dataissue,$msg);
      $errorlevel=3 if ($errorlevel<3);
   }
   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}



1;
