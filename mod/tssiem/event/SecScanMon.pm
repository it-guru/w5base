package tssiem::event::SecScanMon;
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
sub SecScanMon
{
   my $self=shift;
   my $queryparam=shift;


   my $firstDayRange=14;
   my $maxDeltaDayRange="15";

   my $StreamDataobj="tssiem::secscan";


   my $joblog=getModuleObject($self->Config,"base::joblog");
   my $datastream=getModuleObject($self->Config,$StreamDataobj);
   my $appl=getModuleObject($self->Config,"TS::appl");
   my $wfa=getModuleObject($self->Config,"base::workflowaction");
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
            $datastream->ResetFilter();
            $datastream->SetFilter({id=>\$lastid,cdate=>\$laststamp});
            my ($lastrec,$msg)=$datastream->getOnlyFirst(qw(id));
            if (!defined($lastrec)){
               msg(WARN,"record with id '$lastid' has been ".
                        "deleted or changed - using date only");
               $lastid=undef;
            }
            %flt=( 
               cdate=>">\"$laststamp GMT\""
            );
         }
      }
      else{
         msg(WARN,"notify without $eventlabel informations!");
         msg(WARN,"using secscan Filter=".Dumper(\%flt));
      }
   }

   $flt{islatest}="1";


   { # process new records
      my $skiplevel=0;
      my $recno=0;
      $datastream->ResetFilter();
      $datastream->SetNamedFilter("TransactionFix",{cdate=>'<now-36h'});
      $datastream->SetFilter(\%flt);
      $datastream->SetCurrentView(qw(ictono urlofcurrentrec
                                     name applid itscanobjectid
                                     cdate id 
                                     secentcnt
                                     sdate));
      $datastream->SetCurrentOrder("+cdate","+id");
      my ($rec,$msg)=$datastream->getFirst();

      if (defined($rec)){
         READLOOP: do{
        #
        #  skip by lastid removed, becaus this can cause in skiped scans
        #  (lastid is in next scan not "islatest" and does not exists in
        #   IncStream anymore)
        #
        #    if ($skiplevel==2){
        #       if ($rec->{id} ne $lastid){
        #          $skiplevel=3;
        #       }
        #    }
        #    if ($skiplevel==1){
        #       if ($rec->{cdate} ne $laststamp){
        #          msg(WARN,"record with id '$lastid' missing in datastream");
        #          msg(WARN,"this can result in skiped records!");
        #          $skiplevel=3;
        #       }
        #    }
        #    if ($skiplevel==0){
        #       if (defined($laststamp) && defined($lastid)){
        #          if ($laststamp eq $rec->{cdate}){
        #             $skiplevel=1;
        #          }
        #       }
        #       else{
        #          $skiplevel=3;
        #       }
        #    }
        #    if ($skiplevel==1){
        #       if ($lastid eq $rec->{id}){
        #          msg(INFO,"got ladid point $lastid");
        #          $skiplevel=2;
        #       }
        #    }
            if ($skiplevel==0 ||  # = no records to skip
                $skiplevel==3){   # = all skips are done
               my $d=CalcDateDuration($rec->{sdate},NowStamp("en"));
               if ($d->{totaldays}>10.0){
                 # msg(WARN,"skip notify for scan ".$rec->{id}." due scan ".
                 #          "to far (".$d->{totaldays}." days) in the past");
                 # msg(WARN,Dumper($rec));
               }
               else{
                  $self->analyseRecord($datastream,$rec,$res);
                  $recno++;
               }
               $exitmsg="last:".$rec->{cdate}.";".$rec->{id};
            }
            else{
               msg(INFO,"skip rec $rec->{cdate} - ".
                        "id=$rec->{id} ".
                        "skiplevel=$skiplevel recon=$recno");
            }
            ($rec,$msg)=$datastream->getNext();
            if (defined($msg)){
               msg(ERROR,"db record problem: %s",$msg);
               return({exitcode=>1,msg=>$msg});
            }
         }until(!defined($rec) || $recno>10000);
      }
   }

   my $ncnt=0;
   {  # handle results

      my $a=1;
      if (keys(%{$res->{new}})){
         foreach my $itscanobjectid (keys(%{$res->{new}})){
            $ncnt++;
            $self->doNotify($datastream,$wfa,$user,$appl,$itscanobjectid,
                            $res->{new}->{$itscanobjectid});
         }

      }
   }
   $joblog->ValidatedUpdateRecord({id=>$jobid},
                                 {exitcode=>"0",
                                  exitmsg=>$exitmsg,
                                  exitstate=>"ok - $ncnt messages"},
                                 {id=>\$jobid});
   return({exitcode=>0,exitmsg=>'ok'});
}


