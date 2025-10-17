package AL_TCom::event::ExcelImportV01;
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

   $self->RegisterEvent("ImportProkom","ImportProkom");
   return(1);
}

sub ImportProkom
{
   my $self=shift;
   my $filename=shift;

   msg(INFO,"try to open file '$filename'");
   $self->{wf}=getModuleObject($self->Config,"base::workflow");
   $self->{appl}=getModuleObject($self->Config,"itil::appl");
   return({exitcode=>1,msg=>"ERROR in accon"}) if (!defined($self->{wf}));

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

   my $msgcol=35; 
   my $newrec={};
   #printf STDERR ("fifi line=%s\n",Dumper($data));
   $newrec->{class}="THOMEZMD::workflow::businesreq";
   $newrec->{step}="base::workflow::request::main";
   my ($m,$d,$y)=$data->[1]=~m/^(\d+)-(\d+)-(\d+)$/;
   $newrec->{eventstart}=$self->getParent->ExpandTimeExpression("$d.$m.".(2000+$y),"GMT");
   my ($m,$d,$y)=$data->[2]=~m/^(\d+)-(\d+)-(\d+)$/;
   $newrec->{eventend}=$self->getParent->ExpandTimeExpression("$d.$m.".(2000+$y),"GMT");
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
