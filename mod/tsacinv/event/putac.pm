package tsacinv::event::putac;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
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

# Doku AssetManager XML Interface unter ...
# https://mywiki.telekom.de/display/CM/Asset+Manager-Interfaces-XML+interfaces+over+FTP+server

use strict;
use vars qw(@ISA);
use kernel;
use kernel::Event;
use kernel::FileTransfer;

use LWP::UserAgent;         # for AC XML Interface
use HTTP::Request::Common;  #
use HTTP::Cookies;          #
use XML::Parser;            #
use HTML::Parser;           #

use Time::HiRes;

use File::Temp qw(tempfile);
@ISA=qw(kernel::Event);

my %w52ac=(0 =>'OTHER',
           5 =>'CUSTOMER RESPONSIBILITY',
           20=>'TEST',
           25=>'DISASTER',
           30=>'TRAINING',
           40=>'REFERENCE',
           50=>'ACCEPTANCE',
           60=>'DEVELOPMENT',
           70=>'PRODUCTION');

#
# To reduce config items in AssetManager, a list of srcsystems
# in W5Base are excluded from XML Export (starting from 28.02.2025).
#
my $exclude_srcsys_expr=qr/^(AWS|TPC\d+|AZURE|OTC|GCP)$/i;

my %locmap;

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;

   # old calls - abwärtskompatibilität
   $self->RegisterEvent("putac","SendXmlToAM_appl");
   $self->RegisterEvent("putacasset","SendXmlToAM_asset",timeout=>40000);
   $self->RegisterEvent("putacsystem","SendXmlToAM_system",timeout=>40000);
   $self->RegisterEvent("putacappl","SendXmlToAM_appl",timeout=>40000);
   $self->RegisterEvent("SendXmlToAM_system","SendXmlToAM_system",timeout=>40000);
   $self->RegisterEvent("SendXmlToAM_asset","SendXmlToAM_asset",timeout=>40000);
   $self->RegisterEvent("SendXmlToAM_campus","SendXmlToAM_campus");
   $self->RegisterEvent("SendXmlToAM_logicalgroups","SendXmlToAM_logicalgroups");
   $self->RegisterEvent("SendXmlToAM_itclust","SendXmlToAM_itclust");


   #######################################################################
   # new parallel Interface
   $self->RegisterEvent("SendXmlToAM","SendXmlToAM");  # full transfer

   $self->RegisterEvent("SendXmlToAM_appl","SendXmlToAM_appl",
      timeout=>50000
   );
   $self->RegisterEvent("SendXmlToAM_instance","SendXmlToAM_instance",
      timeout=>3600
   );


   #######################################################################


#   $self->RegisterEvent("putac","SWInstallModified");
#   $self->RegisterEvent("SWInstallModified","SWInstallModified");
   return(1);
}

sub SendXmlToAM
{
   my $self=shift;
   my $obj=shift;

   my @objlist=qw(appl instance);

   if ($obj ne ""){
      if (in_array(\@objlist,$obj)){
         @objlist=($obj);
      }
      else{
         return({exitmsg=>1,
                 msg=>msg(ERROR,
                          "invalid object request to SendXmlToAM ($obj)")});
      }
   }

   foreach my $obj (@objlist){
      my $bk=$self->W5ServerCall("rpcCallEvent","SendXmlToAM_$obj",@_);
      if (!defined($bk->{AsyncID})){
         return({exitmsg=>1,
                 msg=>msg(ERROR,"can't call SendXmlToAM_$obj ")});
      }
   }
   return({exitcode=>0,msg=>'ok'});
}


#
# Bedingungen für einen Asset/System Export
#
# - CO-Nummer muß eingetragen sein, und in W5Base/Darwin als 
#   installiert/aktiv markiert sein.
# - Betreuungsteam muß innerhalb von DTAG.TSI.Prod.CSS.AS.DTAG* liegen
#   oder das Adminteam muß innerhalb von DTAG.TSI.Prod.CSS.AS.DTAG* liegen.
# - Es darf NICHT "automatisierte Updates durch Schnittstellen" zugelassen sein
# - CI-Status muß "installiert/aktiv" sein
# - Dem Asset muß min. ein System zugeordnet sein. 
# - Beim System muß ein Asset eingetragen sein, das in AssetManager aktiv ist.
#

sub getAcGroupByW5BaseGroup
{
   my $self=shift;
   my $grpname=shift;
   my $app=$self->getParent;

   my $acgrp=$app->getPersistentModuleObject("tsacgroup","tsacinv::group");

   $grpname=~s/^.*\.CS\.AO\.DTAG/CSS.AO.DTAG/i;
   $grpname=~s/^.*\.Prod\.CS\.Telco/CSS.AO.DTAG/i;
   $grpname=~s/^.*\.TIT/CSS.AO.DTAG/i;
   $grpname=~s/^DTAG\.TSI\.Prod\.CS\.SDMSS\.PSS\.IMS\.IM2$/CSS.SDM.PSS.CIAM/i;
   $grpname=~s/^DTAG\.TSI\.Prod\.CS\.SDMSS\.PSS\.IMS\.IM3$/CSS.SDM.PSS.CIAM/i;
   $grpname=~s/^DTAG\.TSI\.Prod\.CS\.SDMSS\.PSS/CSS.SDM.PSS/i;
   $grpname=~s/^DTAG\.TSI\.TIT\.E-([A-Z]+).*/TIT.$1/i;
   if ($grpname ne ""){
      $acgrp->SetFilter({name=>$grpname}); 
      my ($acgrprec,$msg)=$acgrp->getOnlyFirst(qw(name));
      if (defined($acgrprec)){
         return($acgrprec->{name});
      }
   }
   else{
      return(undef);
   }
   return(undef);
}

sub mkAcFtpRecIP
{
   my $self=shift;
   my $arec=shift;
   my $rec=shift;

   return(undef) if ($rec->{srcsys} =~ $exclude_srcsys_expr);
   if (ref($rec->{ipaddresses}) eq "ARRAY"){
      my @ip;
      foreach my $iprec (@{$rec->{ipaddresses}}){
          my $desc="DESC:".$iprec->{comments};
          push(@ip,{
             EventID=>"IP:".$rec->{systemid}.":".$iprec->{id},
             Description=>$desc,
             Comp_ExternalID=>$rec->{id},
             Comp_ExternalSystem=>"W5Base",
             Computer=>$rec->{systemid},
             Application=>"[NULL]",
             Remarks=>"admin",
             Status=>"configured",
             bDeleted=>"0",
             IPMS=>"",
             ExternalID=>$iprec->{id},
             ExternalSystem=>"W5Base",
             TcpIpAddress=>$iprec->{name}
          });
      }
      my @l;
      push(@l,{Interfaces=>\@ip});
      #die("hard");
      return(\@l);
   }
   return();
}


