package AL_TCom::event::mkExcelReport;
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
use kernel::date;
use kernel::Event;
use Spreadsheet::WriteExcel::Big;
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


   $self->RegisterEvent("mkcoreport","mkcoreport");
   return(1);
}

sub mkcoreport
{
   my $self=shift;
   my $filename=shift;
   my %param=@_;
   my $app=$self->getParent;
   return({exitcode=>1,msg=>'no filename'}) if ($filename eq "");
   

   my %xls;
   my %stat;
   if (!$self->openXLS(\%xls,$filename)){
      return({exitcode=>1});
   }
   msg(INFO,"start mkCOreport to $filename");
   my $co=getModuleObject($self->Config,"tsacinv::costcenter");
   $co->SetFilter({bc=>['AL T-COM','T-Com',
                        'BC Billing Services','Billing Services',
                        'GHS / Töchter']});
  # $co->SetFilter({name=>[qw(9100010073 9100009867 9100008982 9100008460
  #                           70111057 9100004464 9100009665)]});
   $co->SetCurrentView(qw(name bc sememail));
   my ($rec,$msg)=$co->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         msg(INFO,"prozess co $rec->{name}");
         $self->processCO(\%xls,\%stat,$rec);
         ($rec,$msg)=$co->getNext();
      } until(!defined($rec));
   }
   if (!$self->closeXLS(\%xls,\%stat)){
      msg(ERROR,"fail to open $filename");
      return({exitcode=>1});
   }

   return({exitcode=>0});
}

sub processCO
{
   my $self=shift;
   my $xls=shift;
   my $stat=shift;
   my $corec=shift;

   my $sheet=$xls->{sheet}->{co};
   my $col=0;
   my $row=$sheet->{row}++;
   $sheet->write_string($row,$col++,
                        $corec->{name},
                        $self->xlsFormat($xls,"default"));
   $sheet->write_string($row,$col++,
                        $corec->{bc},
                        $self->xlsFormat($xls,"default"));
   $sheet->write_string($row,$col++,
                        $corec->{sememail},
                        $self->xlsFormat($xls,"default"));
   $stat->{bc}->{$corec->{bc}}->{cocount}++;

   my $acsys=$self->getParent->getPersistentModuleObject("tsacinv::system");
   $acsys->SetFilter({conumber=>\$corec->{name}});
   $acsys->SetCurrentView(qw(systemname systemid conumber systemos
                             assetassetid systemcpucount systemola));

   my ($rec,$msg)=$acsys->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         msg(INFO,"prozess sys $rec->{systemname}");
         $stat->{co}->{$corec->{name}}->{syscount}++;
         $self->processAcSYS($xls,$stat,$corec,$rec);
         ($rec,$msg)=$acsys->getNext();
      } until(!defined($rec));
   }
   $sheet->write_number($row,$col++,
                        $stat->{co}->{$corec->{name}}->{syscount},
                        $self->xlsFormat($xls,"default"));

   $sheet->write_number($row,$col++,
                        $stat->{co}->{$corec->{name}}->{cpucount},
                        $self->xlsFormat($xls,"default"));

   $sheet->write_number($row,$col++,
                        $stat->{co}->{$corec->{name}}->{cpucountprod},
                        $self->xlsFormat($xls,"default"));

   $sheet->write_number($row,$col++,
                        $stat->{co}->{$corec->{name}}->{w5fail},
                        $self->xlsFormat($xls,"default"));


}

