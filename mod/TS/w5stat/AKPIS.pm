package TS::w5stat::AKPIS;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
use kernel::Universal;
use kernel::date;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);

   $self->{applicationfields}=[
      qw(
         name cistatusid mandatorid opmode
         businessteam applid chmapprgroups
         tsm 
         contacts
         applmgr
         isnosysappl systems cloudareas
         isnoifaceappl interfaces
         description
         acinmassingmentgroup
         mgmtitemgroup 
         dataissuestate
      )
   ];

   return($self);
}



sub getPresenter
{
   my $self=shift;

   my @l=(
          'AKPIS'=>{
                         opcode=>\&displayAKPIS,
                         overview=>undef,
                         group=>['Application','Group'],
                         prio=>9100,
                      }
         );

}


sub displayAKPIS
{  
   my $self=shift;
   my ($primrec,$hist)=@_;


   my $akpis;
   foreach my $substatstream (@{$primrec->{statstreams}}){
      if ($substatstream->{statstream} eq "AKPIS"){
         $akpis=$substatstream;
      }
   }
   return() if (!defined($akpis));

   my $app=$self->getParent();
   #my $user=$app->extractYear($primrec,$hist,"User",
   #                           setUndefZero=>1);

   my $d="";
   my $applcnt=0;
   if (exists($akpis->{stats}->{'AKPIS.app.all.count'})){
      $applcnt=$akpis->{stats}->{'AKPIS.app.all.count'}->[0];
   }
   $d.="<br>";
   $d.="<table width=80% border=0 cellspacing=2 cellpadding=0>";

   foreach my $kpi (sort(keys(%{$akpis->{stats}}))){
      $d.="<tr>";
      $d.="<td valign=top>";
      $d.="<b>$kpi</b>";
      my $trtxt=$app->T($kpi);
      if ($trtxt ne $kpi){
         $d.="<br><i>$trtxt</i>";
      }
      $d.="<br><br>";
      $d.="</td>";
      my $v=$akpis->{stats}->{$kpi};
      $v=$v->[0] if (ref($v) eq "ARRAY");
      $d.="<td valign=top align=right>";
      $d.="<b>$v</b>";
      $d.="</td>\n";

      $d.="</tr>";
   }
   $d.="</table>\n";

   if ($app->IsMemberOf("admin")){
      $d.="<br><hr>";
      $d.="Debug-Data:<br>";
      
      $d.="w5stat w5baseid=".
          $app->OpenByIdWindow("base::w5stat",$primrec->{id},$primrec->{id}).
          "<br>";
      $d.="w5stat AKPIS w5baseid=".
          $app->OpenByIdWindow("base::w5stat",$akpis->{id},$akpis->{id}).
          "<br>";
      $d.="w5stat AKPIS Stand=$akpis->{mdate}<br>";
      $d.="<hr>";
   }
   return($d);
}

#sub OpenByIdWindow
#{
#   my $self=shift;
#   my $dataobj=shift;
#   my $id=shift;
#
#}



sub processData
{
   my $self=shift;
   my $statstream=shift;
   my $dstrange=shift;
   my %param=@_;
   my ($year,$month)=$dstrange=~m/^(\d{4})(\d{2})$/;
   my $count=0;

   return() if ($statstream ne "AKPIS");



   my $appl=getModuleObject($self->getParent->Config,"TS::appl");
   $appl->SetCurrentView(@{$self->{applicationfields}});
   if ($appl->Config->Param("W5BaseOperationMode") eq "devx"){
      $appl->SetFilter({cistatusid=>'<=4',
                        name=>'W5* Dina* TSG_VIRTUELLE_T-SERVER*'.
                              'NGSS*Perfo* ServiceOn*  BI* AD(P)'});
   }
   else{
      $appl->SetFilter({cistatusid=>'4'});
   }
   $appl->SetCurrentOrder("NONE");
   msg(INFO,"starting collect of AKPIS Applications");
   my ($rec,$msg)=$appl->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord($statstream,'tsAKPIS::appl',
                                         $dstrange,$rec,%param);
         ($rec,$msg)=$appl->getNext();
         $count++;
      } until(!defined($rec));
   }
   msg(INFO,"FINE of tsAKPIS::appl  $count records");

   my $asset=getModuleObject($self->getParent->Config,"TS::asset");
   $asset->SetCurrentView(qw(
      name cistatusid mandatorid 
      dataissuestate eohs plandecons
   ));
   if ($asset->Config->Param("W5BaseOperationMode") eq "devx"){
      $asset->SetFilter({cistatusid=>'<=4',
        name=>" A21524409 A21565671 A21559627 A21224829 A21414755" 
      });

   }
   else{
      $asset->SetFilter({cistatusid=>'4'});
   }
   $asset->SetCurrentOrder("NONE");
   msg(INFO,"starting collect of AKPIS Hardware");
   my ($rec,$msg)=$asset->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord($statstream,'tsAKPIS::asset',
                                         $dstrange,$rec,%param);
         ($rec,$msg)=$asset->getNext();
         $count++;
      } until(!defined($rec));
   }
   msg(INFO,"FINE of tsAKPIS::asset  $count records");

}


