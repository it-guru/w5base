package tsacinv::event::AMsapInstanceImport;
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
use kernel::Event;
use kernel::database;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->{srcsys}="SAPIIMP";
   $self->{prodcompfix}={
      'APPL568549'=>{
         prodcomp=>'SAP HANA'
      },
      'APPL606584'=>{
         prodcomp=>'SQUID'
      }
   };
   $self->{prodcompmap}={
      'Apache Webserver'        =>{ 
                                   software=>'Apache_Webserver',
                                   version=>undef,
                                   swnature=>'Apache'
                                  },
      'FTP server'              =>{ 
                                   software=>'SFTP-Server',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'Mail-Server'             =>{ 
                                   software=>'Postfix',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'Printserver (LPD)'       =>{ 
                                   software=>'Printserver_LPD',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'Reverse Proxy'           =>{ 
                                   software=>'HAProxy',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP BC'                  =>{ 
                                   software=>'SAP_R/3_Business_Connector',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP BI (BW)'             =>{ 
                                   software=>'SAP_BW',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP Business Objects'    =>{ 
                                   software=>'SAP_BO',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP CRM'                 =>{ 
                                   software=>'SAP_CRM',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP Content Server'      =>{ 
                                   software=>'SAP_Content_Server',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP Dynamic HANA'        =>{ 
                                   software=>'SAP_HANA',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP ERP'                 =>{ 
                                   software=>'SAP_ERP',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP Enterprise Portal'   =>{ 
                                   software=>'SAP_ENTERPRISE_PORTAL',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP GRC'                 =>{ 
                                   software=>'SAP_GRC',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP HANA'                =>{ 
                                   software=>'SAP_HANA',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP JAVA (ADS)'          =>{ 
                                   software=>'SAP_JAVA_ADS',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP JAVA (BI)'           =>{ 
                                   software=>'SAP_JAVA_BI',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP LDAP Connector'      =>{ 
                                   software=>'SAP_LDAP_CONNECTOR',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP NW (JAVA-BI)'        =>{ 
                                   software=>'SAP_JAVA_BI',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP NW (JAVA-SLD)'       =>{ 
                                   software=>'SAP_JAVA_SLD',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP NWDI (JAVA)'         =>{ 
                                   software=>'SAP_NWDI',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP Netweaver'           =>{ 
                                   software=>'SAP_NETWEAVER',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP PI'                  =>{ 
                                   software=>'SAP_Process_Integration',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP R/3'                 =>{ 
                                   software=>'SAP_R/3',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP R/3 Enterprise'      =>{ 
                                   software=>'SAP_R/3_Enterprise',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP Router'               =>{ 
                                   software=>'SAP_WWS_SAP_Router',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP SOLUTION MANAGER'    =>{ 
                                   software=>'SOLUTION_MANAGER',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP SRM'                 =>{ 
                                   software=>'SAP_SRM',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP TREX'                =>{ 
                                   software=>'SAP_TREX',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP WEB AS'              =>{ 
                                   software=>'SAP_WEB_AS',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP XI'                  =>{ 
                                   software=>'Business_Objects_XI',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'Samba Server'            =>{ 
                                   software=>'Samba',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'Shared Frontend Services'=>{ 
                                   software=>undef,
                                   version=>undef,
                                   swnature=>undef
                                  },
      'Terminal-Server'         =>{ 
                                   software=>undef,
                                   version=>undef,
                                   swnature=>undef
                                  },
      'Tomcat Server'           =>{ 
                                   software=>'Apache_Tomcat',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'UC4'                     =>{
                                   software=>'UC4_Automation_Plattform_SERVER',
                                   version=>'1.0.0',
                                   swnature=>'UC4'
                                  },
      'WEBDispatcher'           =>{ 
                                   software=>'SAP_WEBDISPATCHER',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'Wily Introscope'         =>{ 
                                   software=>'SAP_WILY_Introscope',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'standalone DB Application'=>{ 
                                   software=>'Oracle_Database_Standard_Edition',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SQUID'                   =>{ 
                                   software=>'squid',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'SAP_CLOUD_CONNECTOR'     =>{ 
                                   software=>'SAP_Cloud_Connector',
                                   version=>undef,
                                   swnature=>undef
                                  },
      'Forward Proxy'           =>{ 
                                   software=>'HAProxy',
                                   version=>undef,
                                   swnature=>undef
                                  },
   };

   

   return($self);
}

sub AMsapInstanceImport
{
   my $self=shift;
   my $app=$self->getParent;

   my $lnkappl=getModuleObject($self->Config,"tsacinv::lnkapplappl");


   $lnkappl->SetFilter({type=>\'SAP',deleted=>'0'});
   $lnkappl->SetCurrentView(qw(ALL));


   my $pcnt=0;
   my $store={};
   my ($rec,$msg)=$lnkappl->getFirst();
   if (defined($rec)){
      do{
         last if (!defined($rec));
         $pcnt+=$self->ProcessRecord($rec,$store);
         ($rec,$msg)=$lnkappl->getNext();
      } until(!defined($rec));
   }
   $self->FineProcess($store);

   return({exicode=>0,exitmsg=>"pcnt=$pcnt"});
}


sub FineProcess
{
   my $self=shift;
   my $store=shift;
   my $app=$self->getParent;;

   #print STDERR Dumper($store);
   #
   my $swi=$app->getPersistentModuleObject("W5BaseInst","TS::swinstance");
   my $sinst=$app->getPersistentModuleObject("W5BaseInstSw",
                                             "itil::lnksoftwaresystem");


   my %prodcomp=();
   foreach my $k (sort(keys(%{$store->{child}}))){
      my $childapplid=$store->{child}->{$k}->{applid};
      if (exists($self->{prodcompfix}->{$childapplid})){
         $store->{child}->{$k}->{prodcomp}=
            $self->{prodcompfix}->{$childapplid}->{prodcomp};
      }

      if ($store->{child}->{$k}->{prodcomp} ne ""){
         $prodcomp{$store->{child}->{$k}->{prodcomp}}++;
      }
   }
   my %software;
   foreach my $prodcomp (sort(keys(%prodcomp))){
      if (!exists($self->{prodcompmap}->{$prodcomp})){
         msg(ERROR,sprintf("missing prodcomp map for %s\n",$prodcomp));
      }
      if ($self->{prodcompmap}->{$prodcomp}->{software} ne ""){
         $software{$self->{prodcompmap}->{$prodcomp}->{software}}++
      }
   }
   {
      my $softobj=getModuleObject($self->Config,"itil::software");
      foreach my $software (sort(keys(%software))){
         $softobj->SetFilter({name=>$software,cistatusid=>4});
         my ($swrec,$msg)=$softobj->getOnlyFirst(qw(ALL));
         if (!defined($swrec)){
            msg(ERROR,"missing '$software' in inventory");
         }
      }
   }
   msg(INFO,"software: ".join(" ",sort(keys(%software))));

   foreach my $k (sort(keys(%{$store->{child}}))){
      my $rec=$store->{child}->{$k};
      my $refcnt=$rec->{cnt};
      my $name=$k;
      $name=~s/\s+/ /g;
      $name=~s/[^a-z0-9_]/_/ig;
      my @p=sort(keys(%{$rec->{parent}}));
      my $parent=$p[0];

      #if ($refcnt!=1){
      #   printf STDERR ("Instance: $k (fixed: $name)\n");
      #   printf STDERR ("ERROR: refcnt=$refcnt at @p\n");
      #}


      my $w5appid=$rec->{parent}->{$parent}->{w5baseid};
      my $prodcomp=$rec->{prodcomp};

      if ($w5appid ne ""){
         my %soll;
         if ($#{$rec->{system}}==-1){
            $soll{$name}={
               name=>$name,
               mandatorid=>'200',
               addname=>"",
               runon=>'0',
               swtype=>'primary',
               applid=>$w5appid,
               srcsys=>$self->{srcsys},
               acinmassingmentgroup=>$rec->{iassignment},
               cistatusid=>"4"
            };
         }
         else{
            my $mode="primary";
            foreach my $sysrec (sort({$a->{name} cmp $b->{name}}
                                      @{$rec->{system}})){
               $soll{$name."-".$sysrec->{name}}={
                  name=>$name,
                  mandatorid=>'200',
                  addname=>$sysrec->{name},
                  runon=>'0',
                  swtype=>$mode,
                  system=>$sysrec->{name},
                  systemid=>$sysrec->{id},
                  applid=>$w5appid,
                  acinmassingmentgroup=>$rec->{iassignment},
                  srcsys=>$self->{srcsys},
                  cistatusid=>"4"
               };
               $mode="secondary" if ($mode eq "primary");
            }
         }
         foreach my $k (sort(keys(%soll))){
            {
               my $w5appl=$app->getPersistentModuleObject("W5BaseAppl",
                                                          "itil::appl");
               $w5appl->SetFilter({id=>\$soll{$k}->{applid}});
               my ($arec,$msg)=$w5appl->getOnlyFirst(qw(ALL));
               if ($arec->{tsmid} ne ""){
                  $soll{$k}->{databossid}=$arec->{tsmid};
               }
               elsif ($arec->{applmgrid} ne ""){
                  $soll{$k}->{databossid}=$arec->{applmgrid};
               }
               elsif ($arec->{tsm2id} ne ""){
                  $soll{$k}->{databossid}=$arec->{tsm2id};
               }
               else{
                  $soll{$k}->{databossid}=$arec->{databossid};
               }
               if ($arec->{businessteamid} ne ""){
                  $soll{$k}->{swteamid}=$arec->{businessteamid};
               }
            }
            $swi->ResetFilter();
            $swi->SetFilter({name=>$soll{$k}->{name},
                             addname=>$soll{$k}->{addname},
                             swtype=>$soll{$k}->{swtype},
                             cistatusid=>"<6"});
            my @cur=$swi->getHashList(qw(ALL));

            foreach my $oldrec (@cur){
               next if (ref($soll{$k}) ne "HASH" || exists($soll{$k}->{id}));
               if ($oldrec->{srcsys} ne $self->{srcsys}){
                  msg(ERROR,"name colisition for $oldrec->{fullname}");
                  $soll{$k}=undef;
               }
               else{
                  if ($swi->ValidatedUpdateRecord($oldrec,$soll{$k},
                      {id=>\$oldrec->{id}})){
                     $soll{$k}->{id}=$oldrec->{id};
                  }
               }
            }
            if (ref($soll{$k}) eq "HASH" && !exists($soll{$k}->{id})){
               my $swiid=$swi->ValidatedInsertRecord($soll{$k});
               $soll{$k}->{id}=$swiid;
            }
         }
         foreach my $k (sort(keys(%soll))){
            if (ref($soll{$k}) eq "HASH" && defined($soll{$k}->{systemid})){
               my $sw=$self->{prodcompmap}->{$prodcomp}->{software};
               my $version=$self->{prodcompmap}->{$prodcomp}->{version};
               my $swnature=$self->{prodcompmap}->{$prodcomp}->{swnature};
               if ($sw ne "" && $soll{$k}->{systemid} ne ""){
                  $sinst->ResetFilter();
                  $sinst->SetFilter({systemid=>\$soll{$k}->{systemid},
                                     software=>$sw});
                  my @curinst=$sinst->getHashList(qw(mdate id));
                  if ($#curinst==-1){
                     my $newswinstrec={
                            systemid=>$soll{$k}->{systemid},
                            software=>$sw,
                            srcsys=>$self->{srcsys}
                     };
                     if (defined($version)){
                        $newswinstrec->{version}=$version;
                     }
                     if (my $iid=$sinst->ValidatedInsertRecord($newswinstrec)){
                        @curinst=({id=>$iid,software=>$sw});
                     }
                     else{
                        printf STDERR ("error insert softwareinst %s\n",
                                       Dumper($newswinstrec));
                     }
                  }
                  my $swinstrec;
                  if (ref($curinst[0]) eq "HASH"){
                     $swinstrec=$curinst[0];
                  }
                  $swi->ResetFilter();
                  $swi->SetFilter({id=>\$soll{$k}->{id}});
                  my ($oldrec,$msg)=$swi->getOnlyFirst(qw(ALL));
                  if (defined($swinstrec) && defined($oldrec) && 
                      ($oldrec->{lnksoftwaresystemid} ne $swinstrec->{id})){
                     my $updswinst={
                        lnksoftwaresystemid=>$swinstrec->{id}
                     };
                     if ($swi->ValidatedUpdateRecord($oldrec,$updswinst,
                         {id=>\$oldrec->{id}})){
                        if (defined($swnature)){
                           $swi->ResetFilter();
                           $swi->SetFilter({id=>\$soll{$k}->{id}});
                           my ($oldrec,$msg)=$swi->getOnlyFirst(qw(ALL));
                           if (defined($oldrec)){
                              $updswinst={swnature=>$swnature};
                              if ($swi->ValidatedUpdateRecord($oldrec,
                                  $updswinst,
                                  {id=>\$oldrec->{id}})){
                                 msg(INFO,"nature ok");
                              }
                              else{
                                 msg(ERROR,"nature set failed on ".
                                     Dumper($oldrec));
                              }
                           }
                        }
                     }
                     else{
                        msg(INFO,"prodcomp '$prodcomp' as '$sw' to ".
                                 "$soll{$k}->{id} failed");
                     }
                  }
               }
            }
            if (defined($soll{$k}->{id})){
               $swi->ResetFilter();
               $swi->SetFilter({id=>\$soll{$k}->{id}});
               my ($oldrec,$msg)=$swi->getOnlyFirst(qw(ALL));
               if (defined($oldrec) && $soll{$k}->{swteamid} ne ""){
                  my $foundteam=0;
                  foreach my $crec (@{$oldrec->{contacts}}){
                     if ($crec->{target} eq "base::grp" &&
                         $crec->{targetid} eq $soll{$k}->{swteamid}){
                        $foundteam++;
                     }
                  }
                  if (!$foundteam){
                     my $cobj=$app->getPersistentModuleObject("W5BaseContct",
                                                       "base::lnkcontact");
                     $cobj->ValidatedInsertRecord({
                        parentobj=>'itil::swinstance',
                        roles=>['write'],
                        targetid=>$soll{$k}->{swteamid},
                        target=>'base::grp',
                        srcsys=>$self->{srcsys},
                        comments=>$self->{srcsys}." initial Import",
                        refid=>$oldrec->{id}
                     });
                  }
               }
            }
         }
      }
   }
}


sub ProcessRecord
{
   my $self=shift;
   my $rec=shift;
   my $store=shift;
   my $app=$self->getParent;;


   my $applid=$rec->{parent_applid};

   return(0) if ($applid eq "");

   my $w5appl=$app->getPersistentModuleObject("W5BaseAppl","itil::appl");
   my $w5sys=$app->getPersistentModuleObject("W5BaseSys","itil::system");

   $w5appl->SetFilter({applid=>\$applid});

   my ($w5applrec,$msg)=$w5appl->getOnlyFirst(qw(id applid));

   return(0) if (!defined($w5applrec));


   my $amappl=$app->getPersistentModuleObject("AMapp","tsacinv::appl");

   $amappl->SetFilter({
      applid=>\$rec->{child_applid},
      deleted=>0,
      status=>'!"out of operation"',
      assignmentgroup=>'TIT.HUB.INT.SAS.*'
   });
   my ($amapplrec,$msg)=$amappl->getOnlyFirst(qw(ALL));

   return(0) if (!defined($amapplrec));  # Instance-Anwendung existiert nicht

   my %systemid;
   foreach my $sysrec (@{$amapplrec->{systems}}){
      $systemid{$sysrec->{systemid}}++;
   }
   $w5sys->SetFilter({systemid=>[keys(%systemid)],cistatusid=>"<5 AND >3"});

   my @system=$w5sys->getHashList(qw(name systemid id));

   my $syscnt=$#system+1;
   if ($#system>0){
    #  msg(ERROR,"logical system not unique for $rec->{child}");
   }

   my @sys;
   foreach my $sysrec (@system){
      push(@sys,{
         name=>$sysrec->{name},
         id=>$sysrec->{id},
      });
   }


  
   return(0) if (!defined($w5applrec));

   if (!exists($store->{child}->{$rec->{child}})){
      $store->{child}->{$rec->{child}}={
         applid=>$rec->{child_applid},
         name=>$rec->{child},
         syscnt=>$syscnt,
         system=>\@sys,
         parent=>{
         },
         iassignment=>$amapplrec->{iassignmentgroup},
         assignment=>$amapplrec->{assignmentgroup},
         prodcomp=>$amapplrec->{prodcomp}
      };
   }
   $store->{child}->{$rec->{child}}->{cnt}++;
   $store->{child}->{$rec->{child}}->{parent}->{$rec->{parent}}={
       applid=>$rec->{parent_applid},
       w5baseid=>$w5applrec->{id}
   };

   #printf STDERR Dumper($store->{child}->{$rec->{child}});


   return(1);
}





1;
