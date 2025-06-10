package TS::qrule::AssetManagerInstanceImport;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Import handler for SAP Software-Instances from AssetManager

=head3 IMPORTS

NONE

=head3 HINTS
no hints

[de:]

keine Tips

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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
   return(["TS::appl"]);
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

   my $srcsys="AssetManagerApplInstSAP";

   my $applid=$rec->{applid};

   return(undef) if (!($applid=~m/^APPL\d+$/));

   my $amif=getModuleObject($dataobj->Config,"tsacinv::lnkapplappl");
   my $amappl=getModuleObject($dataobj->Config,"tsacinv::appl");
   my $w5sys=getModuleObject($dataobj->Config,"itil::system");
   my $w5swi=getModuleObject($dataobj->Config,"itil::swinstance");

   $amif->SetFilter({
      parent_applid=>\$applid,
      deleted=>\'0',
      type=>\'SAP'
   });

   my @preList=$amif->getHashList(qw(id child_applid parent 
                                     child type mdate parent_applid));
   my %uList;
   my %uNames;
   foreach my $ifrec (@preList){
      my $k=$ifrec->{parent_applid}.":".$ifrec->{child_applid};
      $uNames{$ifrec->{child}}++;
      if (!exists($uList{$k})){
         $uList{$k}=$ifrec;
      }
   }

   if (keys(%uNames)){
      my %pApplidByChild;
      $amif->ResetFilter();
      $amif->SetFilter({
         child=>[sort(keys(%uNames))],
         deleted=>\'0',
         type=>\'SAP'
      });

      my @chklist=$amif->getHashList(qw(id child_applid parent 
                                        child type mdate parent_applid));
      foreach my $chkrec (@chklist){
         my $curNum=999999999999;
         my $chkNum=$chkrec->{parent_applid};
         $chkNum=~s/[^0-9]//g;
         if (exists($pApplidByChild{$chkrec->{child}})){
            $curNum=$pApplidByChild{$chkrec->{child}};
            $curNum=~s/[^0-9]//g;
         }
         
         if ($curNum>$chkNum){
            $pApplidByChild{$chkrec->{child}}=$chkrec->{parent_applid};
         }
      }
      foreach my $k (keys(%uList)){  # remove duplicates with lower applid
         foreach my $childName (keys(%pApplidByChild)){
            if ($uList{$k}->{child} eq $childName){
               if ($uList{$k}->{parent_applid} ne $pApplidByChild{$childName}){
                  msg(INFO,"drop instance ".$uList{$k}->{child}." ".
                           "in faver of $pApplidByChild{$childName}");
                  delete($uList{$k});
               }
            }
         }
      }
   }

   my @l=values(%uList);

   my %childapplid;
   my $cappldata={};

   my $amsysidrec={};
   my %sysids;

   if ($#l!=-1){
      foreach my $amrec (@l){
         $childapplid{$amrec->{child_applid}}++;
      }
      $amappl->SetFilter({applid=>[keys(%childapplid)]});
      $amappl->SetCurrentView(qw(applid name prodcomp systems));
      $cappldata=$amappl->getHashIndexed(qw(applid));
      foreach my $applid (keys(%childapplid)){
         if (exists($cappldata->{applid}->{$applid})){
            foreach my $sysrec (@{$cappldata->{applid}->{$applid}->{systems}}){
               $sysids{$sysrec->{systemid}}++;
            }
         }
      }
   }
   if (keys(%sysids)){
      $w5sys->SetFilter({systemid=>[keys(%sysids)],cistatusid=>"<6"});
      $w5sys->SetCurrentView(qw(id systemid name));
      my $w5systems=$w5sys->getHashIndexed(qw(systemid));
      foreach my $systemid (keys(%{$w5systems->{systemid}})){
         $sysids{$systemid}=$w5systems->{systemid}->{$systemid};
      }
   }

   foreach my $systemid (keys(%sysids)){
      if (ref($sysids{$systemid}) ne "HASH"){
         my $msg="missing AssetManager import of logical system: ".$systemid;
         push(@qmsg,$msg);
         push(@dataissue,$msg);
         delete($sysids{$systemid});
         $errorlevel=3 if ($errorlevel<3);
      }
   }

   my @swisoll;
   my %CurSrcidList;
   foreach my $childrec (@l){
      my %sysnameProcessed;
      my $applid=$childrec->{child_applid};
      next if ($applid eq "");
      next if (!exists($cappldata->{applid}->{$applid}));
      my $amapplrec=$cappldata->{applid}->{$applid};
      foreach my $sysrec (@{$amapplrec->{systems}}){
         my $systemid=$sysrec->{systemid};
         next if (!($sysrec->{child}=~m/^SEC/i));
         next if ($systemid eq "");
         next if (!exists($sysids{$systemid}));
         next if (exists($sysnameProcessed{$sysids{$systemid}->{name}}));
         my $prodcomp=$amapplrec->{prodcomp};
         $prodcomp=~s/\s*standalone\s*//;
         $prodcomp=~s/ /_/g;
         $prodcomp=$prodcomp."@" if ($prodcomp ne "");
         my $instancename=$childrec->{child};
         $instancename=~s/\s+/_/g;
         if (length($instancename)>39){
            $instancename=substr($instancename,0,39);
         }
         my $swrec={
            name=>$instancename,
            cistatusid=>'4',
            swtype=>'primary',
            applid=>$rec->{id},
            mandatorid=>$rec->{mandatorid},
            databossid=>$rec->{databossid},
            addname=>$prodcomp.$sysids{$systemid}->{name},
            systemid=>$sysids{$systemid}->{id},
            srcsys=>$srcsys,
            srcid=>$childrec->{child_applid}.":".$sysids{$systemid}->{systemid}
         };
         $sysnameProcessed{$sysids{$systemid}->{name}}++; 
         $CurSrcidList{$swrec->{srcid}}++;
         push(@swisoll,$swrec);
         
      }
   }

   my @flt=(
       {applid=>\$rec->{id},srcsys=>\$srcsys}
   );
   if (keys(%CurSrcidList)){
      push(@flt,{srcsys=>\$srcsys,srcid=>[keys(%CurSrcidList)]});
   }
   $w5swi->SetFilter(\@flt);

   my @cur=$w5swi->getHashList(qw(name mandatorid cistatusid swtype
                                  applid databossid
                                  fullname srcsys srcid srcload));
   my @opList;
   my $res=kernel::QRule::OpAnalyse(
      sub{  # comperator
         my ($a,$b)=@_;   # a=swisoll b=curlist in W5Base
         my $eq;          # undef= nicht gleich

         if ( $a->{srcid} eq $b->{srcid} &&
              $a->{mandatorid} eq $b->{mandatorid}){
            $eq=0;  # rec found - aber u.U. update notwendig
            if (lc($a->{name}) eq lc($b->{name}) &&
                $a->{applid} eq $b->{applid}  &&
                $a->{databossid} eq $b->{databossid}  &&
                $a->{addname} eq $b->{addname}  &&
                $a->{swtype} eq $b->{swtype}  &&
                $a->{cistatusid} eq $b->{cistatusid}){
               $eq=1;   # alles gleich - da braucht man nix machen
            }
         }
         return($eq);
      },
      sub{  # oprec generator
         my ($mode,$oldrec,$newrec,%p)=@_;
         if ($mode eq "insert" || $mode eq "update"){
            my $oprec={
               OP=>$mode,
               DATAOBJ=>'itil::swinstance',
               DATA=>$newrec
            };
            if ($mode eq "update"){
               $oprec->{IDENTIFYBY}=$oldrec->{id};
            }
            return($oprec);
         }
         elsif ($mode eq "delete"){
            my $oprec={
               OP=>"update",
               DATAOBJ=>'itil::swinstance',
               IDENTIFYBY=>$oldrec->{id},
               DATA=>{
                  name  =>$oldrec->{name},
                  cistatusid  =>6
               }
            };
            return(undef) if ($oldrec->{cistatusid} eq "6");
            return($oprec);
         }

         return(undef);
      },
      \@cur,\@swisoll,\@opList
   );
   foreach my $oprec (@opList){
      if ($oprec->{OP} eq "insert"){
         push(@qmsg,"add instance: ".$oprec->{DATA}->{name});
      }
      if ($oprec->{OP} eq "update" &&
          $oprec->{DATA}->{cistatusid} eq "6"){
         push(@qmsg,"delete instance: ".$oprec->{DATA}->{name});
      }
   }
   #printf STDERR ("opList=%s\n",Dumper(\@opList));

   if (!$res){
      my $opres=ProcessOpList($self->getParent,\@opList);
   }

   my @result=$self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}




1;
