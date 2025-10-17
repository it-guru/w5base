package AL_TCom::event::RMADataload;
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
use Data::Dumper;
use kernel;
use kernel::Event;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}


sub CreateWorkflows
{
   my $self=shift;

   foreach my $riskid (keys(%{$self->{d}->{risk}})){
      my $rec=$self->{d}->{risk}->{$riskid};
      next if ($rec->{invalid});
      $self->{wf}->ResetFilter();
      $self->{wf}->SetFilter({srcsys=>\$rec->{srcsys},
                              srcid=>\$rec->{srcid}});
      my ($wfrec,$msg)=$self->{wf}->getOnlyFirst(qw(ALL));
      if (defined($wfrec)){
         printf STDERR ("old $rec->{srcsys} $rec->{srcid}\n");

      }
      else{
         my $id=$self->{wf}->ValidatedInsertRecord($rec);
         if (defined($id)){
            printf STDERR ("INFO:  new RiskMgmt Workflow $id for ".
                           "Risk ID  $rec->{srcid} created\n");
            $rec->{wfheadid}=$id;
         }
         else{
            msg(ERROR,"fail to create Workflow ".Dumper($rec));
         }
      }
   }
   foreach my $mid (keys(%{$self->{d}->{measure}})){
      my $rec=$self->{d}->{measure}->{$mid};
      next if ($rec->{invalid});
      if (!exists($self->{d}->{risk}->{$rec->{riskid}})){
         msg(ERROR,"invalid riskid for $rec->{srcid} ".
                   "1st ref at $rec->{ref}->[0]");
         next;
      } 
      if (!exists($self->{d}->{risk}->{$rec->{riskid}}->{wfheadid})){
         msg(ERROR,"missing riskmgmt workflow for $rec->{srcid} ".
                   "1st ref at $rec->{ref}->[0]");
         next;
      } 
      if ($rec->{detaildescription} eq ""){
         msg(ERROR,"missing detaildescription for $rec->{srcid} ".
                   "1st ref at $rec->{ref}->[0]");
         next;
      }
      $self->{wf}->ResetFilter();
      $self->{wf}->SetFilter({srcsys=>\$rec->{srcsys},
                              srcid=>\$rec->{srcid}});
      my ($wfrec,$msg)=$self->{wf}->getOnlyFirst(qw(ALL));
      if (defined($wfrec)){
         printf STDERR ("old $rec->{srcsys} $rec->{srcid}\n");
      }
      else{
         if ($rec->{plannedstart} eq $rec->{plannedend}){
            msg(WARN,"ignoring planned end for $rec->{srcid}");
            delete($rec->{plannedend});
         }
         if ($rec->{plannedstart} ne "" && $rec->{plannedend} ne ""){
            my @d=($rec->{plannedstart}, $rec->{plannedend});
            @d=sort(@d);
            if ($d[0] ne $rec->{plannedstart}){
               msg(WARN,"swapping start and end for $rec->{srcid}");
               my $tmp=$rec->{plannedstart};
               $rec->{plannedstart}=$rec->{plannedend};
               $rec->{plannedend}=$tmp;
            }
         }
         if ($rec->{plannedend} ne ""){
            my ($y)=$rec->{plannedend}=~m/^(\d+)/;
            if ($y>2020){
               msg(WARN,"ignoring to far in future planned end ".
                        "for $rec->{srcid}");
               delete($rec->{plannedend});
            }
         }
         my $id=$self->{wf}->ValidatedInsertRecord($rec);
         if (defined($id)){
            printf STDERR ("INFO:  new OpMeasure Workflow $id for ".
                           "Measure ID  $rec->{srcid} created\n");
            $rec->{wfheadid}=$id;

            my $wr=getModuleObject($self->Config,
                                   "base::workflowrelation");
            $wr->ValidatedInsertRecord({
               name=>"riskmesure",
               translation=>"itil::workflow::riskmgmt",
               srcwfid=>$self->{d}->{risk}->{$rec->{riskid}}->{wfheadid},
               dstwfid=>$id,
            });
            if (exists($rec->{addnote})){
               if (!($self->{wf}->Action->StoreRecord($id,"wfaddnote",
                   {translation=>'base::workflow::request'},$rec->{addnote}))){
                  msg(ERROR,"fail to add note to Workflow ".
                            "1st ref at $rec->{ref}->[0]");
               
               }
            }
         }
         else{
            msg(ERROR,"fail to create Workflow ".Dumper($rec));
         }
      }
   }

}


