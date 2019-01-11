package tssiem::event::SSLcertMon;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
sub SSLcertMon
{
   my $self=shift;
   my $queryparam=shift;

die() if (!$self->{p});

   my $firstDayRange=14;
   my $maxDeltaDayRange="15";

   my $StreamDataobj="tssiem::secent";

my $firstDayRange=1184;
my $maxDeltaDayRange="1185";



   my $joblog=getModuleObject($self->Config,"base::joblog");
   my $datastream=getModuleObject($self->Config,$StreamDataobj);


   my $eventlabel='IncStreamAnalyse::'.$datastream->Self;
   my $method=(caller(0))[3];

   $joblog->SetFilter({name=>\$method,
                       exitcode=>\'0',
                       exitmsg=>'last:*',
                       cdate=>">now-${maxDeltaDayRange}d",    # max. 15 days deltascan
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

   my $res;

   my $lastSuccessRun;
   my $startstamp="now-${firstDayRange}d";        # intial scan over 14 days
   my $exitmsg="done";
   my $laststamp;
   my $lastid;
   my %flt;
   {    #analyse lastSuccessRun
      %flt=( 
         sdate=>">$startstamp",
         qid=>\"86002"
      );
      if (defined($firstrec)){
         my $lastmsg=$firstrec->{exitmsg};
         if (($laststamp,$lastid)=$lastmsg=~m/^last:(\d+-\d+-\d+ \d+:\d+:\d+);(\d+)$/){
            %flt=( 
               sdate=>">=\"$laststamp GMT\"",
               qid=>\"86002"
            );
         }
      }
   }

   { # process new records
      my $skiplevel=0;
      my $recno=0;
      $datastream->SetFilter(\%flt);
      $datastream->SetCurrentView(qw(ictoid ipaddress port protocol 
                                 sslparsedw5baseref sslparsedvalidtill
                                 sdate srcid));
      $datastream->SetCurrentOrder("+sdate","srcid");
      $datastream->Limit(1000);
      my ($rec,$msg)=$datastream->getFirst();

      if (defined($rec)){
         READLOOP: do{
            if ($skiplevel==2){
               if ($rec->{srcid} ne $lastid){
                  $skiplevel=3;
               }
            }
            if ($skiplevel==0){
               if (defined($laststamp) && defined($lastid)){
                  if ($laststamp eq $rec->{sdate}){
                     $skiplevel=1;
                  }
               }
               else{
                  $skiplevel=3;
               }
            }
            if ($skiplevel==1){
               if ($lastid eq $rec->{srcid}){
                  msg(INFO,"got ladid point $lastid");
                  $skiplevel=2;
               }
            }
            if ($skiplevel==0 ||  # = no records to skip
                $skiplevel==3){   # = all skips are done
               $self->analyseRecord($rec,$res);
               $recno++;
               $exitmsg="last:".$rec->{sdate}.";".$rec->{srcid};
            }
            else{
               msg(INFO,"skip rec $rec->{sdate} - srcid=$rec->{srcid} skiplevel=$skiplevel recon=$recno");
            }
            ($rec,$msg)=$datastream->getNext();
            if (defined($msg)){
               msg(ERROR,"db record problem: %s",$msg);
               return({exitcode=>1,msg=>$msg});
            }
         }until(!defined($rec) || $recno>10);
      }
   }

   {  # handle results

      my $a=1;


   }
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
   my $rec=shift;
   my $res=shift;
   if (defined($rec->{sslparsedw5baseref})){
      print STDERR Dumper($rec);
      die();
   }
   printf STDERR ("fifi :PROCESS: $rec->{srcid} $rec->{sdate}\n");

}


1;