sub mkAcFtpRecSystem
{
   my $self=shift;
   my $arec=shift;
   my $rec=shift;
   my %param=@_;

   my $CurrentEventId="Process System '$rec->{name}'";
   my $inmassign=$rec->{acinmassingmentgroup};

   my $cfmassign="TIT";
   return(undef) if ($inmassign eq "");

   return(undef) if ( !(
                          ($inmassign=~m/^MIS\..*$/i) ||
                          ($inmassign=~m/^SAP\..*$/i) ||
                          ($inmassign=~m/^S\.SEO\.DE\..*$/i) ||
                          ($inmassign=~m/^PCS\..*$/i) 
                       ) &&
                     ($rec->{srcsys} =~ $exclude_srcsys_expr));
   if ($self->{DebugMode}){
      msg(INFO,"mkAcFtpRecSystem: $CurrentEventId");
   }

   my $nsys=1;
   if ($rec->{itcloudareaid} eq ""){  # For clouds the SystemPartOfAsset calc
      $nsys=100;                     # makes no sense, because AssetManager
   }                                 # can only handle 0.01 (100 sys per Asset)
   elsif ($rec->{assetid} ne ""){
      my $s=getModuleObject($self->Config,"itil::system");
      $s->SetFilter({assetid=>$rec->{assetid},
                     cistatusid=>"<6"});
      my @l=$s->getHashList(qw(id));

      $nsys=$#l+1;
      if ($nsys<=0){
         $nsys=1;
      }
   }
   my $pSystemPartOfAsset=1/$nsys;
   my $TXTpSystemPartOfAsset=sprintf("%0.2lf",$pSystemPartOfAsset);

   my $memory=$rec->{memory};
   $memory="1" if ($memory eq "");
   my $cpucount=$rec->{cpucount};
   $cpucount="1" if ($cpucount eq "");

   my @acrec;
    
   my $acrec={
               LogSys=>{
                    EventID=>$CurrentEventId,
                    ExternalSystem=>'W5Base',
                    ExternalID=>$rec->{id},
                    Security_Unit=>"TS.DE",
                    Status=>"in operation",
                    Name=>$rec->{name},
                    Usage=>"HOUSING",
                    OperatingSystem=>"[NULL]",
                    CO_CC=>$rec->{conumber},
                    bDelete=>'0',
                    lMemorySizeMb=>$memory,
                    fCPUNumber=>$cpucount,
                    AssignmentGroup=>$cfmassign,
                    IncidentAG=>$inmassign
               }
               # laut Rainer ist kein Model_Code
               # bei Systemen notwendig     Model_Code=>'MGER033048',
             };
   #
   # Wenn das Asset nicht Darwin "gehört", dann will die MU selbst den
   # SystemPartOfAsset Wert definieren - ist zwar unlogisch - ist aber so (HV).
   #

   if (defined($arec) && $arec->{srcsys} eq "W5Base"){
      $acrec->{LogSys}->{pSystemPartOfAsset}=$TXTpSystemPartOfAsset;
   }
   else{
      # Nach dem neuen (seit 01.08.2019) Housing Konzept
      $acrec->{LogSys}->{pSystemPartOfAsset}="0.00";
   }

   if ($rec->{mandator}=~m/^TelekomIT HU Internal_IT/){
      $acrec->{LogSys}->{SC_Location_ID}="DWR0.0000.0000";
   }
   elsif ($rec->{mandator}=~m/^TelekomIT.*/){
      $acrec->{LogSys}->{SC_Location_ID}="4787.0000.0000";
   }
   elsif ($rec->{mandator}=~m/^T-Systems.*/){
      $acrec->{LogSys}->{SC_Location_ID}="B065.0091.0023";
      # TS-TSIG_DE_FRANKFURT-AM-MAIN_HAHNSTR.-43
   }
   else{
      if ($self->{DebugMode}){
         msg(ERROR,"unable to detect SC_Location_ID ".
                   "for mandator $rec->{mandator}");
         msg(ERROR,"ignore system $rec->{name} in XML upload");
      }
      return();
   }
   if (defined($arec)){  # alles gut - Asset Datensatz ist sichtbar
      $acrec->{LogSys}->{Parent_Assettag}=$arec->{assetid};
   }
   else{
      return(undef) if (!($rec->{asset}=~m/^A[0-9]{5,10}$/));
      $acrec->{LogSys}->{Parent_Assettag}=$rec->{asset};
   }

   push(@acrec,$acrec);

   my $ac2rec=\%{$acrec};
   delete($ac2rec->{LogSys}->{Status});
   push (@acrec,$ac2rec);


   my $ac3rec={
               LogSys=>{
                    EventID=>$CurrentEventId,
                    ExternalSystem=>'W5Base',
                    ExternalID=>$rec->{id},
                    Parent_Assettag=>$rec->{asset},
                    Status=>"in operation"
               }
             };
   push (@acrec,$ac3rec);

   return(@acrec);
}

sub SendXmlToAM_system
{
   my $self=shift;
   my @systemname=@_;

   my $system=getModuleObject($self->Config,"TS::system");
   my $acasset=getModuleObject($self->Config,"tsacinv::asset");
   my $acsystem=getModuleObject($self->Config,"tsacinv::system");

   my %filter=(srcsys=>'!AssetManager',cistatusid=>[2,3,4,5]);
   $self->{DebugMode}=0;
   if ($#systemname!=-1){
      if (grep(/^debug$/i,@systemname)){
         @systemname=grep(!/^debug$/i,@systemname);
         $self->{DebugMode}=1;
         msg(ERROR,"processing DebugMode - loading '%s'",join(",",@systemname));
      }
      if ($#systemname!=-1){
         $filter{name}=\@systemname;
      }
   }
   #$self->{DebugMode}=0;   # force non debug mode
   my (%fh,%filename);

   $self->{jobstart}=NowStamp();
   ($fh{system},       $filename{system}               )=$self->InitTransfer();
   ($fh{interface},    $filename{interface}            )=$self->InitTransfer();

   $system->SetFilter(\%filter);

   my @idList=$system->getHashList(qw(id srcsys));
   my $acnew=0;
   my $acnewback=0;

   foreach my $idRec (@idList){
      $system->ResetFilter();
      $system->SetFilter({id=>\$idRec->{id}});
      my ($rec,$msg)=$system->getOnlyFirst(qw(ALL));
      if (defined($rec)){
         my $t0=Time::HiRes::time();
         msg(INFO,"Start of Record systemname=$rec->{name}");
         if ($rec->{asset} ne "" && $rec->{acinmassingmentgroup} ne ""){
            if ($self->{DebugMode}){
               msg(INFO,"check assetid '$rec->{asset}'");
            }
            $acasset->ResetFilter();
            $acasset->SetFilter({assetid=>\$rec->{asset}});
            my ($acassetrec,$msg)=$acasset->getOnlyFirst(qw(assetid srcsys));
            if (defined($acassetrec) && $self->{DebugMode}){
               msg(INFO," assetid '$rec->{asset}' OK");
            }
            foreach my $acftprec ($self->mkAcFtpRecSystem($acassetrec,$rec)){
               if (defined($acftprec)){
                  my $fh=$fh{system};
                  print $fh hash2xml($acftprec,{header=>0});
                  $acnew++;
               }
            }
            if (my $iplst=$self->mkAcFtpRecIP($acassetrec,$rec)){
               my $fh=$fh{interface};
               foreach my $iprec (@$iplst){
                  print $fh hash2xml($iprec,{header=>0});
               }
            }
         }
         my $t1=Time::HiRes::time();
         my $top=$t1-$t0;
         msg(INFO,"End of Record in time top=$top");
      }
   }
   msg(INFO,"count status: acnew=$acnew acnewback=$acnewback");
   $self->TransferFile($fh{system},$filename{system},"logsys");
   $self->TransferFile($fh{interface},$filename{interface},"interface");
}


sub mkAcFtpRecAsset
{
   my $self=shift;
   my $rec=shift;
   my %param=@_;
   my $app=$self->getParent;

   return(undef) if ($rec->{srcsys} =~ $exclude_srcsys_expr);
   my $CurrentEventId="Process Asset '$rec->{name}'";

   my $inmassign=$rec->{acinmassingmentgroup};
   my $cfmassign="TIT";
   return(undef) if ($inmassign eq "");
   return(undef) if ($rec->{locationid} eq "");

   my $accurrec;


   if ($rec->{name}=~m/^A.{3,10}$/){
      my $acass=$app->getPersistentModuleObject("tsacasset","tsacinv::asset");
      $acass->SetFilter({assetid=>\$rec->{name}});
      my ($arec,$msg)=$acass->getOnlyFirst(qw(assetid aperturestat 
                                              srcsys srcid));
      if (defined($arec)){
         $accurrec=$arec;
      }
   }



   if (!exists($locmap{$rec->{locationid}})){
      msg(INFO,"try to find ac location for $rec->{locationid}");
      $locmap{$rec->{locationid}}="0";
      my $loc=getModuleObject($self->Config,"base::location");
      $loc->SetFilter({id=>\$rec->{locationid}});
      my ($w5locrec,$msg)=$loc->getOnlyFirst(qw(ALL));
      if (defined($w5locrec)){
         my $acloc=getModuleObject($self->Config,"tsacinv::location");

         # 1st try
         my %flt=(location=>'"'.$w5locrec->{location}.'"',
                  locationtype=>\'Site',
                  zipcode=>$w5locrec->{zipcode});
         if ($rec->{class} ne "BUNDLE"){ #Only Bundles are allowed on 
            $flt{isdatacenter}=\'0';     #DataCenter Locations (Housing-Concept)
         }
         $acloc->ResetFilter();
         $acloc->SetFilter(\%flt);
         my @l=$acloc->getHashList(qw(fullname code w5locid));
         foreach my $r (@l){
            if (ref($r->{w5locid}) eq "ARRAY" &&
                in_array($r->{w5locid},$rec->{locationid})){
               $locmap{$rec->{locationid}}=$r->{fullname};
            }
         }



         # 2nd try
         if ($locmap{$rec->{locationid}} eq "0"){
            my %flt=(location=>'"'.$w5locrec->{location}.'"',
                     locationtype=>\'Site');
            if ($rec->{class} ne "BUNDLE"){ #Only Bundles are allowed on 
               $flt{isdatacenter}=\'0';     #DataCenter 
            }                               #Locations (Housing-Concept)
            $acloc->ResetFilter();
            $acloc->SetFilter(\%flt);
            @l=$acloc->getHashList(qw(fullname code w5locid));
         }
         foreach my $r (@l){
            if (ref($r->{w5locid}) eq "ARRAY" &&
                in_array($r->{w5locid},$rec->{locationid})){
               $locmap{$rec->{locationid}}=$r->{code};
            }
         }

         # 3th try
         if ($locmap{$rec->{locationid}} eq "0"){
            my %flt=(location=>'"'.$w5locrec->{location}.'"',
                     locationtype=>\'Building');  # seems new for Amazon Frankf.
            $acloc->ResetFilter();
            $acloc->SetFilter(\%flt);
            @l=$acloc->getHashList(qw(fullname code w5locid));
         }
         foreach my $r (@l){
            if (ref($r->{w5locid}) eq "ARRAY" &&
                in_array($r->{w5locid},$rec->{locationid})){
               $locmap{$rec->{locationid}}=$r->{code};
            }
         }

      }
   }
   return(undef) if ($locmap{$rec->{locationid}} eq "0");

   my $place=$rec->{place};
   if ($place ne "" && $rec->{room} ne ""){
      $place=" / ".$place;
   }
   if ($rec->{room} ne ""){
      $place=$rec->{room}.$place;
   }
   my $cpucount=$rec->{cpucount};
   $cpucount="1" if ($cpucount eq "");
   my $cpuspeed=$rec->{cpuspeed};
   $cpuspeed="1" if ($cpuspeed eq "");


   my $modelcode="MGER033048";

   if ($rec->{class} eq "BUNDLE"){
      $modelcode="M1696818"; # =OTC - ich hatte zwar einen ModelCode "BUNDLE"
                             # angefordert, hab aber dann OTC bekommen.
                             # - thats life :-[
   }

   my $acrec={
               Asset=>{
                    EventID=>$CurrentEventId,
                    ExternalSystem=>'W5Base',
                    ExternalID=>$rec->{id},
                    Security_Unit=>"TS.DE",
                    Status=>"in work",
                    Usage=>"HOUSING",
                    CPUType=>'[NULL]',
                    SerialNo=>$rec->{serialno},
                    lCPUNumber=>$cpucount,
                    lCPUspeedMhz=>$cpuspeed,
                    Remarks=>$rec->{comments},
                    BriefDescription=>$rec->{kwords},
                    Place=>$place,
                    SlotNo=>$rec->{rack},
                    Remarks=>$rec->{comments},
                    Security_Unit=>"TS.DE",
                    bDelete=>'0',
                    AssignmentGroup=>$cfmassign,
                    IncidentAG=>$inmassign,
                    Model_Code=>$modelcode
               }
             };

   if (!defined($accurrec) ||
        (!defined($accurrec->{aperturestat}) ||
         ($accurrec->{aperturestat}=~m/deleted/i))){
      $acrec->{Asset}->{Location_Code}=$locmap{$rec->{locationid}};
   }

   if ($rec->{mandator}=~m/^TelekomIT.*/){
  #   $acrec->{Asset}->{SC_Location_ID}="4787.0000.0000";# T-Com Bonn Land
   }
   else{
      return(undef);
   }
   return($acrec);
}

