package tsacinv::qrule::compareCluster;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This quality rule compares a W5Base cluster to an AssetManager cluster
and updates on demand necessary fields.
If there were found more than one Cluster services (Cluster-Packages)
with the same name in AssetManager or if the Cluster name in
AssetManager contains prohibited characters, an error is generated.

=head3 IMPORTS

- name of cluster

=head3 HINTS

More than one cluster packages with the same name, which are not in 
status 'out of operation', are not allowed in AssetManager.

The following characters only are allowed in Cluster name: a-zA-Z0-9_-

In case of an error, please contact a person which is responsible
for the data management in AssetManager.

[de:]

Gleichnamige Cluster-Packages, die nicht im Status 'out of operation' sind,
dürfen in AssetManager nicht vorkommen.

Im Cluster-Namen sind ausschließlich folgende Zeichen erlaubt: a-zA-Z0-9_-

Im Fehlerfall kontaktieren Sie bitte einen für die Pflege der Daten in
AssetManager zuständigen Ansprechpartner.


=cut
#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
   return(["itil::itclust","AL_TCom::itclust"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=shift;

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   return(0,undef) if ($rec->{cistatusid}!=4);

   my ($parrec,$msg);
   my $par=getModuleObject($self->getParent->Config(),"tsacinv::itclust");


   #
   # Level 0
   #
   if ($rec->{clusterid} ne ""){   # pruefen ob SYSTEMID von AssetManager
      $par->SetFilter({clusterid=>\$rec->{clusterid}});
      ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      return(undef,undef) if (!$par->Ping());
      if (!defined($parrec)){
         if ($rec->{clusterid} ne $rec->{id}){
            # hier koennte u.U. noch eine Verbindung zu AM über
            # den Namen aufgebaut werden
         }
      }
   }

   #
   # Level 1
   #
   if (!defined($parrec)){      # pruefen ob wir bereits nach AM geschrieben
      # try to find parrec by srcsys and srcid
      $par->ResetFilter();
      $par->SetFilter({srcsys=>\'W5Base',srcid=>\$rec->{id}});
      ($parrec)=$par->getOnlyFirst(qw(ALL));
   }

   #
   # Level 2
   #
   if (defined($parrec)){
      if ($rec->{clusterid} ne $parrec->{clusterid}){
         $forcedupd->{clusterid}=$parrec->{clusterid};
      }
      if ($parrec->{srcsys} eq "W5Base"){
         if ($rec->{srcsys} ne "w5base"){
            $forcedupd->{srcsys}="w5base";
         }
         if ($rec->{srcid} ne ""){
            $forcedupd->{srcid}=undef;
         }
      }
      else{
         if ($rec->{srcsys} ne "AssetManager"){
            $forcedupd->{srcsys}="AssetManager";
         }
         if ($rec->{srcid} ne $parrec->{clusterid}){
            $forcedupd->{srcid}=$parrec->{clusterid};
         }
         $forcedupd->{srcload}=NowStamp("en");
      }
   }

   #
   # Level 3
   #

   if ($rec->{cistatusid}==4 || $rec->{cistatusid}==3 ||
       $rec->{cistatusid}==5){
      if ($rec->{srcid} ne "" && $rec->{srcsys} eq "AssetManager"){
         if (!defined($parrec)){
            push(@qmsg,
                 'given clusterid not found as active in AssetManager');
            push(@dataissue,
                 'given clusterid not found as active in AssetManager');
            $errorlevel=3 if ($errorlevel<3);
         }


         ####################################################################### 
         # create data issue, if multiple services with same name
         # but different serviceids in AM;
         # to avoid duplicate entry in lnkitclustsvc

         my %svccnt;
         foreach my $svc (@{$parrec->{services}}) {
            if (lc($svc->{status}) ne 'out of operation') {
               $svccnt{$svc->{name}}++;
            }
         }
         my @dupsvc=grep({$svccnt{$_}>1} keys(%svccnt));

         if ($#dupsvc!=-1) {
            my $msg="Multiple cluster services with same name ".
                    "found in AssetManager: ";
            $msg.="@dupsvc";
            $errorlevel=3 if ($errorlevel<3);
            
            return(3,{qmsg=>$msg,dataissue=>$msg});
         }
         ####################################################################### 

         $self->IfComp($dataobj,
                       $rec,"name",
                       $parrec,"name",
                       $autocorrect,$forcedupd,$wfrequest,
                       \@qmsg,\@dataissue,\$errorlevel,
                       mode=>'string');
         my @opList;
         my $res=OpAnalyse(
                    sub{  # comperator 
                       my ($a,$b)=@_;
                       my $eq;
                       # Primärer Vergleich darf NUR auf den Namen erfolgen,
                       # da es ansonsten zu Key-Fehlern kommt, wenn dem gleichen
                       # Namen eine neue ClusterPackageID "verpasst" wurde.
                       if (lc($a->{name}) eq lc($b->{name})){
                          $eq=0;
                          $eq=1 if ($a->{comments} eq $b->{usage} &&
                                    lc($a->{name}) eq lc($b->{name}) &&
                                    $a->{itservid} eq $b->{serviceid});
                       }
                       # $eq undef= Record needs to be inserted
                       # $eq   0  = Record needs to be updated
                       # $eq   1  = Record is perfect equal and no update needed
                       return($eq);
                    },
                   sub{  # oprec generator
                       my ($mode,$oldrec,$newrec,%p)=@_;
                       if ($mode eq "insert" || $mode eq "update"){
                          my $identifyby=undef;
                          if ($mode eq "update"){
                             $identifyby=$oldrec->{id};
                          }
                          my $opl="";
                          $opl.=$newrec->{name} if ($newrec->{name} ne "");
                          $opl.=" "  if ($opl ne "" && 
                                         $newrec->{serviceid} ne "");
                          if ($newrec->{serviceid} ne ""){
                             $opl.="(ClusterServiceID:".
                                   $newrec->{serviceid}.")";
                          }
                          return({OP=>$mode,
                                  OPLABEL=>$opl,
                                  MSG=>
                                     "$mode ClustService $newrec->{serviceid} ".
                                     "in W5Base",
                                  IDENTIFYBY=>$identifyby,
                                  DATAOBJ=>'itil::lnkitclustsvc',
                                  DATA=>{
                                     name      =>$newrec->{name},
                                     itservid  =>$newrec->{serviceid},
                                     comments  =>$newrec->{usage},
                                     clustid   =>$p{refid}
                                     }
                                  });
                       }
                       elsif ($mode eq "delete"){
                          if ($oldrec->{itservid} ne ""){
                             my $itclustsvc=getModuleObject(
                                $self->getParent->Config(),
                                "itil::lnkitclustsvc");
                             $itclustsvc->SetFilter({id=>\$oldrec->{id}});
                             my ($svc,$msg)=$itclustsvc->getOnlyFirst(qw(ALL));
                             if (defined($svc)){
                                if ($#{$svc->{swinstances}}!=-1){
                                   push(@qmsg,"cluster services invalid but ".
                                              "automatic delete not posible ".
                                              "(manual cleanup nessesary)");
                                   return();
                                }
                             }
                             my @dropop=({OP=>$mode,
                                     OPLABEL=>$oldrec->{fullname},
                                     MSG=>"delete ClustService $oldrec->{name} ".
                                          "from W5Base",
                                     DATAOBJ=>'itil::lnkitclustsvc',
                                     IDENTIFYBY=>$oldrec->{id},
                                     });


                             return(@dropop);
                          }
                       }
                       return(undef);
                    },
                    $rec->{services},$parrec->{services},\@opList,
                    refid=>$rec->{id});
          if (!$res){
             if ($rec->{allowifupdate}==1){
                my $opres=ProcessOpList($self->getParent,\@opList);
             }
             else{
                #
                # this can be in the future maybe a seperate function
                #
                @opList=grep({$_->{OP} ne "update"} @opList);
                
                if ($#opList!=-1){
                   push(@qmsg,"cluster services needs correction");
                   foreach my $oprec (@opList){
                      if ($oprec->{OP} eq "delete"){
                         push(@qmsg,"delete needed for: ".
                                    $oprec->{OPLABEL});
                      }
                      elsif ($oprec->{OP} eq "insert"){
                         push(@qmsg,"insert needed for: ".
                                    $oprec->{OPLABEL});
                      }
                   #   elsif ($oprec->{OP} eq "update"){    # update only
                   #      push(@qmsg,"update needed for: ". # in 
                   #                 $oprec->{OPLABEL});    # allowifupdate
                   #   }                                    # mode needed
                   }
                   push(@dataissue,"cluster service list inconsistent to ".
                                   "AssetManager");
                   $errorlevel=3 if ($errorlevel<3);
                }
                ##########################################################
             }
          }
      }
   }

   if (keys(%$forcedupd)){
      if (exists($forcedupd->{name}) &&
          $forcedupd->{name}=~m/[^-a-z0-9_]/i) {
         my $msg="prohibited characters found in AssetManager Cluster name: ".
                 $forcedupd->{name};
         push(@qmsg,$msg);
         push(@dataissue,$msg);
         $errorlevel=3 if ($errorlevel<3);
      }
      elsif ($dataobj->ValidatedUpdateRecord($rec,$forcedupd,
             {id=>\$rec->{id}})){
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
      my $msg="different values stored in AssetManager: ";
      push(@qmsg,$msg);
      push(@dataissue,$msg);
      $errorlevel=3 if ($errorlevel<3);
   }


   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}



1;