sub analyseRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $res=shift;

   msg(INFO,"PROCESS: $rec->{id} $rec->{cdate} icto='$rec->{ictono}'");

   if ($rec->{secentcnt}>0){
      if (!exists($res->{new}->{$rec->{itscanobjectid}})){
         $res->{new}->{$rec->{itscanobjectid}}=[];
      }
      push(@{$res->{new}->{$rec->{itscanobjectid}}},{
         urlofcurrentrec=>$rec->{urlofcurrentrec},
         applid=>$rec->{applid},
         ictoid=>$rec->{ictoid},
         name=>$rec->{name}
      });
   }
}


sub doNotify
{
   my $self=shift;
   my $datastream=shift;
   my $wfa=shift;
   my $user=shift;
   my $appl=shift;
   my $itscanobjectid=shift;
   my $rec=shift;
   my $debug="";


   $appl->ResetFilter();
   if ($rec->[0]->{applid} ne ""){
      $appl->SetFilter({id=>\$itscanobjectid,cistatusid=>"<6"});
   }
   else{
      $appl->SetFilter({ictono=>\$itscanobjectid,cistatusid=>"<6"});
   }

   my @l=$appl->getHashList(qw(name id applmgr tsmid tsm2id contacts));

   my %uid;

   my @itscanobjectname=();

   foreach my $arec (@l){
      push(@itscanobjectname,$arec->{name});
      $uid{cc}->{$arec->{tsmid}}++;
      $uid{cc}->{$arec->{tsm2id}}++;
      $uid{to}->{$arec->{applmgrid}}++;
      foreach my $crec (@{$arec->{contacts}}){
         my $roles=$crec->{roles};
         $roles=[$roles] if (ref($roles) ne "ARRAY");
         if ($crec->{target} eq "base::user" &&
             in_array($roles,"applmgr2")){
            $uid{cc}->{$crec->{targetid}}++;
         }
      }
   }
   if ($#l>0){  # das ist nur dann der Fall, wenn per ICTO gescannt wurde
      @itscanobjectname=($itscanobjectid);
   }


   my @targetuids=grep(!/^$/,keys(%{$uid{to}}),keys(%{$uid{cc}}));

   my %nrec;

   $user->ResetFilter(); 
   $user->SetFilter({userid=>\@targetuids});
   foreach my $urec ($user->getHashList(qw(fullname userid lastlang lang))){
      my $lang=$urec->{lastlang};
      $lang=$urec->{lang} if ($lang eq "");
      $lang="en" if ($lang eq "");
      $nrec{$lang}->{$urec->{userid}}++;
   }
   my $lastlang;
   if ($ENV{HTTP_FORCE_LANGUAGE} ne ""){
      $lastlang=$ENV{HTTP_FORCE_LANGUAGE};
   }
   foreach my $lang (keys(%nrec)){
      $ENV{HTTP_FORCE_LANGUAGE}=$lang;
      my @emailto;
      my @emailcc;
      foreach my $userid (keys(%{$nrec{$lang}})){
         if (exists($uid{to}->{$userid})){
            push(@emailto,$userid);
         }
         elsif (exists($uid{cc}->{$userid})){
            push(@emailcc,$userid);
         }
      }
      my $subject=$datastream->T(
         "Qualys new security scan found for",
         'tssiem::qrule::SecScanMon').' '.$itscanobjectname[0];

      my @scans;
      foreach my $urlrec (@{$rec}){
         push(@scans,sprintf("<b>%s</b>\n%s\n",
                             $urlrec->{name},
                             $urlrec->{urlofcurrentrec}));
      }



      my $tmpl=$datastream->getParsedTemplate("tmpl/SecScanMon_MailNotify",{
         static=>{
            SCANLIST=>join("\n",@scans),
            ITSCANOBJECTNAME=>$itscanobjectname[0],
            DEBUG=>$debug
         }
      });

      $wfa->Notify("INFO",$subject,$tmpl, 
         emailto=>\@emailto, 
         emailcc=>\@emailcc, 
         emailcategory =>['Qualys',
                          'tssiem::event::SecScanMon',
                          'NewSecScan'],
         emailbcc=>[
         #   11634953080001, # HV
            12663941300002  # Roland
         ]
      );
   }
   if ($lastlang ne ""){
      $ENV{HTTP_FORCE_LANGUAGE}=$lastlang;
   }
   else{
      delete($ENV{HTTP_FORCE_LANGUAGE});
   }
}


1;
