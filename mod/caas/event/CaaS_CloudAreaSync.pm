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

   my $caasCloud=getModuleObject($self->Config,"caas::cloud");
   my $caasCloudArea=getModuleObject($self->Config,"caas::project");

   #######################################################################
   # Check stale retry state (exitcode=-1)
   #######################################################################

   my $staleRetry=0;
   my $joblog=getModuleObject($self->Config,"base::joblog");
   $joblog->SetFilter({name=>[$self->Self()."::CaaS_CloudAreaSync"],
                       exitcode=>'!0',
                       cdate=>'>now-6h'});
   $joblog->SetCurrentOrder('cdate');
   my @jobList=$joblog->getHashList(qw(id exitcode cdate));
   if ($#jobList!=-1){
      $staleRetry=$#jobList+1;
      foreach my $jrec (@jobList){
         $staleRetry-- if ($jrec->{exitcode}!=0);
      }
      $staleRetry=1 if (!$staleRetry); # only if all are not 0 - stale is given
   }

   #######################################################################
   # Load all CaaS BaseData for Sync
   #######################################################################

   $caasCloud->SetFilter({});
   my @tobeClouds=$caasCloud->getHashList(qw(id name fancyname));

   if ($#tobeClouds==0 && $tobeClouds[0]->{id} eq "-1"){
      return({exitcode=>'-1',
              msg=>'WARN: CaaS cloudlist temporary incomplete'});
   }

   if ($#tobeClouds<1){
      if (!$staleRetry){
         my @lastmsg=$caasCloud->LastMsg();
         if (grep(/ HTTP 503 /,@lastmsg)){
            return({exitcode=>'-1',
                    msg=>'WARN: CaaS cloudlist temporary incomplete'}); 
         }
      }
      else{
      #   # Store this info silent
         $self->SilentLastMsg(ERROR,"interface in stale retry longer then 6h");
      }
      my $infoObj=getModuleObject($self->Config,"itil::lnkapplappl");
      if ($infoObj->NotifyInterfaceContacts($caasCloud)){
         return({exitcode=>-1,exitmsg=>'Interface notified'});
      }
      msg(ERROR,"CaaS_CloudAreaSync not enough Clouds (CloudEnviroments) ".
                "on CaaS API found");
      return({exitcode=>'1'});
   }


   $caasCloudArea->SetFilter({});
   my @tobeCloudAreas=$caasCloudArea->getHashList(qw(id name applid 
                                                     cloudid cluster project
                                                     requestoraccount));
   if ($#tobeCloudAreas<10){
      if (!$staleRetry){
         my @lastmsg=$caasCloudArea->LastMsg();
         if (grep(/ HTTP 503 /,@lastmsg)){
            return({exitcode=>'-1',
                    msg=>'WARN: CaaS projectlist temporary incomplete'}); 
         }
      }
      else{
         $self->SilentLastMsg(ERROR,"interface in stale retry longer then 6h");
      }
      my $infoObj=getModuleObject($self->Config,"itil::lnkapplappl");
      if ($infoObj->NotifyInterfaceContacts($caasCloudArea)){
         return({exitcode=>-1,exitmsg=>'Interface notified'});
      }
      msg(ERROR,"CaaS_CloudAreaSync not enough CloudAreas (Projects) ".
                "on CaaS API found");
      return({exitcode=>'1'});
   }


   #######################################################################
   # CaaS Cloud-Enviroment-Sync
   #######################################################################

   my $itcloud=getModuleObject($self->Config,"TS::itcloud");

   $itcloud->SetFilter({shortname=>'CAAS',cistatusid=>'4 2 3'});
   my @baseFields=qw(databossid platformrespid securityrespid supportid 
                     shortname srcid srcsys mandatorid
                     can_iaas can_saas can_paas
                     acinmassignmentgroupid);
   my @currClouds=$itcloud->getHashList(qw(+cdate name cistatusid),@baseFields,
                                        (qw(contacts)));

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
         if ( $a->{srcid} eq $b->{id} ){
            $eq=0;  # rec found - aber u.U. update notwendig
            my $aname=$a->{name};
            $aname=~s/\[.*\]$//;

            if ($a->{cistatusid}<6 &&
                $a->{mandatorid} eq $currClouds[0]->{mandatorid} &&
                $a->{srcid} eq $b->{id}  &&
                $aname eq $b->{fancyname}  &&
                $a->{srcsys} eq $self->Self()){
               $eq=1;   # alles gleich - da braucht man nix machen
            }
         }
         else{
            if ( lc($a->{name}) eq lc($b->{fancyname}) ){  # equal but need
               $eq=0;                                      # sure update (at
            }                                              # leased srcid)
         }
         return($eq);
      },
      sub{  # oprec generator
         my ($mode,$oldrec,$newrec,%p)=@_;
         if ($mode eq "insert" || $mode eq "update"){
            my $oprec={
               OP=>$mode,
               DATAOBJ=>'TS::itcloud',
               DATA=>{
               }
            };
            if ($mode eq "insert"){
               $oprec->{DATA}->{srcid}=$newrec->{id};
               $oprec->{DATA}->{srcsys}=$self->Self();
               $oprec->{DATA}->{name}=$newrec->{fancyname};
               $oprec->{DATA}->{cistatusid}='4';
               foreach my $dupFld (qw(databossid securityrespid platformrespid
                                      supportid shortname mandatorid
                                      can_iaas can_saas can_paas
                                      acinmassignmentgroupid)){
                  $oprec->{DATA}->{$dupFld}=$currClouds[0]->{$dupFld};
               }
            }
            if ($mode eq "update"){
               if ($oldrec->{srcid} ne $newrec->{id}){
                  $oprec->{DATA}->{srcid}=$newrec->{id};
               }
               if ($oldrec->{srcsys} ne $self->Self()){
                  $oprec->{DATA}->{srcsys}=$self->Self();
               }
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
      my $lnkcontact=getModuleObject($self->Config,"base::lnkcontact");
      foreach my $op (@opList){
         if ($op->{OP} eq "insert.successful" &&
             $op->{IDENTIFYBY} ne ""){
            my $id=$op->{IDENTIFYBY};
            # add contacts to new created cloudareas
            #printf STDERR ("add contacts to %s\n%s\n",
            #               $id,Dumper($currClouds[0]->{contacts}));
            $lnkcontact->copyContacts($currClouds[0]->{contacts},
               $itcloud->SelfAsParentObject(),$id,
               "inherited from CaaS Tmpl-Cloud"
            );
         }
      }
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


   my $itcloudarea=getModuleObject($self->Config,"TS::itcloudarea");

   $itcloudarea->SetFilter({srcsys=>$self->Self()});
   my @currCloudAreas=$itcloudarea->getHashList(qw(id 
                               cloudid srcsys srcid name fullname));


   my %CaaSproj;

   foreach my $prec (@tobeCloudAreas){
      $CaaSproj{$prec->{id}}={
         cloudid=>$prec->{cloudid},
         id=>$prec->{id},
         cluster=>$prec->{cluster},
         requestoraccount=>$prec->{requestoraccount},
         project=>$prec->{project},
         cloud=>$w5cloud->{srcid}->{$prec->{cloudid}}
      }
   }
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
               DATAOBJ=>'TS::itcloudarea',
               DATA=>{
               }
            };
            if ($mode eq "insert"){
               $oprec->{DATA}->{srcid}=$newrec->{id};
               $oprec->{DATA}->{srcsys}=$self->Self();
               $oprec->{DATA}->{cloudid}=$w5cloudid;
               $oprec->{DATA}->{name}=$newrec->{name};
               $oprec->{DATA}->{applid}=$newrec->{applid};
               $oprec->{DATA}->{cistatusid}='3';
            }
            if ($mode eq "update"){
               if ($oldrec->{srcid} ne $newrec->{id}){
                  $oprec->{DATA}->{srcid}=$newrec->{id};
               }
               if ($oldrec->{srcsys} ne $self->Self()){
                  $oprec->{DATA}->{srcsys}=$self->Self();
               }
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
               DATAOBJ=>'TS::itcloudarea',
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
            # Wir brauchen prod/test -> CaaS-test/CaaS-production
            # den Cluster und den Namen des Projektes. Das mit :xxx am
            # Ende der u.U. vorhandenen CloudArea wird ignoriert (das scheint
            # der Namespace zu sein - und der wird nicht mehr nach Darwin
            # transferiert.
            #print STDERR ("Rec:%s\n",Dumper($opList[$c]));
            #$opList[$c]->{OP}="invalid";
            my $CaaSrec=$CaaSproj{$opList[$c]->{DATA}->{srcid}};
            my $opmode="unknown";
            if ($CaaSrec->{cloud}->{name}=~m/-test-/){
               $opmode="CaaS-test";
            }
            elsif ($CaaSrec->{cloud}->{name}=~m/-prod-/){
               $opmode="CaaS-production";
            }
            my $cluster=$CaaSrec->{cluster};
            my $name=$CaaSrec->{project};

            my $pattern="CaaS-DTIT.".$name.'@'.$opmode.'('.$cluster.'):*';
            $pattern=~s/\s/?/g;

            #print STDERR Dumper($CaaSrec);
            #printf STDERR ("opmode=%s cluster=%s name=%s\n",
            #               $opmode,$cluster,$name);
            #printf STDERR ("fullname pattern=%s\n",$pattern);

            $itcloudarea->ResetFilter();
            $itcloudarea->SetFilter({
               fullname=>$pattern,
               cistatusid=>"<6",
               applid=>$opList[$c]->{DATA}->{applid}
            });
            my ($carec,$msg)=$itcloudarea->getOnlyFirst(
                               qw(id cistatusid applid cifirstactivation));
            if (defined($carec) && $carec->{cistatusid}==4 &&
                $carec->{cifirstactivation} ne ""){
               $opList[$c]->{DATA}->{cistatusid}="4";
               $opList[$c]->{DATA}->{cifirstactivation}=
                      $carec->{cifirstactivation};
               $opList[$c]->{DATA}->{requestoraccount}="itil::itcloudarea::".
                                                      $carec->{id};
            }
         }
         if ($opList[$c]->{OP} eq "insert"){
            if ($opList[$c]->{DATA}->{cistatusid} ne "4"){
               my $CaaSrec=$CaaSproj{$opList[$c]->{DATA}->{srcid}};
               if ($CaaSrec->{requestoraccount} ne ""){
                  $opList[$c]->{DATA}->{requestoraccount}=
                        $CaaSrec->{requestoraccount};
               }
            }
         }
      }
   }

   if (!$res){
      my $opres=ProcessOpList($itcloudarea,\@opList);
   }

   if (1){ # cleanup old cloudareas on "old" CaaS-DTIT Cloud
      $itcloudarea->ResetFilter();
      $itcloudarea->SetFilter({
         cloud=>"CaaS-DTIT",
         cistatusid=>"<6",
      });
      my @cleanAreas=$itcloudarea->getHashList(qw(ALL));
      foreach my $oldrec (@cleanAreas){
         my $op=$itcloudarea->Clone();
         $op->ValidatedUpdateRecord($oldrec,{cistatusid=>'6'},
                                    {id=>$oldrec->{id}});
      }
   }

   #printf STDERR ("opList=%s\n",Dumper(\@opList));
   #######################################################################

   #printf STDERR ("s=%s\n",Dumper(\@tobeClouds));
   #printf STDERR ("i=%s\n",Dumper(\@currClouds));
   #printf STDERR ("w5cloud=%s\n",Dumper($w5cloud));

   #printf STDERR ("s=%s\n",Dumper(\@tobeCloudAreas));


   return({exitcode=>'0'});
}





1;