sub getRepOrgFromApplrec
{
   my $self=shift;
   my $reclist=shift;
   my $app=$self->getParent();

   my @repOrg;
   my %appblk=();
   my @appblk=("all");

   foreach my $rec (@{$reclist}){
      $appblk{"all"}++;
      my $mgmtitemgroup=$rec->{mgmtitemgroup};
      $mgmtitemgroup=[$mgmtitemgroup] if (ref($mgmtitemgroup) ne "ARRAY");

      my $grp=$app->getPersistentModuleObject("base::grp");
      if ($rec->{businessteam} ne ""){
         push(@repOrg,$rec->{businessteam});
      }
      if ($rec->{mandatorid} ne ""){
         $grp->SetFilter({grpid=>\$rec->{mandatorid},cistatusid=>'4'});
         my ($grec)=$grp->getOnlyFirst(qw(fullname));
         if (defined($grec)){
            push(@repOrg,$grec->{fullname});
         }
      }
      foreach my $t (@repOrg){
         $self->getParent->Trace(" -> $t");
      }
      if ($rec->{opmode} eq "prod"){
         $appblk{"prod"}++;
      } 
      else{
         $appblk{"nonprod"}++;
      }

      if (in_array($mgmtitemgroup,"IBI-Relevant")){
         $appblk{"ibi"}++;
      }
      if (grep(/^top(\d+)-/i,@$mgmtitemgroup)){
         $appblk{"top"}++;
      }
   }
   @appblk=sort(keys(%appblk));

   return({repOrg=>\@repOrg,appblk=>\@appblk});

}


