package tsotc::event::ScanNewSystems;
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
   my $self=bless({@_},$type);
   $self->{OTC_ScanNewSystems_timeout}=1800;
   return($self);
}



sub Init
{
   my $self=shift;


   $self->RegisterEvent("ScanNewSystems","ScanNewSystems",
                        timeout=>$self->{OTC_ScanNewSystems_timeout});

   $self->RegisterEvent("OTC_ScanNewSystems","ScanNewSystems",
                        timeout=>$self->{OTC_ScanNewSystems_timeout});

   $self->RegisterEvent("OTC_validateSystemCompleteness",
                        "validateSystemCompleteness",
                        timeout=>1800);

   $self->RegisterEvent("validateSystemCompleteness",
                        "validateSystemCompleteness",
                        timeout=>1800);
}


sub validateSystemCompleteness
{
   my $self=shift;
   my $StreamDataobj="tsotc::system";
   my $datastream=getModuleObject($self->Config,$StreamDataobj);
   my $sys=getModuleObject($self->Config,"itil::system");
   my @datastreamview=qw(cdate name id);
   $datastream->SetFilter({cdate=>"<now-3h"});
   my @l=$datastream->getHashList(@datastreamview);
   my $misscnt=0;

   foreach my $otcsysrec (@l){
      $sys->ResetFilter();
      $sys->SetFilter({srcid=>\$otcsysrec->{id},srcsys=>\'OTC'});
      my ($chkrec,$msg)=$sys->getOnlyFirst(qw(id));
      if (!defined($chkrec)){
         msg(INFO,"system ".$otcsysrec->{name}." with id=".$otcsysrec->{id}.
                  " missed");
         $self->ScanNewSystems("ID",$otcsysrec->{id});
         $misscnt++;
      }
   }
   if ($misscnt==0){
      return({exitcode=>0,exitmsg=>'ok'});
   }
   return({exitcode=>1,exitmsg=>'misscnt='.$misscnt});
}




