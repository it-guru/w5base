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

   my @msg;

   my $w5sys=getModuleObject($self->Config,"itil::system");
   my $amsys=getModuleObject($self->Config,"tsacinv::system");
   my $amsys2=getModuleObject($self->Config,"tsacinv::system");
   my $amass=getModuleObject($self->Config,"tsacinv::asset");
   $amsys2->BackendSessionName("xxo$$");

   $self->openExcel();

   my %loc;
   my @notsirz=(
      'DE_FRANKFURT-AM-MAIN_KRUPPSTRASSE_121-127',
      'DE_FRANKFURT_AM_MAIN_ESCHBORNER_LANDSTRASSE_100',
      'DE_MUENCHEN_DACHAUER-STRASSE_665',
      'DE_BONN_LANDGRABENWEG_151',
      'TSI-CSM-MAGDEBURG-LÜBE',
      'DE_BERLIN_HOLZHAUSER_STRASSE_4-8',
      'DE_MUENCHEN_ELISABETH-SELBERT-STRASSE_1'
   );
   {
      my $amloc=getModuleObject($self->Config,"tsacinv::location");
      $amloc->SetFilter({isdatacenter=>'0'});
      my $i=$amloc->getHashIndexed(qw(fullname));
      @notsirz=sort(keys(%{$i->{fullname}}));
   }
   my %assetid;
   my %smap;
   


   if (1){  # Fall1: Systeme sehen aus wie INVOICE_ONLY - haben aber nicht den passenden 
            # namen.
      $amsys->ResetFilter();
      $amsys->SetFilter({
         usage=>\'INVOICE_ONLY?',
         deleted=>\'0',
         customerlink=>'DTAG DTAG.*',
         status=>'"!out of operation"'
      });
      foreach my $amsysrec ($amsys->getHashList(
                            qw(systemname systemid
                               assetassetid
                               assignmentgroup
                               iassignmentgroup
                               tsacinv_locationfullname
                               orderedservices
                               services))){
         my @l=split(/\//,$amsysrec->{tsacinv_locationfullname});
         next if (in_array(\@notsirz,$l[1]));

         $loc{$l[1]}++;

         $assetid{$amsysrec->{assetassetid}}++;  # an den Assets, muß dann ein 
                                                 # INVOICE_ONLY System vorhanden
                                                 # sein.

         # prüfen, ob "echtes" INVOICE_ONLY System bereits vorhanden
         $amsys2->ResetFilter();
         $amsys2->SetFilter({assetassetid=>\$amsysrec->{assetassetid},
                             usage=>\'INVOICE_ONLY',
                             deleted=>\'0',
                             status=>'"!out of operation"'});
         my ($amivosys,$msg)=$amsys2->getOnlyFirst(qw(systemid));
         # checken wir mal, ob das System schon in Darwin erfasst ist.
         # Wenn ja, wird $amsysrec das technische System. Wenn nein, wird
         # $amsysrec umbenannt und wird das INVOICE_ONLY System
         $w5sys->ResetFilter();
         $w5sys->SetFilter({systemid=>\$amsysrec->{systemid}});
         my ($w5sysrec,$msg)=$w5sys->getOnlyFirst(qw(id));
         msg(INFO,"check SystemID $amsysrec->{systemid}");
         if (defined($w5sysrec)){
            # das wie INVOICE_ONLY ausschauende system ist bereits in darwin
            # importiert. 
            

            if (!defined($amivosys)){
               $self->addLine("CreateIVOSysInAM","",
                          $l[1],$amsysrec->{assignmentgroup},
                         "Es muss ein neues INVOICE_ONLY System ".
                         "in AssetManager von der Assignmentgroup ".
                         "$amsysrec->{assignmentgroup} ".
                         "erzeugt werden, das auf die AssetID ".
                         "$amsysrec->{assetassetid} verweist");
            }
            else{
               $self->addLine("TransAuthAmW5Sys",$amsysrec->{systemid},
                         $l[1],"AssetManager-Admins",
                         "Die Authorität für die SystemID ".
                         "$amsysrec->{systemid} muss auf Darwin ".
                         "übertragen werden.");
            }
         }
         else{
            # das wie INVOICE_ONLY ausschauende system ist noch nicht in
            # darwin importiert.
            $self->addLine("CreateTecSysInW5","",
                      $l[1],$amsysrec->{iassignmentgroup},
                      "Es muss in W5Base/Darwin ein neues System mit ".
                      "dem Namen ".
                      lc($amsysrec->{systemname})." erzeugt werden, das ".
                      "auf die ".
                      "AssetID $amsysrec->{assetassetid} verweist. ".
                      "Das neue System (vermutlich) die ".
                      "Incident-Assignmentgroup $amsysrec->{iassignmentgroup} ".
                      "bekommen und einer Application ".
                      "zugeordnet werden.");
            $self->addLine("RenameSysInAM",$amsysrec->{systemid},
                      $l[1],$amsysrec->{assignmentgroup},
                      "Das System mit der SystemID $amsysrec->{systemid} ".
                      "muss von $amsysrec->{systemname} auf ".
                      "$amsysrec->{systemid}_HW umbeannt werden.");
         }


      }
   }

   if (1){ # Fall2: Assets sind von W5Base Darwin erzeugt, stehen aber in
           # einem RZ von T-Systems
      $amass->ResetFilter();
      $amass->SetFilter({
         status=>'"!wasted"',
         deleted=>\'0',
         srcsys=>\'W5Base',
      });
      foreach my $amassrec ($amass->getHashList(
                            qw(assetid tsacinv_locationfullname))){
         my @l=split(/\//,$amassrec->{tsacinv_locationfullname});
         next if (in_array(\@notsirz,$l[1]));
         $self->addLine("TransfAssetAuthD2A",$amassrec->{assetid},
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
            assetid=>[keys(%assetid)]    # load assetids from posible INVOICE_ONLY?
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


   if (1){  # Leistungsverschiebungen von tech. System nach INVOICE_ONLY
      $amsys->ResetFilter();
      $amsys->SetFilter({
         usage=>\'INVOICE_ONLY',
         deleted=>\'0',
         customerlink=>'DTAG DTAG.*',
         status=>'"!out of operation"'
      });
      foreach my $amsysrec ($amsys->getHashList(
                            qw(systemname systemid
                               assetassetid
                               tsacinv_locationfullname
                               orderedservices
                               services))){
         # Prüfung ob Services vom INVOICE_ONLY verschoben werden muessen

         #foreach my $s (@{$amsysrec->{orderedservices}},
         #               @{$amsysrec->{services}}){
         #   $smap{$s->{name}}->{type}->{$s->{type}}++;
         #}
      }
   }


   $self->closeExcel();




   return({exicode=>0});
}



1;