sub SendXmlToAM_asset
{
   my $self=shift;
   my @assetname=@_;

   my $asset=getModuleObject($self->Config,"TS::asset");
   my $acsystem=getModuleObject($self->Config,"tsacinv::system");
   my $acasset=getModuleObject($self->Config,"tsacinv::asset");
   my $mand=getModuleObject($self->Config,"tsacinv::mandator");

   my %filter=(srcsys=>\'w5base',cistatusid=>[2,3,4,5]);
   $self->{DebugMode}=0;
   if ($#assetname!=-1){
      if (grep(/^debug$/i,@assetname)){
         @assetname=grep(!/^debug$/i,@assetname);
         $self->{DebugMode}=1;
         msg(ERROR,"processing DebugMode - loading '%s'",join(",",@assetname));
      }
      if ($#assetname!=-1){
         $filter{name}=\@assetname;
      }
   }
   my $mandconfig;
   {  # mandator init
      $mand->SetFilter({cistatusid=>[3,4,5]});
      $mand->SetCurrentView(qw(id grpid defaultassignmentid 
                               defaultassignment doexport));
      $mandconfig=$mand->getHashIndexed(qw(grpid doexport));
      if (ref($mandconfig) ne "HASH"){
         return({exitcode=>1,msg=>msg(ERROR,"can not read mandator config")});
      }
      my @mandid=map({$_->{grpid}} @{$mandconfig->{doexport}->{1}});
      if ($#mandid==-1){
         return({exitcode=>1,msg=>msg(ERROR,"no export mandator")});
      }
      $filter{mandatorid}=\@mandid;
   }
   my (%fh,%filename);

   $self->{jobstart}=NowStamp();
   ($fh{asset},       $filename{asset}               )=$self->InitTransfer();
   $asset->SetFilter(\%filter);
   $asset->SetCurrentView(qw(ALL));

   my ($rec,$msg)=$asset->getFirst(unbuffered=>1);

   my $acnew=0;
   my $acnewback=0;
   if (defined($rec)){
      do{
         if (1){
           # msg(INFO,"now searching externid W5Base/$rec->{id} in ac");
           # $acasset->SetFilter([{srcsys=>\'W5Base',srcid=>$rec->{id}},
           #                      {assetid=>$rec->{name}}]); 
           # my ($acrec,$msg)=$acasset->getOnlyFirst(qw(assetid));
           # if (defined($acrec)){
           #    if (lc($acrec->{assetid}) ne lc($rec->{name})){
           #       # transfer erfolgreich - Namensupdate in W5Base durchführen
           #       # cistatus auf verfügbar stellen
           #       $acnewback++;
           #    }
           # }
           # else{
               # asset existiert noch nicht in AC und muß neu angelegt werden
               my $acftprec=$self->mkAcFtpRecAsset($rec,initial=>1);
               if (defined($acftprec)){
                  my $fh=$fh{asset};
                  print $fh hash2xml($acftprec,{header=>0});
                  $acnew++;
               }
           # }
         }
         
         ($rec,$msg)=$asset->getNext();
      } until(!defined($rec));
   }
   msg(INFO,"count status: acnew=$acnew acnewback=$acnewback");
   $self->TransferFile($fh{asset},$filename{asset},"asset");
}


