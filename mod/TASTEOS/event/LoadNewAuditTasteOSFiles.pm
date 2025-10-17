package TASTEOS::event::LoadNewAuditTasteOSFiles;
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



# Modul to detect expiered SSL Certs based on Qualys scan data
sub LoadNewAuditTasteOSFiles
{
   my $self=shift;
   my %param=@_;


   my $tsossys=getModuleObject($self->Config,"TASTEOS::tsossystem");
   my $tsosmac=getModuleObject($self->Config,"TASTEOS::tsosmachine");

   if ($tsossys->isSuspended() || $tsosmac->isSuspended()){
      return({exitcode=>0,exitmsg=>'TasteOS blacklisted'});
   }

   if (!$tsosmac->Ping()){   # ping on one object is sufficient
      return({exitcode=>0,exitmsg=>'TasteOS not pingable'});
   }

   my $firstDayRange=35;
   my $firstDayRange=45;
   my $maxDeltaDayRange="15";
   my $blockSize=100;
   my $res={};

   if (exists($param{blockSize}) &&
       ($param{blockSize}=~m/^[0-9]+$/)){
      $blockSize=$param{blockSize};
   }

   my $StreamDataobj="tsAuditSrv::auditfile";


   my $joblog=getModuleObject($self->Config,"base::joblog");
   my $datastream=getModuleObject($self->Config,$StreamDataobj);
   # on suspend, no Errors and quit the event silient
   return({}) if ($datastream->isSuspended());
   # if ping failed ...
   if (!$datastream->Ping()){
      # check if there are lastmsgs
      # if there, send a message to interface partners
      my $infoObj=getModuleObject($self->Config,"itil::lnkapplappl");
      return({}) if ($infoObj->NotifyInterfaceContacts($datastream));
      msg(ERROR,"no ping posible to $StreamDataobj");
      return({});
   }


   $self->{sys}=getModuleObject($self->Config,"itil::system");
   $self->{addsys}=getModuleObject($self->Config,"itil::addlnkapplgrpsystem");



   my @datastreamview=qw(mdate fullname systemname systemid filecontent);


   if ($_[0]=~m/^[0-9]{2,10}$/){
      my $fileid=$_[0];
      msg(DEBUG,"Debug process only file requested with id=$fileid");
      $datastream->ResetFilter();
      $datastream->SetFilter({id=>\$fileid});
      my ($chkrec,$msg)=$datastream->getOnlyFirst(@datastreamview);
      if (!defined($chkrec)){
         return({exitcode=>1,exitmsg=>'Record $fileid not found'});
      }
      if ($self->analyseRecord($datastream,$chkrec,$res)){
         return({exitcode=>0,exitmsg=>'DEBUG ok'});
      }
      return({exitcode=>1,exitmsg=>'DEBUG fail'});
   }



   msg(DEBUG,"using blockSize=$blockSize");


   my $eventlabel='IncStreamAnalyse::'.$datastream->Self;
   my $method=(caller(0))[3];

   $joblog->SetFilter({name=>\$method,
                       exitcode=>\'0',
                       exitmsg=>'last:*',
                       cdate=>">now-${maxDeltaDayRange}d", 
                       event=>\$eventlabel});
   $joblog->SetCurrentOrder('-cdate');

   $joblog->Limit(1);
   my ($firstrec,$msg)=$joblog->getOnlyFirst(qw(ALL));

   my %jobrec=(
      name=>$method,
      event=>$eventlabel,
      pid=>$$
   );
   my $jobid=$joblog->ValidatedInsertRecord(\%jobrec);
   msg(DEBUG,"jobid=$jobid");


   my $lastSuccessRun;
   my $startstamp="now-${firstDayRange}d";        # intial scan over 14 days
   my $exitmsg="done";
   my $laststamp;
   my $lastid;
   my %flt=(mdate=>'>now-1d');;
   if ($param{FORCEALL} ne "1"){    #analyse lastSuccessRun
      %flt=( 
         mdate=>">$startstamp"
      );
      if (defined($firstrec)){
         my $lastmsg=$firstrec->{exitmsg};
         msg(DEBUG,"lastmsg: $lastmsg");
         if (($laststamp,$lastid)=
             $lastmsg=~m/^last:(\d+-\d+-\d+ \d+:\d+:\d+);(\S+)$/){
            $exitmsg=$lastmsg;
            msg(DEBUG,"laststamp: $laststamp");
            msg(DEBUG,"lastid: $lastid");
            $datastream->ResetFilter();
            $datastream->SetFilter({id=>\$lastid,mdate=>"\"$laststamp CET\""});
            my ($lastrec,$msg)=$datastream->getOnlyFirst(qw(id));
            if (!defined($lastrec)){
               $datastream->Log(WARN,"backlog","record with id '$lastid' ".
                        "has been deleted or changed - using date only");
               $lastid=undef;
            }
            %flt=( 
               mdate=>">=\"$laststamp CET\"" 
            );
         }
      }
   }
  # $flt{systemid}="S21184692 S21187867 S21189868 S21682087 S21807399 S21815867 S21816597 S21897621 S21897651 S21928039 S21928535 S21938047 S21938050 S22087171 S22087513 S22087739 S22739811 S23381477";
  # msg(INFO,"Filter=".Dumper(\%flt));

   my $recno=0;
   if (1){ # process new records
      my $skiplevel=0;
      $datastream->ResetFilter();
      $datastream->SetFilter(\%flt);
      $datastream->SetCurrentView(@datastreamview);
      $datastream->SetCurrentOrder("+mdate","+id");
      $datastream->Limit($blockSize+2);
      my ($rec,$msg)=$datastream->getFirst();

      if (defined($rec)){
         do{
            msg(DEBUG,"start datastream loop");
            msg(DEBUG,"...handling with laststamp='$laststamp'");
            msg(DEBUG,"...handling with lastid='$lastid'");
            if ($skiplevel==2){
               if ($rec->{id} ne $lastid){
                  $skiplevel=3;
               }
            }
            if ($skiplevel==1){  # laststamp was arived, but not lastid seen
               # this can happend, if lastid id-record is deleted
               if ($rec->{mdate} ne $laststamp){
                  msg(WARN,"record with id '$lastid' missing in datastream");
                  msg(WARN,"this can result in skiped records!");
                  $skiplevel=3;
               }
            }
            if ($skiplevel==0){
               if (defined($laststamp) && defined($lastid)){
                  if ($laststamp eq $rec->{mdate}){
                     $skiplevel=1;
                  }
               }
               else{
                  $skiplevel=3;
               }
            }
            if ($skiplevel==1){
               if (!defined($lastid) || $lastid eq $rec->{id}){
                  msg(INFO,"got ladid point $lastid");
                  $skiplevel=2;
               }
            }
            if ($skiplevel==0 ||  # = no records to skip
                $skiplevel==3){   # = all skips are done
               if ($self->analyseRecord($datastream,$rec,$res)){
                  $recno++;
                  $exitmsg="last:".$rec->{mdate}.";".$rec->{id};
               }
            }
            else{
               msg(INFO,"skip rec $rec->{mdate} - ".
                        "id=$rec->{id} ".
                        "skiplevel=$skiplevel recon=$recno");
            }
            ($rec,$msg)=$datastream->getNext();
         }until(!defined($rec) || $recno>=$blockSize || defined($msg));
      }
   }

   my $ncnt=$recno;
   $joblog->ValidatedUpdateRecord({id=>$jobid},
                                 {exitcode=>"0",
                                  exitmsg=>$exitmsg,
                                  exitstate=>"ok - $ncnt files"},
                                 {id=>\$jobid});
   return({exitcode=>0,exitmsg=>'ok'});
}