sub processRecord
{
   my $self=shift;
   my $statstream=shift;
   my $module=shift;
   my $monthstamp=shift;
   my $rec=shift;
   my $app=$self->getParent();
   my %param=@_;
   my ($year,$month)=$monthstamp=~m/^(\d{4})(\d{2})$/;

   return() if ($statstream ne "AKPIS");

   if ($module eq "tsAKPIS::asset"){
      msg(INFO,"AKPIS Processs $rec->{name}");
      my $assetkpi={};

      if ($rec->{dataissuestate}->{dataissuestate} ne "OK"){
         $assetkpi->{'dataissue.exists'}=1;
      }
      else{
         $assetkpi->{'dataissue.exists'}=0;
      }

      $assetkpi->{'eohs.exceeded'}=0;
      if ($rec->{eohs} ne ""){
         $assetkpi->{'eohs.count'}=1;
         my $d=CalcDateDuration($rec->{eohs},NowStamp("en"));
         if (defined($d) && $d->{totaldays}>0){
            $assetkpi->{'eohs.exceeded'}=1;
         }
      }
      else{
         $assetkpi->{'eohs.count'}=0;
      }

      $assetkpi->{'plandecons.exceeded'}=0;
      if ($rec->{plandecons} ne ""){
         $assetkpi->{'plandecons.count'}=1;
         my $d=CalcDateDuration($rec->{plandecons},NowStamp("en"));
         if (defined($d) && $d->{totaldays}>0){
            $assetkpi->{'plandecons.exceeded'}=1;
         }
      }
      else{
         $assetkpi->{'plandecons.count'}=0;
      }


      my $lnkappl=$app->getPersistentModuleObject("itil::lnkapplsystem");
      $lnkappl->SetFilter({
         applcistatusid=>'4',
         systemcistatusid=>'4',
         assetid=>[$rec->{id}]
      });
      #my @l=$lnkappl->getHashList(qw(applid appl businessteamid));
      $lnkappl->SetCurrentView(qw(applid));
      my $ia=$lnkappl->getHashIndexed("applid");
      my $appl=$app->getPersistentModuleObject("itil::appl");
      $appl->SetFilter({id=>[keys(%{$ia->{applid}})]});
      my @arec=$appl->getHashList(@{$self->{applicationfields}});

      foreach my $arec (@arec){
         foreach my $akey (keys(%$assetkpi)){
            my $key="AKPIS.asset.$akey";
            $self->getParent->storeStatVar("Application",
                                           [$arec->{name}],
                                           {nosplit=>1,
                                            nameid=>$arec->{id}},
                                           $key,$assetkpi->{$akey});
         }
      }

      my $ctrl=$self->getRepOrgFromApplrec(\@arec);
      my @repOrg=@{$ctrl->{repOrg}};
      my @appblk=@{$ctrl->{appblk}};

      foreach my $appblk (@appblk){
         my $key="AKPIS.asset.in_${appblk}_app.count";
         $self->getParent->storeStatVar("Group",\@repOrg,{},
                                        $key,1);
         foreach my $akey (keys(%$assetkpi)){
            my $key="AKPIS.asset.in_${appblk}_app.$akey";
            $self->getParent->storeStatVar("Group",\@repOrg,{},
                                           $key,$assetkpi->{$akey});
         }
      }
   }
   if ($module eq "tsAKPIS::appl"){
      msg(INFO,"AKPIS Processs $rec->{name}");
      $self->getParent->Trace("");
      $self->getParent->Trace("Processing: ".$rec->{name});

      my $appkpi={};
      my $name=$rec->{name};

      my $ctrl=$self->getRepOrgFromApplrec([$rec]);
      my @repOrg=@{$ctrl->{repOrg}};
      my @appblk=@{$ctrl->{appblk}};

      if ($rec->{dataissuestate}->{dataissuestate} ne "OK"){
         $appkpi->{'dataissue.exists'}=1;
      }
      else{
         $appkpi->{'dataissue.exists'}=0;
      }



      if ($#{$rec->{contacts}}==-1){
         $appkpi->{'contacts.filled'}=0;
      }
      else{
         $appkpi->{'contacts.filled'}=1;
      }

      $appkpi->{'systems.filled'}=0;
      if ($#{$rec->{systems}}==-1 && $#{$rec->{cloudareas}}==-1){
         if (!$rec->{isnosysappl}){
            $appkpi->{'systems.filled'}=1;
         }
      }
      else{
         $appkpi->{'systems.filled'}=1;
      }

      $appkpi->{'interfaces.filled'}=0;
      if ($#{$rec->{interfaces}}==-1){
         if (!$rec->{isnoifaceappl}){
            $appkpi->{'interfaces.filled'}=1;
         }
      }
      else{
         $appkpi->{'interfaces.filled'}=1;
      }



      foreach my $v (qw(tsm applmgr description businessteam opmode
                        acinmassingmentgroup applid)){
         if ($rec->{$v} ne ""){
            $appkpi->{$v.'.filled'}=1;
         }
         else{
            $appkpi->{$v.'.filled'}=0;
         }
      }
      $appkpi->{'techchmapprgroup.filled'}=0;

      foreach my $apprgrp (@{$rec->{'chmapprgroups'}}){
         if ($apprgrp->{group} ne "" && 
             $apprgrp->{responsibility} eq "technical"){
            $appkpi->{'techchmapprgroup.filled'}=1;
         }

      }

      foreach my $akey (keys(%$appkpi)){
         my $key="AKPIS.app.$akey";
         $self->getParent->storeStatVar("Application",
                                        [$rec->{name}],
                                        {nosplit=>1,
                                         nameid=>$rec->{id}},
                                        $key,$appkpi->{$akey});
      }

      foreach my $appblk (@appblk){
         my $key="AKPIS.app.$appblk.count";
         $self->getParent->storeStatVar("Application",
                                        [$rec->{name}],
                                        {nosplit=>1,
                                         nameid=>$rec->{id}},
                                        $key,1);
         $self->getParent->storeStatVar("Group",\@repOrg,{},
                                        $key,1);
         foreach my $akey (keys(%$appkpi)){
            my $key="AKPIS.app.$appblk.$akey";
            $self->getParent->storeStatVar("Group",\@repOrg,{},
                                           $key,$appkpi->{$akey});
         }
      }

   }
}


1;
