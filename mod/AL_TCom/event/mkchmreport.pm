package AL_TCom::event::mkchmreport;
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


   $self->RegisterEvent("mkchmreport","mkchmreport");
   return(1);
}

sub mkchmreport
{
   my $self=shift;
   my %param=@_;
   my $app=$self->getParent;
   my @monthlist;
   my $xlsexp={};

   $param{timezone}="GMT" if (!defined($param{timezone}));
   $param{month}="lastmonth" if (!defined($param{month}));

   my $f;
   my $filename="CO-Report";
   $self->getParent->PreParseTimeExpression($param{month},$param{timezone},\$f);
   if (defined($f)){
      $filename.="-$f";
   }
   $filename.=".xls";

   my $wf=getModuleObject($self->Config,"base::workflow");
   $wf->SetCurrentOrder("NONE");
   $wf->SetCurrentView(qw(id name involvedcostcenter
                          headref class stateid
                          srcid additional));
   $wf->SetFilter(eventend=>$param{month},
                  mandator=>"\"AL T-Com\"",
                  class=>[grep(/^AL_TCom::.*::change$/,
                               keys(%{$wf->{SubDataObj}}))]);
   my %co=();
   my ($rec,$msg)=$wf->getFirst();
   if (defined($rec)){
      do{
         msg(INFO,"process $rec->{srcid}");
         my $add=CompressHash(Datafield2Hash($rec->{additional}));
         msg(DEBUG,"ServiceCenterCoordinator=%s",
                   $add->{ServiceCenterCoordinator});
         if ($add->{ServiceCenterCoordinator} eq "CSS.TCOM.CHM-MGR"){
        #    msg(DEBUG,"rec=%s",Dumper($rec));
            my $colist=$rec->{involvedcostcenter};
            $colist=[$colist] if (ref($colist) ne "ARRAY");
            foreach my $co (@$colist){
               #
               # HPOS CO-Number need to be maped to costcenter 70110954 
               # Info from Fr. Helbrecht, Birgit
               #
#               my @hposmap=qw(6013002013 6013002014 6013002015 6013002016
#                              6013002017 6013002018 6013002019 6013002020
#                              6013002021 9100007903 9100008444 9100008445
#                              9100008446 9100008447 9100008451 9100008452
#                              9100008453 9100008454 9100008455 9100008456
#                              9100008457 9100008458 9100008459 9100008460
#                              9100008461 9100008462 9100008524 9100008560
#                              9100008570 9100008646 9100008647 9100008648
#                              9100008649 9100008650 9100008651 9100008652
#                              9100008653 9100008654 );
#               $co="70110954" if (grep(/^$co$/,@hposmap));
#              laut Bernd Schneider absofort nicht mehr mappen

               $co{$co}={number=>{}} if (!defined($co{$co}));
               $co{$co}->{number}->{$rec->{srcid}}++;
            }
         }
         ($rec,$msg)=$wf->getNext();
      } until(!defined($rec));
   }
   $self->xlsExport(\%co,$filename);
   msg(DEBUG,"d=%s",Dumper(\%co));
   return({exitcode=>0});
}

sub xlsExport
{
   my $self=shift;
   my $co=shift;
   my $filename=shift;
   my $xlsexp={};
   my $ws;

   eval("use Spreadsheet::WriteExcel::Big;");
   $xlsexp->{xls}->{state}="bad";
   if ($@ eq ""){
      $xlsexp->{xls}->{filename}="/tmp/out.".time().".xls";
      $xlsexp->{xls}->{workbook}=Spreadsheet::WriteExcel::Big->new(
                                            $xlsexp->{xls}->{filename});
      if (defined($xlsexp->{xls}->{workbook})){
         $xlsexp->{xls}->{state}="ok";
         $xlsexp->{xls}->{worksheet}=$xlsexp->{xls}->{workbook}->
                                     addworksheet("CHM");
         $xlsexp->{xls}->{format}->{default}=$xlsexp->{xls}->{workbook}->
                                             addformat(text_wrap=>1,
                                                       align=>'top');
         $xlsexp->{xls}->{format}->{header}=$xlsexp->{xls}->{workbook}->
                                             addformat(text_wrap=>1,
                                                       align=>'top',
                                                       bold=>1);
         $xlsexp->{xls}->{line}=0;
         $ws=$xlsexp->{xls}->{worksheet};
         $ws->write($xlsexp->{xls}->{line},0,
                    "CO-Nummer",
                    $xlsexp->{xls}->{format}->{header});
         $ws->set_column(0,0,17);
         $ws->write($xlsexp->{xls}->{line},1,
                    "Change Anzahl",
                    $xlsexp->{xls}->{format}->{header});
         $ws->set_column(1,1,20);
         $ws->write($xlsexp->{xls}->{line},2,
                    "Change Nummern",
                    $xlsexp->{xls}->{format}->{header});
         $ws->set_column(2,2,190);
         $xlsexp->{xls}->{line}++;
      }
      foreach my $conum (sort(keys(%$co))){
         next if ($conum eq "");
         $ws->write($xlsexp->{xls}->{line},0,$conum,
              $xlsexp->{xls}->{format}->{default});
         $ws->write($xlsexp->{xls}->{line},1,
              scalar(keys(%{$co->{$conum}->{number}})),
              $xlsexp->{xls}->{format}->{default});
         $ws->write($xlsexp->{xls}->{line},2,
                    join(", ",sort(keys(%{$co->{$conum}->{number}}))),
              $xlsexp->{xls}->{format}->{default});
         $xlsexp->{xls}->{line}++;
      }
      $xlsexp->{xls}->{workbook}->close(); 
      my $file=getModuleObject($self->Config,"base::filemgmt");
      if (open(F,"<".$xlsexp->{xls}->{filename})){
         my $dir="Reports/CHM";
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
