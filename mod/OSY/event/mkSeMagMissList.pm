package OSY::event::mkSeMagMissList;
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


   $self->RegisterEvent("mkSeMagMissList","mkSeMagMissList");
   return(1);
}

sub mkSeMagMissList
{
   my $self=shift;
   my %param=@_;
   my $app=$self->getParent;

   my $sys=getModuleObject($self->Config,"itil::system");
   $sys->SetFilter(cistatusid=>[3,4]);
   $sys->SetCurrentView(qw(id systemid name applications));
   my ($rec,$msg)=$sys->getFirst();
   if (defined($rec)){
      do{
         if ($rec->{systemid} ne ""){
            msg(INFO,"Process: $rec->{name} ($rec->{systemid})");
         #   msg(INFO,Dumper($rec));
         }
         ($rec,$msg)=$sys->getNext();
      } until(!defined($rec));
   }
   return({exitcode=>0});
}

#sub processRec
#{
#   my $self=shift;
#   my $start=shift;
#   my $p800=shift;
#   my $rec=shift;
#
#
#   msg(DEBUG,"process %s srcid=%s",$rec->{id},$rec->{srcid});
#   for(my $c=0;$c<=$#{$rec->{affectedcontractid}};$c++){
#      my $cid=$rec->{affectedcontractid}->[$c];
#      $p800->{$cid}={} if (!defined($p800->{$cid}));
#      if (!defined($rec->{headref}->{tcomworktime})){
#          $rec->{headref}->{tcomworktime}=[0]; 
#      }
#      if (!defined($rec->{headref}->{tcomworktimespecial})){
#          $rec->{headref}->{tcomworktimespecial}=[0]; 
#      }
#      if (ref($rec->{headref}->{tcomworktime}) eq "ARRAY"){
#         $rec->{headref}->{tcomworktime}=$rec->{headref}->{tcomworktime}->[0]; 
#      }
#      if (ref($rec->{headref}->{tcomworktimespecial}) eq "ARRAY"){
#         $rec->{headref}->{tcomworktimespecial}=
#                 $rec->{headref}->{tcomworktimespecial}->[0]; 
#      }
#      if ($rec->{class}=~m/::change$/){
#         $p800->{$cid}->{p800_app_changecount}++;
#         $p800->{$cid}->{p800_app_changewt}+=$rec->{headref}->{tcomworktime};
#         if (ref($rec->{headref}->{tcomcodchangetype}) ne "ARRAY"){
#            $rec->{headref}->{tcomcodchangetype}=[];
#         }
#         if ($rec->{headref}->{tcomcodchangetype}->[0] eq "customer"){
#            if ($rec->{tcomcodcause} ne "std"){
#               $p800->{$cid}->{p800_app_changecount_customer}+=1;
#               $p800->{$cid}->{p800_app_customerwt}+=
#                               $rec->{headref}->{tcomworktime};
#               $p800->{$cid}->{p800_app_change_customerwt}+=
#                               $rec->{headref}->{tcomworktime};
#            }
#         }
#      }
#      if ($rec->{class}=~m/::diary$/ || $rec->{class}=~m/::businesreq$/){
#         if ($rec->{tcomcodcause} ne "std"){
#            $p800->{$cid}->{p800_app_specialcount}++;
#            $p800->{$cid}->{p800_app_speicalwt}+=
#                           $rec->{headref}->{tcomworktime};
#            $p800->{$cid}->{p800_app_customerwt}+=
#                           $rec->{headref}->{tcomworktime};
#         }
#         if (ref($rec->{headref}->{tcomcodchangetype}) ne "ARRAY"){
#            $rec->{headref}->{tcomcodchangetype}=[];
#         }
#      }
#      if ($rec->{class}=~m/::incident$/){
#         $p800->{$cid}->{p800_app_incidentcount}++;
#         $p800->{$cid}->{p800_app_incidentwt}+=$rec->{headref}->{tcomworktime};
#         if ($rec->{tcomcodcause} ne "std"){
#            $p800->{$cid}->{p800_app_speicalwt}+=
#                                   $rec->{headref}->{tcomworktimespecial};
#         }
#      }
#   }
#}
#
#
#sub processRecSpecial
#{
#   my $self=shift;
#   my $start=shift;
#   my $p800=shift;
#   my $rec=shift;
#   my $xlsexp=shift;
#   my $specialmon=shift;
#
#   msg(DEBUG,"special process %s:%s end=%s",
#              $rec->{id},$rec->{srcid},$rec->{eventend});
#   if ((my ($eY,$eM,$eD,$eh,$em,$es)=$rec->{eventend}=~
#          m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/)){
#      my ($wY,$wM,$wD,$wh,$wm,$ws)=($eY,$eM,$eD,$eh,$em,$es);
#      eval('($wY,$wM,$wD)=Add_Delta_YMD("GMT",$wY,$wM,$wD,0,1,-19);');
#      if ($@ eq ""){
#         my $mon=sprintf("%02d/%04d",$wM,$wY);
#         return(undef) if ($mon ne $specialmon);
#         msg(DEBUG,"report month =%s",$mon);
#         if ($rec->{class}=~m/::incident$/){
#            $rec->{headref}->{specialt}=$rec->{headref}->{tcomworktimespecial};
#         }
#         if ($rec->{class}=~m/::diary$/ || $rec->{class}=~m/::businesreq$/){
#            $rec->{headref}->{specialt}=$rec->{headref}->{tcomworktime};
#         }
#         if ($rec->{class}=~m/::change$/){
#            if ($rec->{headref}->{tcomcodchangetype}->[0] eq "customer"){
#               $rec->{headref}->{specialt}=$rec->{headref}->{tcomworktime};
#            }
#         }
#         if ($rec->{tcomcodcause} ne "std"){
#            $self->xlsExport($xlsexp,$rec,$mon,$eY,$eM,$eD);
#            for(my $c=0;$c<=$#{$rec->{affectedcontractid}};$c++){
#               my $cid=$rec->{affectedcontractid}->[$c];
#               my $wt=$rec->{headref}->{specialt};
#               if ($wt>0){
#                  $p800->{$mon}={} if (!defined($p800->{$mon}));
#                  $p800->{$mon}->{$cid}={} if (!defined($p800->{$mon}->{$cid}));
#                  msg(DEBUG,"report special process $cid");
#                  $p800->{$mon}->{$cid}->{p800_app_speicalwt}+=$wt;
#                  if (!defined($p800->{$mon}->{$cid}->{additional})){
#                     $p800->{$mon}->{$cid}->{additional}={wfheadid=>[],
#                                                          srcid=>[]};
#                  }
#                  push(@{$p800->{$mon}->{$cid}->{additional}->{wfheadid}},
#                       $rec->{id});
#                  push(@{$p800->{$mon}->{$cid}->{additional}->{srcid}},
#                       $rec->{srcid}) if ($rec->{srcid} ne "");
#               }
#            }
#         }
#      }
#   }
#}
#
#
#sub xlsExport
#{
#   my $self=shift;
#   my $xlsexp=shift;
#   my $rec=shift;
#   my $repmon=shift;
#   my ($wY,$wM,$wD)=@_;
#
#   if (!defined($xlsexp->{xls})){
#      if (!defined($xlsexp->{xls}->{state})){
#         eval("use Spreadsheet::WriteExcel::Big;");
#         $xlsexp->{xls}->{state}="bad";
#         if ($@ eq ""){
#            $xlsexp->{xls}->{filename}="/tmp/out.$$.xls";
#            $xlsexp->{xls}->{workbook}=Spreadsheet::WriteExcel::Big->new(
#                                                  $xlsexp->{xls}->{filename});
#            if (defined($xlsexp->{xls}->{workbook})){
#               $xlsexp->{xls}->{state}="ok";
#               $xlsexp->{xls}->{worksheet}=$xlsexp->{xls}->{workbook}->
#                                           addworksheet("P800 Sonderleistung");
#               $xlsexp->{xls}->{format}->{default}=$xlsexp->{xls}->{workbook}->
#                                                   addformat(text_wrap=>1,
#                                                             align=>'top');
#               $xlsexp->{xls}->{format}->{header}=$xlsexp->{xls}->{workbook}->
#                                                   addformat(text_wrap=>1,
#                                                             align=>'top',
#                                                             bold=>1);
#               $xlsexp->{xls}->{line}=0;
#               my $ws=$xlsexp->{xls}->{worksheet};
#
#               $ws->write($xlsexp->{xls}->{line},0,
#                          "Tag.Monat.Jahr (GMT)",
#                          $xlsexp->{xls}->{format}->{header});
#               $ws->set_column(0,0,17);
#
#               $ws->write($xlsexp->{xls}->{line},1,
#                          "AG-Name",
#                          $xlsexp->{xls}->{format}->{header});
#               $ws->set_column(1,1,40);
#
#               $ws->write($xlsexp->{xls}->{line},2,
#                          "Vertrag Nr.",
#                          $xlsexp->{xls}->{format}->{header});
#               $ws->set_column(2,2,20);
#
#               $ws->write($xlsexp->{xls}->{line},3,
#                          "ID im Quellsystem",
#                          $xlsexp->{xls}->{format}->{header});
#               $ws->set_column(3,3,18);
#
#               $ws->write($xlsexp->{xls}->{line},4,
#                          "Ist Sunden",
#                          $xlsexp->{xls}->{format}->{header});
#               $ws->set_column(4,4,12);
#
#               $ws->write($xlsexp->{xls}->{line},5,
#                          "Tätigkeit",
#                          $xlsexp->{xls}->{format}->{header});
#               $ws->set_column(5,5,30);
#
#               $ws->write($xlsexp->{xls}->{line},6,
#                          "Beschreibung",
#                          $xlsexp->{xls}->{format}->{header});
#               $ws->set_column(6,6,140);
#
#               $xlsexp->{xls}->{line}++;
#            }
#         }
#         
#      }
#   }
#   if (defined($xlsexp->{xls}) && $rec->{headref}->{specialt}>0){
#      my $ag=$rec->{affectedapplication};
#      $ag=[$ag] if (!ref($ag) eq "ARRAY");
#      my $vert=$rec->{affectedcontract};
#      $vert=[$vert] if (!ref($vert) eq "ARRAY");
#      my $ws=$xlsexp->{xls}->{worksheet};
#      my $srcid=$rec->{srcid};
#      $srcid=$rec->{id} if ($srcid eq "");
#      $ws->write($xlsexp->{xls}->{line},0,
#           sprintf("%02d.%02d.%04d",$wD,$wM,$wY),
#           $xlsexp->{xls}->{format}->{default});
#      $ws->write($xlsexp->{xls}->{line},1,
#           join(", ",@$ag),
#           $xlsexp->{xls}->{format}->{default});
#      $ws->write($xlsexp->{xls}->{line},2,
#           join(", ",@$vert),
#           $xlsexp->{xls}->{format}->{default});
#      $ws->write($xlsexp->{xls}->{line},3,
#           $srcid,
#           $xlsexp->{xls}->{format}->{default});
#      $ws->write($xlsexp->{xls}->{line},4,
#           $rec->{headref}->{specialt}/60,
#           $xlsexp->{xls}->{format}->{default});
#
#      my $cause=$rec->{headref}->{tcomcodcause};
#      $cause=join("",@$cause) if (ref($cause) eq "ARRAY");
#      $cause=$self->getParent->T($cause,"AL_TCom::lib::workflow");
#      $ws->write($xlsexp->{xls}->{line},5,$cause,
#           $xlsexp->{xls}->{format}->{default});
#      my $name=$rec->{name};
#      if ($self->getParent->Config->Param("UseUTF8")){
#         $name=utf8($name)->latin1();
#      }
#      $ws->write($xlsexp->{xls}->{line},6,$name,
#           $xlsexp->{xls}->{format}->{default});
#      $xlsexp->{xls}->{line}++;
#   }
#}
#
#
#sub xlsFinish
#{
#   my $self=shift;
#   my $xlsexp=shift;
#   my $repmon=shift;
#
#   if (defined($xlsexp->{xls}) && $xlsexp->{xls}->{state} eq "ok"){
#      $xlsexp->{xls}->{workbook}->close(); 
#      my $file=getModuleObject($self->Config,"base::filemgmt");
#      $repmon=~s/\//./g;
#      my $filename=$repmon.".xls";
#      if (open(F,"<".$xlsexp->{xls}->{filename})){
#         my $dir="TSI-Connect/Konzernstandard-Sonderleistungen";
#         $file->ValidatedInsertOrUpdateRecord({name=>$filename,
#                                               parent=>$dir,
#                                               file=>\*F},
#                                              {name=>\$filename,
#                                               parent=>\$dir});
#      }
#      else{
#         msg(ERROR,"can't open $xlsexp->{xls}->{filename}");
#      }
#   }
#}


1;
