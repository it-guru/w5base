package GCP::qrule::compareSystem;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This QualityRule compares a W5Base/Darwin logical system to an GCP 
logical system and updates the defined fields if necessary. Automated
imports are only done if the field "Allow automatic interface updates"
is set to "yes". 

=head3 IMPORTS

The fields Memory, CPU-Count, CO-Number, Description, Systemname
are imported from TPC. IP-Addresses can only be synced when the field 
"Allow automatic interface updates" is set to "yes". 

=head3 HINTS



=cut

#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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

   my $realsrcsys=$rec->{itcloudshortname};

   return(undef,undef) if ($rec->{srcsys} ne "GCP");



   my $TPCenv=$realsrcsys;

   my ($parrec,$msg);
   my $par=getModuleObject($self->getParent->Config(),"GCP::system");
   return(undef,undef) if (!$par->Ping());


   #
   # Level 1
   #
   if (!defined($parrec)){      # pruefen ob wir bereits nach TPC geschrieben
      # try to find parrec by srcsys and srcid
      $par->ResetFilter();
      $par->SetFilter({idpath=>\$rec->{srcid}});
      ($parrec)=$par->getOnlyFirst(qw(ALL));
   }

   #
   # Level 3
   #
   if (defined($parrec)){
      if ($rec->{cistatusid}==6){
         # das kann auftreten, wenn die GCP Datenbank temporär Rotz-Daten 
         # hatte (d.h. es fehlten einfach Systeme, die in Wirklichkeit noch
         # da waren.
         $forcedupd->{cistatusid}=4;
      }
   }
   if (!defined($parrec)){
      return(undef,undef) if (!$par->Ping());
      $forcedupd->{cistatusid}=6;
      push(@qmsg,
         'set system CI-Status to disposed of waste due missing on GCP');
   }

   if (($rec->{cistatusid}==4 || $rec->{cistatusid}==3 ||
        $rec->{cistatusid}==5 ||
        (exists($forcedupd->{cistatusid}) && $forcedupd->{cistatusid}==4)) &&
       ($rec->{srcsys}=~m/^GCP$/)){
      if ($rec->{srcid} ne "" && $rec->{srcsys} eq "GCP"){
         if (!defined($parrec)){
            return(undef,undef) if (!$par->Ping());
            $forcedupd->{cistatusid}=6;
            push(@qmsg,
               'set system CI-Status to disposed of waste due missing on TPC');
         }
         else{
            my @sysname=();
            my $sysname=lc($parrec->{name});
            $sysname=~s/\s/_/g;
            $sysname=~s/\..*$//;

            my $nameok=1;
            if ($sysname ne $rec->{name} && ($sysname=~m/\s/)){
               $nameok=0;
               my $m='systemname with whitespace in GCP - '.
                     'contact GCP Admin to fix this!';
               push(@qmsg,$m);
               push(@dataissue,$m);
               $errorlevel=3 if ($errorlevel<3);
            }
            if ($nameok){
               if ($sysname ne ""){
                  push(@sysname,$sysname);
               }
            }
            push(@sysname,"gcp".$parrec->{id});

            #my %sysiface;
            #my %ipaddresses;
            #if ($parrec->{address} ne ""){
            #   $ipaddresses{$parrec->{address}}={
            #      name=>$parrec->{address},
            #      netareatag=>'CNDTAG'
            #   };
            #}

            my %ipaddresses;
            foreach my $iprec (@{$parrec->{ipaddresses}}){
               $ipaddresses{$iprec->{name}}=$iprec;  # name ifname
            }


            my @ipaddresses;
            @ipaddresses=sort({$a->{name} cmp $b->{name}} values(%ipaddresses));

            my %syncData=(
               id=>$parrec->{id},
               name=>\@sysname,
               cpucount=>$parrec->{cpucount},
               memory=>$parrec->{memory},
               ipaddresses=>\@ipaddresses,
               availabilityZone=>$parrec->{zonename}
            );

            my $w5itcloudarea;
            if ($parrec->{projectId} ne ""){
               msg(INFO,"try to add CloudArea to system ".$rec->{name});
               my $cloudarea=getModuleObject($self->getParent->Config,
                                             "itil::itcloudarea");
               $cloudarea->SetFilter({srcsys=>\$TPCenv,
                                      srcid=>\$parrec->{projectId}
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
                  msg(ERROR,"found GCP System $rec->{name} ".
                            "on invalid CloudArea");
               }
            }
            $dataobj->QRuleSyncCloudSystem("GCP",
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
      my $msg="different values stored in TPC: ";
      push(@qmsg,$msg);
      push(@dataissue,$msg);
      $errorlevel=3 if ($errorlevel<3);
   }
   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}



1;