sub SendXmlToAM_instance
{
   my $self=shift;
   my @w5id=@_;

   my $elements=0;
   my $w5appl=getModuleObject($self->Config,"itil::appl");
   my $sys=getModuleObject($self->Config,"itil::system");
   my $lnkitclustsvc=getModuleObject($self->Config,"itil::lnkitclustsvc");
   my $swinstance=getModuleObject($self->Config,"TS::swinstance");
   my $acgrp=getModuleObject($self->Config,"tsacinv::group");
   my $user=getModuleObject($self->Config,"base::user");
   my $mand=getModuleObject($self->Config,"tsacinv::mandator");
   my $mandconfig;
   my $acuser=getModuleObject($self->Config,"tsacinv::user");
   my %filter=(cistatusid=>['3','4','5']);
   $self->{DebugMode}=0;

   if ($#w5id!=-1){  # same as  SendXmlToAM_appl
      if (in_array(\@w5id,"debug")){
         @w5id=grep(!/^debug$/i,@w5id);
         $self->{DebugMode}=1;
         msg(ERROR,"processing DebugMode - loading ids '%s'",join(",",@w5id));
      }
      $filter{id}=\@w5id;
   }
   {  # mandator init  # same as  SendXmlToAM_appl
      $mand->SetFilter({cistatusid=>[3,4,5]});
      $mand->SetCurrentView(qw(id grpid defaultassignmentid 
                               defaultassignment doexport));
      $mandconfig=$mand->getHashIndexed(qw(grpid doexport));
      if (ref($mandconfig) ne "HASH"){
         return({exitcode=>1,msg=>msg(ERROR,"can not read mandator config")});
      }
      my @mandid=map({$_->{grpid}} @{$mandconfig->{doexport}->{1}});
      if ($#mandid==-1){
         return({exitcode=>1,msg=>msg(ERROR,"no export mandator")});
      }
      $filter{mandatorid}=\@mandid;
   }

   $swinstance->SetFilter(\%filter);
   $swinstance->SetCurrentView(qw(ALL));

   my (%fh,%filename);
   #($fh{appl},         $filename{appl}               )=$self->InitTransfer();
   #($fh{appl_appl_rel},$filename{appl_appl_rel}      )=$self->InitTransfer();
   ($fh{ci_appl_rel},  $filename{ci_appl_rel}        )=$self->InitTransfer();
   #($fh{appl_contact_rel},$filename{appl_contact_rel})=$self->InitTransfer();
   ($fh{instance},     $filename{instance}           )=$self->InitTransfer();



   my ($irec,$msg)=$swinstance->getFirst();
   $self->{jobstart}=NowStamp();
   my %grpnotfound;
   my %ciapplrel=();
   if (defined($irec)){
      do{
         #msg(INFO,"dump=%s",Dumper($irec));
         #msg(INFO,"id=$rec->{id}");
         my $jobname="W5Base.$self->{jobstart}.".NowStamp().
                     '.Instance'.$irec->{id};
         msg(INFO,"process swinstance=$irec->{name} jobname=$jobname");
         my $CurrentEventId="Instance '$irec->{fullname}'";
         if ($irec->{swinstanceid} eq ""){
            my $acswi=getModuleObject($self->Config,
                                      "tsacinv::swinstance");
            $acswi->SetFilter({srcsys=>\'W5Base',srcid=>\$irec->{id}});
            my ($acswirec,$msg)=$acswi->getOnlyFirst(qw(swinstanceid));
            if (defined($acswirec) && $acswirec->{swinstanceid} ne ""){
               my $swi=$swinstance->Clone();
               $swi->UpdateRecord({
                  swinstanceid=>$acswirec->{swinstanceid}},
                  {id=>\$irec->{id}}
               );
            }
         }

         my $amparentid;
         my $costcenter;
         if ($irec->{system} ne ""){
            $sys->ResetFilter();
            $sys->SetFilter({id=>\$irec->{systemid}});
            my ($sysrec,$msg)=$sys->getOnlyFirst(qw(systemid));
            $amparentid=$sysrec->{systemid};
         }
         if ($irec->{itclusts} ne ""){
            $lnkitclustsvc->ResetFilter();
            $lnkitclustsvc->SetFilter({id=>\$irec->{itclustsid}});
            my ($itclustsrec,$msg)=$lnkitclustsvc->getOnlyFirst(qw(clusterid));
            $amparentid=$itclustsrec->{clusterid};
         }
         if ($amparentid ne ""){
            my $assignment=$irec->{swteam};
            if ($assignment ne ""){
               $acgrp->ResetFilter(); 
               $acgrp->SetFilter({name=>$assignment}); 
               my ($acgrprec,$msg)=$acgrp->getOnlyFirst(qw(name));
               if (defined($acgrprec)){
                  $assignment=$acgrprec->{name};
               }
               else{
                  $grpnotfound{$assignment}=1;
                  $assignment="TIT";
               }
            }
            else{
               $assignment="TIT";
            }
            ########################################################
            my $iassignment=$irec->{acinmassingmentgroup};
            if (!($irec->{srcsys} =~ $exclude_srcsys_expr)){
               if ($iassignment eq ""){
                  $iassignment="[NULL]";
               }
               ########################################################
               #
               # Info von Florian Sahlmann vom 11.06.2008:
               # SAP-Instance:    M079345
               # APPL_Instance:   M079346
               # DB-Instance:     M079347
               # SELECT BarCode from AmModel where Name = 'DB-INSTANCE';
               #
               #
               my $model="M079346";
               $model="M079345" if ($irec->{swnature}=~m/^SAP.*$/i); 
               $model="M079347" if ($irec->{swnature}=~m/mysql/i); 
               $model="M079347" if ($irec->{swnature}=~m/oracle/i); 
               $model="M079347" if ($irec->{swnature}=~m/informix/i); 
               $model="M079347" if ($irec->{swnature}=~m/mssql/i); 
               $model="M079347" if ($irec->{swnature}=~m/db2/i); 
               my $swi={
                  Instances=>{
                     EventID=>$CurrentEventId,
                     ExternalSystem=>'W5Base',
                     ExternalID=>$irec->{id},
                     Parent=>uc($amparentid),
                     Name=>$irec->{fullname},
                     Status=>"in operation",
                     Model=>$model,
                     Remarks=>$irec->{comments},
                     Assignment=>$assignment,
                     IncidentAG=>$iassignment,
                     SC_Location_Id=>'4787.0000.0000',
                     #CostCenter=>$rec->{conumber},
                     Security_Unit=>"TS.DE",
                     CustomerLink=>"TS.DE",
                     bDelete=>'0'
                  }
               };
               if ($irec->{databossid} eq "12072167880012"){
                  $swi->{Instances}->{SC_Location_Id}="4787.0000.0000";
               }

               my $fh=$fh{instance};
               print $fh hash2xml($swi,{header=>0});
               $elements++;

               ##########################################################
               #
               # create relation to Application
               #
               my $applid=$irec->{applid};
               $w5appl->ResetFilter();
               $w5appl->SetFilter({id=>\$applid});
               my ($arec)=$w5appl->getOnlyFirst(qw(ALL)); 
               if (defined($arec)){
                  my $CurrentAppl=$arec->{name};
                  $CurrentEventId="Add Instance '$irec->{fullname}' ".
                                  "to $CurrentAppl";
                  my $externalid=$irec->{id};
                  if ($externalid eq ""){
                     $externalid="I-".$arec->{id}."-".$irec->{id};
                  }
                  my $acftprec={
                      CI_APPL_REL=>{
                         EventID=>$CurrentEventId,
                         ExternalSystem=>'W5Base',
                         ExternalID=>$externalid,
                         Appl_ExternalSystem=>'W5Base',
                         Appl_ExternalID=>$arec->{id},
                         Port_ExternalSystem=>'W5Base',
                         Port_ExternalID=>$irec->{id},
                         Security_Unit=>"TS.DE",
                         bDelete=>'0',
                         bActive=>'1',
                      }
                  };
                  if ($irec->{swinstanceid} ne ""){
                     $acftprec->{CI_APPL_REL}->{Portfolio}=
                            uc($irec->{swinstanceid});
                  }
                  if ($arec->{applid} ne ""){ # Realtion nur wenn Anwendung ID hat
                     $acftprec->{CI_APPL_REL}->{Application}=uc($arec->{applid});
                     #$acftprec->{CI_APPL_REL}->{Usage}=$w52ac{$ApplU};
                     my $fh=$fh{ci_appl_rel};
                     print $fh hash2xml($acftprec,{header=>0});
                     $elements++;
                  }
               }
               ##########################################################
            }
         }
         ($irec,$msg)=$swinstance->getNext();
      } until(!defined($irec));
   }

   $self->TransferFile($fh{ci_appl_rel},$filename{ci_appl_rel}, "ci_appl_rel");
   my $back=$self->TransferFile($fh{instance},$filename{instance},"instance");

   return($back);
}


sub SendXmlToAM_itclust
{
   my $self=shift;
   my @w5id=@_;

   my $elements=0;
   my $acitclust=getModuleObject($self->Config,"tsacinv::itclust");
   my $itclust=getModuleObject($self->Config,"TS::itclust");
   my $user=getModuleObject($self->Config,"base::user");
   my $acuser=getModuleObject($self->Config,"tsacinv::user");

   my %filter=(cistatusid=>['3','4','5']);
   $self->{DebugMode}=0;
   if ($#w5id!=-1){
      if (in_array(\@w5id,"debug")){
         @w5id=grep(!/^debug$/i,@w5id);
         $self->{DebugMode}=1;
         msg(ERROR,"processing DebugMode - loading ids '%s'",join(",",@w5id));
      }
      $filter{id}=\@w5id;
   }

   $itclust->SetFilter(\%filter);
   $itclust->SetCurrentView(qw(ALL));

   my (%fh,%filename);
   ($fh{itclust},      $filename{itclust}               )=$self->InitTransfer();


   my ($rec,$msg)=$itclust->getFirst();
   $self->{jobstart}=NowStamp();
   my %grpnotfound;
   if (defined($rec)){
      do{
         my $skip=0;
         if (lc($rec->{srcsys}) eq lc("AssetManager")){
            msg(INFO,"skip itclust=$rec->{name} - already comes from AssetManager");
            $skip++;
         }
         if (!$skip && $rec->{acinmassingmentgroup} ne ""){
            my $jobname="W5Base.$self->{jobstart}.".NowStamp().
                        '.Campus_'.$rec->{id};
            msg(INFO,"process itclust=$rec->{name} jobname=$jobname");
            my $CurrentEventId="Add Cluster $rec->{name} ($rec->{id})";
            my $acitclustrec;
            if ($rec->{clusterid} ne ""){
               $acitclust->ResetFilter();
               $acitclust->SetFilter({clusterid=>\$rec->{clusterid}});
               ($acitclustrec,$msg)=$acitclust->getOnlyFirst(qw(id clusterid));
        
            }
            else{
               $acitclust->SetFilter({srcsys=>\'W5Base',srcid=>\$rec->{id}});
               ($acitclustrec,$msg)=$acitclust->getOnlyFirst(qw(id clusterid
                                                          assignmentgroup));
               die("AssetManager not online") if (!$acitclust->Ping());
               if (defined($acitclustrec) && $acitclustrec->{clusterid} ne ""){
                  my $itclustop=$itclust->Clone();
                  $itclustop->UpdateRecord(
                     {clusterid=>$acitclustrec->{clusterid}},
                     {id=>\$rec->{id}});
               }
            }
            die("AssetManager not online") if (!$acitclust->Ping());
           
            my $assignment="TIT";
            my $acstatus="IN OPERATION";
            my $acftprec={
                Clusters=>{
                   Security_Unit=>"TS.DE",
                   Status=>$acstatus,
                   EventID=>$CurrentEventId,
                   Assignment=>$assignment,
                   IncidentAG=>$rec->{acinmassingmentgroup},
                   bDelete=>'0',
                   ClusterType=>'Cluster',
                   Name=>$rec->{fullname}
                }
            };
            $acftprec->{Clusters}->{ExternalID}=$rec->{id};
            $acftprec->{Clusters}->{ExternalSystem}="W5Base";
            $acftprec->{Clusters}->{SC_Location}="4787.0000.0000";
            $acftprec->{Clusters}->{AC_Location}="LGER029687";

            my $fh=$fh{itclust};
            print $fh hash2xml($acftprec,{header=>0});
         }

         ($rec,$msg)=$itclust->getNext();
      } until(!defined($rec));
   }

   my $back=$self->TransferFile($fh{itclust},$filename{itclust},"cluster");

   return($back);
}


