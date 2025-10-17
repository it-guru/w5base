package AL_TCom::event::ExpandExcelV1;
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

sub Init
{
   my $self=shift;

   $self->RegisterEvent("ExpandExcelV1","ExpandExcelV1");
   return(1);
}

sub ExpandExcelV1
{
   my $self=shift;

   $self->{acsys}=getModuleObject($self->Config,"tsacinv::system");
   return({exitcode=>1,msg=>"ERROR in acsys"}) if (!defined($self->{acsys}));
   $self->{acgrp}=getModuleObject($self->Config,"tsacinv::group");
   return({exitcode=>1,msg=>"ERROR in acgrp"}) if (!defined($self->{acgrp}));
   my $exitcode=$self->ProcessExcelExpand(
                "/tmp/w5_tcom.xls",
                "/tmp/w5_tcom_new.xls");

   return({exitcode=>$exitcode});
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
  
   if ($row==0){
      $data->[45]="in W5Base gefunden";
      $data->[46]="W5Base Anwendung";
      $data->[47]="W5Base SeM";
      $data->[48]="W5Base TSM";
      $data->[49]="AssetManager Assignmentgroup Leiter";
      return();
   }

   $self->{acsys}->SetFilter({systemid=>\$data->[0]});
   my ($rec,$msg)=$self->{acsys}->getOnlyFirst(qw(w5base_appl 
                                                  w5base_sem w5base_tsm));
   $data->[45]="Nein";
   if (!($rec->{w5base_appl}=~m/^\s*$/)){
      $data->[45]="Ja";
      $data->[46]=$rec->{w5base_appl};
      if ($rec->{w5base_sem} ne ""){
         $data->[47]=$rec->{w5base_sem};
      }
      if ($rec->{w5base_tsm} ne ""){
         $data->[48]=$rec->{w5base_tsm};
      }
   }
   else{
      $self->{acgrp}->SetFilter({name=>\$data->[19]});
      my ($rec,$msg)=$self->{acgrp}->getOnlyFirst(qw(supervisor)); 
      if ($rec->{supervisor} ne ""){
         $data->[49]=$rec->{supervisor};
      }
   }
}


##########################################################################
##########################################################################
##########################################################################
##########################################################################




sub ProcessExcelExpand
{
   my $self=shift;
   my $inpfile=shift;
   my $outfile=shift;

   if (!defined($outfile)){
      $outfile=$inpfile;
      $outfile=~s/\.xls$/_new.xls/i;
   }
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
      for(my $row=0;$row<=$oWkS->{MaxRow};$row++){
         if ($oWkS->{'Cells'}[$row][0]){
            my $keyval=$oWkS->{'Cells'}[$row][0]->Value();
            next if ($keyval eq "");
            printf("INFO:  Prozess: '%s'\n",$keyval);
            $self->ProcessExcelExpandLevel1($oExcel,$oBook,$oWkS,$iSheet,$row);
         }
      }
   }
   printf("INFO:  saving '%s'\n","$outfile");
   $oExcel->SaveAs($oBook,$outfile);
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