sub processAcSYS
{
   my $self=shift;
   my $xls=shift;
   my $stat=shift;
   my $corec=shift;
   my $srec=shift;

   $stat->{bc}->{$corec->{bc}}->{syscount}++;

   my $sheet=$xls->{sheet}->{sys};
   my $col=0;
   my $row=$sheet->{row}++;

   $sheet->write_string($row,$col++,
                        $srec->{systemid},
                        $self->xlsFormat($xls,"default"));
   $sheet->write_string($row,$col++,
                        $srec->{assetassetid},
                        $self->xlsFormat($xls,"default"));
   $sheet->write_string($row,$col++,
                        $srec->{systemname},
                        $self->xlsFormat($xls,"default"));
   $sheet->write_string($row,$col++,
                        $srec->{conumber},
                        $self->xlsFormat($xls,"default"));
   $sheet->write_string($row,$col++,
                        $corec->{bc},
                        $self->xlsFormat($xls,"default"));
   $sheet->write_string($row,$col++,
                        $corec->{sememail},
                        $self->xlsFormat($xls,"default"));
   my %w5appl;
   my %w5tsm;
   my %w5opmode;
   my %w5businessteam;
   my $w5sys=$self->getParent->getPersistentModuleObject("itil::system");
   my $w5appl=$self->getParent->getPersistentModuleObject("itil::appl");
   $w5sys->SetFilter({systemid=>$srec->{systemid}});
   my ($w5srec)=$w5sys->getOnlyFirst(qw(name applications id));
   my $w5ok="missed";
   if (defined($w5srec)){
      $w5ok="ok";
      if (ref($w5srec->{applications}) eq "ARRAY"){
         foreach my $arec (@{$w5srec->{applications}}){
            $w5appl->ResetFilter();
            $w5appl->SetFilter({id=>\$arec->{applid}});
            my ($w5arec)=$w5appl->getOnlyFirst(qw(tsmemail opmode 
                                                  businessteam));
            $w5appl{$arec->{appl}}++;     
            $w5tsm{$w5arec->{tsmemail}}++;     
            if ($w5arec->{opmode} ne ""){
               $w5opmode{$w5arec->{opmode}}++;     
            }
            $w5businessteam{$w5arec->{businessteam}}++;     
         }
      }
   }
   else{
      $stat->{bc}->{$corec->{bc}}->{w5fail}++;
      $stat->{co}->{$corec->{name}}->{w5fail}++;
   }
   
   $sheet->write_string($row,$col++,
                        $w5ok,
                        $self->xlsFormat($xls,"default"));

   $sheet->write_string($row,$col++,
                        $srec->{systemos},
                        $self->xlsFormat($xls,"default"));

   $sheet->write_string($row,$col++,
                        $srec->{systemola},
                        $self->xlsFormat($xls,"default"));

   $sheet->write_number($row,$col++,
                        $srec->{systemcpucount},
                        $self->xlsFormat($xls,"default"));

   my $cpurel=$srec->{systemcpucount};
   $cpurel=1 if ($cpurel==0);
   $stat->{co}->{$corec->{name}}->{cpucount}+=$cpurel;
   $sheet->write_number($row,$col++,
                        $cpurel,
                        $self->xlsFormat($xls,"default"));


   $sheet->write_string($row,$col++,
                        join("; ",sort(keys(%w5opmode))),
                        $self->xlsFormat($xls,"default"));
   my $relmode="prod";
   if (!exists($w5opmode{prod})){
      $relmode="nonprod";
   }
   if (keys(%w5opmode)==0){
      $relmode="prod";
   }
   $stat->{co}->{$corec->{name}}->{'cpucount'.$relmode}+=$cpurel;
   $sheet->write_string($row,$col++,
                        $relmode,
                        $self->xlsFormat($xls,"default"));

   $sheet->write_string($row,$col++,
                        join("; ",sort(keys(%w5appl))),
                        $self->xlsFormat($xls,"default"));

   $sheet->write_string($row,$col++,
                        join("; ",sort(keys(%w5tsm))),
                        $self->xlsFormat($xls,"default"));

   $sheet->write_string($row,$col++,
                        join("; ",sort(keys(%w5businessteam))),
                        $self->xlsFormat($xls,"default"));


}


sub addStats
{
   my $self=shift;
   my $xls=shift;
   my $stat=shift;

   my $sheet=$xls->{sheet}->{bc};
   my $col=0;
   my $row=$sheet->{row}++;
   foreach my $bc (sort(keys(%{$stat->{bc}}))){
      $sheet->write_string($row,$col++,
                           $bc,
                           $self->xlsFormat($xls,"default"));
      $sheet->write_number($row,$col++,
                           $stat->{bc}->{$bc}->{cocount},
                           $self->xlsFormat($xls,"default"));
      $sheet->write_number($row,$col++,
                           $stat->{bc}->{$bc}->{syscount},
                           $self->xlsFormat($xls,"default"));
      $col=0;
      $row++;
   }

}

