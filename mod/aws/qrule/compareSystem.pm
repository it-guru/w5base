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


   my ($awsid,$awsacccountid,$awsregion)=$rec->{srcid}=~m/^(\S+)\@([0-9]+)\@(\S+)$/;
   my ($parrec,$msg);
   my $par=getModuleObject($self->getParent->Config(),"aws::system");
   return(undef,undef) if (!$par->Ping());

   #
   # Level 1
   #
   if (!defined($parrec)){      # pruefen ob wir bereits nach AWS geschrieben
      # try to find parrec by srcsys and srcid
      $par->ResetFilter();
      my $flt={
         id=>$awsid,
         accountid=>$awsacccountid,
         region=>$awsregion
      };
      $par->SetFilter($flt);
      ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
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

            if ($rec->{srcsys} eq "AWS"){
               my $sysname=lc($parrec->{name});
               $sysname=~s/\s/_/g;
               $sysname=~s/\..*$//; # remove posible Domain part 
               if (length($sysname)>40){
                  $sysname=substr($sysname,40);
               }
               if ($sysname eq "" || 
                   (!($dataobj->ValidateSystemname($sysname)))){
                  $sysname=$parrec->{id};
               }
             
               if ($rec->{name} ne $sysname){
                  $dataobj->ResetFilter();
                  $dataobj->SetFilter({name=>\$sysname,id=>"!".$rec->{id}});
                  my ($chkrec,$msg)=$dataobj->getOnlyFirst(qw(id name));
                  if (defined($chkrec)){
                     $parrec->{name}=$parrec->{id};
                  }
                  else{
                     $parrec->{name}=$sysname;
                  }
                  $self->IfComp($dataobj,
                                $rec,"name",
                                $parrec,"name",
                                $autocorrect,$forcedupd,$wfrequest,
                                \@qmsg,\@dataissue,\$errorlevel,
                                mode=>'string');
               }

               $self->IfComp($dataobj,
                             $rec,"cpucount",
                             $parrec,"cpucount",
                             $autocorrect,$forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'integer');

               $self->IfComp($dataobj,
                             $rec,"memory",
                             $parrec,"memory",
                             $autocorrect,$forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'integer');

               $self->IfComp($dataobj,
                             $rec,"osrelease",
                             $parrec,"image_name",
                             $autocorrect,$forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'leftouterlinkmissok',
                             iomapped=>$par);
               my $w5itcloudarea;
               if ($parrec->{accountid} ne ""){
                  msg(INFO,"try to add cloudarea to system ".$rec->{name});
                  my $cloudarea=getModuleObject($self->getParent->Config,
                                                "itil::itcloudarea");
                  $cloudarea->SetFilter({cloud=>'AWS',
                                         srcid=>$parrec->{accountid}
                  });
                  my ($w5cloudarearec,$msg)=$cloudarea->getOnlyFirst(qw(ALL));
                  if (defined($w5cloudarearec)){
                     $w5itcloudarea=$w5cloudarearec;
                     if ($w5cloudarearec->{cistatusid} eq "4" &&
                         $w5cloudarearec->{applid} ne ""){
                        if ($rec->{itcloudareaid} ne $w5cloudarearec->{id}){
                           $forcedupd->{itcloudareaid}= $w5cloudarearec->{id};
                        }
                     }
                  }
                  else{
                     msg(ERROR,"found AWS System $rec->{name} ".
                               "on invalid cloudarea");
                     die();
                  }
               }
               if ($autocorrect){
                  my $net=getModuleObject($self->getParent->Config(),
                          "TS::network");
                  my $netarea=$net->getTaggedNetworkAreaId();

                  #############################################################
       
                  my @opList;
                  my %cleanAWSIflist;
                  for(my $i=0;$i<=$#{$parrec->{ipaddresses}};$i++){
                     my $otciprec=$parrec->{ipaddresses}->[$i];
                     if ($otciprec->{ifname} ne ""){
                        $cleanAWSIflist{$otciprec->{ifname}}={
                           mac=>$otciprec->{mac},
                           name=>$otciprec->{ifname}
                        };
                     }
                  }
                  my @cleanAWSIPlist=@{$parrec->{ipaddresses}};

                  my $res=OpAnalyse(
                             sub{  # comperator 
                                my ($a,$b)=@_;
                                my $eq;
                                if ($a->{name} eq $b->{name}){
                                  $eq=0;
                                  if ($a->{srcsys} eq "AWS" &&
                                      $a->{ifname} eq $b->{ifname} &&
                                      $a->{dnsname} eq $b->{dnsname} &&
                                      $a->{itcloudareaid} eq 
                                                 $w5itcloudarea->{id} &&
                                      $a->{cistatusid} eq "4"){
                                     $eq=1;
                                  }
                                  else{
                                  }
                                }
                                return($eq);
                             },
                             sub{  # oprec generator
                                my ($mode,$oldrec,$newrec,%p)=@_;
                                if ($mode eq "insert" || $mode eq "update"){
                                   my $networkid=$netarea->{ISLAND};
                                   my $identifyby=undef;
                                   if ($mode eq "update"){
                                      $identifyby=$oldrec->{id};
                                   }
                                   my $type="1";   # secondary
                                   my $oprec={
                                     OP=>$mode,
                                     MSG=>"$mode ip $newrec->{ipaddress} ".
                                          "in W5Base",
                                     IDENTIFYBY=>$identifyby,
                                     DATAOBJ=>'itil::ipaddress',
                                     DATA=>{
                                      name         =>$newrec->{name},
                                      cistatusid   =>"4",
                                      srcsys       =>'AWS',
                                      type         =>$type,
                                      ifname       =>$newrec->{ifname},
                                      dnsname      =>$newrec->{dnsname},
                                      itcloudareaid=>$w5itcloudarea->{id},
                                      systemid     =>$p{refid}
                                     }
                                   };
                                   if ($mode eq "insert"){
                                      $oprec->{DATA}->{networkid}=$networkid;
                                   }
                                   return($oprec);
                                }
                                elsif ($mode eq "delete"){
                                   my $networkid=$oldrec->{networkid};
                                   return({OP=>$mode,
                                           MSG=>"delete ip $oldrec->{name} ".
                                               "from W5Base",
                                           DATAOBJ=>'itil::ipaddress',
                                           IDENTIFYBY=>$oldrec->{id},
                                           });
                                }
                                return(undef);
                             },
                             $rec->{ipaddresses},\@cleanAWSIPlist,\@opList,
                             refid=>$rec->{id});
                  #printf STDERR Dumper(\@opList);
                  if (!$res){
                     my $opres=ProcessOpList($self->getParent,\@opList);
                  }

                  # Zielnetzwerke festlegen und prüfen ob frei
                  my @otcip=map({$_->{name}} @{$parrec->{ipaddresses}});
                  my %otcip;
                  foreach my $iprec (@{$parrec->{ipaddresses}}){
                     push(@otcip,$iprec->{name});
                     $otcip{$iprec->{name}}={networkid=>$netarea->{ISLAND}};
                     $otcip{$iprec->{name}}->{NetareaTag}=$iprec->{netareatag};
                  }
                  my $ip=getModuleObject($self->getParent->Config(),
                                                "itil::ipaddress");
                  $ip->switchSystemIpToNetarea(
                     \%otcip,$rec->{id},$netarea,\@qmsg
                  );

                  my @cleanAWSIflist=values(%cleanAWSIflist);
                  @opList=();
                  my $res=OpAnalyse(
                             sub{  # comperator 
                                my ($a,$b)=@_;
                                my $eq;
                                if ($a->{name} eq $b->{name}){
                                   $eq=0;
                                   $eq=1 if ( $a->{mac} eq $b->{mac});
                                }
                                return($eq);
                             },
                             sub{  # oprec generator
                                my ($mode,$oldrec,$newrec,%p)=@_;
                                if ($mode eq "insert" || $mode eq "update"){
                                   #if ($mode eq "insert" && 
                                   #    $newrec->{cistatusid} eq "6"){
                                   #   return(); # do not insert 
                                   #             # already unconfigured ip's
                                   #}
                                   my $identifyby=undef;
                                   if ($mode eq "update"){
                                      $identifyby=$oldrec->{id};
                                   }
                                   if ($newrec->{name}=~m/^\s*$/){
                                      $mode="nop";
                                   }
                                   return({OP=>$mode,
                                           MSG=>"$mode if $newrec->{name} ".
                                                "in W5Base",
                                           IDENTIFYBY=>$identifyby,
                                           DATAOBJ=>'itil::sysiface',
                                           DATA=>{
                                              name      =>$newrec->{name},
                                              mac       =>$newrec->{mac},
                                              srcsys    =>'AWS',
                                              systemid  =>$p{refid}
                                              }
                                           });
                                }
                                elsif ($mode eq "delete"){
                                   return({OP=>$mode,
                                           MSG=>"delete if $oldrec->{name} ".
                                               "from W5Base",
                                           DATAOBJ=>'itil::sysiface',
                                           IDENTIFYBY=>$oldrec->{id},
                                           });
                                }
                                return(undef);
                             },
                             $rec->{sysiface},\@cleanAWSIflist,\@opList,
                             refid=>$rec->{id});
                  if (!$res){
                     my $opres=ProcessOpList($self->getParent,\@opList);
                  }

               }
            }




#            if (!($parrec->{availability_zone}=~m/^eu[0-9a-z-]{3,10}$/)){
#               my $msg='invalid availability zone from AWS';
#               push(@qmsg,$msg);
#               push(@dataissue,$msg);
#               $errorlevel=3 if ($errorlevel<3);
#            }
#            else{  # handling AssetID
#               my $ass=getModuleObject($self->getParent->Config(),
#                                       "itil::asset");
#               my $otclabel="AWS: Availability Zone";
#               my $k="$otclabel ".$parrec->{availability_zone};
#               msg(INFO,"checking assetid for '$k'");
#               $ass->SetFilter({
#                  kwords=>\$k,
#                  cistatusid=>[4],
#                  srcsys=>\'w5base'
#               }); 
#               my @l=$ass->getHashList(qw(id name fullname));
#               if ($#l==-1){
#                  my $msg='can not identify availability zone asset from AWS';
#                  push(@qmsg,$msg);
#                  push(@dataissue,$msg);
#                  $errorlevel=3 if ($errorlevel<3);
#
#                  # try to notify
#                  $ass->ResetFilter();
#                  $ass->SetFilter({
#                     kwords=>"\"$otclabel *\"",
#                     cistatusid=>[4],
#                     srcsys=>\'w5base'
#                  }); 
#                  my @l=$ass->getHashList(qw(id databossid));
#                  my %uid;
#                  foreach my $arec (@l){
#                     if ($arec->{databossid} ne ""){
#                        $uid{$arec->{databossid}}++;
#                     }
#                  }
#                  if (keys(%uid)){
#                     my $wfa=getModuleObject($ass->Config,"base::workflowaction");
#                     $wfa->Notify("ERROR","missing AWS Asset for $parrec->{availability_zone}",
#                        "Ladies and Gentlemen,\n\n".
#                        "Please create an asset record in it-inventory\n".
#                        "for AWS availability zone ".
#                        "with '$k' in keywords.\n\n".
#                        "(as already done, like for other availability zones)",
#                        emailto=>[keys(%uid)],
#                        emailbcc=>[
#                           11634953080001, # HV
#                        ]
#                     );
#
#
#                  }
#               }
#               elsif ($#l>0){
#                  my $msg='availability zone asset not unique from AWS';
#                  push(@qmsg,$msg);
#                  push(@dataissue,$msg);
#                  $errorlevel=3 if ($errorlevel<3);
#               }
#               else{
#                  $self->IfComp($dataobj,
#                                $rec,"asset",
#                                {assetassetid=>$l[0]->{name}},"assetassetid",
#                                $autocorrect,$forcedupd,$wfrequest,
#                                \@qmsg,\@dataissue,\$errorlevel,
#                                mode=>'leftouterlink');
#               }
#            }
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
