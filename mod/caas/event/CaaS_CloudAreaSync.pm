package caas::event::CaaS_CloudAreaSync;
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
use kernel::Event;
use kernel::QRule;
@ISA=qw(kernel::Event);

sub Init
{
   my $self=shift;

   $self->RegisterEvent("CaaS_CloudAreaSync","CaaS_CloudAreaSync");
   return(1);
}

sub CaaS_CloudAreaSync
{
   my $self=shift;



   #######################################################################
   # CaaS Cloud-Enviroment-Sync
   #######################################################################

   my $caasCloud=getModuleObject($self->Config,"caas::cloud");
   $caasCloud->SetFilter({});
   my @tobeClouds=$caasCloud->getHashList(qw(id name fancyname));

   if ($#tobeClouds<1){
      msg(ERROR,"CaaS_CloudAreaSync not enough Cloud-Enviroments ".
                "on CaaS API found");
      return({exitcode=>'1'});
   }


   my $itcloud=getModuleObject($self->Config,"itil::itcloud");

   $itcloud->SetFilter({shortname=>'CAAS',cistatusid=>'4'});
   my @baseFields=qw(databossid platformrespid securityrespid supportid 
                     shortname srcid srcsys mandatorid);
   my @currClouds=$itcloud->getHashList(qw(+cdate name cistatusid),@baseFields);

   if ($#currClouds==-1){
      msg(ERROR,"CaaS_CloudAreaSync only working with one ".
                "shortname=CAAS cloud at leased");
      return({exitcode=>'1'});
   }

   my @opList=();
   my $res=kernel::QRule::OpAnalyse(
      sub{  # comperator
         my ($a,$b)=@_;   # a=lnkadditionalci b=aus AM
         my $eq;          # undef= nicht gleich
         if ( $a->{id} eq $b->{srcid} ||
              lc($a->{name}) eq lc($b->{fancyname})){
            $eq=0;  # rec found - aber u.U. update notwendig
            my $aname=$a->{name};
            $aname=~s/\[.*\]$//;
            my $bname=$b->{name};
            $bname=~s/\s+/_/g;
            if ($aname eq $bname &&
                $a->{cistatusid}<6 &&
                $a->{mandatorid} eq $currClouds[0]->{mandatorid} &&
                $a->{srcid} eq $b->{id}  &&
                $a->{name} eq $b->{fancyname}  &&
                $a->{srcsys} eq $self->Self()){
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
               DATAOBJ=>'itil::itcloud',
               DATA=>{
                  srcsys     => $self->Self(),
                  srcid      => $newrec->{id},
               }
            };
            if ($mode eq "insert"){
               $oprec->{DATA}->{name}=$newrec->{fancyname};
               $oprec->{DATA}->{cistatusid}='4';
               foreach my $dupFld (qw(databossid securityrespid platformrespid
                                      supportid shortname)){
                  $oprec->{DATA}->{$dupFld}=$currClouds[0]->{$dupFld};
               }
            }
            if ($mode eq "update"){
               if ($oldrec->{name} ne $newrec->{fancyname}){
                  $oprec->{DATA}->{name}=$newrec->{fancyname};
               }
               if ($oldrec->{mandatorid} ne $currClouds[0]->{mandatorid}){
                  $oprec->{DATA}->{mandatorid}=$currClouds[0]->{mandatorid};
               }
               if ($oldrec->{cistatusid}!=4){
                  $oprec->{DATA}->{cistatusid}="4";
               }
               $oprec->{IDENTIFYBY}=$oldrec->{id};
            }
            return($oprec);
         }
         elsif ($mode eq "delete"){
            # don't do any deletes (or mark deletes)
            return(undef);
         }
         return(undef);
      },
      \@currClouds,\@tobeClouds,\@opList
   );
   if (!$res){
      my $opres=ProcessOpList($itcloud,\@opList);
   }
   #######################################################################

   $itcloud->ResetFilter();
   $itcloud->SetFilter({shortname=>'CAAS',cistatusid=>'4'});
   my @baseFields=qw(databossid platformrespid securityrespid supportid 
                     shortname srcid srcsys mandatorid);
   $itcloud->SetCurrentView(qw(id srcid name));

   my $w5cloud=$itcloud->getHashIndexed(qw(srcid));

   #######################################################################


   #######################################################################
   # CaaS CloudArea-Sync
   #######################################################################

   my $caasCloudArea=getModuleObject($self->Config,"caas::project");
   $caasCloudArea->SetFilter({});
   my @tobeCloudAreas=$caasCloudArea->getHashList(qw(id name applid cloudid));

   if ($#tobeCloudAreas<10){
      msg(ERROR,"CaaS_CloudAreaSync not enough CloudAreas (Projects) ".
                "on CaaS API found");
      return({exitcode=>'1'});
   }


   my $itcloudarea=getModuleObject($self->Config,"itil::itcloudarea");

   $itcloudarea->SetFilter({srcsys=>$self->Self()});
   my @currCloudAreas=$itcloudarea->getHashList(qw(id 
                               cloudid srcsys srcid name fullname));

   my @opList=();
   my $res=kernel::QRule::OpAnalyse(
      sub{  # comperator
         my ($a,$b)=@_;   # a=lnkadditionalci b=aus AM
         my $eq;          # undef= nicht gleich
         if ( $a->{srcid} eq $b->{id} ){
            $eq=0;  # rec found - aber u.U. update notwendig
            my $aname=$a->{name};
            $aname=~s/\[.*\]$//;
            my $bname=$b->{name};
            my $w5cloudid=$w5cloud->{srcid}->{$b->{cloudid}}->{id};
            if ($aname eq $bname &&
                $a->{cistatusid}<6 &&
                $a->{cloudid} eq $w5cloudid  &&
                $a->{applid} eq $b->{applid}  &&
                $a->{srcsys} eq $self->Self()){
               $eq=1;   # alles gleich - da braucht man nix machen
            }
         }
         return($eq);
      },
      sub{  # oprec generator
         my ($mode,$oldrec,$newrec,%p)=@_;
         if ($mode eq "insert" || $mode eq "update"){
            my $w5cloudid=$w5cloud->{srcid}->{$newrec->{cloudid}}->{id};
            my $oprec={
               OP=>$mode,
               DATAOBJ=>'itil::itcloudarea',
               DATA=>{
                  srcsys     => $self->Self(),
                  srcid      => $newrec->{id},
               }
            };
            if ($mode eq "insert"){
               $oprec->{DATA}->{cloudid}=$w5cloudid;
               $oprec->{DATA}->{name}=$newrec->{name};
               $oprec->{DATA}->{applid}=$newrec->{applid};
               $oprec->{DATA}->{cistatusid}='3';
            }
            if ($mode eq "update"){
               if ($oldrec->{applid} ne $newrec->{applid}){
                  $oprec->{DATA}->{applid}=$newrec->{applid};
               }
               if ($oldrec->{name} ne $newrec->{name}){
                  $oprec->{DATA}->{name}=$newrec->{name};
               }
               if ($oldrec->{cloudid} ne $w5cloudid){
                  $oprec->{DATA}->{cloudid}=$w5cloudid;
               }
               if ($oldrec->{cistatusid} eq "6"){
                  $oprec->{DATA}->{cistatusid}=3;
               }
               $oprec->{IDENTIFYBY}=$oldrec->{id};
            }
            return($oprec);
         }
         elsif ($mode eq "delete"){
            my $oprec={
               OP=>"update",
               DATAOBJ=>'itil::itcloudarea',
               IDENTIFYBY=>$oldrec->{id},
               DATA=>{
                  cistatusid  =>6
               }
            };
            return(undef) if ($oldrec->{cistatusid} eq "6");
            return($oprec);
         }
         return(undef);
      },
      \@currCloudAreas,\@tobeCloudAreas,\@opList
   );
   my @msg;

   if (1){  # temp function, to activate New imported CloudArea
            # which are already exists with oldnames
      my $appl=getModuleObject($self->Config,"itil::appl");
      for(my $c=0;$c<=$#opList;$c++){
         ##################################################################
         # check valid state of applid
         if ($opList[$c]->{OP} eq "insert" ||   
             ($opList[$c]->{OP} eq "update" &&
              exists($opList[$c]->{DATA}->{applid}))){
            my ($arec,$msg);
            $appl->ResetFilter();
            if ($opList[$c]->{DATA}->{applid} ne ""){
               $appl->SetFilter({id=>\$opList[$c]->{DATA}->{applid}});
               ($arec,$msg)=$appl->getOnlyFirst(qw(id cistatusid name));
            }
            if (!defined($arec) || $opList[$c]->{DATA}->{applid} eq ""){
               $opList[$c]->{OP}="invalid";
               push(@msg,"ERROR: invalid application (W5BaseID) in project ".
                         $opList[$c]->{DATA}->{name});
            }
            else{
               if ($arec->{cistatusid} ne "3" &&
                   $arec->{cistatusid} ne "4"){
                  $opList[$c]->{OP}="invalid";
                  push(@msg,"ERROR: invalid cistatus for application ".
                            $arec->{name}.
                            " in project ".$opList[$c]->{DATA}->{name});
               }
            }
         }
         ##################################################################
         # check if there is an old cloudarea which is already active
         if ($opList[$c]->{OP} eq "insert" ){





         }
      }
   }

   if (!$res){
      my $opres=ProcessOpList($itcloudarea,\@opList);
   }


   #printf STDERR ("opList=%s\n",Dumper(\@opList));
   #######################################################################

   #printf STDERR ("s=%s\n",Dumper(\@tobeClouds));
   #printf STDERR ("i=%s\n",Dumper(\@currClouds));
   #printf STDERR ("w5cloud=%s\n",Dumper($w5cloud));

   #printf STDERR ("s=%s\n",Dumper(\@tobeCloudAreas));


   return({exitcode=>'1'});
}





1;
