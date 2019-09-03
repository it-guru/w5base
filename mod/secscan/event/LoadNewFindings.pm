package secscan::event::LoadNewFindings;
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
sub LoadNewFindings
{
   my $self=shift;
   my $queryparam=shift;


   my $firstDayRange=100;
   my $maxDeltaDayRange="15";

   my $StreamDataobj="secscan::finding";


   my $joblog=getModuleObject($self->Config,"base::joblog");
   my $datastream=getModuleObject($self->Config,$StreamDataobj);
   $self->{appl}=getModuleObject($self->Config,"TS::appl");
   $self->{ipaddress}=getModuleObject($self->Config,"itil::ipaddress");
   $self->{wf}=getModuleObject($self->Config,"base::workflow");
   my $user=getModuleObject($self->Config,"base::user");

   my @datastreamview=qw(ALL);

   if ($queryparam ne ""){
      $datastream->SetFilter({id=>\$queryparam});
      foreach my $rec ($datastream->getHashList(@datastreamview)){
          my $res={};
          $self->analyseRecord($datastream,$rec,$res);
      }
      return({exitcode=>0,exitmsg=>'DEBUG: ok'});
   }

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
         findcdate=>">$startstamp",
         isdel=>\'0'
      );
      if (defined($firstrec)){
         my $lastmsg=$firstrec->{exitmsg};
         if (($laststamp,$lastid)=
             $lastmsg=~m/^last:(\d+-\d+-\d+ \d+:\d+:\d+);(\S+)$/){
            $exitmsg=$lastmsg;
            %flt=( 
               findcdate=>">=\"$laststamp GMT\"",
               isdel=>\'0'
            );
         }
      }
   }

   { # process new records
      my $skiplevel=0;
      my $recno=0;
      $datastream->SetFilter(\%flt);
      $datastream->SetCurrentView(@datastreamview);
      $datastream->SetCurrentOrder("+findcdate","+id");
      #$datastream->Limit(1000);
      my ($rec,$msg)=$datastream->getFirst();

      if (defined($rec)){
         READLOOP: do{
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
               if ($rec->{findcdate} ne $laststamp){
                  msg(WARN,"record with id '$lastid' missing in datastream");
                  msg(WARN,"this can result in skiped records!");
                  $skiplevel=3;
               }
            }
            if ($skiplevel==0){
               if (defined($laststamp) && defined($lastid)){
                  if ($laststamp eq $rec->{findcdate}){
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
               $self->analyseRecord($datastream,$rec,$res);
               $recno++;
               $exitmsg="last:".$rec->{findcdate}.";".$rec->{id};
            }
            else{
               msg(INFO,"skip rec $rec->{findcdate} - ".
                        "id=$rec->{id} ".
                        "skiplevel=$skiplevel recon=$recno");
            }
            ($rec,$msg)=$datastream->getNext();
            if (defined($msg)){
               msg(ERROR,"db record problem: %s",$msg);
               return({exitcode=>1,msg=>$msg});
            }
            if ($recno>50){  # limit record-handing in one pass
               last;
            } 
         }until(!defined($rec));
      }
   }
   my $dataop=$datastream->Clone();
   $datastream->ResetFilter();
   $datastream->SetFilter({
      wfhandeled=>\'1',
      findmdate=>'<now-7d',
      isdel=>\'1'
   });
   my ($rec,$msg)=$datastream->getFirst();

   if (defined($rec)){
      do{
         msg(INFO,"cleanup finding id=$rec->{id}");
         my $srcsys="secscan::finding";
         my $srcid=$rec->{id};
         my $srckey=$srcsys."::".$srcid;  # because length of srcid :-[

         my $wfop=$self->{wf}->Clone(); 
         $self->{wf}->ResetFilter();
         $self->{wf}->SetFilter({
            srcsys=>\$srckey,
            step=>"!secscan::workflow::FindingHndl::finish"
         });
         foreach my $wfrec ($self->{wf}->getHashList(qw(id))){
            msg(INFO,"cleanup workflow id=$wfrec->{id}");
            if ($wfop->nativProcess('wfforceobsolete',{},$wfrec->{id})){
               $dataop->ValidatedUpdateRecord($rec,{
                  wfhandeled=>'0',
                  hstate=>"OBSOLETE"
               },{id=>\$rec->{id}});
            }
         }
         




         ($rec,$msg)=$datastream->getNext();
         if (defined($msg)){
            msg(ERROR,"db record problem: %s",$msg);
            return({exitcode=>1,msg=>$msg});
         }
      }until(!defined($rec));
   }






   my $ncnt=0;
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

   msg(INFO,"F:$rec->{id}");
   msg(INFO,"  SecToken  :$rec->{name}");
   msg(INFO,"  Host      :$rec->{hostname}");
   msg(INFO,"  IpAddr    :$rec->{ipaddr}");
   msg(INFO,"  SecTokenID: $rec->{sectokenid}");

   my $ipaddr=$rec->{ipaddr};

   $self->{ipaddress}->ResetFilter();
   $self->{ipaddress}->SetFilter({name=>\$ipaddr,cistatusid=>\'4'});

   my @l=$self->{ipaddress}->getHashList(qw(id applications dnsname 
                                            name system itclustsvc));
   my %applid;
   if ($#l!=-1){
      foreach my $iprec (@l){
         if (ref($iprec->{applications}) eq "ARRAY"){
            foreach my $applrec (@{$iprec->{applications}}){
               if ($applrec->{applid} ne ""){
                  $applid{$applrec->{applid}}++;
               }
            }
         }
      }
   }

   # now all applications are detected
   my $applrec;

   if (keys(%applid)){
      $self->{appl}->ResetFilter();
      $self->{appl}->SetFilter({cistatusid=>"<6",
                                applmgrid=>"![EMPTY]",
                                id=>[keys(%applid)]
      });
      my @appls=$self->{appl}->getHashList(qw(+cdate name
                                              tsmid tsm2id opmid opm2id 
                                              applmgrid));
      if ($#appls!=-1){
         $applrec=$appls[0];
      }
      #print Dumper(\@l);
      #print Dumper(\@appls);
   }

   my $reponsibleid;
   my %altreponsibleid;
   if (defined($applrec)){
      $reponsibleid=$applrec->{applmgrid};
      foreach my $fname (qw(tsmid tsm2id opmid opm2id)){
         if ($applrec->{$fname} ne $reponsibleid &&
             $applrec->{$fname} ne ""){
            $altreponsibleid{$applrec->{$fname}}++;
         }
      }
   }



   # 
   #  Now we have a reponsibleid and we can start a workflow
   # 
   my ($WfRec,$msg);
   if (defined($reponsibleid)){
      msg(INFO,"start handling for reponsibleid $reponsibleid");
      my @srckey;
      my $srcsys="secscan::finding";
      my $srcid=$rec->{sectokenid};
      my $srckey=$srcsys."::".$srcid;  # because length of srcid :-[
      
      # check if workflow already exists
      $self->{wf}->ResetFilter();
      $self->{wf}->SetFilter({srcsys=>\$srckey});
      my @WfRec=$self->{wf}->getHashList(qw(ALL));
      if ($#WfRec!=-1){
         msg(INFO,"  already exists with WorkflowID=$WfRec[0]->{id}");
         $WfRec=$WfRec[0];
         if ($WfRec->{stateid}>15){
            msg(INFO,"need to reactivate $WfRec->{id}");
            my $wfop=$self->{wf}->Clone(); 
            if ($wfop->nativProcess('wfreactivate',{
                  secfindingreponsibleid=>$reponsibleid,
                  detaildescription=>$rec->{detailspec} },$WfRec->{id})){
               msg(INFO,"ok - it was reactivated $WfRec->{id}");
            }
         }
      #   $self->{wf}->Action->StoreRecord($WfRec->{id},"note",
      #                              {additional=>{}},"recreation detected");
      }
      if (!defined($WfRec)){
         my $newrec={
            srcsys=>$srckey,
            class=>'secscan::workflow::FindingHndl',
            secfindingreponsibleid=>$reponsibleid,
            secfindingipaddrref=>$ipaddr,
            secfindingitem=>$rec->{secitem},
            detaildescription=>$rec->{detailspec}
         };
         my $sectreadrules=trim($rec->{sectreadrules});
         my @sectreadrules=split(/\s*[,;]\s*/,$sectreadrules);
         if (!in_array(\@sectreadrules,"IgnoreFinding")){
            if (in_array(\@sectreadrules,"EnforceRemove")){
               $newrec->{secfindingenforceremove}=1;
            }
            if (in_array(\@sectreadrules,"GetStatement")){
               $newrec->{secfindingaskstatement}=1;
            }

            if (keys(%altreponsibleid)){
               $newrec->{secfindingaltreponsibleid}=[sort(keys(%altreponsibleid))];
            }
            # sectreadrules handling!

            my $id=$self->{wf}->nativProcess("NextStep",$newrec);
            if ($id ne ""){
               $self->{wf}->ResetFilter();
               $self->{wf}->SetFilter({id=>\$id});
               ($WfRec,$msg)=$self->{wf}->getOnlyFirst(qw(ALL));
            }
         }
      }
   }
   my $dataop=$dataobj->Clone();
   $dataop->BackendSessionName("cloned$$"); # needed because oracle gets problems with getNext
   my $upd={};
   if (defined($WfRec)){
      msg(INFO,"start handling for existing workflow");
      if (!$rec->{wfhandeled}){
         $upd->{wfhandeled}=1;
      }
      if (!$rec->{hstate}){
         $upd->{hstate}="AUTOANALYSED";
      }
      if ($rec->{wfref} ne $WfRec->{urlofcurrentrec}){
         $upd->{wfref}=$WfRec->{urlofcurrentrec};
      }
      if ($rec->{wfheadid} ne $WfRec->{id}){
         $upd->{wfheadid}=$WfRec->{id};
      }
   }
   else{
      msg(INFO,"start handling unknown ip adresses");
      if (!$rec->{hstate}){
         $upd->{hstate}="NOTAUTOHANDLED";
      }
      #if ($rec->{comments} eq ""){
      if (1){
         my $newcomments="";
         my $ipflt=$rec->{ipaddr};
         $ipflt=~s/\*//g;
         $ipflt=~s/\?//g;
         msg(INFO,"try to query NOAH on ip $ipflt");
         if ($ipflt ne ""){
            my $noa=getModuleObject($dataobj->Config,"tsnoah::ipaddress");
            $noa->SetFilter({name=>$ipflt});
            my @l=$noa->getHashList(qw(name systemname urlofcurrentrec));
            if ($#l!=-1){
               $newcomments.="NOAH IP-Informations:\n".join("\n\n",map({
                  $_->{systemname}."\n".$_->{urlofcurrentrec};
               } @l));
            }
            if (1){
               # now we try to find the correct networks
               my @netmask=qw(0 0 0 0);
               my @network=qw(0 0 0 0);
               my @flt;
               foreach my $ipaddr (split(/[\s;]+/,$rec->{ipaddr})){
                   my @okt=split(/\./,$ipaddr);
                   for(my $o=0;$o<=3;$o++){
                      my $bitmask=128;
                      for(my $bit=0;$bit<8;$bit++){
                         $bitmask=(128>>$bit)|$bitmask;
                         $netmask[$o]=$bitmask;
                         my $netmask=join(".",@netmask);
                         for(my $n=0;$n<4;$n++){
                            $network[$n]=$okt[$n]&$netmask[$n];
                         }
                         my $network=join(".",@network);
                         push(@flt,{
                            name=>\$network,
                            subnetmask=>\$netmask 
                         });
                      }
                   }
               }
               if ($#flt!=-1){
                  my $noa=getModuleObject($dataobj->Config,"tsnoah::ipnet");
                  $noa->SetFilter(\@flt);
                  my @l=$noa->getHashList(qw(fullname name subnetmask
                                             urlofcurrentrec));
                  if ($#l!=-1){
                     if ($newcomments ne ""){
                        $newcomments.="\n\n";
                     }
                     $newcomments.="NOAH IP-Networks:\n".join("\n\n",map({
                        $_->{fullname}."\n".$_->{name}." ".
                        "(".$_->{subnetmask}.")\n".
                        $_->{urlofcurrentrec};
                     } @l));
                  }
               }
            }
         }
         if (trim($rec->{comments}) ne trim($newcomments)){
            $upd->{comments}=$newcomments;
         }
      }
   }
   if (keys(%$upd)){
      if (!$dataop->ValidatedUpdateRecord($rec,$upd,{id=>\$rec->{id}})){
         msg(ERROR,"ValidatedUpdateRecord failed on upd");
         msg(ERROR,"rec=".Dumper($rec));
         msg(ERROR,"upd=".Dumper($upd));
      }
   }


}


1;