sub SendXmlToAM_logicalgroups
{
   my $self=shift;
   my @w5id=@_;

   my $elements=0;
   my $sys=getModuleObject($self->Config,"itil::system");
   my $ass=getModuleObject($self->Config,"itil::asset");

   my %filter=(cistatusid=>['3','4','5'],itfarm=>'!""');
   if ($#w5id!=-1){
      if (in_array(\@w5id,"debug")){
         @w5id=grep(!/^debug$/i,@w5id);
         $self->{DebugMode}=1;
         msg(ERROR,"processing DebugMode - loading assets '%s'",join(",",@w5id));
      }
      $filter{name}=\@w5id;
   }

   $ass->SetFilter(\%filter);
   $ass->SetCurrentView(qw(ALL));

   my (%fh,%filename);
   ($fh{lg},      $filename{lg}               )=$self->InitTransfer();


   my ($rec,$msg)=$ass->getFirst();
   $self->{jobstart}=NowStamp();
   if (defined($rec)){
      do{
         if ($rec->{name}=~m/^A\d+$/){ 
            my $jobname="W5Base.$self->{jobstart}.".NowStamp().
                        '.Asset_'.$rec->{id};
            msg(INFO,"process asset =$rec->{name} ($rec->{itfarm}) ".
                     "jobname=$jobname");
            my $CurrentEventId="Add Asset $rec->{name} to farm $rec->{itfarm}";
            my $groupname="W5Base_".$rec->{itfarm};
            my $groupdesc="TelIT ".$rec->{itfarm};
            my $acftprec={
                   CI_LogGroup_Rel=>{
                      Description=>$groupdesc,
                      Portfolio=>$rec->{name},
                      EventID=>$CurrentEventId,
                      ExternalSystem=>"W5Base",
                      ExternalID=>"Asset-W5BaseID:".$rec->{id},
                      LogGroup_Description=>$groupname,
                      LogGroup_bDelete=>0,
                      bDelete=>'0'
                   }
            };

            my $fh=$fh{lg};
            print $fh hash2xml($acftprec,{header=>0});
            if (ref($rec->{systems}) eq "ARRAY"){
               foreach my $sysrec (@{$rec->{systems}}){
                  if ($sysrec->{systemid}=~m/^S\d+$/){
                     $CurrentEventId="Add System $sysrec->{name} to farm $rec->{itfarm}";
                     my $acftprec={
                            CI_LogGroup_Rel=>{
                               Description=>$groupdesc,
                               Portfolio=>$sysrec->{systemid},
                               EventID=>$CurrentEventId,
                               ExternalSystem=>"W5Base",
                               ExternalID=>"System-W5BaseID:".$sysrec->{id},
                               LogGroup_Description=>$groupname,
                               LogGroup_bDelete=>0,
                               bDelete=>'0'
                            }
                     };
                     print $fh hash2xml($acftprec,{header=>0});
                  }
               }
            }
         }
         ($rec,$msg)=$ass->getNext();
      } until(!defined($rec));
   }

   my $back=$self->TransferFile($fh{lg},$filename{lg},"loggroup_ci_rel");

   return($back);
}


sub SendXmlToAM_campus
{
   my $self=shift;
   my @w5id=@_;

   my $elements=0;
   my $acappl=getModuleObject($self->Config,"tsacinv::appl");
   my $campus=getModuleObject($self->Config,"TS::campus");
   my $user=getModuleObject($self->Config,"base::user");
   my $acuser=getModuleObject($self->Config,"tsacinv::user");

   my %filter=(cistatusid=>['3','4','5']);
   $self->{DebugMode}=0;
   if ($#w5id!=-1){
      if (in_array(\@w5id,"debug")){
         @w5id=grep(!/^debug$/i,@w5id);
         $self->{DebugMode}=1;
         msg(ERROR,"processing DebugMode - loading ids '%s'",join(",",@w5id));
      }
      $filter{id}=\@w5id;
   }

   $campus->SetFilter(\%filter);
   $campus->SetCurrentView(qw(ALL));

   my (%fh,%filename);
   ($fh{campus},      $filename{campus}               )=$self->InitTransfer();


   my ($rec,$msg)=$campus->getFirst();
   $self->{jobstart}=NowStamp();
   my %grpnotfound;
   if (defined($rec)){
      do{
         my $jobname="W5Base.$self->{jobstart}.".NowStamp().
                     '.Campus_'.$rec->{id};
         msg(INFO,"process campus=$rec->{name} jobname=$jobname");
         my $CurrentEventId="Add Campus $rec->{name} ($rec->{id})";
         my $acapplrec;
         if ($rec->{campusid} ne ""){
            $acappl->ResetFilter();
            $acappl->SetFilter({applid=>\$rec->{campusid}});
            ($acapplrec,$msg)=$acappl->getOnlyFirst(qw(id applid
                                                       assignmentgroup));
        
         }
         else{
            $acappl->SetFilter({srcsys=>\'W5Base',srcid=>\$rec->{id}});
            ($acapplrec,$msg)=$acappl->getOnlyFirst(qw(id applid
                                                       assignmentgroup));
            die("AssetManager not online") if (!$acappl->Ping());
            if (defined($acapplrec) && $acapplrec->{applid} ne ""){
               $campus->UpdateRecord({campusid=>$acapplrec->{applid}},
                                  {id=>\$rec->{id}});
            }
         }
         die("AssetManager not online") if (!$acappl->Ping());

         my $assignment="TIT";
         my $acstatus="IN OPERATION";
         if ($rec->{acinmassingmentgroup} ne ""){
            my $acftprec={
                Appl=>{
                   Security_Unit=>"TS.DE",
                   Status=>$acstatus,
                   Priority=>"3",
                   EventID=>$CurrentEventId,
                   AssignmentGroup=>$assignment,
                   IncidentAG=>$rec->{acinmassingmentgroup},
                   bDelete=>'0',
                   Name=>$rec->{fullname}
                }
            };
            $acftprec->{Appl}->{ExternalID}=$rec->{id};
            $acftprec->{Appl}->{ExternalSystem}="W5Base";

            my $fh=$fh{campus};
            print $fh hash2xml($acftprec,{header=>0});
         }

         ($rec,$msg)=$campus->getNext();
      } until(!defined($rec));
   }

   my $back=$self->TransferFile($fh{campus},$filename{campus},"appl");

   return($back);
}


