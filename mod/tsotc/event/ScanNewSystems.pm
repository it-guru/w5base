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



# Modul to detect expiered SSL Certs based on Qualys scan data
sub ScanNewSystems
{
   my $self=shift;
   my $queryparam=shift;

   my $firstDayRange=1000;
   my $maxDeltaDayRange="15";

   my $StreamDataobj="tsotc::system";


   my $joblog=getModuleObject($self->Config,"base::joblog");
   my $datastream=getModuleObject($self->Config,$StreamDataobj);
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
               cdate=>">=\"$laststamp GMT\""
            );
         }
      }
   }

   { # process new records
      my $skiplevel=0;
      my $recno=0;
      $datastream->SetFilter(\%flt);
      $datastream->SetCurrentView(qw(name cdate id contactemail availability_zone));
      $datastream->SetCurrentOrder("+cdate","+id");
      $datastream->Limit(1000);
      my ($rec,$msg)=$datastream->getFirst();

      if (defined($rec)){
         READLOOP: do{
            if ($skiplevel==2){
               if ($rec->{id} ne $lastid){
                  $skiplevel=3;
               }
            }
            if ($skiplevel==2){
               if ($rec->{cdate} ne $laststamp){
                  msg(WARN,"record with id '$lastid' missing in datastream");
                  msg(WARN,"this can result in skiped records!");
                  $skiplevel=3;
               }
            }
            if ($skiplevel==0){
               if (defined($laststamp) && defined($lastid)){
                  if ($laststamp eq $rec->{cdate}){
                     $skiplevel=1;
                  }
               }
               else{
                  $skiplevel=3;
               }
            }
            if ($skiplevel==1){
               if ($lastid eq $rec->{id}){
                  msg(INFO,"got ladid point $lastid");
                  $skiplevel=2;
               }
            }
            if ($skiplevel==0 ||  # = no records to skip
                $skiplevel==3){   # = all skips are done
               $self->analyseRecord($datastream,$rec,$res);
               $recno++;
               $exitmsg="last:".$rec->{cdate}.";".$rec->{id};
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
         }until(!defined($rec) || $recno>10);
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
                                  exitstate=>"ok"},
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

   if (!($rec->{name}=~m/^[a-z0-9_-]{2,35}$/)){
      msg(ERROR,"skip OTC Systemname $rec->{name} - invalid systemname");
      return();
   }
   if ($rec->{contactemail} eq ""){
      msg(ERROR,"skip OTC Systemname $rec->{name} - no contactemail");
      return();
   }

   my $sys=$self->getPersistentModuleObject("W5BaseOTCSys","tsotc::system");

   my $w5baseid=$sys->Import({importname=>$rec->{name}});


#   my $sys=$self->getPersistentModuleObject("W5BaseSys","itil::system");
#
#   $sys->SetFilter({name=>$rec->{name},cistatusid=>[4]});
#   my ($srec)=$sys->getOnlyFirst(qw(id name cistatusid srcsys srcid));
#
#   if (defined($srec)){
#      print Dumper($srec);
#
#   }
#   else{   # try to create new
#   }
}



1;
