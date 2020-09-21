package itil::lib::Listedit;
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
use strict;
use vars qw(@ISA);
use kernel;
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use kernel::Field::TextURL;
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5base"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1);
}


sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $wrgroups=shift;

   if (exists($self->{CI_Handling})){
      if (!$self->ProtectObject($oldrec,$newrec,
                                $self->{CI_Handling}->{activator})){
         return(0);
      }
   }
   return($self->SUPER::SecureValidate($oldrec,$newrec,$wrgroups));
}

sub URLValidate
{
   my $self=shift;
   my $name=shift;
   return(kernel::Field::TextURL::URLValidate($name));
}

sub IPValidate 
{
   my $self=shift;
   my $ip=shift;
   my $msg=shift;
   return(kernel::Field::TextURL::IPValidate($ip,$msg));
}

sub isValidClientIP
{
   my $self=shift;
   my $ip=shift;

   if (in_array($ip,[qw(
          127.0.0.1 127.0.0.1 127.0.1.1 127.1.1.1
          0.0.0.0 0.0.0.255 0.0.255.255 0.255.255.255 
          255.255.255.255
          255.255.255.0
          255.0.0.0
       )])){
      return(0);
   }
   return(1);
}



sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   if ($self->getField("cistatusid")){
      $self->NotifyOnCIStatusChange($oldrec,$newrec);
   }
   return($bak);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   return("default") if ( $self->IsMemberOf($self->{adminsgroups}));

   my $effowner=defined($rec) ? $rec->{owner} : undef;
   my $userid=$self->getCurrentUserId();
   if (defined($effowner) && $effowner!=$userid){
      return(undef);
   }

   return("default") if (!defined($rec) || 
                         (defined($rec) && $rec->{cistatus}<=2 &&
                          $rec->{owner}==$userid));
   return(undef);
}