sub RMADataload
{
   my $self=shift;
   my $filename=shift;


   msg(INFO,"try to open file '$filename'");
   $self->{wf}=getModuleObject($self->Config,"base::workflow");
   foreach my $trtab (qw(itil::workflow::riskmgmt AL_TCom::workflow::riskmgmt)){
      push(@{$self->{trtab}},$self->LoadTranslation($trtab,1));
   }

   $self->{appl}=getModuleObject($self->Config,"itil::appl");
   $self->{appname}={};
   $self->{d}={};
   return({exitcode=>1,msg=>"ERROR in accon"}) if (!defined($self->{wf}));

   my $exitcode=$self->ProcessExcelImport($filename);

   printf("INFO:  try to load workflows\n");

   #print Dumper($self->{d});
   $self->CreateWorkflows();

   return({exitcode=>$exitcode});
}

sub revT
{
   my $self=shift;
   my $ns=shift;
   my $lang=shift;
   my $text=shift;
   foreach my $trtab (@{$self->{trtab}}){
      foreach my $k (keys(%{$trtab->{$lang}})){
         my $qns=quotemeta($ns);
         if ($text eq $trtab->{$lang}->{$k}){
            if ($trtab->{$lang}->{$k} eq $text){
               my $bk=$k;
               $bk=~s/$qns//x;
               return($bk);
            }
         }
      }
   }
   return(undef);
}

