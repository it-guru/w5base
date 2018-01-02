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

our %src;
our %dst;


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
   $ENV{REMOTE_USER}="service/ONEERP";
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
   my $total=0;
   my %to=();
   my %cc=(11634953080001=>1,  # vogler
           11634955470001=>1    # merx  
           );
   my $msg="";
   my $EventJobBaseUrl=$self->Config->Param("EventJobBaseUrl");
   foreach my $rec ($self->{$o}->getHashList(qw(ALL))){
      if ($self->{$o}->ValidatedUpdateRecord($rec,
                        {name=>$data->[1]},{id=>\$rec->{id}})){
         msg(INFO,"... set $data->[0] -> $data->[1] in ".$self->{$o}->Self);
         $total++;
         $to{$rec->{databossid}}++ if ($rec->{databossid} ne "");
         my $l=$self->{$o}->T($self->{$o}->Self,$self->{$o}->Self);
         $msg.="\n".$l." : $data->[0]\n".
               "$EventJobBaseUrl/auth/finance/costcenter/ById/".$rec->{id}."\n";
               
      }
   }
   $data->[$logcol]="$total replaces in ".$self->{$o}->Self;

   foreach my $o (qw(system asset appl custcontract)){ 
      $self->{$o}->ResetFilter();
      $self->{$o}->SetFilter({conumber=>\$data->[0],
                              cistatusid=>"<=5"});
      my $n=0;
      foreach my $rec ($self->{$o}->getHashList(qw(ALL))){
         if ($self->{$o}->ValidatedUpdateRecord($rec,
                           {conumber=>$data->[1]},{id=>\$rec->{id}})){
            msg(INFO,"... set $data->[0] -> $data->[1] in ".$self->{$o}->Self.
                     " on id ".$rec->{id});
            $n++;
            $total++;
            $cc{$rec->{databossid}}++ if ($rec->{databossid} ne "");
            my $l=$self->{$o}->T($self->{$o}->Self,$self->{$o}->Self);
            my $t=$self->{$o}->Self;
            $t=~s/::/\//g;
            $msg.="\n".$l." : $rec->{name}\n".
                  "$EventJobBaseUrl/auth/$t/ById/".$rec->{id}."\n";
         }
      }
      $data->[$logcol++]="$n replaces in ".$self->{$o}->Self;
   }
   if ($total>0){
      #printf STDERR ("fifi to=%s\n",Dumper(\%to));
      #printf STDERR ("fifi cc=%s\n",Dumper(\%cc));
      my $wfa=getModuleObject($self->Config,"base::workflowaction");
      if (keys(%to)!=0){
         $wfa->Notify("INFO",
                      "CO/Kostenstellen/PSP Migration - ".
                      "OneERP - ".$data->[0]."->".$data->[1],
                      "Sehr geehrte Damen und Herren,\n\n".
                      "Aufgrund einer notwendigen Umstellung von CO-Nummern ".
                      "und Kostenstellen aufgrund des OneERP Projektes ".
                      "(T-Systems), wurden in W5Base/Darwin ".
                      "Korrekturen an Config-Items durchgeführt, die durch ".
                      "Sie datenverantwortet werden.\n\n".
                      "Im konkreten Fall wurde der Kostenknoten '<b>".
                      $data->[0]."</b>' auf '<b>".$data->[1].
                      "</b>' umgestellt. ".
                      "Die Korrektur hat Auswirkungen auf die folgenden ".
                      "Config-Items:\n".$msg.
                      "\n\nBitte prüfen Sie im Bedarfsfall, ob diese ".
                      "Umstellungen auch aus Ihrer Sicht korrekt sind.",
                      emailto=>[keys(%to)],
                      emailcc=>[keys(%cc)]);
      }
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
   eval('use Spreadsheet::ParseExcel;'.
        'use Spreadsheet::ParseExcel::SaveParser;'.
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
   $src{$data[0]}++ if ($data[0] ne "");
   $dst{$data[1]}++ if ($data[1] ne "");
   if ($src{$data[0]}>1){
      printf STDERR ("Doppelte SRC CO: $data[0] in line $row\n");
      $data[2].="DoppeltSRC";
   }
   if ($data[0] ne ""){
      $self->ProcessLineData($oExcel,$oBook,$oWkS,$iSheet,$row,\@data);
   }
   for(my $col=0;$col<=$#data;$col++){
      if ($data[$col] ne $orgdata[$col]){
         $oBook->AddCell($iSheet,$row,$col,$data[$col],0);
      }
   }
}





1;
