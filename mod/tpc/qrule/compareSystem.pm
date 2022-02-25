package tpc::qrule::compareSystem;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This QualityRule compares a W5Base/Darwin logical system to an TPC 
logical system and updates the defined fields if necessary. Automated
imports are only done if the field "Allow automatic interface updates"
is set to "yes". 

=head3 IMPORTS

The fields Memory, CPU-Count, CO-Number, Description, Systemname
are imported from TPC. IP-Addresses can only be synced when the field 
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

   return(undef,undef) if ($rec->{srcsys} ne "TPC");

   my ($parrec,$msg);
   my $par=getModuleObject($self->getParent->Config(),"tpc::machine");
   return(undef,undef) if (!$par->Ping());


   #
   # Level 1
   #
   if (!defined($parrec)){      # pruefen ob wir bereits nach TPC geschrieben
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
      # das kann auftreten, wenn die TPC Datenbank temporär Rotz-Daten 
      # hatte (d.h. es fehlten einfach Systeme, die in Wirklichkeit noch
      # da waren.
      $forcedupd->{cistatusid}=4;
   }
   if ($rec->{cistatusid}==4 || $rec->{cistatusid}==3 ||
       $rec->{cistatusid}==5 ||
       (exists($forcedupd->{cistatusid}) && $forcedupd->{cistatusid}==4)){
      if ($rec->{srcid} ne "" && $rec->{srcsys} eq "TPC"){
         if (!defined($parrec)){
            return(undef,undef) if (!$par->Ping());
            $forcedupd->{cistatusid}=6;
            push(@qmsg,
               'set system CI-Status to disposed of waste due missing on TPC');
         }
         else{
            if ($parrec->{ismcos}){
               # ok, this record should be transfered to srcsys=AssetManager
               # because for MCOS always AssetManager(TSI) is datamaster
               my $instanceUUID=uc($parrec->{instanceUUID});
               my $acsys=getModuleObject($self->getParent->Config,
                         "tsacinv::system");
               if (defined($acsys) && $acsys->Ping()){
                  $acsys->SetFilter({
                     srcid=>\$instanceUUID,
                     srcsys=>\'MCOS_FCI',
                     deleted=>\'0'
                  });
                  my @as=$acsys->getHashList(qw(systemid name srcsys srcid));
                  if ($#as==0){
                     my $amrec=$as[0];
                     #
                     # Validate posibility of srcsys transfer
                     #
                     my $systemid=$amrec->{systemid};
                     my $name=$amrec->{name};
                     $systemid=~s/[^a-z0-9_-]//gi;
                     $name=~s/[^a-z0-9_-]//gi;
                     $dataobj->SetFilter([
                        {systemid=>$systemid},
                        {name=>$name},
                     ]);
                     my @chkl=$dataobj->getHashList(qw(id));
                     if ($#chkl!=-1){
                        msg(ERROR,"MCOS transfer error for $rec->{id}");
                     }
                     else{
                        $forcedupd->{srcsys}='AssetManager';
                        $forcedupd->{systemid}=$amrec->{systemid};
                        my $m="MCOS transfer record to AssetManager datamaster";
                        push(@qmsg,$m);
                     }
                  }
                  else{
                     my $u="";
                     if ($#as!=-1){
                        $u="unique ";
                     }
                     my $m="MCOS System not ${u}identifiable in AssetManager";
                     push(@qmsg,$m);
                  }
               }
            }




            my @sysname=();
            my $sysname=lc($parrec->{name});
            $sysname=~s/\s/_/g;
            $sysname=~s/\..*$//;

            my $nameok=1;
            if ($sysname ne $rec->{name} && ($sysname=~m/\s/)){
               $nameok=0;
               my $m='systemname with whitespace in TPC - '.
                     'contact TPC Admin to fix this!';
               push(@qmsg,$m);
               push(@dataissue,$m);
               $errorlevel=3 if ($errorlevel<3);
            }
            if ($nameok){
               if ($sysname ne ""){
                  push(@sysname,$sysname);
               }
            }
            if ($parrec->{genname} ne "" && 
                $parrec->{genname} ne $parrec->{name}){
               push(@sysname,$parrec->{genname});
            }
            push(@sysname,$parrec->{id});

            #my %sysiface;
            #my %ipaddresses;
            #if ($parrec->{address} ne ""){
            #   $ipaddresses{$parrec->{address}}={
            #      name=>$parrec->{address},
            #      netareatag=>'CNDTAG'
            #   };
            #}

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
               id=>$parrec->{id},
               name=>\@sysname,
               cpucount=>$parrec->{cpucount},
               memory=>$parrec->{memory},
               osrelease=>$parrec->{image_name},
               sysiface=>\@sysiface,
               ipaddresses=>\@ipaddresses,
               availabilityZone=>'Any'
            );

            my $w5itcloudarea;
            if ($parrec->{projectId} ne ""){
               msg(INFO,"try to add cloudarea to system ".$rec->{name});
               my $cloudarea=getModuleObject($self->getParent->Config,
                                             "itil::itcloudarea");
               $cloudarea->SetFilter({srcsys=>\'TPC',
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
                  msg(ERROR,"found TPC System $rec->{name} ".
                            "on invalid cloudarea");
               }
            }
            $dataobj->QRuleSyncCloudSystem("TPC",
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
