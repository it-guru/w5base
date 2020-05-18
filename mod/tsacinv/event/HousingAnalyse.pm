package tsacinv::event::HousingAnalyse;
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
use kernel::Event;
use kernel::database;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->{MsgBuffer}={};
   $self->{MsgArray}=[];

   return($self);
}


sub openExcel
{
   my $self=shift;

   eval("use Spreadsheet::WriteExcel::Big;");
   if (!defined($self->{XLS})){
      $self->{XLS}={};
   }
   my $xlsexp=$self->{XLS};
   $xlsexp->{xls}->{state}="bad";
   if ($@ eq ""){
      $xlsexp->{xls}->{filename}="/tmp/out.".time().".xls";
      $xlsexp->{xls}->{workbook}=Spreadsheet::WriteExcel::Big->new(
                                            $xlsexp->{xls}->{filename});
      if (defined($xlsexp->{xls}->{workbook})){
         $xlsexp->{xls}->{state}="ok";
         $xlsexp->{xls}->{worksheet}=$xlsexp->{xls}->{workbook}->
                                     addworksheet("CHM");
         $xlsexp->{xls}->{format}->{default}=$xlsexp->{xls}->{workbook}->
                                             addformat(text_wrap=>1,
                                                       align=>'top');
         $xlsexp->{xls}->{format}->{text}=$xlsexp->{xls}->{workbook}->
                                             addformat(text_wrap=>1,
                                                       num_format=>'#',
                                                       align=>'top');
         $xlsexp->{xls}->{format}->{header}=$xlsexp->{xls}->{workbook}->
                                             addformat(text_wrap=>1,
                                                       align=>'top',
                                                       bold=>1);
         $xlsexp->{xls}->{line}=0;
         my $ws=$xlsexp->{xls}->{worksheet};
         $ws->write($xlsexp->{xls}->{line},0,
                    "ToDoTag",
                    $xlsexp->{xls}->{format}->{header});
         $ws->set_column(0,0,24);

         $ws->write($xlsexp->{xls}->{line},1,
                    "AM ID Ref",
                    $xlsexp->{xls}->{format}->{header});
         $ws->set_column(1,1,15);

         $ws->write($xlsexp->{xls}->{line},2,
                    "Standort",
                    $xlsexp->{xls}->{format}->{header});
         $ws->set_column(2,2,40);

         $ws->write($xlsexp->{xls}->{line},3,
                    "ToDo Target",
                    $xlsexp->{xls}->{format}->{header});
         $ws->set_column(3,3,40);

         $ws->write($xlsexp->{xls}->{line},4,
                    "Bemerkungen",
                    $xlsexp->{xls}->{format}->{header});
         $ws->set_column(4,4,220);

         $xlsexp->{xls}->{line}++;

         $xlsexp->{xls}->{amws}=$xlsexp->{xls}->{workbook}->
                                     addworksheet("AssetManagerUpd");
         $xlsexp->{xls}->{amline}=1;
         my $amupd=$xlsexp->{xls}->{amws};
         $amupd->write(0,0,"SystemID",$xlsexp->{xls}->{format}->{header});
         $amupd->set_column(0,0,20);
         $amupd->write(0,1,"AssetID",$xlsexp->{xls}->{format}->{header});
         $amupd->set_column(0,1,20);
         $amupd->write(0,2,"Systemname",
                           $xlsexp->{xls}->{format}->{header});
         $amupd->set_column(0,2,24);
         $amupd->write(0,3,"Assignmentgroup",
                           $xlsexp->{xls}->{format}->{header});
         $amupd->set_column(0,3,28);
         $amupd->write(0,4,"ExternalSystem",
                           $xlsexp->{xls}->{format}->{header});
         $amupd->set_column(0,4,24);
         $amupd->write(0,5,"ExternalId",
                           $xlsexp->{xls}->{format}->{header});
         $amupd->set_column(0,5,20);
         $amupd->write(0,6,"SystemPartOfAsset",
                           $xlsexp->{xls}->{format}->{header});
         $amupd->set_column(0,6,20);
      }
   }
}

