package AL_TCom::event::VikingExcelImport;
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub VikingExcelImport
{
   my $self=shift;
   my $filename=shift;

   msg(INFO,"try to open file '$filename'");
   $self->{appl}=getModuleObject($self->Config,"TS::appl");

   my $exitcode=$self->ProcessExcelImport($filename);

   return({exitcode=>$exitcode});
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
   for(my $iSheet=0; $iSheet < $oBook->{SheetCount} ; $iSheet++) {
      my $oWkS = $oBook->{Worksheet}[$iSheet];
      my $sheetName=$oWkS->get_name();
      msg(INFO,"processing Worksheet '$sheetName'");
      my $Hcellname={};
      my $Acellname=[];
      for(my $row=0;$row<=$oWkS->{MaxRow};$row++){
         if ($row==0){
            for(my $col=0;$col<=$oWkS->{MaxCol};$col++){
               next if (!($oWkS->{'Cells'}[$row][$col]));
               next if ($oWkS->{'Cells'}[$row][$col]->Value() eq "");
               my $v=$oWkS->{'Cells'}[$row][$col]->Value();
               $Acellname->[$col]=trim($v);
               $Hcellname->{$v}=$col;
            }
         }
         else{
            if (1 && $sheetName eq "Appl"){
               $self->ProcessRowAppl($oExcel,$oBook,$oWkS,$sheetName,
                                     $Hcellname,$Acellname,$iSheet,$row
               );
            }
            if (1 && $sheetName eq "System"){
               $self->ProcessRowSystem($oExcel,$oBook,$oWkS,$sheetName,
                                     $Hcellname,$Acellname,$iSheet,$row
               );
            }
         }
      }
   }
   return(0);
}


sub ProcessRowAppl
{
   my $self=shift;
   my $oExcel=shift;
   my $oBook=shift;
   my $oWkS=shift;
   my $sheetName=shift;
   my $Hcellname=shift;
   my $Acellname=shift;
   my $iSheet=shift;
   my $row=shift;
   my @data;
   my %data;

   for(my $col=0;$col<=$oWkS->{MaxCol};$col++){
      next if (!($oWkS->{'Cells'}[$row][$col]));
      next if (trim($oWkS->{'Cells'}[$row][$col]->Value()) eq "");
      $data[$col]=trim($oWkS->{'Cells'}[$row][$col]->Value());
      $data{$Acellname->[$col]}=$data[$col];
   }
   my $appl=$self->getPersistentModuleObject("TS::appl");

   my %flt=(cistatusid=>"2 3 4 5");
   if (exists($data{'W5BaseID'})){
      $flt{id}=\$data{'W5BaseID'};
   }
   elsif(exists($data{'Name'})){
      $flt{name}=\$data{'Name'};
   }
   else{
      return();
   }
   $appl->SetFilter(\%flt);
   my ($arec,$msg)=$appl->getOnlyFirst(qw(ALL));
   if (defined($arec)){
      msg(INFO,"process application '$arec->{name}'");
      msg(INFO,"acinmassingmentgroup=$arec->{acinmassingmentgroup}");
      my $iagsoll=$data{'Incident Assignmentgroup neu'};
      if ($iagsoll ne "" && $arec->{acinmassingmentgroup} ne $iagsoll){
         msg(INFO,"change to $iagsoll");
         $appl->ValidatedUpdateRecord($arec,{
             acinmassingmentgroup=>$iagsoll
         },{id=>\$arec->{id}});
      }

      my $cagsoll=$data{'Change-Approver Gruppen neu'};
      if ($cagsoll ne ""){
         my @cagsoll=grep(!/^\s*$/, map({trim($_)} split(/(\r|\n)/,$cagsoll)));
         my @cag=map({
            my @l=map({trim($_)} split(/;/,$_));
            $l[0]=~s/^MIS\.SIS\.DE\.SN\.CSO\.AIX\.CA$/MIS.SIS.DE.CSO.AIX.CA/;
            $l[1]=~s/Kunde/customer/i;
            $l[1]=~s/Technisch/technical/i;
            $l[1]=~s/fachlich/functional/i;
            my $rec={
                'group' => $l[0],
                'responsibility' => $l[1]
            }; 
         } @cagsoll);
         my %map;
         map({
            push(@{$map{i}->{$_->{responsibility}}},$_->{group});
         } @{$arec->{chmapprgroups}});
         map({
            push(@{$map{s}->{$_->{responsibility}}},$_->{group});
         } @cag);
         #printf STDERR ("map:%s",Dumper(\%map));
         foreach my $responsibility (qw(technical customer functional)){
            my $cag=$self->getPersistentModuleObject("TS::lnkapplchmapprgrp");
            if (exists($map{s}->{$responsibility})){
               if (!exists($map{i}->{$responsibility})){
                  $map{i}->{$responsibility}=[];
               } 
               if (join(",",sort(@{$map{s}->{$responsibility}})) ne 
                   join(",",sort(@{$map{i}->{$responsibility}}))){
                  msg(INFO,"modify $responsibility");
                  $cag->BulkDeleteRecord({ 
                     refid=>\$arec->{id},
                     responsibility=>\$responsibility,
                     parentobj=>\'TS::appl'
                  });
                  foreach my $group (@{$map{s}->{$responsibility}}){
                     $cag->ValidatedInsertRecord({ 
                        refid=>$arec->{id},
                        responsibility=>$responsibility,
                        parentobj=>'TS::appl',
                        group=>$group
                     });
                  }
               }
            } 
         }
      }

   }
   else{
      msg(ERROR,"unable to process line ".($row+1)." in Sheet '$sheetName'");
   }
}



