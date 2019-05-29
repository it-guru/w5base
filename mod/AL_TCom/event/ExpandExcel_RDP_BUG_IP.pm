package AL_TCom::event::ExpandExcel_RDP_BUG_IP;
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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

   $self->RegisterEvent("ExpandExcel_RDP_BUG_IP","ExpandExcel_RDP_BUG_IP");
   return(1);
}

sub ExpandExcel_RDP_BUG_IP
{
   my $self=shift;
   my $name=shift;

   $self->{user}=getModuleObject($self->Config,"base::user");
   if (!defined($self->{user})){
      return({exitcode=>1,msg=>"ERROR in base::user"});
   }

   $self->{ipaddress}=getModuleObject($self->Config,"itil::ipaddress");
   if (!defined($self->{ipaddress})){
      return({exitcode=>1,msg=>"ERROR in itil::ipaddress"});
   }

   $self->{appl}=getModuleObject($self->Config,"TS::appl");
   if (!defined($self->{appl})){
      return({exitcode=>1,msg=>"ERROR in TS::appl"});
   }

   $self->{lnkapplurlip}=getModuleObject($self->Config,"itil::lnkapplurlip");
   if (!defined($self->{lnkapplurlip})){
      return({exitcode=>1,msg=>"ERROR in itil::lnkapplurlip"});
   }

   $self->{tsnoahip}=getModuleObject($self->Config,"tsnoah::ipaddress");
   if (!defined($self->{tsnoahip})){
      return({exitcode=>1,msg=>"ERROR in tsnoah::ipaddress"});
   }

#   $self->{acsys}=getModuleObject($self->Config,"tsacinv::system");
#   return({exitcode=>1,msg=>"ERROR in acsys"}) if (!defined($self->{acsys}));
#   $self->{w5sys}=getModuleObject($self->Config,"itil::system");
#   return({exitcode=>1,msg=>"ERROR in w5sys"}) if (!defined($self->{w5sys}));
#   $self->{w5app}=getModuleObject($self->Config,"itil::appl");
#   return({exitcode=>1,msg=>"ERROR in w5app"}) if (!defined($self->{w5app}));
#   $self->{w1sys}=getModuleObject($self->Config,"w5v1inv::system");
#   return({exitcode=>1,msg=>"ERROR in w1sys"}) if (!defined($self->{w1sys}));
#   $self->{w1lnk}=getModuleObject($self->Config,"w5v1inv::lnksystem2application");
#   return({exitcode=>1,msg=>"ERROR in w1lnk"}) if (!defined($self->{w1lnk}));


   my $exitcode=$self->ProcessExcelExpand($name);

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
      $data->[1]="Systemname/ClusterService";
      $data->[2]="Applicationsname";
      $data->[3]="ICTO-Nummer";
      $data->[4]="Application Manager (Email)";
      $data->[5]="Technical Solution Manager (Email)";
      $data->[6]="Standorte und Eigentümer-Infos/ Ansprechpartner";
      return();
   }

   $self->{ipaddress}->ResetFilter();
   my $ip=trim($data->[0]);
   
   $self->{ipaddress}->SetFilter({name=>\$ip,cistatusid=>'<6'});
   my ($iprec,$msg)=$self->{ipaddress}->getOnlyFirst(qw(id 
                                                        system itclustsvc
                                                        applications name));

   if (!defined($iprec)){
      $self->{lnkapplurlip}->ResetFilter();
      $self->{lnkapplurlip}->SetFilter({name=>\$ip});
      my ($urliprec,$msg)=$self->{lnkapplurlip}->getOnlyFirst(qw(ALL));
      if (defined($urliprec)){
         $data->[6]="known only by URL";
      }
      else{
          $self->{tsnoahip}->ResetFilter();
          $self->{tsnoahip}->SetFilter({name=>\$ip});
          my ($noahip,$msg)=$self->{tsnoahip}->getOnlyFirst(qw(ALL));
          if (defined($noahip)){
             $data->[1]="NOAH:".$noahip->{systemname};
             $data->[6]="NOAH:".$noahip->{subnet};
          }
      }
   }
   else{
      if ($iprec->{system} ne ""){
         $data->[1]=$iprec->{system};

      }
      if ($iprec->{itclustsvc} ne ""){
         $data->[1]=$iprec->{itclustsvc};

      }
      my %applid;
      my %applname;
      foreach my $applrec (@{$iprec->{applications}}){
         $applid{$applrec->{applid}}++;
         $applname{$applrec->{appl}}++;
      }
      $data->[2]=join("; ",sort(keys(%applname)));
      if (keys(%applid)){
         $self->{appl}->ResetFilter();
         $self->{appl}->SetFilter({id=>[keys(%applid)]});
         my %applmgrid;
         my %tsmid;
         my %applmgremail;
         my %tsmemail;
         my %ictoid;
         foreach my $arec ($self->{appl}->getHashList(qw(ictono name id 
                                                         applmgrid tsmid))){
             if ($arec->{ictono} ne ""){
                $ictoid{$arec->{ictono}}++;
             } 
             if ($arec->{applmgrid} ne ""){
                $applmgrid{$arec->{applmgrid}}++;
             } 
             if ($arec->{tsmid} ne ""){
                $tsmid{$arec->{tsmid}}++;
             } 
         }
         my @uids=(keys(%applmgrid),keys(%tsmid));
         if ($#uids>-1){
            $self->{user}->ResetFilter();
            $self->{user}->SetFilter({userid=>\@uids});
            $self->{user}->SetCurrentView(qw(userid email));
            my $i=$self->{user}->getHashIndexed("userid");
            foreach my $uid (keys(%tsmid)){
               if (exists($i->{userid}->{$uid})){
                  $tsmemail{$i->{userid}->{$uid}->{email}}++;
               }
            }
            foreach my $uid (keys(%applmgrid)){
               if (exists($i->{userid}->{$uid})){
                  $applmgremail{$i->{userid}->{$uid}->{email}}++;
               }
            }
         

         }
         $data->[3]=join("; ",sort(keys(%ictoid)));
         $data->[4]=join("; ",sort(keys(%applmgremail)));
         $data->[5]=join("; ",sort(keys(%tsmemail)));
      }
      #print Dumper($iprec);

   }




#   $data->[45]="Nein";
#   if (!($rec->{w5base_appl}=~m/^\s*$/)){
#      $data->[45]="Ja";
#      $data->[46]=$rec->{w5base_appl};
#      if ($rec->{w5base_sem} ne ""){
#         $data->[47]=$rec->{w5base_sem};
#      }
#      if ($rec->{w5base_tsm} ne ""){
#         $data->[48]=$rec->{w5base_tsm};
#      }
#   }
#   else{
#      $self->{acgrp}->SetFilter({name=>\$data->[19]});
#      my ($rec,$msg)=$self->{acgrp}->getOnlyFirst(qw(supervisor)); 
#      if ($rec->{supervisor} ne ""){
#         $data->[49]=$rec->{supervisor};
#      }
#   }
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
