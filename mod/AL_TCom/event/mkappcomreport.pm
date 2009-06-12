package AL_TCom::event::mkappcomreport;
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
#  AppComII Report auf Anforderung durch den Workflow :
#  https://darwin.telekom.de/darwin/auth/base/workflow/ById/12434305750002
#  https://darwin.telekom.de/darwin/auth/base/workflow/ById/12445390340002
use strict;
use vars qw(@ISA);
use kernel;
use kernel::date;
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


   $self->RegisterEvent("mkappcomreport","mkappcomreport");
   return(1);
}

sub mkappcomreport
{
   my $self=shift;
   my %param=@_;
   my $app=$self->getParent;
   my @monthlist;
   my $xlsexp={};

   $param{timezone}="GMT" if (!defined($param{timezone}));
   $param{month}="currentmonth" if (!defined($param{month}));

   my $f;
   my $filename="AppComII-SystemStatus";
   $self->getParent->PreParseTimeExpression($param{month},$param{timezone},\$f);
   if (defined($f)){
      $filename.="-$f";
   }
   $filename=~s/\//-/g;
   $filename.=".xls";

   my %S=();
   my $glong={businessteam   => 'Betriebsteam',
              businessdepart => 'Betriebsfachbereich'};
   my $sys=getModuleObject($self->Config,"itil::system");
   my $appl=getModuleObject($self->Config,"itil::appl");
   $sys->SetCurrentOrder("NONE");
   $sys->SetCurrentView(qw(id name applications servicesupport));
   $sys->SetFilter({cistatusid=>\"4"});
   my ($rec,$msg)=$sys->getFirst(unbuffered=>1);
   #my ($rec,$msg)=$sys->getFirst();
   if (defined($rec)){
      do{
         msg(INFO,"process $rec->{id} ($rec->{name})");
         if (ref($rec->{applications}) eq "ARRAY"){
            foreach my $a (@{$rec->{applications}}){
               $appl->ResetFilter();
               $appl->SetFilter({id=>\$a->{applid}});
               my ($arec,$msg)=$appl->getOnlyFirst(keys(%$glong));
               foreach my $gname (keys(%$glong)){
                  my $gvalue=$arec->{$gname};
                  $gvalue="unknown" if ($gvalue eq "");
                  my $servicesupport=$rec->{servicesupport};
                 
                  if ($servicesupport=~m/^OSY C .*/){
                     $S{$gname}->{$gvalue}->{classic}++
                  }
                  elsif($servicesupport=~m/^OSY AC .*/){
                     $S{$gname}->{$gvalue}->{appcom}++
                  }
                  elsif($servicesupport=~m/^OSY S .*/){
                     $S{$gname}->{$gvalue}->{std}++
                  }
                  else{
                     $S{$gname}->{$gvalue}->{other}++
                  }
               }
            }
         }
         ($rec,$msg)=$sys->getNext();
      } until(!defined($rec));
   }
   msg(INFO,"pre xlsExport");
   $self->xlsExport(\%S,$glong,$filename);
   return({exitcode=>0});
}

sub xlsExport
{
   my $self=shift;
   my $S=shift;
   my $glong=shift;
   my $filename=shift;
   my $xlsexp={};
   my $ws;

   msg(INFO,"writing excel to $filename");
   eval("use Spreadsheet::WriteExcel::Big;");
   $xlsexp->{xls}->{state}="bad";
   if ($@ eq ""){
      $xlsexp->{xls}->{filename}="/tmp/out.".time().".xls";
      $xlsexp->{xls}->{workbook}=Spreadsheet::WriteExcel::Big->new(
                                            $xlsexp->{xls}->{filename});
      if (defined($xlsexp->{xls}->{workbook})){
         $xlsexp->{xls}->{state}="ok";
         foreach my $gname (sort(keys(%$glong))){
            $xlsexp->{xls}->{worksheet}->{$gname}=$xlsexp->{xls}->{workbook}->
                                        addworksheet("Systems - ".
                                                     $glong->{$gname});
            $xlsexp->{xls}->{format}->{default}=$xlsexp->{xls}->{workbook}->
                                                addformat(text_wrap=>1,
                                                          align=>'top');
            $xlsexp->{xls}->{format}->{header}=$xlsexp->{xls}->{workbook}->
                                                addformat(text_wrap=>1,
                                                          align=>'top',
                                                          bold=>1);
            $xlsexp->{xls}->{line}->{$gname}=0;
            $ws=$xlsexp->{xls}->{worksheet}->{$gname};
            $ws->write($xlsexp->{xls}->{line}->{$gname},0,
                       $glong->{$gname},
                       $xlsexp->{xls}->{format}->{header});
            $ws->set_column(0,0,50);
            $ws->write($xlsexp->{xls}->{line}->{$gname},1,
                       "Classic Systeme\n(OSY C *)",
           
                       $xlsexp->{xls}->{format}->{header});
            $ws->set_column(1,1,22);
            $ws->write($xlsexp->{xls}->{line}->{$gname},2,
                       "AppCom Systeme\n(OSY AC *)",
                       $xlsexp->{xls}->{format}->{header});
            $ws->set_column(2,2,22);
            $ws->write($xlsexp->{xls}->{line}->{$gname},3,
                       "Standardized Systeme\n(OSY S *)",
                       $xlsexp->{xls}->{format}->{header});
            $ws->set_column(3,3,22);
            $ws->write($xlsexp->{xls}->{line}->{$gname},4,
                       "sonstige Systeme",
                       $xlsexp->{xls}->{format}->{header});
            $ws->set_column(4,4,22);
            $xlsexp->{xls}->{line}->{$gname}++;
         }
      }
      foreach my $gname (sort(keys(%$glong))){
         $ws=$xlsexp->{xls}->{worksheet}->{$gname};
         foreach my $depart (sort(keys(%{$S->{$gname}}))){
            $ws->write_string($xlsexp->{xls}->{line}->{$gname},0,
                 $depart,
                 $xlsexp->{xls}->{format}->{default});
            $ws->write_number($xlsexp->{xls}->{line}->{$gname},1,
                 $S->{$gname}->{$depart}->{classic},
                 $xlsexp->{xls}->{format}->{default});
            $ws->write_number($xlsexp->{xls}->{line}->{$gname},2,
                 $S->{$gname}->{$depart}->{appcom},
                 $xlsexp->{xls}->{format}->{default});
            $ws->write_number($xlsexp->{xls}->{line}->{$gname},3,
                 $S->{$gname}->{$depart}->{std},
                 $xlsexp->{xls}->{format}->{default});
            $ws->write_number($xlsexp->{xls}->{line}->{$gname},4,
                 $S->{$gname}->{$depart}->{other},
                 $xlsexp->{xls}->{format}->{default});
            $xlsexp->{xls}->{line}->{$gname}++;
         }
      }
      $xlsexp->{xls}->{workbook}->close(); 
      my $file=getModuleObject($self->Config,"base::filemgmt");
      if (open(F,"<".$xlsexp->{xls}->{filename})){
         my $dir="Reports/AppCom";
         $file->ValidatedInsertOrUpdateRecord({name=>$filename,
                                               parent=>$dir,
                                               file=>\*F},
                                              {name=>\$filename,
                                               parent=>\$dir});
      }
      else{
         msg(ERROR,"can't open $xlsexp->{xls}->{filename}");
      }
   }
}



1;