sub ProcessRowSystem
{
   my $self=shift;
   my $oExcel=shift;
   my $oBook=shift;
   my $oWkS=shift;
   my $sheetName=shift;
   my $Hcellname=shift;
   my $Acellname=shift;
   my $iSheet=shift;
   my $row=shift;
   my @data;
   my %data;

   for(my $col=0;$col<=$oWkS->{MaxCol};$col++){
      next if (!($oWkS->{'Cells'}[$row][$col]));
      next if (trim($oWkS->{'Cells'}[$row][$col]->Value()) eq "");
      $data[$col]=trim($oWkS->{'Cells'}[$row][$col]->Value());
      $data{$Acellname->[$col]}=$data[$col];
   }
   my $sys=$self->getPersistentModuleObject("TS::system");

   my %flt=(cistatusid=>"3 4 5");
   if (exists($data{'W5BaseID'})){
      $flt{id}=\$data{'W5BaseID'};
   }
   elsif(exists($data{'Systemname'})){
      $flt{name}=\$data{'Systemname'};
   }
   else{
      return();
   }
   $sys->SetFilter(\%flt);
   my ($srec,$msg)=$sys->getOnlyFirst(qw(ALL));
   if (defined($srec)){
      my $niag=$data{'Incident Assignmentgroup neu ab 01.02.2024'};
      if ($niag ne "" && 
          lc($niag) ne "to clarify" &&
          !($niag=~m/wird von/i) &&
          !($niag=~m/wird vom/i) &&
          !($niag=~m/wird in/i)){
         if ($srec->{srcsys} ne "AssetManager"){
            if ($srec->{acinmassingmentgroup} ne $niag){
               msg(INFO,"process system '$srec->{name}'");
               msg(INFO,"change to '$niag'");
               $sys->ValidatedUpdateRecord($srec,{
                   acinmassingmentgroup=>$niag
               },{id=>\$srec->{id}});
            }
         }
      }
      my $chag=$data{'Change Approvergroup ab 01.02.2024'};
      $chag=~s/\s*;\s*tec.*\s*$//;
      if ($chag ne "" && 
          lc($chag) ne "to clarify" &&
          !($chag=~m/wird von/i) &&
          !($chag=~m/wird vom/i) &&
          !($chag=~m/wird in/i)){
         if ($srec->{srcsys} ne "AssetManager"){
            if ($srec->{scapprgroup} ne $chag){
               msg(INFO,"process system '$srec->{name}'");
               msg(INFO,"change to '$chag'");
               $sys->ValidatedUpdateRecord($srec,{
                   scapprgroup=>$chag
               },{id=>\$srec->{id}});
            }
         }
      }
      
   }
   else{
      msg(ERROR,"unable to process line ".($row+1)." in Sheet '$sheetName'");
   }
}





1;