sub isWriteOnCustContractValid
{
   my $self=shift;
   my $contractid=shift;
   my $group=shift;

   my $contract=$self->getPersistentModuleObject("itil::custcontract");
   $contract->SetFilter({id=>\$contractid});
   my ($crec,$msg)=$contract->getOnlyFirst(qw(ALL));
   my @g=$contract->isWriteValid($crec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}

sub isWriteOnApplValid
{
   my $self=shift;
   my $applid=shift;
   my $group=shift;

   my $appl=$self->getPersistentModuleObject("itil::appl");
   $appl->SetFilter({id=>\$applid});
   my ($arec,$msg)=$appl->getOnlyFirst(qw(ALL));
   my @g=$appl->isWriteValid($arec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}


sub isWriteOnApplApplValid
{
   my $self=shift;
   my $lnkapplapplid=shift;
   my $group=shift;

   my $lnkapplappl=$self->getPersistentModuleObject("itil::lnkapplappl");
   $lnkapplappl->SetFilter({id=>\$lnkapplapplid});
   my ($arec,$msg)=$lnkapplappl->getOnlyFirst(qw(ALL));
   my @g=$lnkapplappl->isWriteValid($arec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}



sub isWriteOnITFarmValid
{
   my $self=shift;
   my $itfarmid=shift;
   my $group=shift;

   my $itfarm=$self->getPersistentModuleObject("itil::itfarm");
   $itfarm->SetFilter({id=>\$itfarmid});
   my ($arec,$msg)=$itfarm->getOnlyFirst(qw(ALL));
   my @g=$itfarm->isWriteValid($arec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}


sub isWriteOnClusterValid
{
   my $self=shift;
   my $itclustid=shift;
   my $group=shift;

   if ($itclustid ne ""){
      my $c=getModuleObject($self->Config,"itil::itclust");
      $c->SetFilter({id=>\$itclustid});
      my ($cl,$msg)=$c->getOnlyFirst(qw(ALL));
      my @g=$c->isWriteValid($cl);
      if (grep(/^(ALL|default)$/,@g) || grep(/^$group$/,@g)){
         return(1);
      }
   }
   return(0);
}


sub isWriteOnApplGrpValid
{
   my $self=shift;
   my $applgrpid=shift;
   my $group=shift;

   my $applgrp=$self->getPersistentModuleObject("itil::applgrp");
   $applgrp->SetFilter({id=>\$applgrpid});
   my ($arec,$msg)=$applgrp->getOnlyFirst(qw(ALL));
   my @g=$applgrp->isWriteValid($arec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}

sub isWriteOnSwinstanceValid
{
   my $self=shift;
   my $swinstanceid=shift;
   my $group=shift;

   my $swinstance=$self->getPersistentModuleObject("itil::swinstance");
   $swinstance->SetFilter({id=>\$swinstanceid});
   my ($arec,$msg)=$swinstance->getOnlyFirst(qw(ALL));
   my @g=$swinstance->isWriteValid($arec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}


sub isWriteOnSystemValid
{
   my $self=shift;
   my $systemid=shift;
   my $group=shift;

   my $system=$self->getPersistentModuleObject("itil::system");
   $system->SetFilter({id=>\$systemid});
   my ($srec,$msg)=$system->getOnlyFirst(qw(ALL));
   my @g=$system->isWriteValid($srec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}


sub isWriteOnApplgrpValid
{
   my $self=shift;
   my $applgrpid=shift;
   my $group=shift;

   my $applgrp=$self->getPersistentModuleObject("itil::applgrp");
   $applgrp->SetFilter({id=>\$applgrpid});
   my ($arec,$msg)=$applgrp->getOnlyFirst(qw(ALL));
   my @g=$applgrp->isWriteValid($arec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}


sub isWriteOnITCloudValid
{
   my $self=shift;
   my $itcloudid=shift;
   my $group=shift;

   my $itcloud=$self->getPersistentModuleObject("itil::itcloud");
   $itcloud->SetFilter({id=>\$itcloudid});
   my ($arec,$msg)=$itcloud->getOnlyFirst(qw(ALL));
   my @g=$itcloud->isWriteValid($arec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}


sub isWriteOnSoftwaresetValid
{
   my $self=shift;
   my $softwaresetid=shift;
   my $group=shift;

   my $softwareset=$self->getPersistentModuleObject("itil::softwareset");
   $softwareset->SetFilter({id=>\$softwaresetid});
   my ($arec,$msg)=$softwareset->getOnlyFirst(qw(ALL));
   my @g=$softwareset->isWriteValid($arec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}


sub isWriteOnNetworkValid
{
   my $self=shift;
   my $networkid=shift;
   my $userid=$self->getCurrentUserId();


   my $network=$self->getPersistentModuleObject("itil::network");
   $network->SetFilter({id=>\$networkid});
   my ($nrec,$msg)=$network->getOnlyFirst(qw(ALL));
   if (defined($nrec->{contacts}) && ref($nrec->{contacts}) eq "ARRAY"){
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                                  ["RMember"],"both");
      my @grpids=keys(%grps);
      foreach my $contact (@{$nrec->{contacts}}){
         if ($contact->{target} eq "base::user" &&
             $contact->{targetid} ne $userid){
            next;
         }
         if ($contact->{target} eq "base::grp"){
            my $grpid=$contact->{targetid};
            next if (!grep(/^$grpid$/,@grpids));
         }
         my @roles=($contact->{roles});
         @roles=@{$contact->{roles}} if (ref($contact->{roles}) eq "ARRAY");
         if (grep(/^write$/,@roles)){
            return(1);
         }
      }
   }
   if ($self->IsMemberOf("admin")){
       return(1);
   }
   return(0);
}


sub isWriteOnBProcessValid
{
   my $self=shift;
   my $bprocessid=shift;
   my $group=shift;

   my $bp=$self->getPersistentModuleObject("itil::businessprocess");
   $bp->SetFilter({id=>\$bprocessid});
   my ($arec,$msg)=$bp->getOnlyFirst(qw(ALL));
   my @g=$bp->isWriteValid($arec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}


sub _probeUrl
{
   my $self=shift;
   my $url=shift;
   my $checks=shift;
   my $networkid=shift;
   if (!defined($checks) ||
       ref($checks) ne "ARRAY" ||
       $#{$checks}==-1){
      $checks=[qw(IPCONNECT DNSRESOLV SSLCERT REVDNS)];
   }
   my $d={
      exitcode=>'1',
      exitmsg=>'unable to check url'
   };

   my $na=getModuleObject($self->Config,"itil::network");
   $na->SetFilter({id=>\$networkid});
   my ($nrec,$msg)=$na->getOnlyFirst(qw(ALL));

   my $probeipurl=$nrec->{probeipurl};
   my $probeipproxy=$nrec->{probeipproxy};

   if (!($url=~m#^[a-z0-9]+://#)){
      $url="tcp://".$url;
   }
 
   if ($probeipurl ne ""){
      my $ua;
      eval('
use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Cookies;
use HTML::Parser;

$ua=new LWP::UserAgent(env_proxy=>0);
$ua->timeout(60);
$ua->agent("Mozilla/5.0 (X11; U; Linux i686; de-AT; rv:1.8.1.4) Gecko/20070509 SeaMonkey/1.1.2");
');
      if ($@ ne ""){
         $d->{exitcode}=1100;
         $d->{exitmsg}=$@;
      }
      else{
         if (defined($ua)){
            if ($probeipproxy eq "HTTP_PROXY"){
               $probeipproxy=$self->Config->Param("http_proxy");
            }
            if ($probeipproxy ne ""){
               $ua->proxy(['http','https'],$probeipproxy);
            }
         }
         $ua->timeout(200);
         my $req=POST($probeipurl,[url=>$url,operation=>$checks]);
         $req->header('user-agent'=>'Mozilla/5.0 (X11; Linux x86_64)');
         $req->header('Accept'=>'*/*');

         my $response=$ua->request($req);
         if ($response->code ne "200"){
            msg(ERROR,"fail to probeip '$probeipurl' at ".
                      "network '$nrec->{name}' response ".
                      "HTTP Code='".$response->code."' while query '$url'");
            return(0,undef);
         }
         my $res=$response->content;
         if ($res eq ""){
            msg(ERROR,"can not contact probeip url '$url' at ".
                      "network '$nrec->{name}'");
            $d->{exitcode}=1101;
            $d->{exitmsg}="probeip url not accessable";
            return($d);
         }
         my $rdata;
         eval("use JSON; \$rdata=decode_json(\$res);");
         if ($@ ne ""){
            $d->{exitcode}=1200;
            $d->{exitmsg}=$@;
         }
         if (ref($rdata) eq "HASH"){
            $d=$rdata;
            $d->{networkid}=$networkid;
            $d->{probeipurl}=$probeipurl;
            if ($probeipproxy ne ""){
               $d->{probeipurl}=$probeipurl;
            }
         }
         else{
            $d->{exitcode}=1201;
            msg(ERROR,"invalid JSON response from probeip ".
                      "url '$probeipurl' at ".
                      "network '$nrec->{name}' while query to '$url'");
            print STDERR "DEBUG INfo:".Dumper($rdata);
            $d->{exitmsg}="probeip url answers with invalid json data";
         }
      }
   }
   else{
      $d->{exitcode}=999;
      my $networkname="NetworkAreaID:$networkid";
      if (defined($nrec)){
         $networkname=$nrec->{name}
      }
      $d->{exitmsg}="ERROR: unable to scan networkarea \"$networkname\" - ".
                    "no probe url known";
   }
   return($d);
}

sub probeUrl
{
   my $self=shift;
   my $url=shift;
   my $checks=shift;
   my $networkid=shift;

   if ($networkid ne "" && $networkid ne "0"){
      my $tempchk=_probeUrl($self,$url,$checks,$networkid);
      if (ref($tempchk) eq "HASH" &&
          $tempchk->{exitcode} eq "502"   # Bad Gateway
         ){  # sleep some time and make a second try
         sleep(10);
         $tempchk=_probeUrl($self,$url,$checks,$networkid);
      }
      return($tempchk);


   }
   else{
      my $na=getModuleObject($self->Config,"itil::network");
      $na->SetFilter({cistatusid=>'4',probeipurl=>'!""'});
      foreach my $netrec ($na->getHashList(qw(ALL))){
         if ($netrec->{id} ne "0" && $netrec->{id} ne ""){
            my $tempchk=probeUrl($self,$url,$checks,$netrec->{id});
            if (ref($tempchk) eq "HASH" &&
                $tempchk->{exitcode} eq "0" ){
               return($tempchk);
            }
         }
      }
      return({
         exitcode=>9999,
         exitmsg=>"ERROR: unable to find url in any networkarea"
      });
   }
}



#sub preQualityCheckRecord
#{
#   my $self=shift;
#   my $rec=shift;
#   my @param=@_;
#
#   # load Autodiscovery Data from all configured engines
#
#   my %AutoDiscovery=();
#
#   my $p=$self->SelfAsParentObject();
#   if ($p eq "itil::system" || $p eq "itil::swinstance"){
#      my $add=$self->getPersistentModuleObject("itil::autodiscdata");
#      my $ade=$self->getPersistentModuleObject("itil::autodiscengine");
#      $ade->SetFilter({localdataobj=>\$p});
#      foreach my $engine ($ade->getHashList(qw(ALL))){
#         my $rk;
#         $rk="systemid"     if ($p eq "itil::system");
#         $rk="swinstanceid" if ($p eq "itil::swinstance");
#         $add->SetFilter({$rk=>\$rec->{id},engine=>\$engine->{name}});
#         my ($oldadrec)=$add->getOnlyFirst(qw(ALL));
#         # check age of oldadrec - if newer then 24h - use old one
#            # todo
#
#         my $ado=$self->getPersistentModuleObject($engine->{addataobj});
#         if (!exists($rec->{$engine->{localkey}})){
#            # autodisc key data does not exists in local object
#            msg(ERROR,"preQualityCheckRecord failed for $p ".
#                      "local key $engine->{localkey} does not exists");
#            next;
#         }
#         if (defined($ado)){  # check if autodisc object name is OK
#            my $adokey=$ado->getField($engine->{adkey});
#            if (defined($adokey)){ # check if autodisc key is OK
#               my $adfield=$add->getField("data");
#               $ado->SetFilter({
#                  $engine->{adkey}=>\$rec->{$engine->{localkey}}
#               });
#               my ($adrec)=$ado->getOnlyFirst(qw(ALL));
#               if (defined($adrec)){
#                  if ($ado->Ping()){
#                     $adrec->{xmlstate}="OK";
#                     my $adxml=hash2xml({xmlroot=>$adrec});
#                     if (!defined($oldadrec)){
#                        $add->ValidatedInsertRecord({engine=>$engine->{name},
#                                                     $rk=>$rec->{id},
#                                                     data=>$adxml});
#                     }
#                     else{
#                        my $upd={data=>$adxml};
#                        my $chk=$adfield->RawValue($oldadrec);
#                        if (trim($upd->{data}) eq trim($chk)){  # wird verm.
#                           delete($upd->{data});    # sein, da XML im Aufbau
#                           $upd->{mdate}=$oldadrec->{mdate}; # dynamisch ist
#                        }
#                        $add->ValidatedUpdateRecord($oldadrec,$upd,{
#                           engine=>\$engine->{name},
#                           $rk=>\$rec->{id}
#                        });
#                     }
#                     $AutoDiscovery{$engine->{name}}={
#                        data=>$adfield->RawValue({data=>$adxml})
#                     };
#                  }
#               }
#               if (defined($oldadrec) && 
#                   !exists($AutoDiscovery{$engine->{name}})){
#                  $AutoDiscovery{$engine->{name}}={
#                     data=>$adfield->RawValue($oldadrec)
#                  };
#               }
#            }
#            else{
#               msg(ERROR,"preQualityCheckRecord failed for $p ".
#                         "while access AutoDisc($engine->{name}) key ".
#                          $engine->{adkey});
#            }
#         }
#         else{
#            msg(ERROR,"preQualityCheckRecord failed for $p ".
#                      "while load AutoDisc($engine->{name}) object ".
#                       $engine->{addataobj});
#         }
#      }
#   }
#   $param[0]->{AutoDiscovery}=\%AutoDiscovery;
#   return(1);
#}


sub updateDenyHandling
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $denyupdid;
   if (exists($newrec->{denyupdid})){
      $denyupdid=$newrec->{denyupdid};
   }
   if (exists($newrec->{denyupd})){
      $denyupdid=$newrec->{denyupd};
   }
   if (defined($denyupdid)){
      if ($denyupdid>0){
         if (exists($newrec->{denyupdvalidto}) &&
             $newrec->{denyupdvalidto} ne ""){
            # prüfen ob länger als 36 Monate in der Zukunft!
            my $d=CalcDateDuration(NowStamp("en"),$newrec->{denyupdvalidto});
            if ($d->{days}>1095){
               $self->LastMsg(ERROR,
                    "deny reject valid to can only be 3 years in the future");
               return(0);
            }
         }
         if (effVal($oldrec,$newrec,"denyupdvalidto") eq ""){ # default=1.5Jahre
            $newrec->{denyupdvalidto}=$self->ExpandTimeExpression("now+550d");
         }
      }
      else{
         if ($oldrec->{denyupdcomments} ne "" ||
             $newrec->{denyupdcomments} ne ""){
            $newrec->{denyupdcomments}="";
         }
         if ($oldrec->{denyupdvalidto} ne "" ||
             $newrec->{denyupdvalidto} ne ""){
            $newrec->{denyupdvalidto}=undef;
         }
      }
   }
   if ($self->SelfAsParentObject() eq "itil::asset"){
      if (effChanged($oldrec,$newrec,"denyupdvalidto") ||
          effChanged($oldrec,$newrec,"refreshpland") ||
          effChanged($oldrec,$newrec,"denyupd") ||
          effChanged($oldrec,$newrec,"deprstart")){
         CHKLOOP: foreach my $var (qw(refreshinfo3 
                                      refreshinfo2 
                                      refreshinfo1)){
            my $cur=effVal($oldrec,$newrec,$var);
            if ($cur ne ""){
               my $d=CalcDateDuration(NowStamp("en"),$cur);
               if ($d->{days}>-28){
                  last CHKLOOP;
               }
               $newrec->{$var}=undef;
            }
         }
      }
   }
   return(1);
}


sub getupdateDenyHandlingScript
{
   my $self=shift;
   my $app=$self->getParent();

   my $d=<<EOF;

var d=document.forms[0].elements['Formated_denyupd'];
var r=document.forms[0].elements['Formated_refreshpland'];
var c=document.forms[0].elements['Formated_denyupdcomments'];

if (!d){
   d=document.forms[0].elements['Formated_denyupselect']; // new style
}

if (d){
   var v=d.options[d.selectedIndex].value;
   if (v!="" && v!="0"){
      if (r){
         r.value="";
         r.disabled=true;
      }
      if (c){
         c.disabled=false;
      }
   }
   else{
      if (c){
         c.value="";
         c.disabled=true;
      }
      if (r){
         r.disabled=false;
      }
   }
}

EOF
   return($d);
}

sub Version2Key
{
   my $version=shift;

   my @v=split(/\./,$version);
   my @relkey=();
   for(my $relpos=0;$relpos<5;$relpos++){
      $v[$relpos]=~s/\D//g;
      if ($v[$relpos]=~m/^\d+$/){
         $relkey[$relpos]=sprintf("%06d",int($v[$relpos]));
         if (length($relkey[$relpos])>6){
            $relkey[$relpos]=substr($relkey[$relpos],
                                    length($relkey[$relpos])-6);
         }
      }
      else{
         $relkey[$relpos]="000000";
      }
   }
   return(join("",@relkey));
}


sub calcSoftwareState
{
   my $self=shift;
   my $current=shift;
   my $analysedataobj=shift;
   my $forcesoftwarecallname=shift;

   if (!defined($analysedataobj) || $analysedataobj eq ""){
      $analysedataobj="itil::lnksoftwaresystem";
   }

   my $FilterSet=$self->getParent->Context->{FilterSet};
   if ($FilterSet->{softwareset} eq ""){
      return("NO SOFTSET SELECTED");
   }
   if ($FilterSet->{Set}->{name} ne $FilterSet->{softwareset} &&
       $FilterSet->{softwareset} ne ""){
      $FilterSet->{Set}={name=>$FilterSet->{softwareset}};
      my $ss=getModuleObject($self->getParent->Config,
                             "itil::softwareset");
      my $setname=$FilterSet->{softwareset};
      my $flt={cistatusid=>\'4',name=>$setname};
      $ss->SetFilter($flt);
      my ($rec)=$ss->getOnlyFirst("name","software","osrelease");
      if (!defined($rec)){
         my $fsetname;
         $fsetname=" -".$setname."- ";
         if (ref($setname) eq "ARRAY"){
            $fsetname=" -[".join(",",@$setname)."]- ";
         }
         return("INVALID SOFTSET $fsetname SELECTED");
      }
      #print STDERR Dumper($rec);
      $FilterSet->{Set}->{data}=$rec;
      Dumper($FilterSet->{Set}->{data});
   }
   my @applid;
   my @analysegroups=qw(OS MW DB);
   my @systemid;
   my $cachekey;
   if ($self->getParent->SelfAsParentObject() eq "itil::system"){
      @systemid=($current->{id});
      $cachekey=join(",",sort(@systemid));
      @analysegroups=qw(OS);
   }
   elsif ($self->getParent->SelfAsParentObject() eq "itil::appl"){
      @applid=($current->{id});
      $cachekey=join(",",sort(@applid));
   }
   else{
      @analysegroups=qw(MW DB);
      $cachekey=$current->{id};
   }
   if ($FilterSet->{Analyse}->{id} ne $cachekey){
      $FilterSet->{Analyse}={id=>$cachekey};
      # load interessting softwareids from softwareset
      my %swid;
      foreach my $swrec (@{$FilterSet->{Set}->{data}->{software}}){
         $swid{$swrec->{softwareid}}++;
      }
      # check softwareset against installations
      $FilterSet->{Analyse}->{relevantSoftwareInst}=0;
      $FilterSet->{Analyse}->{todo}=[];
      $FilterSet->{Analyse}->{totalstate}="OK";
      $FilterSet->{Analyse}->{dstate}={};
      $FilterSet->{Analyse}->{totalmsg}=[];
      $FilterSet->{Analyse}->{softwareid}=[keys(%swid)];

      my $resdstate=$FilterSet->{Analyse}->{dstate};
      foreach my $g (@analysegroups){
         $resdstate->{group}->{$g}={
            count=>0,
            fail=>0,
            warn=>0,
         };
      }

      if ($#applid!=-1 || $#systemid!=-1){ # load systems
         my $lnk=getModuleObject($self->getParent->Config,
                                "itil::lnkapplsystem");
         if ($#applid!=-1){
            $lnk->SetFilter({applid=>\@applid,
                             systemcistatusid=>[3,4]}); 
         }
         else{
            $lnk->SetFilter({systemid=>\@systemid,
                             applcistatusid=>[3,4]}); 
         }
         $FilterSet->{Analyse}->{systems}=[];
         $FilterSet->{Analyse}->{systemids}={};
         foreach my $lnkrec ($lnk->getHashList(qw(systemid osreleaseid
                                                  system 
                                                  systemdenyupd
                                                  systemdenyupdvalidto))){
            my $sid=$lnkrec->{systemid};
            if (!exists($FilterSet->{Analyse}->{systemids}->{$sid})){
               my $srec={
                  name=>$lnkrec->{system},
                  systemid=>$lnkrec->{systemid},
                  denyupd=>$lnkrec->{systemdenyupd},
                  denyupdvalidto=>$lnkrec->{systemdenyupdvalidto},
                  osrelease=>$lnkrec->{osrelease},
                  osreleaseid=>$lnkrec->{osreleaseid}
               };
               $FilterSet->{Analyse}->{systemids}->{$sid}=$srec;
               push(@{$FilterSet->{Analyse}->{systems}},
                    $FilterSet->{Analyse}->{systemids}->{$sid});
               my @ruleset;
               if (ref($FilterSet->{Set}->{data}->{osrelease}) eq "ARRAY"){
                  @ruleset=@{$FilterSet->{Set}->{data}->{osrelease}};
               }
               @ruleset=sort({$a->{comparator}<=>$b->{comparator}} @ruleset);

               my $failpost="";
               if ($srec->{denyupd}>0){
                  $failpost=" but OK";
                  if ($srec->{denyupdvalidto} ne ""){
                      my $d=CalcDateDuration(
                                        NowStamp("en"),$srec->{denyupdvalidto});
                      if ($d->{totalminutes}<0){
                         $failpost=" and not OK";
                      }
                  }
               }

               my $dstate="OK";
               $resdstate->{group}->{OS}->{count}++;
               foreach my $osrec (@ruleset){
                  if ($srec->{osreleaseid} eq  $osrec->{osreleaseid}){
                     if ($osrec->{comparator} eq "0"){
                        $dstate="FAIL";
                        if ($failpost ne " but OK"){
                           push(@{$FilterSet->{Analyse}->{todo}},
                                 "- update OS '$srec->{osrelease}' ".
                                 "on $srec->{name}");
                           push(@{$FilterSet->{Analyse}->{totalmsg}},
                               "$srec->{name} OS '$srec->{osrelease}' ".
                               "is marked as not allowed");
                           $resdstate->{group}->{OS}->{fail}++;
                        }
                        if (!($FilterSet->{Analyse}->{totalstate}=~m/^FAIL/)){
                           $FilterSet->{Analyse}->{totalstate}="FAIL".$failpost;
                        }
                     }
                     if ($osrec->{comparator} eq "1"){
                        $dstate="WARN";
                        if ($failpost ne " but OK"){
                           push(@{$FilterSet->{Analyse}->{todo}},
                                 "- OS '$srec->{osrelease}' ".
                                 "on $srec->{name} needs soon a update");
                           push(@{$FilterSet->{Analyse}->{totalmsg}},
                               "$srec->{name} OS '$srec->{osrelease}' ".
                               "is soon not allowed");
                           $resdstate->{group}->{OS}->{warn}++;
                        }
                        if (!($FilterSet->{Analyse}->{totalstate}=~m/^FAIL/)){
                           $FilterSet->{Analyse}->{totalstate}=
                              "WARN".$failpost;
                        }
                     }
                  }
               }
               if (ref($resdstate->{system}->{record}) ne "ARRAY"){
                  $resdstate->{system}->{record}=[];
               }
               push(@{$resdstate->{system}->{record}},{
                  systemname=>$lnkrec->{system},
                  state=>$dstate,
               });
            }
         }
      }
      #print STDERR Dumper($FilterSet->{Analyse});
      my $lnk=getModuleObject($self->getParent->Config,$analysedataobj);
      if ($#applid!=-1){# load system installed software
         $lnk->SetFilter({
           systemid=>[keys(%{$FilterSet->{Analyse}->{systemids}})]
         });
      }
      else{
         $lnk->SetFilter({id=>\$current->{id}});
      }
      my @fl=qw(id systemid softwareid);
      if ($lnk->can("getAnalyseSoftwareStateRecordsIndexed")){
         $FilterSet->{Analyse}->{ssoftware}=
            $lnk->getAnalyseSoftwareStateRecordsIndexed(@fl);
      }
      else{
         $lnk->SetCurrentView(qw(systemid system software denyupd denyupdvalidto
                                 releasekey version softwareid is_dbs is_mw));
         $FilterSet->{Analyse}->{ssoftware}=$lnk->getHashIndexed(@fl);
      }


      if ($#applid!=-1){# load related software instances
         my $sw=getModuleObject($self->getParent->Config,
                                "itil::swinstance");
         $sw->SetFilter({cistatusid=>[3,4],
                         applid=>\$current->{id}});
         $FilterSet->{Analyse}->{swi}=[
              $sw->getHashList(qw(id lnksoftwaresystemid fullname))];
      }

      my $ssoftware=$FilterSet->{Analyse}->{ssoftware}->{softwareid};

      my @ruleset=@{$FilterSet->{Set}->{data}->{software}};

      @ruleset=sort({$b->{comparator}<=>$a->{comparator}} @ruleset);


      foreach my $swi (values(%{$FilterSet->{Analyse}->{ssoftware}->{id}})){
         my $softwarecallname=$swi->{software};
         if ($forcesoftwarecallname ne ""){
            $softwarecallname=$forcesoftwarecallname;  
                              # for f.e. HPSA Autodiscovery Data 
         }                    # with diffrent software frontend names
         if ($swi->{is_mw}){
            $resdstate->{group}->{MW}->{count}++;
         }
         if ($swi->{is_dbs}){
            $resdstate->{group}->{DB}->{count}++;
         }
         
         RULESET: foreach my $swrec (@ruleset){
            if ($swrec->{softwareid} eq  $swi->{softwareid}){
               $FilterSet->{Analyse}->{relevantSoftwareInst}++;
               if ($swi->{version}=~m/^\s*$/){
                  push(@{$FilterSet->{Analyse}->{todo}},
                        "- no version specified in software installaton ".
                        "of $swrec->{softwareid} on system $swi->{systemid}");
               }
               if ($swrec->{startwith} ne ""){
                  my $qstartwith=quotemeta($swrec->{startwith});
                  if (!($swi->{version}=~m/^$qstartwith/i)){
                     next RULESET;
                  }
               }
               my $failpost="";
               if ($swi->{denyupd}>0){
                  $failpost=" but OK";
                  if ($swi->{denyupdvalidto} ne ""){
                      my $d=CalcDateDuration(
                                        NowStamp("en"),$swi->{denyupdvalidto});
                      if ($d->{totalminutes}<0){
                         $failpost=" and not OK";
                      }
                  }
               }
               if ($swi->{releasekey}=~m/^0*$/){
                  push(@{$FilterSet->{Analyse}->{todo}},
                        "- version unusable in  ".
                        "$softwarecallname on $swi->{system} ");
                  $FilterSet->{Analyse}->{totalstate}="FAIL";
                  push(@{$FilterSet->{Analyse}->{totalmsg}},
                       "version unusable");
                  last RULESET;
               }
               if (length($swrec->{releasekey})!=
                   length($swi->{releasekey}) ||
                   ($swi->{releasekey}=~m/^0*$/) ||
                   ($swrec->{releasekey}=~m/^0*$/)){
                  push(@{$FilterSet->{Analyse}->{todo}},
                        "- releasekey missmatch in  ".
                        "$softwarecallname on $swi->{system} ");
                  $FilterSet->{Analyse}->{totalstate}="FAIL";
                  push(@{$FilterSet->{Analyse}->{totalmsg}},
                       "releasekey error");
               }
               else{
                  if ($swrec->{comparator} eq "3"){
                     if ($swrec->{releasekey} gt $swi->{releasekey}){
                        if ($failpost ne " but OK"){
                           push(@{$FilterSet->{Analyse}->{todo}},
                                 "- soon update $softwarecallname on ".
                                 "system $swi->{system} ".
                                 "from $swi->{version} to  $swrec->{version}");
                           if ($swi->{is_mw}){
                              $resdstate->{group}->{MW}->{warn}++;
                           }
                           if ($swi->{is_dbs}){
                              $resdstate->{group}->{DB}->{warn}++;
                           }
                        }
                        if (!($FilterSet->{Analyse}->{totalstate}=~m/^FAIL/)){
                           $FilterSet->{Analyse}->{totalstate}="WARN".$failpost;
                        }
                        push(@{$FilterSet->{Analyse}->{totalmsg}},
                             "$softwarecallname needs soon >=$swrec->{version}");
                        last RULESET;
                     }
                  }
                  elsif ($swrec->{comparator} eq "2"){
                     if ($swrec->{releasekey} ne $swi->{releasekey} ||
                         $swrec->{version} ne $swi->{version}){
                        if ($failpost ne " but OK"){
                           push(@{$FilterSet->{Analyse}->{todo}},
                                 "- only version $swi->{version} ".
                                 " of $softwarecallname is allowed on  ".
                                 " system $swi->{system} ");
                           if ($swi->{is_mw}){
                              $resdstate->{group}->{MW}->{fail}++;
                           }
                           if ($swi->{is_dbs}){
                              $resdstate->{group}->{DB}->{fail}++;
                           }
                        }
                        if (!($FilterSet->{Analyse}->{totalstate}=~m/^FAIL/)){
                           $FilterSet->{Analyse}->{totalstate}="FAIL".$failpost;
                        }
                        push(@{$FilterSet->{Analyse}->{totalmsg}},
                             "$softwarecallname needs $swrec->{version}");
                        last RULESET;
                     }
                  }
                  elsif ($swrec->{comparator} eq "12"){
                     if ($swrec->{releasekey} eq $swi->{releasekey} ||
                         $swrec->{version} eq $swi->{version}){
                        last RULESET;
                     }
                  }
                  elsif ($swrec->{comparator} eq "10"){
                     if ($swrec->{releasekey} eq $swi->{releasekey} ||
                         $swrec->{version} eq $swi->{version}){
                        if ($failpost ne " but OK"){
                           push(@{$FilterSet->{Analyse}->{todo}},
                               "- remove disallowed version $softwarecallname ".
                               " $swi->{version} from  system $swi->{system} ");
                           if ($swi->{is_mw}){
                              $resdstate->{group}->{MW}->{fail}++;
                           }
                           if ($swi->{is_dbs}){
                              $resdstate->{group}->{DB}->{fail}++;
                           }
                        }
                        if (!($FilterSet->{Analyse}->{totalstate}=~m/^FAIL/)){
                           $FilterSet->{Analyse}->{totalstate}="FAIL".$failpost;
                        }
                        push(@{$FilterSet->{Analyse}->{totalmsg}},
                             "$softwarecallname disallowed $swrec->{version}");
                        last RULESET;
                     }
                  }
                  elsif ($swrec->{comparator} eq "11"){
                     if ($swrec->{releasekey} gt $swi->{releasekey}){
                        if ($failpost ne " but OK"){
                           push(@{$FilterSet->{Analyse}->{todo}},
                               "- remove disallowed version $softwarecallname ".
                               " $swi->{version} from  system $swi->{system} ");
                           if ($swi->{is_mw}){
                              $resdstate->{group}->{MW}->{fail}++;
                           }
                           if ($swi->{is_dbs}){
                              $resdstate->{group}->{DB}->{fail}++;
                           }
                        }
                        if (!($FilterSet->{Analyse}->{totalstate}=~m/^FAIL/)){
                           $FilterSet->{Analyse}->{totalstate}="FAIL".$failpost;
                        }
                        push(@{$FilterSet->{Analyse}->{totalmsg}},
                             "$softwarecallname disallowed ".
                             "lower then $swrec->{version}");
                        last RULESET;
                     }
                  }
                  elsif ($swrec->{comparator} eq "0"){
                     if ($swrec->{releasekey} gt $swi->{releasekey}){
                        if ($failpost ne " but OK"){
                           push(@{$FilterSet->{Analyse}->{todo}},
                                 "- update $softwarecallname on ".
                                 "system $swi->{system} ".
                                 "from $swi->{version} to  $swrec->{version}");
                           if ($swi->{is_mw}){
                              $resdstate->{group}->{MW}->{fail}++;
                           }
                           if ($swi->{is_dbs}){
                              $resdstate->{group}->{DB}->{fail}++;
                           }
                        }
                        if (!($FilterSet->{Analyse}->{totalstate}=~m/^FAIL/)){
                           $FilterSet->{Analyse}->{totalstate}="FAIL".$failpost;
                        }
                        push(@{$FilterSet->{Analyse}->{totalmsg}},
                             "$softwarecallname needs >=$swrec->{version}");
                        last RULESET;
                     }
                  }
               }
            }
         }
      }
   }

   my @d;
   if ($#applid!=-1){
      { # system count
         my $m=sprintf("analysed system count: %d",
                         int(keys(%{$FilterSet->{Analyse}->{systemids}})));
         if ($#{$FilterSet->{Analyse}->{systems}}==-1){
            push(@d,"<font color=red>"."WARN: ".$m."</font>");
         }
         else{
            push(@d,"INFO: ".$m);
         }
      }
      # softwareinstallation count
      if (int(keys(%{$FilterSet->{Analyse}->{systemids}}))!=0){
         my $m=sprintf("analysed software installations count: %d",
                        keys(%{$FilterSet->{Analyse}->{ssoftware}->{id}})+0);
         if (keys(%{$FilterSet->{Analyse}->{ssoftware}->{id}})==0){
            push(@d,"<font color=red>"."WARN: ".$m."</font>");
         }
         else{
            push(@d,"INFO: ".$m);
         }
         { # check software instances
            my $m=sprintf("analysed software instance count: %d",
                            $#{$FilterSet->{Analyse}->{swi}}+1);
            if ($#{$FilterSet->{Analyse}->{swi}}!=-1){
               push(@d,"INFO: ".$m);
            }
            else{
               push(@d,"<font color=red>"."WARN: ".$m."</font>");
            }
         }
         my $m=sprintf("found <b>%d</b>".
                       " relevant software installations for check",
                       $FilterSet->{Analyse}->{relevantSoftwareInst});
         push(@d,"INFO: ".$m);
      }
   }
   my $finestate="green";
   if ($FilterSet->{Analyse}->{totalstate} eq "WARN"){
      $finestate="yellow";
   }
   elsif ($FilterSet->{Analyse}->{totalstate} eq "FAIL"){
      $finestate="red";
   }
   my @resdstate;
   foreach my $g (sort(keys(%{$FilterSet->{Analyse}->{dstate}->{group}}))){
       push(@resdstate,"$g(".
              $FilterSet->{Analyse}->{dstate}->{group}->{$g}->{count}."/".
              $FilterSet->{Analyse}->{dstate}->{group}->{$g}->{warn}."/".
              $FilterSet->{Analyse}->{dstate}->{group}->{$g}->{fail}.")");
   }
   push(@d,"INFO:  total state ".$FilterSet->{Analyse}->{totalstate});
   push(@d,"INFO:  grouped state format (count/warn/fail)");
   push(@d,"INFO:  grouped state ".join(" ",@resdstate));
   push(@d,"<b>STATE:</b> <font color=$finestate>".$finestate."</font>");
   
   if ($self->Name eq "rawsoftwareanalysestate"){
      Dumper($FilterSet->{Analyse});
      return({xmlroot=>{
         totalstate=>$FilterSet->{Analyse}->{totalstate},
         dstate=>$FilterSet->{Analyse}->{dstate},
         finestate=>$finestate,
         totalmsg=>$FilterSet->{Analyse}->{totalmsg},
         systems=>$FilterSet->{Analyse}->{systems},
         software=>$FilterSet->{Analyse}->{softwareid},
         relevantSoftwareInst=>$FilterSet->{Analyse}->{relevantSoftwareInst}
      }});
   }
   if ($self->Name eq "softwareanalysestate"){
      return("<div style='width:300px'>".join("<br>",@d)."</div>");
   }
   if ($self->Name eq "softwareanalysetodo" ||
       $self->Name eq "osanalysetodo"){
      return("<div style='width:500px'>".
             join("<br>",@{$FilterSet->{Analyse}->{todo}})."</div>");
   }
   if ($self->Name eq "softwareinstrelstate"){
      my $totalstate=$FilterSet->{Analyse}->{totalstate};
      if ($totalstate eq "OK" && 
          $FilterSet->{Analyse}->{relevantSoftwareInst}==0){
         $totalstate.=" unrestricted";
      }
      return($totalstate);
   }
   if ($self->Name eq "softwarerelstate" ||
       $self->Name eq "osanalysestate"){
      return($FilterSet->{Analyse}->{totalstate});
   }

   if ($self->Name eq "softwareinstrelmsg" ||
       $self->Name eq "softwarerelmsg"){
      return(join("\n",@{$FilterSet->{Analyse}->{totalmsg}}));
   }

   return(join("<br>",@d));
}


sub handleCertExpiration
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $parentobj=shift;
   my $parentrec=shift;
   my $qmsg=shift;
   my $dataissue=shift;
   my $errorlevel=shift;
   my $param=shift;
   my $newrec;

   if (ref($param) ne 'HASH') {
      Stacktrace();
      return(0);
   }
   my $expnotifyleaddays=$param->{expnotifyleaddays};

   if ($expnotifyleaddays eq "" ||
       $expnotifyleaddays<14    ||
       $expnotifyleaddays>70){
      $expnotifyleaddays=8*7;   # default Handling=8 weeks
   }

   return(0) if (!defined($param->{expdatefld}));

   my $endfld=$param->{expdatefld};
   my $notifyfld=$param->{expnotifyfld};

   my $notifylevel=$expnotifyleaddays;
   my $issuelevel =2*7; # 2 week  - dataissue

   $notifylevel=$param->{notifylevel} if (exists($param->{notifylevel}));
   $issuelevel =$param->{issuelevel}  if (exists($param->{issuelevel}));

   if (!defined($parentobj)) {
      $parentobj=$dataobj;
      $parentrec=$rec;
   }

   my $d=CalcDateDuration(NowStamp('en'),$rec->{$endfld},'GMT');

   if (defined($notifylevel)) {
      if ($d->{days}<$notifylevel &&
         ((defined($notifyfld) && !defined($rec->{$notifyfld})) ||
          !defined($notifyfld))) {
         my $uobj=getModuleObject($self->getParent->Config,'base::user');
         $uobj->SetFilter({userid=>\$parentrec->{databossid},
                           cistatusid=>\4});
         my ($databoss,$msg)=$uobj->getOnlyFirst(qw(userid tz lastlang));

         my %ul;
         my @fields=qw(tsmid tsm2id opmid opm2id);
         if (exists($parentrec->{applid}) && $parentrec->{applid}){
            my $aobj=getModuleObject($self->getParent->Config,'itil::appl');
            $aobj->SetFilter({id=>\$parentrec->{applid}});
            my ($arec,$msg)=$aobj->getOnlyFirst(@fields);
            if (defined($arec)){
               foreach my $f (@fields){
                  if ($arec->{$f} ne ""){
                     $ul{$arec->{$f}}={};
                  }
               }
            }
         }
         foreach my $f (@fields){
            if (exists($parentrec->{$f}) && $parentrec->{$f} ne ""){
               $ul{$parentrec->{$f}}={};
            }
         }
         $parentobj->getWriteAuthorizedContacts($parentrec,
                                                [qw(contacts)],30,\%ul);
         my $emailto;
         my @emailcc=keys(%ul);
         my $lastlang=$ENV{HTTP_FORCE_LANGUAGE};
         my $lang;
         my $timezone;

         if (defined($databoss->{userid})) {
            $emailto=$databoss->{userid};
            $lang=$databoss->{lastlang};
            $timezone=$databoss->{tz};
         }
         else {
            $uobj->ResetFilter();
            $uobj->SetFilter({userid=>\@emailcc,cistatusid=>\4});
            my @contacts=$uobj->getHashList(qw(userid tz lang));
            $emailto=$contacts[0]->{userid};
            $lang=$contacts[0]->{lastlang};
            $timezone=$contacts[0]->{tz};
         }
         if ($lang eq ""){
            $lang="en";
         }
         $ENV{HTTP_FORCE_LANGUAGE}=$lang;

         @emailcc=grep($_!=$emailto,@emailcc);

         my %notifyparam=(emailto=>$emailto,
                          emailcc=>\@emailcc);

         my $subject=$self->T('Expiration of a certificate');

         my $exp=$dataobj->getField($endfld)
                         ->FormatedDetail({$endfld=>$rec->{$endfld}});
         $exp.=" ".$timezone;

         my $text=$self->T('Dear databoss').",\n\n";
         if ($d->{totalminutes}>0) {
           $exp.=sprintf(" (in %d %s)",$d->{days},$self->T('days'));
           $text.=sprintf($self->T("Certificate for %s expires"),
                          $parentrec->{name});
         }
         else {
           $text.=sprintf($self->T("Certificate for %s has expired"),
                          $parentrec->{name});
         }
         $text.="\n\n".$self->T('Expiration date').":\n";
         $text.="$exp\n\n";
         $text.=$self->T('SSLEXP01')."\n\n";
         $text.="DirectLink:\n".$rec->{urlofcurrentrec};

         $newrec->{$notifyfld}=NowStamp('en');
         my $wfact=getModuleObject($self->getParent->Config,
                                   "base::workflowaction");
         $wfact->Notify("INFO",$subject,$text,%notifyparam);

         if (defined($lastlang)){
            $ENV{HTTP_FORCE_LANGUAGE}=$lastlang;
         }
         else{
            delete($ENV{HTTP_FORCE_LANGUAGE});
         }
      }
      elsif ($d->{days}>=$notifylevel &&
             defined($notifyfld) &&
             defined($rec->{$notifyfld})) {
            $newrec->{$notifyfld}=undef;
      }
   }

   if (defined($newrec)) {
      $dataobj->ValidatedUpdateRecord($rec,$newrec,{id=>$rec->{id}});
   }

   if (defined($issuelevel) && $d->{days}<$issuelevel) {
      my $msg;

      $$errorlevel=3 if ($$errorlevel<3);

      if ($d->{totalminutes}<0) {
         $msg='Certificate has expired';
      }
      else {
         $msg='Certificate expires in a few days';
      }

      if ($parentobj==$dataobj) {
         push(@$qmsg,$msg);
         push(@$dataissue,$msg);
      }
      else {
         push(@$qmsg,$msg.': '.$rec->{name});
         push(@$dataissue,$msg.': '.$rec->{urlofcurrentrec});
      }
   }

   return(1);
}


sub validateSoftwareVersion
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $version=effVal($oldrec,$newrec,"version");
   my $softwareid=effVal($oldrec,$newrec,"softwareid");
   my $sw=getModuleObject($self->Config,"itil::software");
   $sw->SetFilter({id=>\$softwareid});
   my ($rec,$msg)=$sw->getOnlyFirst(qw(releaseexp));
   if (!defined($rec)){
      $self->LastMsg(ERROR,"invalid software specified");
      return(undef);
   }
   my $releaseexp=$rec->{releaseexp};
   if (defined($ENV{SERVER_SOFTWARE})){
      if (!($releaseexp=~m/^\s*$/)){
         my $chk;
         eval("\$chk=\$version=~m$releaseexp;");
         if ($@ ne "" || !($chk)){
            $self->LastMsg(ERROR,"invalid software version specified");
            return(undef);
         }
      }
   }
   return(1);
}


sub SoftwareInstFullnameSql
{
   my $self=shift;

   my $d="concat(software.name,".
         "if (lnksoftwaresystem.version<>'',".
         "concat('-',lnksoftwaresystem.version),''),".
         "if (lnksoftwaresystem.parent is null,".
         "if (lnksoftwaresystem.system is not null,".
         "concat(' (system installed\@',system.name,".
         "if (lnksoftwaresystem.instpath<>'',".
         "concat(':',lnksoftwaresystem.instpath),''),')'),".
         "' (cluster service installed)'),' (Option)'))";

   return($d);
}




1;
