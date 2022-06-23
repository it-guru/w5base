package leanix::event::leanixDataLoad;
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
use kernel::Event;
use UUID::Tiny;
@ISA=qw(kernel::Event);



sub leanixDataLoad
{
   my $self=shift;

   my $funcmgrid="11785813690001";  # Carsten
   my $databossid="15214605570000"; # Natalia
   $databossid="11785813690001"; # doch alles auf Carsten
   my $bccgroup="16539985210003"; # DTAG.GHQ.VTI.DTIT.Hub.BCO.BCC
   my $mandatorid="200";

   my %db;
   my $lixbc=getModuleObject($self->Config,"leanix::BusinessCapability");
   my $lixap=getModuleObject($self->Config,"leanix::Application");
   my $lixprc=getModuleObject($self->Config,"leanix::Process");
   my $lixitc=getModuleObject($self->Config,"leanix::ITComponent");

   if (1){
      $lixitc->SetFilter({});
      my @l=$lixitc->getHashList(qw(name displayName id w5baseid tags));
      foreach my $itcrec (@l){
         my $id=$itcrec->{id};
         $db{'leanix::ITComponent'}->{$id}=$itcrec;
      }
   }
   if (1){
      $lixprc->SetFilter({tags=>'"Framework: BCC"'});
      my @l=$lixprc->getHashList(qw(name displayName id relations tags));
      if ($#l==-1){
         return({exitcode=>1,exitmsg=>'unexpected result from LeanIX'});
      }

      foreach my $bprec (@l){
         my $id=$bprec->{id};
         $db{'leanix::Process'}->{$id}=$bprec;
      }

      foreach my $id (sort(keys(%{$db{'leanix::Process'}}))){
         my $bprec=$db{'leanix::Process'}->{$id};
         #printf STDERR ("id:%s\n",$bprec->{id});
         #printf STDERR ("   name=%s\n",$bprec->{name});
         $bprec->{shortname}="";
         $bprec->{customer}="DTAG";
         if (my ($s,$n)=$bprec->{name}=~m/^(.*?)\s*:\s*(.*)$/){
            $bprec->{shortname}=$s;
            $bprec->{name}=$n;
         }
         if ($bprec->{shortname}=~m/^DTS/){
            $bprec->{customer}="DTAG.GHQ.VD.TDG.TService.DTS";
         }
         elsif ($bprec->{shortname}=~m/^DTA/){
            $bprec->{customer}="DTAG.GHQ.VD.TDG.TService.DT_A_GmbH";
         }
         elsif ($bprec->{shortname}=~m/^DTT/){
            $bprec->{customer}="DTAG.GHQ.VD.TDG.T.DTT";
         }
         elsif ($bprec->{shortname}=~m/^GKV/){
            $bprec->{customer}="DTAG.GHQ.VD.TDG.GK.DT_GKV";
         }
         elsif ($bprec->{shortname}=~m/^PVG/){
            $bprec->{customer}="DTAG.GHQ.VD.TDG.TService.DT_PVG";
         }
         elsif ($bprec->{shortname}=~m/^TDG_F/){
            $bprec->{customer}="DTAG.GHQ.VD.TDG";
         }
         #printf STDERR ("   name=%s\n",$bprec->{name});
         #printf STDERR ("   shortname=%s\n",$bprec->{shortname});
         #printf STDERR ("   customer=%s\n",$bprec->{customer});
      }
   }


   #
   # Create BusinessProcesses in W5Base/Darwin
   #
   if (1){
      my $w5bp=getModuleObject($self->Config,"itil::businessprocess");
      my $w5bpacl=getModuleObject($self->Config,"crm::businessprocessacl");
      my $srcsys='leanix::Process';
      $bccgroup="16558801150001";  # membergroup.BCO_BS.BP
      foreach my $lixrec (values(%{$db{$srcsys}})){
         my $srcid=$lixrec->{id};
         next if ($lixrec->{shortname} eq "");
         $w5bp->ResetFilter();
         $w5bp->SetFilter({srcid=>\$srcid,srcsys=>\$srcsys});
         my ($w5rec)=$w5bp->getOnlyFirst(qw(ALL));
         my $w5id;
         if (!defined($w5id)){
            $w5bp->ResetFilter();
            $w5bp->SetFilter({customer=>\$lixrec->{customer},
                              shortname=>\$lixrec->{shortname}});
            ($w5rec)=$w5bp->getOnlyFirst(qw(ALL));
         }
         if (!defined($w5rec)){
            my $bk=$w5bp->ValidatedInsertRecord({
               shortname=>$lixrec->{shortname},
               customer=>$lixrec->{customer},
               name=>$lixrec->{name},
               cistatusid=>'4',
               importance=>'3',
               databossid=>$databossid,
               processownerid=>$funcmgrid,
               processowner2id=>$databossid,
               mandatorid=>$mandatorid,
               nature=>'PROCESS',
               srcsys=>$srcsys,
               srcid=>$srcid
            });
            if ($bk){
               $w5bp->ResetFilter();
               $w5bp->SetFilter({id=>\$bk});
               ($w5rec)=$w5bp->getOnlyFirst(qw(ALL));
            }
            else{
               printf STDERR ("fail:%s\n",Dumper($lixrec));
            }
         }
         $w5id=$w5rec->{id};
         my %upd;
         if ($w5rec->{cistatusid} ne "4"){
            $upd{cistatusid}=4;
         }
         if ($w5rec->{importance} eq ""){
            $upd{importance}="3";
         }
         if ($w5rec->{mandatorid} eq ""){
            $upd{mandatorid}=$mandatorid;
         }
         if ($w5rec->{srcsys} ne $srcsys){
            $upd{srcsys}=$srcsys;
         }
         if ($w5rec->{srcid} ne $srcid){
            $upd{srcid}=$srcid;
         }
         if ($w5rec->{databossid} eq ""){
            $upd{databossid}=$databossid;
         }
         if ($w5rec->{processownerid} eq ""){
            $upd{processownerid}=$funcmgrid;
         }
         if ($w5rec->{processowner2id} eq ""){
            $upd{processowner2id}=$databossid;
         }
         if ($w5rec->{description} ne $lixrec->{description}){
            $upd{description}=$lixrec->{description};
         }
         if (keys(%upd)){
            $w5bp->ValidatedUpdateRecord($w5rec,\%upd,{id=>\$w5id});
         }
         $lixrec->{w5id}=$w5id;
         # assign rights
         my $acls=$w5rec->{acls};
         $acls=[] if (ref($acls) ne "ARRAY");
         my $foundgrp=0;
         foreach my $acl (@$acls){
            if ($acl->{acltarget} eq "base::grp" &&
                $acl->{acltargetid} eq $bccgroup){
               $foundgrp++;
            }
         }
         if (!$foundgrp){
            $w5bpacl->ValidatedInsertRecord({
               aclparentobj=>'crm::businessprocess',
               acltarget=>'base::grp',
               acltargetid=>$bccgroup,
               aclmode=>'write',
               refid=>$w5id 
            });
         }
      }
   }




   msg(INFO,"start load of  BCs");
   #$lixbc->SetFilter({tags=>'BCC:* PRK:*',displayName=>'*ES-0001*'});
   #$lixbc->SetFilter({tags=>'*BCC* *PRK*'});
   #$lixbc->SetFilter({id=>'10e88161-f938-45f7-b6a4-d95dfe0ba42d'});
   $lixbc->SetFilter({tags=>'"Framework: BCC" PRK:*'});
   my @lixbcView=qw(name displayName id relations tags);
   my @l=$lixbc->getHashList(@lixbcView);

   if ($#l==-1){
      return({exitcode=>1,exitmsg=>'unexpected result from BC LeanIX call'});
   }
   foreach my $rec (@l){
      my $rel=$rec->{relations};
      foreach my $relrec (@$rel){
         if (!exists($db{$relrec->{dataobjToFS}}->{$relrec->{toId}})){
            $db{$relrec->{dataobjToFS}}->{$relrec->{toId}}=undef;
         }
      }
   }
   foreach my $rec (@l){
      $db{$lixbc->Self()}->{$rec->{id}}=$rec;
   }
   msg(INFO,"end load of BCs n=".($#l+1));



   my $fillup=0;
   my $filluploop=0;
   do{
      $fillup=0;
      $filluploop++;
      msg(INFO,"fillup $filluploop BusinessCapability start");
      foreach my $id (sort(keys(%{$db{'leanix::BusinessCapability'}}))){
         if (!defined($db{'leanix::BusinessCapability'}->{$id})){
            $lixbc->SetFilter({id=>\$id});
            my ($rec)=$lixbc->getOnlyFirst(@lixbcView);
            if (defined($rec)){
               $db{'leanix::BusinessCapability'}->{$id}=$rec;
               my $rel=$rec->{relations};
               foreach my $relrec (@$rel){
                  if (!exists($db{$relrec->{dataobjToFS}}->{$relrec->{toId}})){
                     $db{$relrec->{dataobjToFS}}->{$relrec->{toId}}=undef;
                     msg(INFO,"fillup: ".$relrec->{dataobjToFS}."  id:".
                              $relrec->{toId});                     
                     $fillup++;
                  }
               }
               
            }
         }
      }
   }while($fillup!=0);
   msg(INFO,"fillup BusinessCapability end");


   #
   # Fillup FactSheets for applications from LeanIX
   #
   foreach my $id (sort(keys(%{$db{'leanix::Application'}}))){
      if (!defined($db{'leanix::Application'}->{$id})){
         $lixap->SetFilter({id=>\$id});
         my ($arec)=$lixap->getOnlyFirst(qw(name displayName id 
                                            alias ictoid tags));
         if (defined($arec)){
            $db{'leanix::Application'}->{$id}=$arec;
         }
      }
   }
   foreach my $obj (keys(%db)){
      if (!in_array($obj,[qw(leanix::Application 
                             leanix::BusinessCapability
                             leanix::Process
                             leanix::ITComponent
          )])){
         delete($db{$obj});
      }
   }

   #
   # Loading W5BaseIDs of applications
   #
   my $w5appl=getModuleObject($self->Config,"TS::appl");
   foreach my $id (sort(keys(%{$db{'leanix::Application'}}))){
      if (defined($db{'leanix::Application'}->{$id})){
         my $rec=$db{'leanix::Application'}->{$id};
         if ($rec->{ictoid} ne ""){
            #msg(INFO,"loading $rec->{ictoid}");
            $w5appl->ResetFilter();
            $w5appl->SetFilter({
               ictono=>$rec->{ictoid},
               cistatusid=>'4',opmode=>\'prod'
            });
            my @l=$w5appl->getHashList(qw(name id ));
            if ($#l!=-1){
               $rec->{w5appl}=\@l;
            }
         }
      }
   }


   #
   # Create virtual object leanix::ProcessChain
   #
   foreach my $fsobj (qw(leanix::Application leanix::BusinessCapability)){
      foreach my $fsrec (values(%{$db{$fsobj}})){
         my $tags=$fsrec->{tags};
         $tags=[$tags] if (ref($tags) ne "ARRAY");
         my @tags=@{$tags};
         my @prc=grep(/^PRK:/,@tags);
         foreach my $prc (@prc){
            my $uuid=UUID::Tiny::create_uuid_as_string(UUID_V5,$prc);
            if (!exists($db{'leanix::ProcessChain'}->{$uuid})){
               if (my ($num,$name)=$prc=~m/^PRK:\s*(\d+)\s*(.*)$/){
                  $db{'leanix::ProcessChain'}->{$uuid}={
                     id=>$uuid,
                     displayName=>$prc,
                     name=>$name,
                     shortname=>$num,
                     relations=>[],
                  }
               }
            }
            push(@{$db{'leanix::ProcessChain'}->{$uuid}->{relations}},{
               dataobjToFS=>$fsobj,
               toId=>$fsrec->{id},
               type=>'relToChild'
            });
         }
      }
   }


   # create shortnames
   foreach my $fsobj (qw(leanix::BusinessCapability)){
      foreach my $fsrec (values(%{$db{$fsobj}})){
         my $namestr=$fsrec->{name};
         if (my ($sh,$n)=$namestr=~m/^([A-Z]+-[0-9]+)+\s*[-]{0,1}\s*(.*)$/){
            $fsrec->{name}=$n;
            $fsrec->{shortname}=$sh;
         }
      }
   }




   
   #
   # Create BusinessServices in W5Base/Darwin
   #
   if (1){
      my $w5bs=getModuleObject($self->Config,"itil::businessservice");
      my $lnkc=getModuleObject($self->Config,"base::lnkcontact");
      my $srcsys='leanix::BusinessCapability';
      foreach my $srcsys (qw(leanix::BusinessCapability leanix::ProcessChain)){
         my $nature="BC";
         $bccgroup="16558789800001";  # membergroup.BCO_BS.BC
         if ($srcsys eq "leanix::ProcessChain"){
            $nature="PRC";
            $bccgroup="16558789460001";  # membergroup.BCO_BS.PRC

            next; # Laut Carsten, sollen die PRCs NICHT geladen werden
         }
         foreach my $lixrec (values(%{$db{$srcsys}})){
            # skip BC:BCC Enabling Services -> not create in Darwin
            next if ($lixrec->{id} eq "02e1cc01-c862-481b-a7b8-afa02108f027");
            my $srcid=$lixrec->{id};
            $w5bs->ResetFilter();
            $w5bs->SetFilter({srcid=>\$srcid,srcsys=>\$srcsys});
            my ($w5rec)=$w5bs->getOnlyFirst(qw(ALL));
            my $w5id;
            if (!defined($w5rec)){
               my $bk=$w5bs->ValidatedInsertRecord({
                  nature=>$nature,
                  shortname=>$lixrec->{shortname},
                  description=>$lixrec->{description},
                  name=>$lixrec->{name},
                  cistatusid=>'4',
                  databossid=>$databossid,
                  mandatorid=>$mandatorid,
                  funcmgrid=>$funcmgrid,
                  srcsys=>$srcsys,
                  srcid=>$srcid
               });
               if ($bk){
                  $w5bs->ResetFilter();
                  $w5bs->SetFilter({id=>\$bk});
                  ($w5rec)=$w5bs->getOnlyFirst(qw(ALL));
               }
            }
            $w5id=$w5rec->{id};
            my %upd;
            if ($w5rec->{cistatusid} ne "4"){
               $upd{cistatusid}=4;
            }
            if ($w5rec->{mandatorid} eq ""){
               $upd{mandatorid}=$mandatorid;
            }
            if ($w5rec->{databossid} eq ""){
               $upd{databossid}=$databossid;
            }
            if ($w5rec->{funcmgrid} eq ""){
               $upd{funcmgrid}=$funcmgrid;
            }
            if ($w5rec->{description} ne $lixrec->{description}){
               $upd{description}=$lixrec->{description};
            }
            if (keys(%upd)){
               $w5bs->ValidatedUpdateRecord($w5rec,\%upd,{id=>\$w5id});
            }
            $lixrec->{w5id}=$w5id;

            # add contact
            my $contacts=$w5rec->{contacts};
            $contacts=[] if (ref($contacts) ne "ARRAY");

            my $foundgrp=0;
            foreach my $contact (@$contacts){
               if ($contact->{target} eq "base::grp" &&
                   $contact->{targetid} eq $bccgroup){
                  $foundgrp++;
               }
            }
            if (!$foundgrp){
               $lnkc->ValidatedInsertRecord({
                  parentobj=>'itil::businessservice',
                  target=>'base::grp',
                  targetid=>$bccgroup,
                  roles=>['write'],
                  refid=>$w5id 
               });
            }
         }
      }
   }

   #
   # Create ProcessCains Relations in W5Base/Darwin
   #
   if (1){
      my $w5bs=getModuleObject($self->Config,"itil::businessservice");
      my $w5bsc=getModuleObject($self->Config,"itil::lnkbscomp");
      foreach my $srcsys (qw(leanix::ProcessChain leanix::BusinessCapability)){
         foreach my $lixrec (values(%{$db{$srcsys}})){
            my $srcid=$lixrec->{id};
            my $w5id=$lixrec->{w5id};
            my $w5rec;
       
            if ($w5id ne ""){
               $w5bs->ResetFilter();
               $w5bs->SetFilter({id=>\$w5id});
               ($w5rec)=$w5bs->getOnlyFirst(qw(name id relations));
            }
            if (defined($w5rec)){
               my @currel=@{$w5rec->{servicecomp}};
               foreach my $lixrel (@{$lixrec->{relations}}){
                  # ign relToParent relBusinessCapabilityToITComponent
                  #     relBusinessCapabilityToProcess
                  if (!in_array($lixrel->{type},[
                        qw( relBusinessCapabilityToApplication
                            relBusinessCapabilityToITComponent
                           relToChild )])){
                     next;
                  }
                  #
                  # Skip realtions from ProcessChain to BusinessCapability
                  # - this informations are not correct in LeanIX 
                  #
                  if ($lixrel->{dataobjToFS} eq "leanix::BusinessCapability" &&
                      $srcsys eq "leanix::BusinessCapability"){
                     my $lixBcRec=
                          $db{'leanix::BusinessCapability'}->{$lixrel->{toId}};
                     if ($lixBcRec->{w5id} ne ""){
                        my $targetbsid=$lixBcRec->{w5id};
                        my $found=0;
                        foreach my $currel (@currel){
                           if ($currel->{objtype} eq "itil::businessservice" &&
                               $currel->{obj1id} eq $targetbsid){
                              $found++;
                           }
                        }
                        if (!$found){
                           $w5bsc->ValidatedInsertRecord({
                              businessserviceid=>$w5id,
                              objtype=>'itil::businessservice', 
                              obj1id=>$targetbsid
                           });
                        }
                     }
                  }
                  if ($lixrel->{dataobjToFS} eq "leanix::Application"){
                     my $lixApplRec=
                        $db{'leanix::Application'}->{$lixrel->{toId}};
                     if (ref($lixApplRec->{w5appl}) eq
                         "ARRAY"){
                        my @a=@{$lixApplRec->{w5appl}};
                        foreach my $a (@a){
                           my $found=0;
                           foreach my $currel (@currel){
                              if ($currel->{objtype} eq "itil::appl" &&
                                  $currel->{obj1id} eq $a->{id}){
                                 $found++;
                              }
                           }
                           if (!$found){
                              $w5bsc->ValidatedInsertRecord({
                                 businessserviceid=>$w5id,
                                 objtype=>'itil::appl', 
                                 obj1id=>$a->{id}
                              });
                           }
                        }
                     }
                  }
                  if ($lixrel->{dataobjToFS} eq "leanix::ITComponent"){
                     my $lixApplRec=
                        $db{'leanix::ITComponent'}->{$lixrel->{toId}};
                     if ($lixApplRec->{w5baseid} ne ""){
                        my $w5appid=$lixApplRec->{w5baseid};
                        my @a;
                        my $w5app=$w5bsc->getPersistentModuleObject(
                                  "itil::appl");
                        $w5app->SetFilter({id=>\$w5appid});
                        my @l=$w5app->getHashList(qw(name id));
                        foreach my $arec (@l){
                           push(@a,$arec->{id});
                        }
                        foreach my $a (@a){
                           my $found=0;
                           foreach my $currel (@currel){
                              if ($currel->{objtype} eq "itil::appl" &&
                                  $currel->{obj1id} eq $a){
                                 $found++;
                              }
                           }
                           if (!$found){
                              $w5bsc->ValidatedInsertRecord({
                                 businessserviceid=>$w5id,
                                 objtype=>'itil::appl', 
                                 obj1id=>$a
                              });
                           }
                        }
                     }
                  }
               }
            }
         }
      }
   }


   #
   # Create BusinessProcess Relations in W5Base/Darwin
   #
   if (1){
      my $w5bp=getModuleObject($self->Config,"itil::businessprocess");
      my $w5bpc=getModuleObject($self->Config,"itil::lnkbprocessbservice");
      foreach my $srcsys (qw(leanix::Process)){
         foreach my $lixrec (values(%{$db{$srcsys}})){
            my $srcid=$lixrec->{id};
            my $w5id=$lixrec->{w5id};
            my $w5rec;
       
            if ($w5id ne ""){
               $w5bp->ResetFilter();
               $w5bp->SetFilter({id=>\$w5id});
               ($w5rec)=$w5bp->getOnlyFirst(qw(name id businessservices));
            }
            next if (!defined($w5rec));

            my @currel=@{$w5rec->{businessservices}};
            foreach my $lixrel (@{$lixrec->{relations}}){
               # ign relToParent relBusinessCapabilityToITComponent
               #     relBusinessCapabilityToProcess



#               if (!in_array($lixrel->{type},[
#                     qw( relBusinessCapabilityToApplication
#                        relToChild )])){
#                  next;
#               }
               if ($lixrel->{dataobjToFS} eq "leanix::BusinessCapability"){
                  my $lixBcRec=
                       $db{'leanix::BusinessCapability'}->{$lixrel->{toId}};
                  if ($lixBcRec->{w5id} ne ""){
                     my $targetbsid=$lixBcRec->{w5id};
#printf STDERR ("lixrel=%s\n",Dumper($lixrel));
                     my $found=0;
                     foreach my $currel (@currel){
                        if ($currel->{businessserviceid} eq $targetbsid){
                           $found++;
                        }
                     }
                     if (!$found){
                        $w5bpc->ValidatedInsertRecord({
                           bprocessid=>$w5id,
                           businessserviceid=>$targetbsid,
                        });
                     }
                  }
               }
            }
         }
      }
   }



   

   #print Dumper(\@l);
   #print Dumper($db{'leanix::Application'});
   #print Dumper($db{'leanix::ProcessChain'});

   printf STDERR ("n leanix::Application=%d\n",
                   scalar(keys(%{$db{'leanix::Application'}})));
   printf STDERR ("n leanix::BusinessCapability=%d\n",
                   scalar(keys(%{$db{'leanix::BusinessCapability'}})));
   printf STDERR ("n leanix::ProcessChain=%d\n",
                   scalar(keys(%{$db{'leanix::ProcessChain'}})));
   printf STDERR ("n leanix::ITComponent=%d\n",
                   scalar(keys(%{$db{'leanix::ITComponent'}})));
   printf STDERR ("n leanix::Process=%d\n",
                   scalar(keys(%{$db{'leanix::Process'}})));




   return({exitcode=>0,exitmsg=>'ok'});
}


1;
