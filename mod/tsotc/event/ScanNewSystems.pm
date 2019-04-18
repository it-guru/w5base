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




sub Init
{
   my $self=shift;


   $self->RegisterEvent("ScanNewSystems","ScanNewSystems",timeout=>600);
}




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
               $cnt++;
               if ($self->analyseRecord($datastream,$rec,$res)){
                  $imp++;
               }
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
   msg(INFO,"         contact='$rec->{contactemail}'");

   if (!($rec->{name}=~m/^[a-z0-9_-]{2,35}$/)){
      msg(ERROR,"skip OTC Systemname $rec->{name} - invalid systemname");
      return();
   }
   if ($rec->{contactemail} eq ""){
      msg(ERROR,"skip OTC Systemname $rec->{name} - no contactemail");
      return();
   }

   my $sys=$self->getPersistentModuleObject("W5BaseOTCSys","tsotc::system");
   my $w5sys=$self->getPersistentModuleObject("W5BaseSys","itil::system");
   my $wfa=$self->getPersistentModuleObject("W5BaseWa","base::workflowaction");
   my $user=$self->getPersistentModuleObject("W5BaseUser","base::user");

   my $w5baseid=$sys->Import({importname=>$rec->{name}});

   if (defined($w5baseid)){   # create Notification
      $w5sys->SetFilter({id=>\$w5baseid});
      my ($srec)=$w5sys->getOnlyFirst(qw(id databossid urlofcurrentrec name));
      if (!defined($srec)){
         msg(ERROR,"something went wron while import of OTC Systemname $srec->{name}");
         return();
      }
      msg(INFO,"start doNotify $srec->{name}");
      $self->doNotify($sys,$wfa,$user,$srec);
      return(1);
   }
   return(0);
}



sub doNotify
{
   my $self=shift;
   my $datastream=shift;
   my $wfa=shift;
   my $user=shift;
   my $rec=shift;
   my $debug="";


   my %uid;

   $uid{to}->{$rec->{databossid}}++;
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
         if (exists($uid{cc}->{$userid})){
            push(@emailcc,$userid);
         }
      }
      my $subject=$datastream->T("automatic system import from OTC",
                                 'tsotc::event::ScanNewSystems')." : ".$rec->{name};

#      my @scans;
#      foreach my $url (sort(keys(%$rec))){
#         push(@scans,sprintf("<b>%s</b>\n%s\n",$rec->{$url}->{name},$url));
#      }



      my $tmpl=$datastream->getParsedTemplate("tmpl/ScanNewSystems_MailNotify",{
         static=>{
            URL=>$rec->{urlofcurrentrec},
            SYSTEMNAME=>$rec->{name}
         }
      });

      $wfa->Notify("INFO",$subject,$tmpl, 
         emailto=>\@emailto, 
         emailcc=>\@emailcc, 
         emailbcc=>[
            11634953080001, # HV
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
