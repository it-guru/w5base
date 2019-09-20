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
         $xlsexp->{xls}->{format}->{header}=$xlsexp->{xls}->{workbook}->
                                             addformat(text_wrap=>1,
                                                       align=>'top',
                                                       bold=>1);
         $xlsexp->{xls}->{line}=0;
         my $ws=$xlsexp->{xls}->{worksheet};
         $ws->write($xlsexp->{xls}->{line},0,
                    "ToDoTag",
                    $xlsexp->{xls}->{format}->{header});
         $ws->set_column(0,0,17);

         $ws->write($xlsexp->{xls}->{line},1,
                    "AM ID Ref",
                    $xlsexp->{xls}->{format}->{header});
         $ws->set_column(1,1,20);

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
         $ws->set_column(4,4,190);

         $xlsexp->{xls}->{line}++;
      }
   }
}

sub addMessage
{
   my $self=shift;
   my @col=@_;

   my $key=$col[0].":".$col[1];

   $self->{MsgBuffer}->{$key}=\@col;
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

sub closeExcel
{
   my $self=shift;
   my $xlsexp=$self->{XLS};
      
   $xlsexp->{xls}->{workbook}->close(); 
   my $file=getModuleObject($self->Config,"base::filemgmt");
   if (open(F,"<".$xlsexp->{xls}->{filename})){
      my $dir="Reports/AMHousing";
      my $filename="Report.xls";
      $file->ValidatedInsertOrUpdateRecord({name=>$filename,
                                            parent=>$dir,
                                            file=>\*F},
                                           {name=>\$filename,
                                            parent=>\$dir});
   }
   else{
      msg(ERROR,"can't open $xlsexp->{xls}->{filename}");
   }
}


sub HousingAnalyse
{
   my $self=shift;
   my $app=$self->getParent;
   my @idlist=@_;
   my $defaultStartOfNewHousingHandling=">01.08.2019";

   my @msg;

   my $w5sys=getModuleObject($self->Config,"itil::system");
   my $w5tsgrp=getModuleObject($self->Config,"tsgrpmgmt::grp");
   my $amsys=getModuleObject($self->Config,"tsacinv::system");
   my $amsys2=getModuleObject($self->Config,"tsacinv::system");
   my $amass=getModuleObject($self->Config,"tsacinv::asset");

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
   


   if (1){  # Fall1: Systeme sehen aus wie INVOICE_ONLY - haben aber 
            # nicht den passenden namen.
      $amsys->ResetFilter();
      my $flt={
         usage=>\'INVOICE_ONLY?',
         deleted=>\'0',
         customerlink=>'DTAG DTAG.*',
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
                            qw(systemname systemid
                               assetassetid
                               assignmentgroup
                               iassignmentgroup
                               tsacinv_locationfullname
                               orderedservices
                               services))){
         $amivosys{$amsysrec->{systemid}}++;
         my @l=split(/\//,$amsysrec->{tsacinv_locationfullname});
         #next if (in_array(\@notsirz,$l[1]));

         $loc{$l[1]}++;

         $assetid{$amsysrec->{assetassetid}}++;  # an den Assets, muß dann ein 
                                                 # INVOICE_ONLY System vorhanden
                                                 # sein.
         if (1){
            $w5sys->ResetFilter();
            $w5sys->SetFilter({systemid=>\$amsysrec->{systemid}});
            my ($w5sysrec,$msg)=$w5sys->getOnlyFirst(qw(id));
            msg(INFO,"check SystemID $amsysrec->{systemid}");
            if (defined($w5sysrec)){
               # das wie INVOICE_ONLY ausschauende system ist bereits in 
               # darwin importiert. Das wird nun zu einem tech. Systemdatensatz
               # "umgebaut" (bekommt neue SystemID - Name bleibt gleich):
               
               msg(INFO,"umbau SystemID $amsysrec->{systemid}");
               $w5tsgrp->ResetFilter();
               $w5tsgrp->SetFilter({fullname=>\$amsysrec->{iassignmentgroup}});
               my ($w5tsgrprec,$msg)=$w5tsgrp->getOnlyFirst(qw(ALL));

               $self->addMessage("DelInvoiceOnlyW5Sys",$amsysrec->{systemid},
                         $l[1],"Darwin-Dev",
                         "update system set srcsys='w5base',".
                         "srcid=NULL,systemid=NULL,".
                         "acinmassignmentgroupid='$w5tsgrprec->{id}' ".
                         "where systemid='$amsysrec->{systemid}';");
            }
         }
      }
   }



   if (1){ # Fall2: Assets sind von W5Base Darwin erzeugt, stehen aber in
           # einem RZ von T-Systems
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
      $amass->SetFilter($flt);
      foreach my $amassrec ($amass->getHashList(
                            qw(assetid tsacinv_locationfullname))){
         my @l=split(/\//,$amassrec->{tsacinv_locationfullname});
         next if (in_array(\@notsirz,$l[1]));
         $assetid{$amassrec->{assetid}}++;
         $self->addMessage("TransfAssetAuthD2A",$amassrec->{assetid},
                   $l[1],"AssetManager-Admins",
                   "Das Asset $amassrec->{assetid} muss von ".
                   "ExternalSystem=W5Base".
                   "auf ExternalSystem=NULL umgestellt werden, da es in einem ".
                   "TSI RZ steht. Unklar, wer die Assignmentgroup in ".
                   "AM bekommen ".
                   "soll.");
      }
      if (0){  # Analyse der System-Datensätze an Assets, die von Darwin erzeugt
               # wurden
         $amass->ResetFilter();
         $amass->SetFilter({
            status=>'"!wasted"',
            deleted=>\'0',
            assetid=>[keys(%assetid)]  #load assetids from posible INVOICE_ONLY?
         });
         foreach my $amassrec ($amass->getHashList(
                               qw(assetid tsacinv_locationfullname))){
            my @l=split(/\//,$amassrec->{tsacinv_locationfullname});
          #  next if (in_array(\@notsirz,$l[1]));
          #  printf F ($form,"TransfAssetAuthD2A",$amassrec->{assetid},$l[1],
          #            "Das Asset $amassrec->{assetid} muss von ExternalSystem=W5Base".
          #            "auf ExternalSystem=NULL umgestellt werden, da es in einem ".
          #            "TSI RZ steht. Unklar, wer die Assignmentgroup in AM bekommen ".
          #            "soll.");
            #print Dumper($amassrec);
         }
      }
   }

   foreach my $assetid (sort(keys(%assetid))){
         # prüfen, ob "echtes" INVOICE_ONLY System bereits vorhanden
         msg(INFO,"check AssetID $assetid");
         $amsys2->ResetFilter();
         $amsys2->SetFilter({assetassetid=>\$assetid,
                             usage=>'INVOICE_ONLY*',
                             deleted=>\'0',
                             status=>'"!out of operation"'});
         my @amivosys=$amsys2->getHashList(qw(systemid name usage assetid
                                              assignmentgroup
                                              applications));

         if ($#amivosys>0){
            my @noappsid;
            for(my $c=0;$c<=$#amivosys;$c++){
               if ($#{$amivosys[$c]->{applications}}==-1){
                  push(@noappsid,$c);
               }
            }
            if ($#noappsid==0){   # Wenn nur ein System keine Anwendungen hat,
               @amivosys=($amivosys[$noappsid[0]]); # dann sollte dass das
            }                     # korrekte Verrechnungssystem sein.
         }
         if ($#amivosys>0){
            print Dumper(\@amivosys);
            my $systemid=join(", ",map({$_->{systemid}} @amivosys));
            $self->addMessage("UnUniqueIVOSysInAM",$assetid,
                       "ToDo","INMAssignmentgroup des Assets",
                      "Das INVOICE_ONLY System ".
                      "in AssetManager des Assets $amivosys[0]->{assetassetid} ".
                      "kann nicht eindeutig ermittelt werden. ".
                      "Es käment $systemid in Frage.");
         }
         elsif($#amivosys==-1){
            $self->addMessage("CreateIVOSysInAM",$assetid,
                       "ToDo","INMAssignmentgroup des Assets",
                      "Für die AssetID $amivosys[0]->{assetassetid} ".
                      "muss ein INVOICE_ONLY System erzeugt werden. ".
                      "TSI RZ steht. Unklar, wer die Assignmentgroup in ".
                      "AM bekommen soll.");
         }
         else{
            if ($amivosys[0]->{usage} eq "INVOICE_ONLY?"){
               $self->addMessage("RenameIVOSysInAM",$amivosys[0]->{systemid},
                          "ToDo","ToDo",
                         "Das System mit der SystemID ".
                         $amivosys[0]->{systemid}." muss von ".
                         $amivosys[0]->{name}." auf ".
                         $amivosys[0]->{systemid}."_HW umbeannt werden.");
            }
            $w5sys->ResetFilter();
            $w5sys->SetFilter({cistatusid=>"<6",
                               assetid=>$assetid});
            my @w5techsys=$w5sys->getHashList(qw(id systemid));
            @w5techsys=grep({!in_array([keys(%amivosys)],$_->{systemid})}
                            @w5techsys);
            if ($#w5techsys==-1){
               $self->addMessage("CreateTechW5Sys",$assetid,
                         "??","??",
                         "Für die AssetID $assetid ".
                         "muss mindestens ein technisches/echtes/reales ".
                         "Sytem in W5Base/Darwin erzeugt werden (Neueingabe)");
            }
         }
   }




   foreach my $k (sort(keys(%{$self->{MsgBuffer}}))){
      $self->addLine(@{$self->{MsgBuffer}->{$k}});
   }


   $self->closeExcel();




   return({exicode=>0});
}



1;
