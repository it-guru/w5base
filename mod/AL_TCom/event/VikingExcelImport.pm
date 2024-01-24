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
            #if ($sheetName eq "Appl"){
            #   $self->ProcessRowAppl($oExcel,$oBook,$oWkS,$sheetName,
            #                         $Hcellname,$Acellname,$iSheet,$row
            #   );
            #}
            if ($sheetName eq "System"){
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

   my %flt=(cistatusid=>"3 4 5");
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
     # if ($iagsoll ne "" && $arec->{acinmassingmentgroup} ne $iagsoll){
     #    msg(INFO,"change to $iagsoll");
     #    $appl->ValidatedUpdateRecord($arec,{
     #        acinmassingmentgroup=>$iagsoll
     #    },{id=>\$arec->{id}});
     #    #print STDERR Dumper(\%data);
     # }

      my $cagsoll=$data{'Change-Approver Gruppen neu'};
      if ($cagsoll ne ""){
         my @cagsoll=grep(!/^\s*$/, map({trim($_)} split(/(\r|\n)/,$cagsoll)));
         my @cag=map({
            my @l=map({trim($_)} split(/;/,$_));
            $l[1]=~s/Kunde/customer/i;
            $l[1]=~s/Technisch/technical/i;
            $l[1]=~s/fachlich/functional/i;
            my $rec={
                'group' => $l[0],
                'responsibility' => $l[1]
            }; 
         } @cagsoll);



print STDERR "IST:".Dumper($arec->{chmapprgroups});
print STDERR "SOLL:".Dumper(\@cag);
         #       name          =>'chmapprgroups',
         #       label         =>'Change approver groups',
         #       htmlwidth     =>'200px',
         #       group         =>'chm',
         #       allowcleanup  =>1,
         #       subeditmsk    =>'subedit.approver',
         #       vjointo       =>'TS::lnkapplchmapprgrp',
         #       vjoinbase     =>[{parentobj=>\'TS::appl'}],
         #       vjoinon       =>['id'=>'refid'],
         #       vjoindisp     =>['group','responsibility']),
#c=SAP.AO.DE.SN.DTAG.FINANCE.CA;Kunde
#SAP.AO.DE.SN.DTAG.FINANCE.CA;fachlich
#SAP.AO.DE.SN.DTAG.FINANCE.CA;technisch


      }
      


   }
   else{
      msg(ERROR,"unable to process line $row in Sheet '$sheetName'");
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
      if ($niag ne ""){
         if ($srec->{srcsys} ne "AssetManager"){
            msg(INFO,"process system '$srec->{name}'");
            if ($srec->{acinmassingmentgroup} ne $niag){
               msg(INFO,"change to $niag");
               $sys->ValidatedUpdateRecord($srec,{
                   acinmassingmentgroup=>$niag
               },{id=>\$sys->{id}});
            }
         }
      }
      
   }
   else{
      msg(ERROR,"unable to process line $row in Sheet '$sheetName'");
   }
}





1;