# Modul to detect expiered SSL Certs based on Qualys scan data
sub ScanNewSystems
{
   my $self=shift;
   my $queryparam=shift;


   my $StreamDataobj="tsotc::system";
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
   my @datastreamview=qw(name cdate id contactemail 
                         availability_zone);
   if ($queryparam ne ""){
      if ($queryparam eq "ID"){
         $queryparam=shift;
         msg(INFO,"try to import id='$queryparam'");
         $datastream->SetFilter({id=>$queryparam});
      }
      else{
         msg(INFO,"try to import name='$queryparam'");
         $datastream->SetFilter({name=>$queryparam});
      }
      my @l=$datastream->getHashList(@datastreamview);
      my $cnt=0;
      foreach my $rec (@l){
         if ($self->analyseRecord($datastream,$rec)){
            $cnt++;
         }
      }
      if ($cnt){
         return({exitcode=>0,exitmsg=>'ok'});
      }
      return({exitcode=>1,exitmsg=>'fail'});
   }
   my $firstDayRange=1000;
   my $maxDeltaDayRange="15";



   my $joblog=getModuleObject($self->Config,"base::joblog");
   my $user=getModuleObject($self->Config,"base::user");


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
   

   my $res={};
   my $cnt=0;
   my $imp=0;

   my $lastSuccessRun;
   my $startstamp="now-${firstDayRange}d";        # intial scan over 14 days
   my $exitmsg="done";
   my $laststamp;
   my $lastid;
   my %flt;
   {    #analyse lastSuccessRun
      %flt=( 
         cdate=>">$startstamp"
      );
      if (defined($firstrec)){
         my $lastmsg=$firstrec->{exitmsg};
         if (($laststamp,$lastid)=
             $lastmsg=~m/^last:(\d+-\d+-\d+ \d+:\d+:\d+);(\S+)$/){
            $exitmsg=$lastmsg;
            %flt=( 
               cdate=>">=\"$laststamp GMT-30m\""
            );
         }
      }
   }

   my $tstart=time();
   my $recmaxtime=60;

   { # process new records
      my $skiplevel=0;
      my $recno=0;
      $datastream->SetFilter(\%flt);
      $datastream->SetCurrentView(@datastreamview);
      $datastream->SetCurrentOrder("+cdate","+id");
      $datastream->Limit(1000);
      my ($rec,$msg)=$datastream->getFirst();

      if (defined($rec)){
         READLOOP: do{
            # 
            #  Remove of Skip-Handing because cdate stream problem (cdate
            #  is not creation in OTC Integrated!)
            # 
            #if ($skiplevel==2){
            #   if ($rec->{id} ne $lastid){
            #      $skiplevel=3;
            #   }
            #}
            #if ($skiplevel==1){
            #   if ($rec->{cdate} ne $laststamp){
            #      msg(WARN,"record with id '$lastid' missing in datastream");
            #      msg(WARN,"this can result in skiped records!");
            #      $skiplevel=3;
            #   }
            #}
            #if ($skiplevel==0){
            #   if (defined($laststamp) && defined($lastid)){
            #      if ($laststamp eq $rec->{cdate}){
            #         $skiplevel=1;
            #      }
            #   }
            #   else{
            #      $skiplevel=3;
            #   }
            #}
            #if ($skiplevel==1){
            #   if ($lastid eq $rec->{id}){
            #      msg(INFO,"got ladid point $lastid");
            #      $skiplevel=2;
            #   }
            #}
            if ($skiplevel==0 ||  # = no records to skip
                $skiplevel==3){   # = all skips are done
               $cnt++;
               my $t0=time();
               if ($self->analyseRecord($datastream,$rec,$res)){
                  $imp++;
               }
               $recno++;
               $exitmsg="last:".$rec->{cdate}.";".$rec->{id};
               my $rectime=time()-$t0;
               $recmaxtime=$rectime if ($rectime>$recmaxtime);
            }
            else{
               msg(INFO,"skip rec $rec->{sdate} - ".
                        "id=$rec->{id} ".
                        "skiplevel=$skiplevel recon=$recno");
            }
            ($rec,$msg)=$datastream->getNext();
            if (defined($msg)){
               msg(ERROR,"db record problem: %s",$msg);
               return({exitcode=>1,msg=>$msg});
            }
         }until(!defined($rec) || $recno>50 ||
                ($self->{OTC_ScanNewSystems_timeout}-(time()-$tstart)-
                 (2*$recmaxtime)<0));
      }
   }

   #my $ncnt=0;
   #{  # handle results
   #   my $a=1;
   #   if (keys(%{$res->{new}})){
   #      foreach my $icto (keys(%{$res->{new}})){
   #         $ncnt++;
   #         $self->doNotify($datastream,$wfa,$user,$appl,$icto,
   #                         $res->{new}->{$icto});
   #      }
   #   }
   #}
   $joblog->ValidatedUpdateRecord({id=>$jobid},
                                 {exitcode=>"0",
                                  exitmsg=>$exitmsg,
                                  exitstate=>"ok - $cnt/impcnt=$imp"},
                                 {id=>\$jobid});
   return({exitcode=>0,exitmsg=>'ok'});
}



sub analyseRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $res=shift;

   msg(INFO,"PROCESS: $rec->{id} $rec->{cdate} name='$rec->{name}'");

   #if (!($rec->{name}=~m/^[a-z0-9_-\s]{2,63}$/)){
   #   msg(ERROR,"skip OTC Systemname $rec->{name} - invalid systemname");
   #   return();
   #}

   my $sys=$self->getPersistentModuleObject("W5BaseOTCSys","tsotc::system");
   my $w5sys=$self->getPersistentModuleObject("W5BaseSys","itil::system");
   my $wfa=$self->getPersistentModuleObject("W5BaseWa","base::workflowaction");
   my $user=$self->getPersistentModuleObject("W5BaseUser","base::user");
   my $w5baseid=$sys->Import({importname=>$rec->{id}});

   if (defined($w5baseid)){   # create Notification
      $w5sys->SetFilter({id=>\$w5baseid});
      my ($srec)=$w5sys->getOnlyFirst(qw(ALL));
      if (!defined($srec)){
         msg(ERROR,
            "something went wron while import of OTC Systemname $srec->{name}");
         return();
      }
      msg(INFO,"start doNotify $srec->{name}");
      $self->doNotify($w5sys,$sys,$wfa,$user,$srec);
      return(1);
   }
   return(0);
}









1;