sub ProcessLineData
{
   my $self=shift;
   my $oExcel=shift;
   my $oBook=shift;
   my $oWkS=shift;
   my $iSheet=shift;
   my $row=shift;
   my $data=shift;
   return() if ($row==0);  # skip first rows

   my $msgcol=35; 
   my $newrec={};
   if ($data->[0] ne ""){
      my $riskid=$data->[0];
      my $applname=$data->[1];
      if (!exists($self->{appname}->{$applname})){
         $self->{appl}->ResetFilter();
         $self->{appl}->SetFilter({name=>\$applname});
         my ($arec,$msg)=$self->{appl}->getOnlyFirst(qw(ALL));
         if (!defined($arec)){
            printf STDERR ("ERROR: invalid application name in ".
                           "line %d in sheet %d\n",$row+1,$iSheet+1);
            return;
         }
         $self->{appname}->{$applname}=$arec;
      }
      my $arec=$self->{appname}->{$applname};

      if (my ($rnum)=$data->[2]     # Risiko Behandlung
          =~/_Risiko_(\d+)$/){
         my $invalid=0;
         if ($data->[3] eq 
             "Welche Art von Risiko haben Sie?"){
             my $tag=$self->revT("RISKBASE.","de",trim($data->[4]));
             $invalid=1 if (!defined($tag));
             $self->{d}->{risk}->{$riskid}->{riskbasetype}=$tag;
         }
         elsif ($data->[3] eq 
                "Kurzbescheibung"){
             $self->{d}->{risk}->{$riskid}->{name}=$data->[4];
         }
         elsif ($data->[3] eq 
                "Beschreibung der Auswirkungen bei Risikoeintritt?"){
             $self->{d}->{risk}->{$riskid}->{extdescriskimpact}=$data->[4];
         }
         elsif ($data->[3] eq 
                "Geschätze Ausfallzeit bei Risikoeintritt?"){
             my $d=trim($data->[4]);
             $d="0" if ($d eq "");
             $invalid=1 if ($d eq "");
             $self->{d}->{risk}->{$riskid}->{extdescriskdowntimedays}=trim($d);
         }
         elsif ($data->[3] eq 
                "Eintrittswahrscheinlichkeit des Risikos"){
             my $d=$data->[4];
             $d=~s/ //g;
             my $tag=$self->revT("RISKPCT.","de",trim($d).' %');
             $invalid=1 if (!defined($tag));
             $self->{d}->{risk}->{$riskid}->{extdescriskoccurrency}=$tag;
         }
         elsif ($data->[3] eq 
                "Ab wann kann das Risiko eintreten?"){
             my $d=trim($data->[4]);
             $d=NowStamp("en") if ($d eq "");
             $d=$self->{appl}->ExpandTimeExpression($d,"CET");
             $invalid=1 if ($d eq "");
             $self->{d}->{risk}->{$riskid}->{extdescarisedate}=$d;
         }
         elsif ($data->[3] eq 
                "Schadensausmaß DTAG (Schätzung)"){
             my $v=trim($data->[4])." EUR";
             if ($v=~m/bis/){
                $v=~s/^>//;
             }
             $v=~s/0_5/0,5/g;
             $v=~s/0,5 bis/0,5 Mio bis/g;
             $v=~s/2 bis/2,0 Mio bis/g;
             $v=~s/2 Mio/2,0 Mio/g;
             $v=~s/10 Mio/10,0 Mio/g;
             $v="bis 0,5 Mio EUR" if ($v eq "0 EUR" || $v eq " EUR");
             my $tag=$self->revT("DTAGMONIMP.","de",$v);
             if (!defined($tag)){
                $invalid=1;
                printf STDERR ("can not find '$v'\n");
             }
             $self->{d}->{risk}->{$riskid}->{extdescdtagmonetaryimpact}=$tag;
         }
         elsif ($data->[3] eq 
                "Schadensausmaß in der IT  (Schätzung)"){
             my $v=trim($data->[4])." EUR";
             if ($v=~m/bis/){
                $v=~s/^>//;
             }
             $v=~s/0_5/0,5/g;
             $v=~s/0,5 bis/0,5 Mio bis/g;
             $v=~s/2 bis/2,0 Mio bis/g;
             $v=~s/2 Mio/2,0 Mio/g;
             $v=~s/10 Mio/10,0 Mio/g;
             $v="bis 1000 EUR" if ($v eq "0 EUR" || $v eq " EUR");
             my $tag=$self->revT("TELITMONIMP.","de",$v);
             if (!defined($tag)){
                $invalid=1;
                printf STDERR ("can not find '$v'\n");
             }
             $self->{d}->{risk}->{$riskid}->{extdesctelitmonetaryimpact}=$tag;
         }
         else{
            printf STDERR ("WARN:  ignore risk data line ".
                           "line %d in sheet %d\n",$row+1,$iSheet+1);
            return;
         }
         if (length($self->{d}->{risk}->{$riskid}->{name})>127){
            $self->{d}->{risk}->{$riskid}->{name}=
               substr($self->{d}->{risk}->{$riskid}->{name},0,125)."...";
         }
         if ($invalid){
            printf STDERR ("WARN:  ignore risk data in field ".
                           "line %d in sheet %d\n",$row+1,$iSheet+1);
            $self->{d}->{risk}->{$riskid}->{invalid}++;
         }
         $self->{d}->{risk}->{$riskid}->{eventstart}=NowStamp("en");
         $self->{d}->{risk}->{$riskid}->{name}=~s/[\n\r]/ /g;
         $self->{d}->{risk}->{$riskid}->{class}='AL_TCom::workflow::riskmgmt';
         $self->{d}->{risk}->{$riskid}->{mandatorid}=$arec->{mandatorid};
         $self->{d}->{risk}->{$riskid}->{mandator}=$arec->{mandator};
         $self->{d}->{risk}->{$riskid}->{affectedapplication}=$arec->{name};
         $self->{d}->{risk}->{$riskid}->{affectedapplicationid}=$arec->{id};
         $self->{d}->{risk}->{$riskid}->{srcsys}="RMA_XLSLoad_Risk";
         $self->{d}->{risk}->{$riskid}->{srcid}=$riskid;
         $self->{d}->{risk}->{$riskid}->{fwdtarget}="base::user";
         $self->{d}->{risk}->{$riskid}->{fwdtargetid}=$arec->{applmgrid};
         $self->{d}->{risk}->{$riskid}->{owner}=$arec->{applmgrid};
         $self->{d}->{risk}->{$riskid}->{openuser}=$arec->{applmgrid};
         $self->{d}->{risk}->{$riskid}->{step}="itil::workflow::riskmgmt::main";
         $self->{d}->{risk}->{$riskid}->{stateid}="4";
         push(@{$self->{d}->{risk}->{$riskid}->{ref}},
               "Z".($row+1)."/S".($iSheet+1));
      }
      elsif (my ($rnum,$mnum)=$data->[2]   # Massnahmen Behandlung
             =~/_Risiko_(\d+).Massnahme_(\d+)(_optional){0,1}$/){
         my $mid=$riskid."-".$mnum;
         my $invalid=0;
         if ($data->[3] eq 
             "Welche Art von Risiko haben Sie?"){

         }
         elsif ($data->[3] eq 
                "Maßnahme Kurzbeschreibung"){
            my $d=trim($data->[4]);
            $invalid=1 if (length($d)<10);
            $self->{d}->{measure}->{$mid}->{name}=$d;
         }
         elsif ($data->[3] eq 
                "Geplanter Beginn"){
             my $d=trim($data->[4]);
             $d=NowStamp("en") if ($d eq "");
             $d=$self->{appl}->ExpandTimeExpression($d,"CET");
             $invalid=1 if ($d eq "");
             $self->{d}->{measure}->{$mid}->{plannedstart}=$d;
             $self->{d}->{measure}->{$mid}->{plannedstart}
                =~s/00:00:00/12:00:00/;
         }
         elsif ($data->[3] eq 
                "Geplantes Ende"){
             my $d=trim($data->[4]);
             $d=NowStamp("en") if ($d eq "");
             $d=$self->{appl}->ExpandTimeExpression($d,"CET");
             $invalid=1 if ($d eq "");
             $self->{d}->{measure}->{$mid}->{plannedend}=$d;
             $self->{d}->{measure}->{$mid}->{plannedend}
                =~s/00:00:00/12:00:00/;
         }
         elsif ($data->[3] eq 
                "Bitte hier die Maßnahme schildern, die zur ".
                "Beseitigung/Abschwächung des Risikos führt."){
            my $d=trim($data->[4]);
            $invalid=1 if (length($d)<10);
            $self->{d}->{measure}->{$mid}->{detaildescription}=$d;
         }
         elsif ($data->[3] eq 
                "Notiz die an der Maßnahme haftet"){
            my $d=trim($data->[4]);
            if (length($d)>10){
               $self->{d}->{measure}->{$mid}->{addnote}=$d
            }
            else{
               if (length($data->[4])>1){
                  $invalid=1;
               }
            }
         }
         else{
            printf STDERR ("WARN:  ignore mesure data line ".
                           "line %d in sheet %d\n",$row+1,$iSheet+1);
            return;
         }
         if ($invalid){
            printf STDERR ("WARN:  ignore measure data in field ".
                           "line %d in sheet %d\n",$row+1,$iSheet+1);
            $self->{d}->{measure}->{$mid}->{invalid}++;
         }
         if (length($self->{d}->{measure}->{$mid}->{name})>127){
            $self->{d}->{measure}->{$mid}->{name}=
               substr($self->{d}->{measure}->{$mid}->{name},0,125)."...";
         }
         $self->{d}->{measure}->{$mid}->{name}=~s/[\n\r]/ /g;
         $self->{d}->{measure}->{$mid}->{srcsys}="RMA_XLSLoad_Measure";
         $self->{d}->{measure}->{$mid}->{affectedapplication}=$arec->{name};
         $self->{d}->{measure}->{$mid}->{affectedapplicationid}=$arec->{id};
         $self->{d}->{measure}->{$mid}->{srcid}=$mid;
         $self->{d}->{measure}->{$mid}->{subtyp}="riskmeasure";
         $self->{d}->{measure}->{$mid}->{class}='itil::workflow::opmeasure';
         $self->{d}->{measure}->{$mid}->{eventstart}=NowStamp("en");
         $self->{d}->{measure}->{$mid}->{mandatorid}=$arec->{mandatorid};
         $self->{d}->{measure}->{$mid}->{mandator}=$arec->{mandator};
         $self->{d}->{measure}->{$mid}->{fwdtarget}="base::user";
         $self->{d}->{measure}->{$mid}->{fwdtargetid}=$arec->{applmgrid};
         $self->{d}->{measure}->{$mid}->{owner}=$arec->{applmgrid};
         $self->{d}->{measure}->{$mid}->{openuser}=$arec->{applmgrid};
         $self->{d}->{measure}->{$mid}->{step}="itil::workflow::opmeasure::main";
         $self->{d}->{measure}->{$mid}->{stateid}="4";
         $self->{d}->{measure}->{$mid}->{riskid}=$riskid;
         push(@{$self->{d}->{measure}->{$mid}->{ref}},
               "Z".($row+1)."/S".($iSheet+1));
      }
      else{
         printf STDERR ("WARN: ignore line ".
                        "line %d in sheet %d\n",$row+1,$iSheet+1);
         return;
      }
   }

   return;
   $newrec->{class}="THOMEZMD::workflow::businesreq";
   $newrec->{step}="base::workflow::request::main";
   my ($m,$d,$y)=$data->[1]=~m/^(\d+)-(\d+)-(\d+)$/;
   $newrec->{eventstart}=$self->getParent->ExpandTimeExpression(
                               "$d.$m.".(2000+$y),"GMT");
   my ($m,$d,$y)=$data->[2]=~m/^(\d+)-(\d+)-(\d+)$/;
   $newrec->{eventend}=$self->getParent->ExpandTimeExpression(
                               "$d.$m.".(2000+$y),"GMT");
   $newrec->{mdate}=$self->getParent->ExpandTimeExpression("now","GMT");
   $newrec->{opendate}=$self->getParent->ExpandTimeExpression("now","GMT");
   $newrec->{closedate}=$self->getParent->ExpandTimeExpression("now","GMT");
   $newrec->{customerrefno}=$data->[0];
   $newrec->{name}=$data->[6];
   $newrec->{stateid}=21;
   $newrec->{tcomworktime}=$data->[7]*60;
   $newrec->{detaildescription}=$data->[8];
   $newrec->{zmsarticleno}="701841-0002; Sonstige Abrufleistungen"; 
   $newrec->{affectedapplication}="Prokom_B_Prod" if ($data->[5] eq "P");
   $newrec->{affectedapplication}="Prokom_B_ETA"  if ($data->[5] eq "T");
   $newrec->{initiatorid}=12319309800001;
   $newrec->{initiatorname}="Naumann, Thomas";
   $newrec->{initiatorgroupname}="DTAG.T-Home.ZMD.ZMD6";
   $newrec->{initiatorgroupid}=12318382710002;
   $newrec->{openuser}=12319309800001;
   $newrec->{openusername}="Naumann, Thomas";
   $self->{appl}->ResetFilter();
   $self->{appl}->SetFilter({name=>\$newrec->{affectedapplication}});
   my ($arec,$msg)=$self->{appl}->getOnlyFirst(qw(ALL));
   if (defined($arec)){
      $newrec->{affectedapplication}=$arec->{name}; 
      $newrec->{affectedapplicationid}=$arec->{id}; 
      $newrec->{mandator}=[$arec->{mandator}]; 
      $newrec->{mandatorid}=[$arec->{mandatorid}]; 
      my %contract;
      my %contractid;
      foreach my $c (@{$arec->{custcontracts}}){
         $contract{$c->{custcontract}}++;
         $contractid{$c->{custcontractid}}++;
      }
      $newrec->{affectedcontract}=[keys(%contract)];
      $newrec->{affectedcontractid}=[keys(%contractid)];
      printf STDERR ("newrec=%s\n",Dumper($newrec));
      my $old=$W5V2::OperationContext;
      $W5V2::OperationContext="Kernel";
      $self->{wf}->ValidatedInsertRecord($newrec);
      $W5V2::OperationContext=$old;
   }
   
#   msg(INFO,"Referenz=%s",$data->[0]);
}