sub formatHeaders
{
   my $self=shift;
   my $xls=shift;
   my $stat=shift;

   my $sheet=$xls->{sheet}->{co};   # CO-List
   my $col=0;
   $sheet->set_column($col,$col,12);
   $sheet->write_string(0,$col++,
                        "CO-Number",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,18);
   $sheet->write_string(0,$col++,
                        "BC",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,50);
   $sheet->write_string(0,$col++,
                        "SeM",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,10);
   $sheet->write_string(0,$col++,
                        "System-Count",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,12);
   $sheet->write_string(0,$col++,
                        "License relevant CPU-Count",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,12);
   $sheet->write_string(0,$col++,
                        "License relevant prod CPU-Count",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,10);
   $sheet->write_string(0,$col++,
                        "W5Base System-missed-Count",
                        $self->xlsFormat($xls,"header"));

   my $sheet=$xls->{sheet}->{sys};  # System
   my $col=0;
   $sheet->set_column($col,$col,18);
   $sheet->write_string(0,$col++,
                        "SystemID",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,18);
   $sheet->write_string(0,$col++,
                        "AssetID",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,18);
   $sheet->write_string(0,$col++,
                        "Systemname",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,12);
   $sheet->write_string(0,$col++,
                        "System CO-Number",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,12);
   $sheet->write_string(0,$col++,
                        "BC",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,50);
   $sheet->write_string(0,$col++,
                        "SeM",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,15);
   $sheet->write_string(0,$col++,
                        "W5Base/Darwin Entry",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,45);
   $sheet->write_string(0,$col++,
                        "Operationsystem",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,30);
   $sheet->write_string(0,$col++,
                        "SystemOLA",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,12);
   $sheet->write_string(0,$col++,
                        "AC CPU-Count (total number of cores)",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,12);
   $sheet->write_string(0,$col++,
                        "License relevant CPU-Count",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,20);
   $sheet->write_string(0,$col++,
                        "W5Base/Darwin primary operation mode",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,20);
   $sheet->write_string(0,$col++,
                        "License relevant operation mode",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,40);
   $sheet->write_string(0,$col++,
                        "W5Base/Darwin Applications",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,40);
   $sheet->write_string(0,$col++,
                        "W5Base/Darwin TSM",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,50);
   $sheet->write_string(0,$col++,
                        "W5Base/Darwin Businessteam",
                        $self->xlsFormat($xls,"header"));

   my $sheet=$xls->{sheet}->{bc};  # BC
   my $col=0;
   $sheet->set_column($col,$col,18);
   $sheet->write_string(0,$col++,
                        "BC",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,15);
   $sheet->write_string(0,$col++,
                        "CO-Count",
                        $self->xlsFormat($xls,"header"));
   $sheet->set_column($col,$col,15);
   $sheet->write_string(0,$col++,
                        "System-Count",
                        $self->xlsFormat($xls,"header"));

}

sub openXLS
{
   my $self=shift;
   my $xls=shift;
   my $filename=shift;

   if ($filename=~m#^file:/#){
      $filename=~s#^file:/##;
   }
   eval('$xls->{workbook}=Spreadsheet::WriteExcel::Big->new($filename);');
   if (!defined($xls->{workbook})){
      msg(ERROR,"fail to open $filename");
      return(0);
   }
   $xls->{sheet}->{bc}=$xls->{workbook}->addworksheet("BC");
   if (!defined($xls->{sheet}->{bc})){
      msg(ERROR,"fail to open sheet BC");
      return(0);
   }
   else{
      $xls->{sheet}->{bc}->{row}++;
   }
   $xls->{sheet}->{co}=$xls->{workbook}->addworksheet("CO-Numbers");
   if (!defined($xls->{sheet}->{co})){
      msg(ERROR,"fail to open sheet CO-Numbers");
      return(0);
   }
   else{
      $xls->{sheet}->{co}->{row}++;
   }
   $xls->{sheet}->{sys}=$xls->{workbook}->addworksheet("System List");
   if (!defined($xls->{sheet}->{sys})){
      msg(ERROR,"fail to open sheet System List");
      return(0);
   }
   else{
      $xls->{sheet}->{sys}->{row}++;
   }
   return(1);
}



sub closeXLS
{
   my $self=shift;
   my $xls=shift;
   my $stat=shift;
   $self->addStats($xls,$stat);
   $self->formatHeaders($xls,$stat);
   $xls->{workbook}->close(); 
   return(1);
}



sub xlsFormat
{
   my $self=shift;
   my $xls=shift;
   my $name=shift;
   my $wb=$xls->{workbook};
   return($wb->{format}->{$name}) if (exists($wb->{format}->{$name}));

   my $format;
   if ($name eq "default"){
      $format=$wb->addformat(text_wrap=>1,align=>'top');
   }
   elsif ($name eq "date.de"){
      $format=$wb->addformat(align=>'top',
                                          num_format => 'dd.mm.yyyy HH:MM:SS');
   }
   elsif ($name eq "date.en"){
      $format=$wb->addformat(align=>'top',
                                          num_format => 'yyyy-mm-dd HH:MM:SS');
   }
   elsif ($name eq "longint"){
      $format=$wb->addformat(align=>'top',num_format => '#');
   }
   elsif ($name eq "header"){
      $format=$wb->addformat();
      $format->copy($self->xlsFormat($xls,"default"));
      $format->set_bold();
   }
   elsif (my ($precsision)=$name=~m/^number\.(\d+)$/){
      $format=$wb->addformat();
      $format->copy($self->xlsFormat($xls,"default"));
      my $xf="#";
      if ($precsision>0){
         $xf="0.";
         for(my $c=1;$c<=$precsision;$c++){$xf.="0";};
      }
      $format->set_num_format($xf);
   }
   if (defined($format)){
      $wb->{format}->{$name}=$format;
      return($wb->{format}->{$name});
   }
 #  print STDERR msg(WARN,"XLS: setting format '$name' as 'default'");
   return($self->xlsFormat($xls,"default"));
}

#######################################################################
1;