sub SendXmlToAM_appl
{
   my $self=shift;
   my @w5id=@_;

   my $elements=0;
   my $acappl=getModuleObject($self->Config,"tsacinv::appl");
   my $applappl=getModuleObject($self->Config,"itil::lnkapplappl");
   my $applsys=getModuleObject($self->Config,"itil::lnkapplsystem");
   my $acapplsys=getModuleObject($self->Config,"tsacinv::lnkapplsystem");
   my $acsys=getModuleObject($self->Config,"tsacinv::system");
   my $acgrp=getModuleObject($self->Config,"tsacinv::group");
   my $app=getModuleObject($self->Config,"AL_TCom::appl");
   my $user=getModuleObject($self->Config,"base::user");
   my $mand=getModuleObject($self->Config,"tsacinv::mandator");
   my $swinstance=getModuleObject($self->Config,"TS::swinstance");
   my $mandconfig;
   my $acuser=getModuleObject($self->Config,"tsacinv::user");
   my %filter=(cistatusid=>['3','4','5']);
   $self->{DebugMode}=0;
   if ($#w5id!=-1){
      if (in_array(\@w5id,"debug")){
         @w5id=grep(!/^debug$/i,@w5id);
         $self->{DebugMode}=1;
         msg(ERROR,"processing DebugMode - loading ids '%s'",join(",",@w5id));
      }
      $filter{id}=\@w5id;
   }
   {  # mandator init
      $mand->SetFilter({cistatusid=>[3,4,5]});
      $mand->SetCurrentView(qw(id grpid defaultassignmentid 
                               defaultassignment doexport));
      $mandconfig=$mand->getHashIndexed(qw(grpid name doexport));
      #msg(DEBUG,"mandconfig=%s",Dumper($mandconfig));
      if (ref($mandconfig) ne "HASH"){
         return({exitcode=>1,msg=>msg(ERROR,"can not read mandator config")});
      }
      my @mandid=map({$_->{grpid}} @{$mandconfig->{doexport}->{1}});
      if ($#mandid==-1){
         return({exitcode=>1,msg=>msg(ERROR,"no export mandator")});
      }
      $filter{mandatorid}=\@mandid;
   }
   #msg(INFO,"filter=%s",Dumper(\%filter));


  # $filter{name}="*w5base*";
   $app->SetFilter(\%filter);
   $app->SetCurrentView(qw(ALL));
  # $app->SetCurrentView(qw(id name sem tsm tsm2 conumber currentvers
  #                         description businessteam));

   my (%fh,%filename);
   ($fh{appl},         $filename{appl}               )=$self->InitTransfer();
   ($fh{appl_appl_rel},$filename{appl_appl_rel}      )=$self->InitTransfer();
   ($fh{ci_appl_rel},  $filename{ci_appl_rel}        )=$self->InitTransfer();
   ($fh{appl_contact_rel},$filename{appl_contact_rel})=$self->InitTransfer();
   ($fh{instance},     $filename{instance}           )=$self->InitTransfer();


   my ($rec,$msg)=$app->getFirst();
   $self->{jobstart}=NowStamp();
   my %grpnotfound;
   my %ciapplrel=();
   if (defined($rec)){
      do{
         #msg(INFO,"dump=%s",Dumper($rec));
         #msg(INFO,"id=$rec->{id}");
         my $jobname="W5Base.$self->{jobstart}.".NowStamp().'.Appl_'.$rec->{id};
         msg(INFO,"process application=$rec->{name} jobname=$jobname");
         my $acapplrec;
         if ($rec->{applid} ne ""){
            $acappl->ResetFilter();
            $acappl->SetFilter({applid=>\$rec->{applid}});
            ($acapplrec,$msg)=$acappl->getOnlyFirst(qw(id applid
                                                       assignmentgroup));
        
         }
         else{
            $acappl->SetFilter({srcsys=>\'W5Base',srcid=>\$rec->{id}});
            ($acapplrec,$msg)=$acappl->getOnlyFirst(qw(id applid
                                                       assignmentgroup));
            die("AssetManager not online") if (!$acappl->Ping());
            if (defined($acapplrec) && $acapplrec->{applid} ne ""){
               $app->UpdateRecord({applid=>$acapplrec->{applid}},
                                  {id=>\$rec->{id}});
            }
         }
         die("AssetManager not online") if (!$acappl->Ping());
         if ((!($acapplrec->{assignmentgroup} eq "GQ.PS" ||   # NO GQPS Elements
               ($acapplrec->{assignmentgroup}=~m/^GQ\.PS\./))) &&
             ($rec->{acinmassingmentgroup} ne "" ||           # INM AG needed
              $rec->{applid} ne "") &&
             (!($rec->{srcsys} =~ $exclude_srcsys_expr))){
            my $CurrentEventId;
            my $CurrentAppl=$rec->{name};
            my $ApplU=0;
            my $SysCount=0;
            {  # systems
               $applsys->SetFilter({applid=>\$rec->{id},
                                    systemcistatusid=>['3','4']});
               my @l=$applsys->getHashList(qw(id systemsystemid system
                                              istest iseducation isref 
                                              isapprovtest isdevel isprod
                                              shortdesc systemid
                                              srcsys srcid));
               my @alreadyManuellRelated;
               my @isProtectedNetworkDev;
               if ($rec->{applid} ne ""){
                  $acapplsys->ResetFilter();
                  $acapplsys->SetFilter({applid=>\$rec->{applid}});
                  $acapplsys->SetCurrentView(qw(applid systemid srcsys srcid));
                  foreach my $r ($acapplsys->getHashList(qw(
                                  applid systemid srcsys srcid))){
                     if (!in_array(\@alreadyManuellRelated,$r->{systemid})){
                        if ($r->{srcsys} ne "W5Base"){
                           push(@alreadyManuellRelated,$r->{systemid});
                        }
                     }
                  }
               }
               # check if there are protected network devices
               {
                  my @chks;
                  foreach my $lnk (@l){
                     if ($lnk->{systemsystemid} ne ""){
                        push(@chks,$lnk->{systemsystemid});
                     }
                  }
                  # printf STDERR ("DEBUG checks 01: %s\n",Dumper(\@chks));
                  # at 1st, we are now see all as ProtectedNetworkDev
                  map({
                    if (!in_array(\@isProtectedNetworkDev,$_)){
                       push(@isProtectedNetworkDev,$_);
                    }
                  } @chks);

                  if ($#isProtectedNetworkDev!=-1){
                     $acsys->ResetFilter();
                     $acsys->SetFilter({systemid=>\@isProtectedNetworkDev});
                     foreach my $r ($acsys->getHashList(qw(systemid 
                                                           isprotnetdev))){
                        if (!$r->{isprotnetdev}){
                           @isProtectedNetworkDev=
                              grep(!/^$r->{systemid}$/,@isProtectedNetworkDev);
                        }
                     }
                  }
                  #printf STDERR ("DEBUG: isProtectedNetworkDev %s\n",
                  #               Dumper(\@isProtectedNetworkDev));
               
               }
               foreach my $lnk (@l){
                  next if (in_array(\@alreadyManuellRelated,
                                    $lnk->{systemsystemid}));
                  next if (in_array(\@isProtectedNetworkDev,
                                    $lnk->{systemsystemid}));
                  my $SysU=0;
                  $SysU=20 if ($SysU<20 && $lnk->{istest}); 
                  $SysU=30 if ($SysU<30 && $lnk->{iseducation}); 
                  $SysU=40 if ($SysU<40 && $lnk->{isref}); 
                  $SysU=50 if ($SysU<50 && $lnk->{isapprovtest}); 
                  $SysU=60 if ($SysU<60 && $lnk->{isdevel}); 
                  $SysU=70 if ($SysU<70 && $lnk->{isprod}); 
                  $ApplU=$SysU if ($ApplU<$SysU);
                  next if ($lnk->{systemsystemid}=~m/^\s*$/);
                  # Die AM-SAPLNK werden von der XML Schnittstelle nur
                  # "virtuell" erzeugt - sie dürfen also NICHT als normale
                  # Relationen übertragen werden.
                  next if ($lnk->{srcsys} eq "AM-SAPLNK");
                  if ($rec->{allowifupdate}){
                     # Wenn automatische Updates bei der Anwendung zugelassen
                     # sind, dann dürfen Relationen, die automatisch aus AM
                     # kamen, NICHT nach AM zurück geschrieben werden, da ja
                     # dann AssetManager das führende System für die Relationen
                     # ist.
                     next if ($lnk->{srcsys} eq "AM");
                  }
                  $CurrentEventId="Add System '$lnk->{system}' to $CurrentAppl";
                  my $externalid=$lnk->{id};
                  if ($externalid eq ""){
                     $externalid="C-".$rec->{id}."-".$lnk->{systemid};
                  }
                  my $acftprec={
                      CI_APPL_REL=>{
                         EventID=>$CurrentEventId,
                         ExternalSystem=>'W5Base',
                         ExternalID=>$externalid,
                         Appl_ExternalSystem=>'W5Base',
                         Appl_ExternalID=>$rec->{id},
                         Port_ExternalSystem=>'W5Base',
                         Port_ExternalID=>$lnk->{systemid},
                         Security_Unit=>"TS.DE",
                         Description=>$lnk->{shortdesc},
                         bDelete=>'0',
                         bActive=>'1',
                      }
                  };
                  if ($rec->{applid} ne ""){
                    #$acftprec->{CI_APPL_REL}->{Application}=uc($rec->{applid});
                     $acftprec->{CI_APPL_REL}->{Code}=uc($rec->{applid});
                  }    
                  if ($lnk->{systemsystemid} ne ""){
                     $acftprec->{CI_APPL_REL}->{Portfolio}=
                            uc($lnk->{systemsystemid});
                     $ciapplrel{"$acftprec->{CI_APPL_REL}->{Portfolio}".
                                "-".
                                $acftprec->{CI_APPL_REL}->{Code}}++;
                  }

                  $acftprec->{CI_APPL_REL}->{Usage}=$w52ac{$SysU};
                  my $fh=$fh{ci_appl_rel};
                  print $fh hash2xml($acftprec,{header=>0});
                  $SysCount++;
                  $elements++;
               }
            }
            { # Application
               my %posix=();
               my %idno=();
               foreach my $userent (qw(tsm tsm2 opm opm2 sem databoss 
                                       delmgr delmgr2)){
                  if ($rec->{$userent} ne ""){
                     $user->SetFilter({fullname=>\$rec->{$userent}});
                     $user->SetCurrentView("posix","email");
                     my ($rec,$msg)=$user->getFirst();
                     if (defined($rec)){
                        $posix{$userent}=lc($rec->{posix});
                        if ($posix{$userent} ne ""){
                           $acuser->ResetFilter();
                           $acuser->SetFilter([
                              {
                                 loginname=>\$posix{$userent},
                                 deleted=>\'0'
                              },
                              {
                                 ldapid=>\$posix{$userent},
                                 deleted=>\'0'
                              },
                              {
                                 idno=>\$posix{$userent},
                                 deleted=>\'0'
                              },
                              {
                                 email=>\$rec->{email},
                                 deleted=>\'0',
                              }
                           ]);
                           my @l=$acuser->getHashList(qw(lempldeptid idno));
                           if ($#l>-1 && $#l<3){
                              $idno{$userent}=$l[0]->{idno};
                           }
                        }
                     }
                  }
                  $posix{$userent}="[NULL]" if (!defined($posix{$userent}));
               }
               my $chkassignment=$rec->{businessteam};
               my $assignment=$self->getAcGroupByW5BaseGroup($chkassignment);
               if (!defined($assignment)){
                  if (exists($mandconfig->{grpid}->{$rec->{mandatorid}})){
                     my $mrec=$mandconfig->{grpid}->{$rec->{mandatorid}};
                     if (defined($mrec->{defaultassignment})){
                        $assignment=$mrec->{defaultassignment};
                        $grpnotfound{$chkassignment}=1;
                     }
                  }
               }
               if (!defined($assignment)){
                  $grpnotfound{$chkassignment}=1;
                  $assignment="TIT";
               }

               my $chmapprgrp="[NULL]";

               my $criticality=$rec->{criticality};
               $criticality=~s/^CR//;
               if ($criticality eq ""){
                  if ($rec->{customerprio}==1){
                     $criticality="critical";
                  }
                  elsif ($rec->{customerprio}==2){
                     $criticality="medium";
                  }
                  else{ 
                     $criticality="none";
                  }
               }
               ########################################################
               my $applref="[NULL]";
               if ($rec->{ictono} ne ""){
                  $applref="CAPE: ".$rec->{ictono};
               }
               ########################################################
               my $issoxappl=$rec->{issoxappl};
               $issoxappl="YES" if ($rec->{issoxappl});
               $issoxappl="NO" if (!($rec->{issoxappl}));
               $CurrentAppl="$rec->{name}($rec->{id})";
               $CurrentEventId="Add Application $CurrentAppl";
               $ApplU=10 if ($rec->{isnosysappl} && $SysCount==0);
               $ApplU=5  if (lc($rec->{mandator}) eq "extern");
               if ($rec->{opmode} ne ""){
                  $ApplU=70 if ($rec->{opmode} eq "prod");
                  $ApplU=60 if ($rec->{opmode} eq "devel");
                  $ApplU=50 if ($rec->{opmode} eq "approvtest");
                  $ApplU=40 if ($rec->{opmode} eq "reference");
                  $ApplU=30 if ($rec->{opmode} eq "education");
                  $ApplU=25 if ($rec->{opmode} eq "cbreakdown");
                  $ApplU=20 if ($rec->{opmode} eq "test");
               }
               my $acstatus="IN OPERATION";
               if ($rec->{cistatusid}==3){
                  $acstatus="IN BUILD";
               }
               if ($rec->{cistatusid}==5){
                  $acstatus="OUT OF OPERATION";
               }

               # ---
               # anhand der conumber checken, ob im SAP WIB gesetzt ist
               # ---
               # prüfen ob in assetmanager der customerlink notwendige
               # customerlink existiert
               # ---
               # prüfen ob in assetmanager beim kontierungsobjekt der
               # passende customerlink eingetragen ist.
               # ---
               #$self->validateCostCenter4AssetManager($rec);
               my $conumber=$rec->{conumber};
               if ($conumber=~m/^[a-z]-[a-z0-9]+$/i){
                  $conumber=$rec->{conodenumber};
               }
               my $acftprec={
                                Appl=>{
                                   Security_Unit=>"TS.DE",
                                   Status=>$acstatus,
                                   Priority=>$rec->{customerprio},
                                   EventID=>$CurrentEventId,
                                   AssignmentGroup=>$assignment,
                                   CO_CC=>$conumber,
                                   Description=>$rec->{description},
                                   CustBusinessDesc=>$rec->{description},
                                   Remarks=>$rec->{comments},
                                   MaintWindow=>$rec->{maintwindow},
                                   IncidentAG=>$rec->{acinmassingmentgroup},
                                   ChangeAppr=>$chmapprgrp,
                                   Version=>$rec->{currentvers},
                                   SoxRelevant=>$issoxappl,
                                   Criticality=>$criticality,
                                   Technical_Contact=>$idno{tsm},
                                   DataSupervisor=>$idno{databoss},
                                   Service_Manager=>$idno{sem},
                                   Deputy_Technical_Contact=>$idno{tsm2},
                                   Lead_Del_manager=>$idno{opm},
                                   Del_manager=>$idno{delmgr},
                                   Deputy_Del_manager=>$idno{opm2},
                                   bDelete=>'0',
                                   Name=>$rec->{name},
                                   Appl_Group=>$rec->{applgroup},
                                   Appl_Ref=>$applref
                                }
                            };
               $acftprec->{Appl}->{Customer}='TS.DE';
               $acftprec->{Appl}->{Usage}=$w52ac{$ApplU};
            
               if (defined($acapplrec) && $acapplrec->{applid} ne "" &&
                   ($acapplrec->{applid}=~m/^(APPL|GER)/)){
                  $acftprec->{Appl}->{Code}=$acapplrec->{applid};
                  $acftprec->{Appl}->{ExternalID}=$rec->{id};
                  $acftprec->{Appl}->{ExternalSystem}="W5Base";
               }
               else{
                  $acftprec->{Appl}->{ExternalSystem}="W5Base";
                  $acftprec->{Appl}->{ExternalID}=$rec->{id};
               }
               if ((!exists($acftprec->{Appl}->{Code}) || 
                     $acftprec->{Appl}->{Code} eq "") &&
                   $rec->{applid} ne "" &&
                   ($rec->{applid}=~m/^(APPL|GER)/)){
                  $acftprec->{Appl}->{Code}=$rec->{applid};
               }
                    
               $acftprec->{Appl}->{Description}=~s/[\n\r]/ /g;
               $acftprec->{Appl}->{Version}=~s/[\n\r]/ /g;
               my $fh=$fh{appl};
               print $fh hash2xml($acftprec,{header=>0});
               $elements++;
            }
            { # Interfaces
               $applappl->SetFilter({fromapplid=>\$rec->{id},
                                     toapplcistatus=>\"4"});
               my @l=$applappl->getHashList(qw(id toappl lnktoapplid conproto
                                               toapplid conmode comments));
               foreach my $lnk (@l){
                  $CurrentEventId="Add Interface '$lnk->{toappl}' ".
                                  "to $CurrentAppl";
                  my $replmode=$lnk->{conmode}; #batch, manual, online, Package
                  if ($lnk->{conmode} eq "manuell"){
                     $replmode="manual";
                  }
                  my $acftprec={
                                   APPL_APPL_REL=>{
                                      EventID=>$CurrentEventId,
                                      ExternalSystem=>'W5Base',
                                      ExternalID=>$lnk->{id},
                                      C_Appl_ExternalSystem=>'W5Base',
                                      C_Appl_ExternalID=>$lnk->{toapplid},
                                      UseAssignment=>'Parent',
                                      Type=>$lnk->{conproto},
                                      ReplMode=>$replmode,
                                      Description=>$lnk->{comments},
                                      Qty=>'1',
                                      bDelete=>'0',
                                   }
                               };
                   if (defined($acapplrec) && $acapplrec->{applid} ne ""){
                      $acftprec->{APPL_APPL_REL}->{Parent_Appl}=
                                                 $acapplrec->{applid};
                      $acftprec->{APPL_APPL_REL}->{P_Appl_ExternalSystem}='W5Base';
                      $acftprec->{APPL_APPL_REL}->{P_Appl_ExternalID}=$rec->{id};
                   }
                   else{
                      $acftprec->{APPL_APPL_REL}->{P_Appl_ExternalSystem}='W5Base';
                      $acftprec->{APPL_APPL_REL}->{P_Appl_ExternalID}=$rec->{id};
                   }
                   if ($lnk->{lnktoapplid} ne ""){   # only if in the child is
                      $acftprec->{APPL_APPL_REL}->{Child_Appl}=    # an applid
                                                 $lnk->{lnktoapplid};  # known
                      my $fh=$fh{appl_appl_rel};
                      print $fh hash2xml($acftprec,{header=>0});
                      $elements++;
                   }
               }
            }
            {  # prepare contacts
               if (ref($rec->{contacts}) eq "ARRAY"){
                  foreach my $contact (@{$rec->{contacts}}){
                     next if ($contact->{target} ne "base::user");
                     $user->SetFilter({userid=>\$contact->{targetid}});
                     $user->SetCurrentView(qw(ALL));
                     my ($urec,$msg)=$user->getFirst();
                     if (defined($urec)){
                        my $idno;
                        my $posix;
                        if ($urec->{posix} ne ""){
                           $posix=$urec->{posix};
                           $acuser->SetFilter({ldapid=>\$urec->{posix},
                                               deleted=>\'0'});
                           $acuser->SetCurrentView(qw(lempldeptid));
                           my ($acrec,$msg)=$acuser->getFirst();
                           if (defined($acrec)){
                              $idno=$acrec->{lempldeptid};
                           }
                        }
                        elsif ($urec->{email} ne ""){
                           $acuser->SetFilter({email=>\$urec->{email},
                                               deleted=>\'0'});
                           $acuser->SetCurrentView(qw(lempldeptid));
                           my ($acrec,$msg)=$acuser->getFirst();
                           if (defined($acrec)){
                              $idno=$acrec->{lempldeptid};
                           }
                        }
                        next if ($posix eq "");
                        my $acftprec;
                        if (defined($idno)){
                           $CurrentEventId="Add Contact '$posix' ".
                                           "to $CurrentAppl";
           
                           $acftprec={
                                   APPL_CONTACT_REL=>{
                                      EventID=>$CurrentEventId,
                                      Appl_ExternalSystem=>'W5Base',
                                      Appl_ExternalID=>$rec->{id},
                                      Contact=>uc($posix),
                                      Security_Unit=>"TS.DE",
                                      Description=>'',
                                      bDelete=>'0',
                                   }
                               };
                        }
                        else{
                           $CurrentEventId="New Contact '$urec->{email}' ".
                                           "to $CurrentAppl";
                           $acftprec={
                                   APPL_CONTACT_REL=>{
                                      EventID=>$CurrentEventId,
                                      Appl_ExternalSystem=>'W5Base',
                                      Appl_ExternalID=>$rec->{id},
                                      Description=>'',
                                      Security_Unit=>"TS.DE",
                                      Surname=>$urec->{surname},
                                      Givenname=>$urec->{givenname},
                                      EMail=>$urec->{email},
                                      bDelete=>'0',
                                   }
                               };
                        }
                        my $fh=$fh{appl_contact_rel};
                        print $fh hash2xml($acftprec,{header=>0});
                        $elements++;
                        
                     }
                  }
               }
            }
         } # end of exclude conditions

         ($rec,$msg)=$app->getNext();
      } until(!defined($rec));
   }

   $self->TransferFile($fh{appl_contact_rel},$filename{appl_contact_rel},
                       "appl_contact_rel");
   $self->TransferFile($fh{ci_appl_rel},$filename{ci_appl_rel},
                       "ci_appl_rel");
   $self->TransferFile($fh{appl_appl_rel},$filename{appl_appl_rel},
                       "appl_appl_rel");
   my $back=$self->TransferFile($fh{appl},$filename{appl},"appl");

# temp deakiv, da div. Schnittstellenprobleme noch nicht geklärt sind.
#   $self->sendFileToAssetManagerOnlineInterface($onlinefilename,$elements);
   return($back);
}


