package BCBS::event::ExcelImport;
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


   $self->RegisterEvent("loadimdl","LoadIMDL");
   return(1);
}

sub LoadIMDL
{
   my $self=shift;
   my $filename=shift;
   my ($oExcel,$oBook);

   my $initcode=<<EOF;
use Spreadsheet::ParseExcel;
use Spreadsheet::ParseExcel::SaveParser;
\$oExcel=new Spreadsheet::ParseExcel::SaveParser;
\$oBook=\$oExcel->Parse(\$filename);
EOF

   eval($initcode); 
   if (!defined($oBook)){
      msg(ERROR,$@);
      msg(ERROR,"fail to open '$filename'");
      return({exitcode=>1});
   }
   for(my $iSheet=0; $iSheet < $oBook->{SheetCount} ; $iSheet++) {
      my $oWkS = $oBook->{Worksheet}[$iSheet];
      my %fnames=();
      next if (!$self->PreProcess($oExcel,$oBook,$oWkS,$iSheet,\%fnames));
      for(my $col=0;$col<=$oWkS->{MaxCol};$col++){
         next if (!($oWkS->{'Cells'}[0][$col]));
         next if ($oWkS->{'Cells'}[0][$col]->Value() eq "");
         my $name=$oWkS->{'Cells'}[0][$col]->Value();
         $fnames{$col}=lc($name);
      }
      if (keys(%fnames)>0){
         for(my $row=1;$row<=$oWkS->{MaxRow};$row++){
            printf("INFO:  Prozess: '%d'\n",$row);
            my %data=();
            for(my $col=0;$col<=$oWkS->{MaxCol};$col++){
               next if (!($oWkS->{'Cells'}[$row][$col]));
               next if ($oWkS->{'Cells'}[$row][$col]->Value() eq "");
               my $d=$oWkS->{'Cells'}[$row][$col]->Value();
               $data{$fnames{$col}}=$d;
            }
            $self->ProcessLine($oExcel,$oBook,$oWkS,$iSheet,$row,\%data);
         }
      }
      $self->PostProcess($oExcel,$oBook,$oWkS,$iSheet,\%fnames);
   }
   return({exitcode=>0});
}

sub PreProcess
{
   my $self=shift;
   my $oExcel=shift;
   my $oBook=shift;
   my $oWkS=shift;
   my $iSheet=shift;
   my $fnames=shift;

   return(0) if (!($iSheet==0));
   return(1);
}

sub PostProcess
{
   my $self=shift;
   my $oExcel=shift;
   my $oBook=shift;
   my $oWkS=shift;
   my $iSheet=shift;
   my $fnames=shift;

   return(1);
}

sub ProcessLine
{
   my $self=shift;
   my $oExcel=shift;
   my $oBook=shift;
   my $oWkS=shift;
   my $iSheet=shift;
   my $row=shift;
   my $data=shift;

   printf Dumper($data);
#   foreach my $k (keys(%{$data})){
#      $data->{$k}=$work->{db}->quote($data->{$k});
#   }
#   my $cmd=$work->format_insert_cmd("ta_codreporting",$data);
#
#   $work->do($cmd);
   return(1);
}






1;
