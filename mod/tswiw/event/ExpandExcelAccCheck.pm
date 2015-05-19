package tswiw::event::ExpandExcelAccCheck;
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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

sub ExpandExcelAccCheck
{
   my $self=shift;
   my $filename=shift;

   $self->{wu}=getModuleObject($self->Config,"tswiw::user");
   return({exitcode=>1,msg=>"ERROR in wiwuser"}) if (!defined($self->{wu}));

   msg(INFO,"try to open file '$filename'");
   my $exitcode=$self->ProcessExcelExpand($filename);
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
      $data->[3]="WIW-ID valid";
      $data->[4]="Email valid";
      $data->[6]="ID+mail Match";
      return();
   }
   else{
      if ($row<10000){
         $data->[3]="fail";
         $data->[4]="fail";
         $data->[6]="fail";
         $self->{wu}->ResetFilter();
         $self->{wu}->SetFilter({uid=>$data->[0]});
         my ($rec1,$msg)=$self->{wu}->getOnlyFirst(qw(uid email email2 email3));
         if (defined($rec1)){
            $data->[3]="OK";
            if (lc($data->[1]) eq lc($rec1->{email}) ||
                lc($data->[1]) eq lc($rec1->{email2}) ||
                lc($data->[1]) eq lc($rec1->{email3})){
               $data->[4]="OK";
               $data->[6]="OK";
            }
            else{
               $self->{wu}->ResetFilter();
               $self->{wu}->SetFilter([{email=>$data->[1]},
                                       {email2=>$data->[1]},
                                       {email3=>$data->[1]}]);
               my ($rec2,$msg)=$self->{wu}->getOnlyFirst(qw(uid));
               if (defined($rec2)){
                  $data->[4]="OK";
                  $data->[6]="fail (correct: $rec2->{uid})";
               }
            }
         }
         else{
            $data->[4]="???";
         }
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
