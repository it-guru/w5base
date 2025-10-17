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

When reconciling with the TPC, among other things, the transfer 
of data authority to the to AssetManager in the case of MCOS systems. 
In such a case the MCOS data record is not found in AssetManager, then 
there is a misconfiguration present.
This must be corrected with the MCOS support.


[de:]

Beim Abgleich mit der TPC, wird u.a. auch die Übergabe der Datenautoritiät
auf AssetManager bei MCOS Systemen geregelt. Sollte in einem solchen Fall
der MCOS Datensatz in AssetManager nicht gefunden werden, so liegt eine
Fehlkonfiguriation vor. Diese muss mit dem MCOS Support ausgeregelt werden.


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

   my $realsrcsys=$rec->{itcloudshortname};

   return(undef,undef) if ($rec->{srcsys} ne "TPC" &&
                           !($realsrcsys=~m/^TPC\d+$/));

   if (lc($rec->{srcsys}) eq "tpc"){ # migration TPC->TPC1
      $dataobj->ValidatedUpdateRecord($rec,{srcsys=>'TPC1'},{id=>$rec->{id}});
      $rec->{srcsys}="TPC1";
   }

   my $TPCenv=$realsrcsys;

   my ($parrec,$msg);
   my $par=getModuleObject($self->getParent->Config(),$TPCenv."::machine");
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
   if (defined($parrec)){
      if ($rec->{cistatusid}==6){
         # das kann auftreten, wenn die TPC Datenbank temporär Rotz-Daten 
         # hatte (d.h. es fehlten einfach Systeme, die in Wirklichkeit noch
         # da waren.
         $forcedupd->{cistatusid}=4;
      }
      # $parrec->{ismcos};
      my $tags=getModuleObject($dataobj->Config,"itil::tag_system");
      if ($parrec->{ismcos}){
         if (!in_array($rec->{alltags},[{uname=>\"isMCOS",value=>\"1"}])){
            $tags->ValidatedInsertRecord({
               refid=>$rec->{id},
               name =>'isMCOS',
               uname=>'isMCOS',
               value=>'1',
               ishidden=>1
            });
         }
      }
      else{
         if (in_array($rec->{alltags},[{uname=>\"isMCOS"}])){
            $tags->BulkDeleteRecord({
               refid=>$rec->{id},
               uname=>'isMCOS',
               ishidden=>1
            });
         }
      }
   }
   if (!defined($parrec) && $rec->{cistatusid}<6 && ($rec->{srcsys}=~m/^TPC\d+$/)){
      return(undef,undef) if (!$par->Ping());
      $forcedupd->{cistatusid}=6;
      push(@qmsg,
         'set system CI-Status to disposed of waste due missing on TPC');
   }
   else{
      if (($rec->{cistatusid}==4 || $rec->{cistatusid}==3 ||
           $rec->{cistatusid}==5 ||
           (exists($forcedupd->{cistatusid}) && $forcedupd->{cistatusid}==4)) &&
          ($rec->{srcsys}=~m/^TPC\d+$/)){
         if ($rec->{srcid} ne "" && $rec->{srcsys} eq $TPCenv){
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
                     my @chkl=$dataobj->getHashList(qw(id cistatusid));
                     my $updates=0;
                     #########################################################
                     #
                     # Add Support for "moving" SystemID from an inactiv
                     # system to another system (IT-Inventar) which happens
                     # if f.e. a logical system is moved directly from 
                     # TPC1 (vSphere) to TPC8 (vSphere)
                     #
                     foreach my $chkrec (@chkl){
                        if ($chkrec->{cistatusid}>4){
                           my $op=$dataobj->Clone();
                           $op->ValidatedUpdateRecord({
                              systemid=>$chkrec->{systemid}
                           },
                           {
                              systemid=>undef,
                           },
                           {id=>\$chkrec->{id}});
                           $updates++;
                        }
                     }
                     if ($updates){
                        $dataobj->ResetFilter();
                        $dataobj->SetFilter([
                           {systemid=>$systemid},
                           {name=>$name},
                        ]);
                        @chkl=$dataobj->getHashList(qw(id cistatusid));
                     }
                     #########################################################
                     #

                     if ($#chkl!=-1){
                        my $msg="missconfigurued MCOS system detected";
                        push(@qmsg,$msg);
                        push(@dataissue,$msg);
                        my $msg="no MCOS record in AssetManager found";
                        push(@qmsg,$msg);
                        push(@dataissue,$msg);
                        $errorlevel=3 if ($errorlevel<3);
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
            if ($parrec->{osclass}=~m/linux/i){
               $syncData{osclass}="LINUX";
            }
            elsif ($parrec->{osclass}=~m/win/i){
               $syncData{osclass}="WIN";
            }

            if ($parrec->{osrelease}=~m/other/i){ # Class=LINUX but OS Other
               $syncData{osclass}="MISC";
               $syncData{osrelease}="other";
            }

            ###################################################################
            # check, if shortname comes from TPC (as tag)
            if (ref($parrec->{tags}) eq "HASH" &&
                defined($parrec->{tags}->{shortdescription}) &&
                $parrec->{tags}->{shortdescription} ne "" &&
                length($parrec->{tags}->{shortdescription})<80){
               $syncData{shortdesc}=$parrec->{tags}->{shortdescription};
            }
            ###################################################################

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
                  msg(ERROR,"found TPC System $rec->{name} ".
                            "on invalid CloudArea");
               }
            }
            $dataobj->QRuleSyncCloudSystem($TPCenv,
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