sub analyseRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $res=shift;

   msg(INFO,"F:$rec->{id}");
   msg(INFO,"  Systemname:  $rec->{systemname}");
   msg(INFO,"  SystemID  :  $rec->{systemid}");
   msg(INFO,"  mdate     :  $rec->{mdate}");
   my $sysrec;
   if ($rec->{systemid} ne ""){
      $self->{sys}->ResetFilter();
      $self->{sys}->SetFilter({systemid=>\$rec->{systemid},
                               cistatusid=>[3,4,5]});
      my @l=$self->{sys}->getOnlyFirst(qw(id systemid));
      if ($#l==0){
         $sysrec=$l[0];
      }
   }
   else{
      my $systemname=$rec->{systemname};
      $systemname=~s/\..*$//;   # remove domain, if nodename with domain
      $systemname=~s/[^0-9a-z_-]//gi;
      if ($systemname ne ""){
         $self->{sys}->ResetFilter();
         $self->{sys}->SetFilter({name=>$systemname,
                                  cistatusid=>[3,4,5]});
         my @l=$self->{sys}->getOnlyFirst(qw(id systemid));
         if ($#l==0){
            printf ST
            $sysrec=$l[0];
         }
      }
   }
   if (defined($sysrec)){
      $self->{addsys}->ResetFilter();
      $self->{addsys}->SetFilter({systemid=>\$sysrec->{id},
                                  systemcistatusid=>[3,4],
                                  applgrpcistatusid=>[3,4]});
      my @l=$self->{addsys}->getHashList(qw(ALL));
      foreach my $addsysrec (@l){
          next if (!defined($addsysrec->{applgrp}));
          my $MachineID;
          my $add=$addsysrec->{additional};
          if (ref($add) eq "HASH"){
             $add=$add->{TasteOS_MachineID};
             if (defined($add)){
                $add=$add->[0] if (ref($add) eq "ARRAY");
             }
             if ($add ne ""){
                $MachineID=$add;
             }
          }
          if (defined($MachineID)){
             msg(INFO,"process machineid=$MachineID");
             msg(INFO,"filename=$rec->{filename}");
             my $scandata=$rec->{filecontent};
             if ($rec->{filename}=~m/\.gz$/i){
                my $scandatatxt;
                eval('
                   use IO::Uncompress::Gunzip qw(gunzip);
                   gunzip(\$scandata => \$scandatatxt);
                ');
                if ($scandatatxt ne ""){
                   $scandata=$scandatatxt;
                }
                else{
                   msg(ERROR,"gunzip result=$@");
                   msg(ERROR,"uncompress problem ".
                             "in $rec->{filename} $MachineID");
                   return(1);
                }
             }
             $scandata=~s/^\s*#\s+Uuid:\s+.*$/# Uuid: $MachineID/m;
             my ($d,$code,$message)=$dataobj->CollectREST(
                dbname=>'TASTEOScollector',
                requesttoken=>"PUT.".$MachineID.".".time(),
                method=>'PUT',
                url=>sub{
                   my $self=shift;
                   my $baseurl=shift;
                   my $apikey=shift;
                   $baseurl.="/"  if (!($baseurl=~m/\/$/));
                   my $dataobjurl=$baseurl."patch/data";
                   return($dataobjurl);
                },
                content=>sub{
                   my $self=shift;
                   my $baseurl=shift;
                   my $apikey=shift;
                   return($scandata);
                },
                onfail=>sub{
                   my $self=shift;
                   my $code=shift;
                   my $statusline=shift;
                   my $content=shift;
                   my $reqtrace=shift;
             
                   if ($code eq "404"){  # 404 bedeutet nicht gefunden
                      if (!($rec->{systemname}=~m/^SEC/)){
                         msg(ERROR,"$rec->{systemname}/$rec->{systemid} ".
                                   "machineID:$MachineID - ".
                                   "not found in TasteOS");
                      }
                      return([],"200");
                   }
                   if ($self->Config->Param("W5BaseOperationMode") eq "dev"){
                      msg(ERROR,"PUT pkg_taste.txt($rec->{id} ".
                                "for $rec->{systemname}/$rec->{systemid} ".
                                "returns $code");
                      msg(ERROR,"$content");
                   }
                   return(undef);
                },

                headers=>sub{
                   my $self=shift;
                   my $baseurl=shift;
                   my $apikey=shift;
                   return(['s-token'=>$apikey,
                           'Content-Type','text/plain']);
                }
             );
          }
      }
   }


   #print Dumper($rec);

   return(1); 
}


1;