sub sendFileToAssetManagerOnlineInterface
{
   my $self=shift;
   my $filename=shift;
   my $elements=shift;
   $elements=100000 if (!defined($elements) || $elements==0);

   my $iurl=$self->getParent->Config->Param('DATAOBJSERV');
   my $user=$self->getParent->Config->Param('DATAOBJUSER');
   my $pass=$self->getParent->Config->Param('DATAOBJPASS');
   $iurl={} if (ref($iurl) ne "HASH");
   $user={} if (ref($user) ne "HASH");
   $pass={} if (ref($pass) ne "HASH");
   $iurl=$iurl->{tsaconline};
   $user=$user->{tsaconline};
   $pass=$pass->{tsaconline};
   msg(DEBUG,"Init HTTP Transfer to   : %s",$iurl);
   msg(DEBUG,"AC XML Online-Interface : %s:%s",$user,$pass);
   return($self->sendToAConlineIf($filename,$user,$pass,$iurl,$elements));
}



sub InitTransfer
{
   my $self=shift;
   my $fh;
  my $filename;

   if (!(($fh, $filename) = tempfile())){
      return({msg=>$self->msg(ERROR,'can\'t open tempfile'),exitcode=>1});
   }
   print $fh ("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n\n");
   print $fh ("<XMLInterface>\n");

   return($fh,$filename);
}

