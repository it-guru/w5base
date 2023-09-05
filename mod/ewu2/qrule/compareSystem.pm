package ewu2::qrule::compareSystem;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This QualityRule compares a W5Base/Darwin logical system to an ewu2
logical system and updates the defined fields if necessary. Automated
imports are only done if the field "Allow automatic interface updates"
is set to "yes". If a logical system is a workstation, no DataIssue Workflow
about a missing System ID is created. 

=head3 IMPORTS

The fields Memory, CPU-Count, CO-Number, Description, Systemname
are imported from ewu2. IP-Addresses can only be synced when the field 
"Allow automatic interface updates" is set to "yes". If the Mandator is set to
"Extern" and "Allow automatic interface updates" is set to "yes" some aditional

=head3 HINTS

[en:]


[de:]



=cut

#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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

   return(undef,undef) if ($rec->{srcsys} ne "EWU2");

   my ($parrec,$msg);
   my $par=getModuleObject($self->getParent->Config(),"ewu2::system");
   return(undef,undef) if (!$par->Ping());


   #
   # Level 1
   #
   if (!defined($parrec)){      # pruefen ob wir bereits nach AM geschrieben
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
   if ($rec->{cistatusid}==4 || $rec->{cistatusid}==3 ||
       $rec->{cistatusid}==5){
      if ($rec->{srcid} ne "" && $rec->{srcsys} eq "EWU2"){
         if (defined($parrec) && lc($parrec->{status}) ne "up"){
            my $d=CalcDateDuration($parrec->{mdate},NowStamp("en"));
            if (defined($d) && $d->{totaldays}>14){
               push(@qmsg,'auto deactivation of ewu2 logical system');
               $forcedupd->{cistatusid}="6";
               $checksession->{EssentialsChangedCnt}++;
            }
         }

         if (!defined($parrec) || lc($parrec->{status}) ne "up"){
            push(@qmsg,'given DevLabSystemID not found as up in ewu2');
            push(@dataissue,'given DevLabSystemID not found as up in ewu2');
            $errorlevel=3 if ($errorlevel<3);
         }
         else{
            if (in_array($dataobj->needVMHost(),$rec->{systemtype})){
               msg(INFO,"need to check vmhost ".
                        "vhostsystemid:$rec->{vhostsystemid}");

               my $sys=getModuleObject($dataobj->Config,"itil::system");
               $sys->SetFilter({
                  cistatusid=>'4',
                  srcsys=>'EWU2',
                  srcid=>\$parrec->{hostingcsid}
               });
               my ($vmrec,$msg)=$sys->getOnlyFirst(qw(ALL));
               if (!defined($vmrec)){
                  $par->ResetFilter();
                  $par->SetFilter({id=>\$parrec->{hostingcsid},
                                   status=>"up"});
                  my ($newVMHostrec,$msg)=$par->getOnlyFirst(qw(ALL));
                  if (defined($newVMHostrec)){
                     msg(INFO,"try to import $parrec->{hostingcsid}");
                     my $pid=$par->Import({
                         importname=>$parrec->{hostingcsid},
                         databossid=>$rec->{databossid},
                         mandatorid=>$rec->{mandatorid}
                     });
                     if (defined($pid)){
                        $forcedupd->{vhostsystemid}=$pid;
                        $checksession->{EssentialsChangedCnt}++;
                     }
                     else{
                        # DataIssue
                     }
                  }
                  else{
                     msg(INFO,"new vmhost $parrec->{hostingcsid} is not up -".
                              " import disabled");
                  }
               }
               else{
                  if ($rec->{vhostsystemid} ne $vmrec->{id}){
                     $forcedupd->{vhostsystemid}=$vmrec->{id};
                     $checksession->{EssentialsChangedCnt}++;
                  }
               }
            }
            else{
               my $w5assetid=$rec->{assetid};
               my ($hwrec,$msg)=$par->ImportAsset(
                               $parrec->{physicalelementid},
                               $rec->{mandatorid},$rec->{databossid});
               if (!defined($hwrec)){
                  $self->LastMsg(ERROR,"EWU2 incomplete: ".
                                 "asset ".$parrec->{asset}.
                                 " needs to be imported at first");
                  return(undef);
               }
               if ($w5assetid ne $hwrec->{id}){
                  $forcedupd->{assetid}=$hwrec->{id};
                  $checksession->{EssentialsChangedCnt}++;
               }
            }

            ############################################################### 

            if (defined($parrec->{systemname})){
               $parrec->{systemname}=lc($parrec->{systemname});
               $parrec->{systemname}=~s/\..*$//; # remove posible Domain part 
            }
            my $nameok=1;
            if ($parrec->{systemname} ne $rec->{name} &&
                ($parrec->{systemname}=~m/\s/)){
               $nameok=0;
               my $m='systemname with whitespace in ewu2 - '.
                     'contact oss to fix this!';
               push(@qmsg,$m);
               push(@dataissue,$m);
               $errorlevel=3 if ($errorlevel<3);
            }
            if ($parrec->{systemname}=~m/\.\S{1,3}$/){
               $parrec->{systemname}=~s/\..*//;
               my $m='systemname with DNS Domain in ewu2 - '.
                     'contact oss to fix this!';
               push(@qmsg,$m);
               push(@dataissue,$m);
               $errorlevel=3 if ($errorlevel<3);
            }

            if ($parrec->{systemname}=~m/^\s*$/){  # könnte notwendig werden!
               $nameok=0;
               push(@qmsg,'systemname from ewu2 not useable - '.
                          'contact oss to fix this!');
               $errorlevel=3 if ($errorlevel<3);
            }
            if ($nameok){
               $dataobj->ResetFilter();
               $dataobj->SetFilter({name=>\$parrec->{systemname},
                                    id=>"!".$rec->{id}});
               my ($chkrec,$msg)=$dataobj->getOnlyFirst(qw(id name));
               if (defined($chkrec)){
                  $nameok=0;
                  my $m='systemname from ewu2 is already in use '.
                        'by an other system - '.
                        'contact DevLab to make the systemname unique!';
                  push(@qmsg,$m);
                  push(@dataissue,$m);
                  $errorlevel=3 if ($errorlevel<3);
               }
            }

            if ($nameok){
               $self->IfComp($dataobj,
                             $rec,"name",
                             $parrec,"systemname",
                             $autocorrect,$forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'string');
            }
            $self->IfComp($dataobj,
                          $rec,"cpucount",
                          $parrec,"cpucorestotal",
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
                          $parrec,"osrelease",
                          $autocorrect,$forcedupd,$wfrequest,
                          \@qmsg,\@dataissue,\$errorlevel,
                          mode=>'leftouterlinkbaselogged',
                          iomapped=>$par);
            if ($rec->{allowifupdate}){
               my $net=getModuleObject($self->getParent->Config(),
                       "itil::network");
               $net->SetCurrentView(qw(id name));
               my $netarea=$net->getHashIndexed("name");
               my @opList;

               #
               # %cleanAmIPlist is neassasary, because multiple IP-Addresses
               # can be in one networkcard record
               #
               my %cleanAmIPlist;
               foreach my $ewuiprec (@{$parrec->{ipaddresses}}){
                  my $mappedCIStatus=4;
                  if ($ewuiprec->{name} ne ""){
                     if ($ewuiprec->{name}=~
                         m/^\d{1,3}(\.\d{1,3}){3,3}$/){
                        $cleanAmIPlist{$ewuiprec->{name}}={
                           cistatusid=>$mappedCIStatus,
                           ipaddress=>$ewuiprec->{name},
                           comments=>trim($ewuiprec->{comments})
                        };
                     }
                     else{
                        msg(WARN,"ignoring IPv4 invalid ".
                                 "'$ewuiprec->{name}' ".
                                 "for $parrec->{id}");
                     }
                  }
               }
               my @cleanAmIPlist=values(%cleanAmIPlist);

               my $res=OpAnalyse(
                          sub{  # comperator 
                             my ($a,$b)=@_;
                             my $eq;
                             if ($a->{name} eq $b->{ipaddress}){
                                $eq=0;
                                $eq=1 if ($a->{srcsys} eq "EWU2" &&
                                          $a->{cistatusid} eq 
                                          $b->{cistatusid}       &&
                                          $a->{comments} eq 
                                          $b->{comments});
                             }
                             return($eq);
                          },
                          sub{  # oprec generator
                             my ($mode,$oldrec,$newrec,%p)=@_;
                             if ($mode eq "insert" || $mode eq "update"){
                                if ($mode eq "insert" && 
                                    $newrec->{cistatusid} eq "6"){
                                   return(); # do not insert 
                                             # already unconfigured ip's
                                }
                                my $networkid=$p{netarea}->{name}->
                                            {'Insel-Netz/Kunden-LAN'}->{id};
                                my $identifyby=undef;
                                if ($mode eq "update"){
                                   $identifyby=$oldrec->{id};
                                }
                                if ($newrec->{ipaddress}=~m/^\s*$/){
                                   $mode="nop";
                                }
                                my $type="1";   # secondary
                                # Customer Interface can not be marked
                                # as primary interface, because in some
                                # cases multiple customer interfaces
                                # exists in ewu2 Rotz.
                                #
                                #if (lc(trim($newrec->{description})) eq
                                #    "customer"){
                                #   $type="0"; # Customer Interface is prim
                                #}
                                return({OP=>$mode,
                                        MSG=>"$mode ip $newrec->{ipaddress} ".
                                             "in W5Base",
                                        IDENTIFYBY=>$identifyby,
                                        DATAOBJ=>'itil::ipaddress',
                                        DATA=>{
                                           name      =>$newrec->{ipaddress},
                                           cistatusid=>$newrec->{cistatusid},
                                           srcsys    =>'EWU2',
                                           type      =>$type,
                                           networkid =>$networkid,
                                           comments  =>$newrec->{comments},
                                           systemid  =>$p{refid}
                                           }
                                        });
                             }
                             elsif ($mode eq "delete"){
                                my $networkid=$oldrec->{networkid};
                                if ($networkid ne $p{netarea}->{name}->
                                                  {'Insel-Netz/Kunden-LAN'}->{id}){
                                   return();
                                }
                                return({OP=>$mode,
                                        MSG=>"delete ip $oldrec->{name} ".
                                             "from W5Base",
                                        DATAOBJ=>'itil::ipaddress',
                                        IDENTIFYBY=>$oldrec->{id},
                                        });
                             }
                             return(undef);
                          },
                          $rec->{ipaddresses},\@cleanAmIPlist,\@opList,
                          refid=>$rec->{id},netarea=>$netarea);
               if (!$res){
                  my $opres=ProcessOpList($self->getParent,\@opList);
               }
            }
         }
      }
   }

   if (keys(%$forcedupd)){
      if ($dataobj->ValidatedUpdateRecord($rec,$forcedupd,{id=>\$rec->{id}})){
         my @fld=grep(!/^srcload$/,keys(%$forcedupd));
         if ($#fld!=-1){
            push(@qmsg,"all desired fields has been updated: ".join(", ",@fld));
         }
      }
      else{
         push(@qmsg,$self->getParent->LastMsg());
         $errorlevel=3 if ($errorlevel<3);
      }
   }
   if (keys(%$wfrequest)){
      my $msg="different values stored in ewu2: ";
      push(@qmsg,$msg);
      push(@dataissue,$msg);
      $errorlevel=3 if ($errorlevel<3);
   }
   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}



1;
