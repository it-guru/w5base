package azure::qrule::compareSystem;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This QualityRule compares a W5Base/Darwin logical system to an AZURE 
logical system and updates the defined fields if necessary. Automated
imports are only done if the field "Allow automatic interface updates"
is set to "yes". 

=head3 IMPORTS

The fields Memory, CPU-Count, CO-Number, Description, Systemname
are imported from AZURE. IP-Addresses can only be synced when the field 
"Allow automatic interface updates" is set to "yes". 

=head3 HINTS

[en:]


[de:]



=cut

#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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

   return(undef,undef) if ($rec->{srcsys} ne "AZURE");

   my ($parrec,$msg);
   my $par=getModuleObject($self->getParent->Config(),"azure::virtualMachine");
   return(undef,undef) if (!$par->Ping());


   #
   # Level 1
   #
   my $oldSrcId=0;
   if (!defined($parrec)){      # pruefen ob wir bereits nach AZURE geschrieben
      # try to find parrec by srcsys and srcid

      $par->ResetFilter();
      if (my ($vmId,$subscriptionId)=$rec->{srcid}
          =~m/^([a-z0-9-]+)\@([a-z0-9-]+)$/){
         $par->SetFilter({vmId=>$vmId,subscriptionId=>$subscriptionId});
      }
      else{
         if ($rec->{cistatusid}<6){
            msg(WARN,"Using old Azure srcid process for $rec->{id}");
         }
         $par->SetFilter({id=>\$rec->{srcid}});
         $oldSrcId++;
         #return({id=>\$rec->{srcid}});
      }
      ($parrec)=$par->getOnlyFirst(qw(ALL));
   }
   if ($oldSrcId && defined($parrec)){
      $forcedupd->{srcid}=$parrec->{vmId}.'@'.$parrec->{subscriptionId};
   }

   if ($rec->{cistatusid}==6 && defined($parrec)){
      # das kann auftreten, wenn die AZURE Datenbank temporär Rotz-Daten 
      # hatte (d.h. es fehlten einfach Systeme, die in Wirklichkeit noch
      # da waren.
      $forcedupd->{cistatusid}=4;
   }
   if ($rec->{cistatusid}==4 || $rec->{cistatusid}==3 ||
       $rec->{cistatusid}==5 ||
       (exists($forcedupd->{cistatusid}) && $forcedupd->{cistatusid}==4)){
      if ($rec->{srcid} ne "" && $rec->{srcsys} eq "AZURE"){
         if (!defined($parrec)){
            return(undef,undef) if (!$par->Ping());
            $forcedupd->{cistatusid}=6;
            push(@qmsg,
              'set system CI-Status to disposed of waste due missing on AZURE');
         }
         else{
            my @sysname=($parrec->{name},$parrec->{vmId});
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
               memory=>$parrec->{memory},
               sysiface=>\@sysiface,
               ipaddresses=>\@ipaddresses
            );
            if ($rec->{osrelease} eq "" ||            # sync os only if nobody
                lc($rec->{osrelease}) eq "other" ||   # has changed it in w5b
                lc($rec->{osrelease}) eq "windows" ||
                lc($rec->{osrelease}) eq "linux"){
               $syncData{osrelease}=$parrec->{osrelease};
            }
                

            my $w5itcloudarea;
            if ($parrec->{subscriptionId} ne ""){
               msg(INFO,"try to add CloudArea to system ".$rec->{name});
               my $cloudarea=getModuleObject($self->getParent->Config,
                                             "itil::itcloudarea");
               $cloudarea->SetFilter({srcsys=>\'AZURE',
                                      srcid=>\$parrec->{subscriptionId}
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
                  msg(ERROR,"found AZURE System $rec->{name} ".
                            "on invalid CloudArea");
               }
            }
            #
            # At now, no availabilityZone is active for Azure
            #
            $syncData{availabilityZone}="Any";

            #printf STDERR ("DEBUG:syncData=%s\n",Dumper(\%syncData));
            $dataobj->QRuleSyncCloudSystem("AZURE",
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
      my $msg="different values stored in AZURE: ";
      push(@qmsg,$msg);
      push(@dataissue,$msg);
      $errorlevel=3 if ($errorlevel<3);
   }
   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}



1;