sub TransferFile
{
   my $self=shift;
   my $fh=shift;
   my $filename=shift;
   my $object=shift;

   print $fh ("</XMLInterface>\n");
   close($fh);

   my $ftp=new kernel::FileTransfer($self,"tsacftp");
   if (!defined($ftp)){
      return({exitcode=>1,msg=>msg(ERROR,"can't create ftp object")});
   }

   if (open(FI,"<$filename") && open(FO,">/tmp/last.putac.$object.xml")){
      printf FO ("%s",join("",<FI>));
      close(FO);
      close(FI);
   }
   if ($ftp->Connect()){
      msg(INFO,"Connect to FTP Server OK '$ftp' - debug=$self->{DebugMode}");
      my $jobname="w5base.".$self->{jobstart}.".".sprintf("%08d",$$).".xml";
      my $jobfile="$object/$jobname";
      msg(INFO,"Processing  job : '%s'",$jobfile);
      msg(INFO,"Processing  file: '%s'",$filename);
      if (!$self->{DebugMode}){
         my $transferOK=0;
         if ($self->Config->Param("W5BaseOperationMode") ne "xdev"){
            if (!defined($ftp->Put($filename,$jobfile))){
               msg(ERROR,"File $filename to $jobfile could not be transfered:".
                         " $?, $!");
               msg(ERROR,"FTP transfer failed at ".NowStamp("en")." GMT");
               msg(ERROR,"trying to detect ftp error message ...");
            #   my $s;
            #   eval('$s=$ftp->size($jobfile);');
            #   msg(ERROR,"size on remote site is $s ($@)");
            #   msg(ERROR,"... detecting error message done.");
            }
            else{
               $transferOK++;
            }
         }
         else{
            $transferOK++;
         }
         if ($transferOK){
            unlink($filename);
         }
      }
      $ftp->Disconnect();
   }
   else{
      return({msg=>$self->msg(ERROR,'can\'t connect to ftp srv'),exitcode=>1});
   }

   return({exitcode=>0,msg=>'OK'});
}




sub SWInstallModified
{
   my $self=shift;
   my @refid=@_;
   my ($fh, $filename);
   $self->{jobstart}=NowStamp();

   my $lnk=getModuleObject($self->Config,"w5v1inv::lnksoftware2system");
   my $sys=getModuleObject($self->Config,"w5v1inv::system");
   my %filter=();
   if ($#refid!=-1){
      $filter{id}=\@refid;
   }
   $lnk->SetFilter(\%filter);
   #$lnk->Limit(100);
   $lnk->SetCurrentView(qw(id w5systemid software version licencecount));
   my ($fh,$filename)=$self->InitTransfer();

   my ($rec,$msg)=$lnk->getFirst();
   if (defined($rec)){
      do{
         #msg(DEBUG,"dump=%s",Dumper($rec));
         my $jobname="W5Base.$self->{jobstart}.".NowStamp().'.SWInstall_'.
                     sprintf("%d",$rec->{id});
         my $acftprec={
                          SWInstall=>{
                             ExternalSystem=>'W5Base',
                             ExternalID=>$rec->{id},
                             Customer=>"TS.DE",
                             Status=>"installed/active",
                             EventID=>$jobname,
                             AssignmentGroup=>"TIT",
                             SoftwareVersion=>$rec->{version},
                             SoftwareName=>$rec->{software},
                             LicenseUnits=>$rec->{licencecount},
                          }
                      };
         if (defined($rec->{w5systemid})){
            $sys->SetFilter(w5systemid=>$rec->{w5systemid});
            my $systemid=$sys->getVal("systemid");
            $acftprec->{SWInstall}->{AssetTag}=$systemid if ($systemid ne "");
         }
         print $fh hash2xml($acftprec,{header=>0});
         ($rec,$msg)=$lnk->getNext();
      } until(!defined($rec));
   }
   return($self->TransferFile($fh,$filename,"swinstall"));


}



1;