##########################################################################
##########################################################################
##########################################################################
##########################################################################




sub ProcessExcelImport
{
   my $self=shift;
   my $inpfile=shift;

   if (! -r $inpfile ){
      printf STDERR ("ERROR: can't open '$inpfile'\n");
      printf STDERR ("ERROR: errstr=$!\n");
      exit(1);
   }
   else{
      printf ("INFO:  opening $inpfile\n");
   }
   my $oExcel;
   eval('use Spreadsheet::ParseExcel::SaveParser;'.
        '$oExcel=new Spreadsheet::ParseExcel::SaveParser;');
   if ($@ ne "" || !defined($oExcel)){
      msg(ERROR,"%s",$@);
      return(2);
   }
   my  $oBook=$oExcel->Parse($inpfile);
   if (!$oBook ){
      printf STDERR ("ERROR: can't parse '$inpfile'\n");
      exit(1);
   }
   for(my $iSheet=0; $iSheet < 2 ; $iSheet++) {  # nur die ersten beiden Sheets
      my $oWkS = $oBook->{Worksheet}[$iSheet];
      for(my $row=0;$row<=$oWkS->{MaxRow};$row++){
         if ($oWkS->{'Cells'}[$row][0]){
            my $keyval=$oWkS->{'Cells'}[$row][0]->Value();
            next if ($keyval eq "");
  #          printf("INFO:  Prozess: '%s'\n",$keyval);
            $self->ProcessExcelExpandLevel1($oExcel,$oBook,$oWkS,$iSheet,$row);
         }
      }
   }
}


sub ProcessExcelExpandLevel1
{
   my $self=shift;
   my $oExcel=shift;
   my $oBook=shift;
   my $oWkS=shift;
   my $iSheet=shift;
   my $row=shift;
   my @data=();
   my @orgdata=();

   for(my $col=0;$col<=$oWkS->{MaxCol};$col++){
      next if (!($oWkS->{'Cells'}[$row][$col]));
      next if ($oWkS->{'Cells'}[$row][$col]->Value() eq "");
      $data[$col]=$oWkS->{'Cells'}[$row][$col]->Value();
   }
   @orgdata=@data;
   $self->ProcessLineData($oExcel,$oBook,$oWkS,$iSheet,$row,\@data);
   for(my $col=0;$col<=$#data;$col++){
      if ($data[$col] ne $orgdata[$col]){
         $oBook->AddCell($iSheet,$row,$col,$data[$col],0);
      }
   }
}





1;
