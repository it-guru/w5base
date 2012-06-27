package TS::event::EurekaMigration;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
use finance::costcenter;
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

   $self->RegisterEvent("EurekaMigration","EurekaMigration");
   return(1);
}

sub EurekaMigration
{
   my $self=shift;
   my $filename=shift;

   msg(INFO,"try to open file '$filename'");
   $ENV{REMOTE_USER}="service/EurekaMigration";
   my $exitcode=$self->ProcessExcelImport($filename);

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
   return() if ($row==0);

   my $newrec={};
   msg(INFO,"Searching $data->[0] ...");
   my $logcol=2;

   my $o="costcenter";
   $self->{$o}->ResetFilter();
   $self->{$o}->SetFilter({name=>\$data->[0]});
   my $n=0;
   foreach my $rec ($self->{$o}->getHashList(qw(ALL))){
      if ($self->{$o}->ValidatedUpdateRecord($rec,
                        {name=>$data->[1]},{id=>\$rec->{id}})){
         msg(INFO,"... set $data->[0] -> $data->[1] in ".$self->{$o}->Self);
         $n++;
      }
   }
   $data->[$logcol]="$n replaces in ".$self->{$o}->Self;

   foreach my $o (qw(system asset appl custcontract)){ 
      $self->{$o}->ResetFilter();
      $self->{$o}->SetFilter({conumber=>\$data->[0]});
      my $n=0;
      foreach my $rec ($self->{$o}->getHashList(qw(ALL))){
         if ($self->{$o}->ValidatedUpdateRecord($rec,
                           {conumber=>$data->[1]},{id=>\$rec->{id}})){
            msg(INFO,"... set $data->[0] -> $data->[1] in ".$self->{$o}->Self.
                     " on id ".$rec->{id});
            $n++;
         }
      }
      $data->[$logcol++]="$n replaces in ".$self->{$o}->Self;
   }
   
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
   $self->{costcenter}=getModuleObject($self->Config,"finance::costcenter");
   $self->{custcontract}=getModuleObject($self->Config,"finance::custcontract");
   $self->{appl}=getModuleObject($self->Config,"itil::appl");
   $self->{system}=getModuleObject($self->Config,"itil::system");
   $self->{asset}=getModuleObject($self->Config,"itil::asset");

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
   $oExcel->SaveAs($oBook,$inpfile);
   return({exitcode=>0});
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