sub addMessage
{
   my $self=shift;
   my @col=@_;
   my @locationpath=split(/\//,$col[2]);
   $col[2]=$locationpath[1];

   my $key=$col[0].":".$col[1];
   if (!exists($self->{MsgBuffer}->{$key})){
      push(@{$self->{MsgArray}},\@col);
      $self->{MsgBuffer}->{$key}=\@col;
   }
}

sub addLine
{
   my $self=shift;
   my @col=@_;

   my $xlsexp=$self->{XLS};
   my $ws=$xlsexp->{xls}->{worksheet};
   for(my $c=0;$c<=$#col;$c++){
      $ws->write($xlsexp->{xls}->{line},$c,
                 $col[$c],
                 $xlsexp->{xls}->{format}->{default});

   }
   $xlsexp->{xls}->{line}++;
}

sub addAmUpdLine
{
   my $self=shift;
   my @col=@_;

   my $xlsexp=$self->{XLS};
   my $ws=$xlsexp->{xls}->{amws};
   for(my $c=0;$c<=$#col;$c++){
      $ws->write($xlsexp->{xls}->{amline},$c,
                 $col[$c],
                 $xlsexp->{xls}->{format}->{text});

   }
   $xlsexp->{xls}->{amline}++;
}

sub closeExcel
{
   my $self=shift;
   my $names=shift;
   my $xlsexp=$self->{XLS};
      
   $xlsexp->{xls}->{workbook}->close(); 
   my $file=getModuleObject($self->Config,"base::filemgmt");
   if (open(F,"<".$xlsexp->{xls}->{filename})){
      my $dir="Reports/AMHousing";
      foreach my $filename (@$names){
         $file->ValidatedInsertOrUpdateRecord({name=>$filename,
                                               parent=>$dir,
                                               file=>\*F},
                                              {name=>\$filename,
                                               parent=>\$dir});
      }
   }
   else{
      msg(ERROR,"can't open $xlsexp->{xls}->{filename}");
   }
}


sub getRebuildW5BaseSysSQLcmd
{
    my $self=shift;
    my $w5sysrec=shift;
    my $iassigrp=shift;

    my $cmd=<<EOF;
-- Umbau $w5sysrec->{name} as srcsys=W5Base
update system set srcsys='w5base',srcid=NULL,systemid=NULL,
acinmassignmentgroupid=(select id from metagrpmgmt where fullname='$iassigrp')
where id='$w5sysrec->{id}';
EOF

    return($cmd);
}


sub HousingAnalyse
{
   my $self=shift;
   my $app=$self->getParent;
   my @idlist=@_;
   my $nomail=1;
   my $secCnt=3600;
   my @reportNames;

   my $DarwinDev="TIT.TSI.DE.W5BASE";

   if (grep(/^(-){0,2}mail$/i,@idlist)){
      $nomail=0;
      @idlist=grep(!/^(-){0,2}mail$/i,@idlist);
   }

   if ($#idlist==-1){
      my $stamp=NowStamp();
      push(@reportNames,"Report.$stamp.xls");
      push(@reportNames,"Report.xls");
   }
   else{
      my $stamp=NowStamp();
      push(@reportNames,"IndividualReport.$stamp.xls");
   }





   my $defaultStartOfNewHousingHandling=">01.08.2019";

   my @msg;

   my $w5sys=getModuleObject($self->Config,"itil::system");
   my $w5ass=getModuleObject($self->Config,"itil::asset");
   my $w5tsgrp=getModuleObject($self->Config,"tsgrpmgmt::grp");
   my $amsys=getModuleObject($self->Config,"tsacinv::system");
   my $amsys2=getModuleObject($self->Config,"tsacinv::system");
   my $amass=getModuleObject($self->Config,"tsacinv::asset");
   my $tssmgrp=getModuleObject($self->Config,"tssm::group");
   my $wf=getModuleObject($self->Config,"base::workflow");

   $amsys2->BackendSessionName("xxo$$");

   $self->openExcel();

   my %loc;
   my @notsirz=();
   {
      my $amloc=getModuleObject($self->Config,"tsacinv::location");
      $amloc->SetFilter({isdatacenter=>'0'});
      my $i=$amloc->getHashIndexed(qw(fullname));
      @notsirz=sort(keys(%{$i->{fullname}}));
   }
   my %assetid;
   my %amivosys;
   my %smap;


   my %amasset;
   my %amassetid;
   my %w5asset;
   my %w5assetid;
   my %amsystem;
   my %amsystemid;
   my %w5system;
   my %w5systemid;


   sub getMostHousingIVOlookingSystemID{
      my $assetid=shift;
      my $systemids=shift;
      my %IVOweight;
      my $c=1;
      # alle SystemIDs am Asset sehen gleichberechtigt aus und kommen
      # alle aus W5Base. Nun muss ich versuchen, eines raus zu picken,
      # das dann das INVOICE_ONLY werden soll.
      # Das machen wir dann nach einem Gewichtungssystem ...
      foreach my $systemid (sort(@$systemids)){
         #print Dumper($amsystem{$systemid});
         my $partofasset=$amsystem{$systemid}->{partofasset};
         $partofasset=~s/,/./;
         $partofasset=~s/^\./0./;
         $IVOweight{$systemid}=$c++;
         if ($partofasset==1.0){
            $IVOweight{$systemid}*=100000.0;
         }
         else{
            $IVOweight{$systemid}*=(1.0+$partofasset);
         }
         if ($#{$amsystem{$systemid}->{applications}}==-1){
            $IVOweight{$systemid}*=100.0;
         }
         if ($#{$amsystem{$systemid}->{orderedservices}}>0){
            $IVOweight{$systemid}*=
               (10.0*($#{$amsystem{$systemid}->{orderedservices}}+1));
         }
      }
      my @weightSystemID=sort({
            $IVOweight{$b}<=>$IVOweight{$a};
         } keys(%IVOweight));
      return($weightSystemID[0]);

   }


   if (1){  

      ####################################################################### 
      # load 1st stage of Systemdate from AssetManager
      $amsys->ResetFilter();
      my $flt={
         deleted=>\'0',
         status=>'"!out of operation"'
      };
      if ($#idlist==-1){
         $flt->{cdate}=$defaultStartOfNewHousingHandling;
      }
      else{
         $flt->{systemid}=\@idlist;
      }
      $amsys->SetFilter($flt);
      foreach my $amsysrec ($amsys->getHashList(
                           qw(systemname systemid assetassetid))){
         my $rec=ObjectRecordCodeResolver($amsysrec);
         msg(INFO,"load AssetManager system $rec->{systemid}");
         $amassetid{$rec->{assetassetid}}++;
      }
      ####################################################################### 


      ####################################################################### 
      # load Asset data from W5Base
      $w5ass->ResetFilter();
      my $flt={
         name=>'A*',
         cistatusid=>'2 3 4 5',
         srcsys=>'W5Base',
         cdate=>$defaultStartOfNewHousingHandling
      };
      if ($#idlist==-1){
         $w5ass->SetFilter($flt);
      }
      else{
         $w5ass->SetFilter({name=>\@idlist,
                            cistatusid=>'2 3 4 5'});
      }
      foreach my $w5assrec ($w5ass->getHashList(qw(name))){
         msg(INFO,"load W5Base Asset $w5assrec->{name}");
         $amassetid{$w5assrec->{name}}++;
      }




      ####################################################################### 
      # load Asset data from AssetManager
      $amass->ResetFilter();
      my $flt={
         status=>'"!wasted"',
         deleted=>\'0',
         srcsys=>\'W5Base',
      };
      if ($#idlist==-1){
         $flt->{cdate}=$defaultStartOfNewHousingHandling;
      }
      else{
         $flt->{assetid}=\@idlist;
      }
      if (keys(%amassetid)){
         $amass->SetFilter([$flt,{assetid=>[keys(%amassetid)]}]);
      }
      else{
         $amass->SetFilter($flt);
      }
      foreach my $amassrec ($amass->getHashList(
                            qw(assetid 
                              assignmentgroup
                              iassignmentgroup
                               tsacinv_locationfullname srcsys))){
         my $rec=ObjectRecordCodeResolver($amassrec);
         msg(INFO,"load AssetManager asset $rec->{assetid}");
         $amassetid{$rec->{assetid}}++;
         $amasset{$rec->{assetid}}=$rec;
      }
      ####################################################################### 


      ####################################################################### 
      # load 2st stage of Systemdate from AssetManager
      $amsys->ResetFilter();
      my $flt={
         assetassetid=>[keys(%amassetid)],
         deleted=>\'0',
         status=>'"!out of operation"'
      };
      $amsys->SetFilter($flt);
      foreach my $amsysrec ($amsys->getHashList(
                           qw(systemname systemid
                              assetassetid
                              assignmentgroup
                              iassignmentgroup
                              customerlink usage
                              applications orderedservices
                              srcsys usage partofasset
                              tsacinv_locationfullname))){
         my $rec=ObjectRecordCodeResolver($amsysrec);
         msg(INFO,"2nd load AssetManager system $rec->{systemid}");
         $amsystem{$rec->{systemid}}=$rec;
      }

      ####################################################################### 
      # load Asset data from W5Base
      $w5ass->ResetFilter();
      my $flt={
         name=>[keys(%amassetid)],
      };
      $w5ass->SetFilter($flt);
      foreach my $w5assrec ($w5ass->getHashList(qw(name class 
                                                   cistatusid systems))){
         my $rec=ObjectRecordCodeResolver($w5assrec);
         msg(INFO,"load W5Base asset $rec->{name}");
         $w5assetid{$rec->{name}}=$rec;
         $w5asset{$rec->{id}}=$rec;
      }

      ####################################################################### 
      # load System data from W5Base
      $w5sys->ResetFilter();
      my $flt={
      };
      $w5sys->SetFilter([{
         asset=>[keys(%amassetid)],
         cistatusid=>'2 3 4 5'
      },{
         systemid=>[keys(%amsystem)],
         cistatusid=>'2 3 4 5'
      }]);
      foreach my $w5sysrec ($w5sys->getHashList(qw(name cistatusid systemid id
                                                   asset))){
         my $rec=ObjectRecordCodeResolver($w5sysrec);
         msg(INFO,"load W5Base system $rec->{name}");
         $w5systemid{$rec->{systemid}}=$rec;
         $w5system{$rec->{id}}=$rec;
      }
   }

   # Analyse Phase
   msg(INFO,"--------------------------------------------");


   # Try to detect correct INVOICE_ONLY System

   foreach my $assetid (keys(%amassetid)){
      msg(INFO,"analyse INVOICE_ONLY for asset $assetid");
      my $allowedAsHousingOnTSIlocation=0;
      my @tsisystemid;
      my @ivosystemid;
      my @housingsystemid;
      if ($#ivosystemid==-1){
         msg(INFO,"missing Usage-Fixup on $assetid");
         foreach my $sysrec (values(%amsystem)){
            if ($sysrec->{usage} eq ""){
               if (($sysrec->{iassignmentgroup}=~m/^TIT\..*/) &&
                   ($sysrec->{assignmentgroup}=~m/^MIS\..*/)){
                  msg(INFO,"tread missing Usage on $sysrec->{systemid} as INVOICE_ONLY?");
                  $sysrec->{usage}="INVOICE_ONLY?";
               }
            }
         }


         msg(INFO,"check for INVOICE_ONLY* our HOUSING on $assetid");
         foreach my $sysrec (values(%amsystem)){
            if ($sysrec->{assetassetid} eq $assetid){
               if ($sysrec->{usage} eq "INVOICE_ONLY" ||
                   $sysrec->{usage} eq "INVOICE_ONLY?"){
                  push(@ivosystemid,$sysrec->{systemid});
               }
               elsif ($sysrec->{usage}=~/housing/i){
          #        if (lc($sysrec->{srcsys}) eq "w5base"){
                  push(@housingsystemid,$sysrec->{systemid});
               }
               else{
                  if ($sysrec->{usage} ne ""){  # manchmal ist die usage leer!
                     push(@tsisystemid,$sysrec->{systemid});
                  }
               }
            }
         }
         msg(INFO,"found ".($#ivosystemid+1)." INVOICE_ONLY* Systems");
      }
      # alle INVOICE_ONLY Systeme haben wir nun. 
      # Check ob der Standort eine TSI Standort ist.

       my @locationpath=split(/\//,
                              $amasset{$assetid}->{tsacinv_locationfullname});
       my $isTsiRzAsset=0;
       if (!in_array(\@notsirz,$locationpath[1])){ # check auf TSI Standort
          $isTsiRzAsset=1;
       }

       if (lc($amasset{$assetid}->{srcsys}) eq "w5base" &&
           $isTsiRzAsset==1){
          if (exists($w5assetid{$assetid}) && 
              $w5assetid{$assetid}->{class} eq "BUNDLE"){
             msg(INFO,"AssetID $assetid is a BUNDLE and allowed");
             $allowedAsHousingOnTSIlocation=1;
          }
          else{
             msg(INFO,"AssetID $assetid needs to be ".
                      "transfered to srcsys=AssetManager");
             $self->addMessage("TransfAssetAuthD2A",
                $assetid,
                $amasset{$assetid}->{tsacinv_locationfullname},
                "AssetManager-Admins",
                "Das Asset $assetid muss von ".
                "ExternalSystem=W5Base ".
                "auf ExternalSystem=NULL umgestellt werden, da ".
                "es in einem ".
                "TSI RZ steht. Unklar, wer die Assignmentgroup in ".
                "AM bekommen ".
                "soll."
             );
          }
       }
      
       if ($#ivosystemid>-1 || 
           ($isTsiRzAsset==1 && $#housingsystemid>-1 && 
            $allowedAsHousingOnTSIlocation==0)){
          msg(INFO,"AssetID $assetid needs INVOICE_ONLY handling");
          my @ivosystemidNotInW5B;
          my @ivosystemidWithServices;
          my @ivosystemidShortesName;
          my @ivosystemid100PartOfAsset;
          my $ivosystemidShortesNameLen;
          if ($#ivosystemid>0){
             msg(INFO,"multiple INVOICE_ONLY* systems - try to find the right");
             my @correctnamed;
             foreach my $systemid (@ivosystemid){
                if (length($amsystem{$systemid}->{systemname})==
                     $ivosystemidShortesNameLen){
                   push(@ivosystemidShortesName,$systemid);
                }
                if (!defined($ivosystemidShortesNameLen) ||
                    length($amsystem{$systemid}->{systemname})<
                       $ivosystemidShortesNameLen){
                   $ivosystemidShortesNameLen=
                                   length($amsystem{$systemid}->{systemname});
                   @ivosystemidShortesName=($systemid);
                }
                if (!exists($w5systemid{$systemid})){
                   push(@ivosystemidNotInW5B,$systemid);
                }
                if ($#{$amsystem{$systemid}->{orderedservices}}!=-1){
                   push(@ivosystemidWithServices,$systemid);
                }
                if ($amsystem{$systemid}->{usage} eq "INVOICE_ONLY"){
                   push(@correctnamed,$systemid);
                }
                if ($amsystem{$systemid}->{partofasset}==1.0){
                   push(@ivosystemid100PartOfAsset,$systemid);
                }
             }
             if ($#correctnamed==0){
                msg(INFO,"SystemID $correctnamed[0] is correct named");
                @ivosystemid=@correctnamed;
             }
             elsif ($#correctnamed>0){
                msg(INFO,"multiple correct INVOICE_ONLY SystemIDs on $assetid");
                die("no further processing posible");
             }
          }

          if ($#ivosystemid>0){
             my $ivosystemidSelected;
             if ($#ivosystemid100PartOfAsset==0){
                msg(INFO,"select from multiple INVOICE_ONLY by one100PartOfAsset");
                $ivosystemidSelected=$ivosystemid100PartOfAsset[0];
             }
             elsif ($#ivosystemidNotInW5B==0){
                msg(INFO,"select from multiple INVOICE_ONLY by NotInW5B");
                $ivosystemidSelected=$ivosystemidNotInW5B[0];
             }
             elsif ($#ivosystemidWithServices==0){
                msg(INFO,"select from multiple INVOICE_ONLY by WithService");
                $ivosystemidSelected=$ivosystemidWithServices[0];
             }
             elsif($#ivosystemidShortesName==0){
                msg(INFO,"select from multiple INVOICE_ONLY by ShortestName");
                $ivosystemidSelected=$ivosystemidShortesName[0];
             }
             else{
                my @l=sort(@ivosystemid);
                $ivosystemidSelected=@l[0];
                msg(INFO,"select from multiple INVOICE_ONLY by FirstSystemID");
             }
             msg(INFO,"using $ivosystemidSelected as INVOICE_ONLY");
             # Alle anderen IVO SystemIDs muessen noch gecheckt werden
             foreach my $systemid (@ivosystemid){
                next if ($systemid eq $ivosystemidSelected);
                if (exists($w5systemid{$systemid})){
                   $self->addMessage("TransfSystemAuthA2D",
                      $systemid,
                      $amasset{$assetid}->{tsacinv_locationfullname},
                      "AssetManager-Admins",
                      "Die SystemID $systemid muss von W5Base/Darwin ".
                      "aus gepflegt werden. Es muss ".
                      "ExternalSystem=W5Base ".
                      "und ExternalId=$w5systemid{$systemid}->{id} ".
                      "gesetzt werden. Assignmentgroup muss auf TIT ".
                      "geändert werden."
                   );
                   if (!in_array(\@housingsystemid,$systemid)){
                      # eigentlich ist das dann ein "normales" HOUSING Sys
                      push(@housingsystemid,$systemid);
                   }
                   $self->addAmUpdLine(
                      $systemid,
                      $assetid,
                      $amsystem{$systemid}->{systemname},
                      "TIT",
                      "W5Base",
                      $w5systemid{$systemid}->{id},
                      "0,0"
                   );
                   $secCnt++;
                   $self->addMessage("UpdMDateInW5Sys",
                      $systemid,
                      $amasset{$assetid}->{tsacinv_locationfullname},
                      $DarwinDev,
                      "-- MDate Update des Systems ".
                      "   $w5systemid{$systemid}->{name} \n".
                      "update system set modifydate=DATE_ADD(NOW(),INTERVAL -$secCnt SECOND) where ".
                      "id='$w5systemid{$systemid}->{id}';\n"
                   );
                }
             }
             #
             @ivosystemid=($ivosystemidSelected);
          }
          if ($#ivosystemid==0){
             msg(INFO,"processing asset $assetid with INVOICE_ONLY=".
                      $ivosystemid[0]);
             if ($amsystem{$ivosystemid[0]}->{usage} eq "INVOICE_ONLY?"){
                msg(INFO,"AssetManager: rename of $ivosystemid[0] needed");
               $self->addMessage("RenameIVOSysInAM",
                  $ivosystemid[0],
                  $amasset{$assetid}->{tsacinv_locationfullname},
                  $amsystem{$ivosystemid[0]}->{assignmentgroup},
                  "Das System mit der SystemID ".
                  $ivosystemid[0]." muss in AssetManager von ".
                  $amsystem{$ivosystemid[0]}->{systemname}." auf ".
                  $amsystem{$ivosystemid[0]}->{systemid}.
                  "_HW umbeannt werden."
               );
               $self->addAmUpdLine(
                  $amsystem{$ivosystemid[0]}->{systemid},
                  $assetid,
                  $amsystem{$ivosystemid[0]}->{systemid}."_HW",
                  $amsystem{$ivosystemid[0]}->{assignmentgroup},
                  "[NULL]",
                  "[NULL]",
                  "1,0"
               );
             }


             if (exists($w5systemid{$ivosystemid[0]})){ 
                msg(INFO,"W5Base: INVOICE_ONLY? SystemID $ivosystemid[0] ".
                         "needs covert to a tech system"); 
                if ($w5systemid{$ivosystemid[0]}->{name}
                    =~m/^S[0-9]{6,10}(_HW){0,1}$/i){
                   # scheint sich ohnehin um kein "richtiges" System zu handeln
                   $self->addMessage("DelInvoiceOnlyW5Sys",
                      $ivosystemid[0],
                      $amasset{$assetid}->{tsacinv_locationfullname},
                      $DarwinDev,
                      "-- hartes Entfernen des Systems ".
                      "   $w5systemid{$ivosystemid[0]}->{name} \n".
                      "delete from system where ".
                      "id='$w5systemid{$ivosystemid[0]}->{id}';\n".
                      "delete from ipaddress where ".
                      "system='$w5systemid{$ivosystemid[0]}->{id}';\n".
                      "delete from lnkapplsystem where ".
                      "system='$w5systemid{$ivosystemid[0]}->{id}';\n"
                   );
                }
                else{
                   $self->addMessage("ModIvoW5Sys2techSys",
                      $ivosystemid[0],
                      $amasset{$assetid}->{tsacinv_locationfullname},
                      $DarwinDev,
                      $self->getRebuildW5BaseSysSQLcmd(
                          $w5systemid{$ivosystemid[0]},
                          $amsystem{$ivosystemid[0]}->{iassignmentgroup},
                      )
                   );
                }
             }
             else{
                # check, if other HOUSING Systems are already on $assetid. If
                # no, request a new create of min. 1 system in Darwin.
                my @others=grep(!/^$ivosystemid[0]$/,@housingsystemid);
                if ($#others==-1){
                   my $iassi="???";
                   if (exists($amsystem{$ivosystemid[0]}) &&
                       $amsystem{$ivosystemid[0]}->{iassignmentgroup} ne ""){
                      $iassi=$amsystem{$ivosystemid[0]}->{iassignmentgroup};
                   }
                   $self->addMessage("CreateTecSysW5",
                      $assetid,
                      $amasset{$assetid}->{tsacinv_locationfullname},
                      $iassi,
                      "Für das Asset $assetid muss ein technisches ".
                      "System in W5Base/Darwin per Neueingabe erzeugt werden.\n"
                   );
                }
             }
          }
          if ($#ivosystemid==-1 &&
              ($isTsiRzAsset==1 && $#housingsystemid>-1)){
             msg(INFO,"AssetManager: need to create a INVOICE_ONLY System");
             my $housingivosystemid;
             if ($#housingsystemid==0){
                $housingivosystemid=$housingsystemid[0];
                msg(INFO,"using HOUSING $housingivosystemid");
             }
             else{
                msg(INFO,"multiple HOUSING Systems on TSI RZ Location ".
                         "for $assetid");
                my $sid=getMostHousingIVOlookingSystemID(
                   $assetid,
                   \@housingsystemid
                );

                msg(INFO,"using weighted $sid as INVOCIE_ONLY for $assetid");
                $housingivosystemid=$sid;
             }
             if (defined($housingivosystemid)){
                if (lc($amsystem{$housingivosystemid}->{srcsys}) eq "w5base"){
                   msg(INFO,"AssetManager: $housingivosystemid needs to be ".
                            "transfert to srcsys=AssetManager");
                   if ($#tsisystemid!=-1){
                      msg(INFO,"Housing Mix detected on assetid $assetid");
                      # HOUSING und TSI Systeme können nicht gemeinsam auf
                      # EINEM Asset existieren!
                      $self->addMessage("RemoveW5SysMix",
                         $housingivosystemid,
                         $amasset{$assetid}->{tsacinv_locationfullname},
                         $amsystem{$housingivosystemid}->{iassignmentgroup},
                         "Das System $amsystem{$ivosystemid[0]}->{systemname} ".
                         "muss aus W5Base/Darwin entfernt werden, da es ".
                         "mit TSI Systemen gemeinsam auf einem Asset ".
                         "existiert."
                      );
                   }
                   else{
                      msg(INFO,"do TrSysAutD2AwithIVOmod for assetid $assetid");
                      $self->addMessage("TrSysAutD2AwithIVOmod",
                         $housingivosystemid,
                         $amasset{$assetid}->{tsacinv_locationfullname},
                         "AssetManager-Admins",
                         "Das System ".
                         "$amsystem{$housingivosystemid}->{systemname} ".
                         "($housingivosystemid) muss von ".
                         "ExternalSystem=W5Base ".
                         "auf ExternalSystem=NULL umgestellt werden, da ".
                         "es in einem TSI RZ steht.\n".
                         "Der Systemname muss auf ${housingivosystemid}_HW ".
                         "geändert werden.\n".
                         "Die neue Assignmentgroup wird ".
                         "vom Asset $assetid übernommen auf ".
                         "$amasset{$assetid}->{assignmentgroup} ."
                      );
                      $self->addAmUpdLine(
                         $housingivosystemid,
                         $assetid,
                         ${housingivosystemid}."_HW",
                         $amasset{$assetid}->{assignmentgroup},
                         "[NULL]",
                         "[NULL]",
                         "1,0"
                      );
                      if (exists($w5systemid{$housingivosystemid})){
                         msg(INFO,"W5Base: $housingivosystemid needs to be ".
                                  "rebuild as NEW technical sys ".
                                  "(new systemid)");
                         $self->addMessage("RebuildHousTW5Sys",
                            $housingivosystemid,
                            $amasset{$assetid}->{tsacinv_locationfullname},
                            $DarwinDev,
                            $self->getRebuildW5BaseSysSQLcmd(
                             $w5systemid{$housingivosystemid},
                             $amsystem{$housingivosystemid}->{iassignmentgroup},
                            )
                         );
                      }
                   }
                }
                else{
                   msg(INFO,"HOUSING only exists with srcsys AssetManager");
                }
             }
             else{
                msg(ERROR,"am $assetid blick ichs nicht");
                $self->addMessage("UnknownProblem",
                   $assetid,
                   $amasset{$assetid}->{tsacinv_locationfullname},
                   $DarwinDev,"kein Housing ermittelbar"
                );
             }
          }
       }
       else{
          msg(INFO,"ignoring AssetID $assetid - no HOUSING indicator");
       }
       msg(INFO,"--------------------------------------------");
   }

   foreach my $l (@{$self->{MsgArray}}){
      $self->addLine(@{$l});
   }

   $self->closeExcel(\@reportNames);


   printf("Current Asset-Map:\n\n");
   foreach my $assetid (keys(%amassetid)){
      printf("%s:",$assetid);
      my $c=0;
      my $s=0;
      foreach my $sysrec (values(%amsystem)){
         if ($sysrec->{assetassetid} eq $assetid){
            $s++;
            if ($c==0){
               printf("\n   ");
            }
            my $usage=$sysrec->{usage};
            if (length($usage)>20){
               $usage=TextShorter($usage,18,"INDI");
            }
            printf("%-10s: %-25s",$sysrec->{systemid},$usage);
            $c++;
            if ($c==2){
               $c=0;
            }
         }
      }
      printf("\n") if ($s>0);
      printf("\n");
   }




   printf("\n\n");





   if (!$nomail){
      msg(INFO,"start Mailing ....");
      my %target;
      my %tag;
      foreach my $l (@{$self->{MsgArray}}){
         $target{$l->[3]}++;
         $tag{$l->[0]}++;
      }

      foreach my $target (sort(keys(%target))){
         my %targetemail=();
#         next if ($target ne "TIT.TSI.DE.W5BASE");

         if ($target eq "TIT.TSI.DE.W5BASE"){
            $targetemail{'hartmut.vogler@t-systems.com'}++;
         }

         if (!keys(%targetemail)){
            $tssmgrp->ResetFilter();
            $tssmgrp->SetFilter({fullname=>\$target}); 
            my @l=$tssmgrp->getHashList(qw(fullname memberemails));
            foreach my $rec (@l){
               foreach my $urec (@{$rec->{memberemails}}){
                  if ($urec->{useremail} ne ""){
                     $targetemail{lc($urec->{useremail})}++;
                  }
               }
            }
         }

         my $subject="Housing SACM Issues for $target";
         my $mailtxt="";

         $mailtxt.="To: ".join("; ",sort(keys(%targetemail)))."\n\n";
         foreach my $t (sort(keys(%tag))){
            foreach my $l (@{$self->{MsgArray}}){
               if ($l->[0] eq $t){
                  if ($target eq $l->[3]){
                     $mailtxt.=$l->[1].":\n";
                     $mailtxt.=$l->[4]."\n";
                     $mailtxt.="--\n\n";
                  }
               }
            }
         }

         my %notify=(
                     class        =>'base::workflow::mailsend',
                     step         =>'base::workflow::mailsend::dataload',
                     name         =>$subject,
                     emailfrom    =>'"AssetManager HOUSING Check" <>',
                     emailto      =>[sort(keys(%targetemail))],
                     emailbcc     =>'hartmut.vogler@t-systems.com',
                     emailtext    =>$mailtxt,
                    );
         my $r=undef;
         if (my $id=$wf->Store(undef,\%notify)) {
            my %d=(step=>'base::workflow::mailsend::waitforspool');
            $r=$wf->Store($id,%d);
         }
      }
   }




   return({exicode=>0});
}



1;
