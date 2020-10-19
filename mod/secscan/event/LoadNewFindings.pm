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
   $self->{ipaddress}=getModuleObject($self->Config,"TS::ipaddress");
   $self->{wf}=getModuleObject($self->Config,"base::workflow");
   my $user=getModuleObject($self->Config,"base::user");

   my @datastreamview=qw(id hstate hostname ipaddr isdel itemrawdesc 
                         ofid name mdate startdate enddate findmdate
                         wfheadid wfref wfhandeled  hstate execptionperm
                         secitem sectokenid sectreadrules spec 
                         srcid srcsys respemail);
   # NICHT ALL verwenden, da die recup* Felder die Abfrage extrem langsam
   # machen würden

   if ($queryparam ne "" && $queryparam ne "FORCEALL"){
      $datastream->SetFilter({id=>\$queryparam});
      $datastream->SetCurrentOrder("+findcdate","+id");
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
   my %flt=(isdel=>\'0');;
   if ($queryparam ne "FORCEALL"){    #analyse lastSuccessRun
      #%flt=( 
      #   findcdate=>">$startstamp",
      #   isdel=>\'0'
      #);
      %flt=( 
         sectokenid=>'B2AC4CD49142F15BE1E20804E1438EA246792B36D991FBF3F32CCE1870AA4DD7', 
         hstate=>"[EMPTY]",
         isdel=>\'0'
      );
      if (defined($firstrec)){
         my $lastmsg=$firstrec->{exitmsg};
         if (($laststamp,$lastid)=
             $lastmsg=~m/^last:(\d+-\d+-\d+ \d+:\d+:\d+);(\S+)$/){
            $exitmsg=$lastmsg;
            $datastream->ResetFilter();
            $datastream->SetFilter({id=>\$lastid,findcdate=>\$laststamp});
            my ($lastrec,$msg)=$datastream->getOnlyFirst(qw(id));
            if (!defined($lastrec)){
               msg(WARN,"record with id '$lastid' ".
                        "has been deleted or changed - using date only");
               $lastid=undef;
            }
            %flt=( 
               findcdate=>">=\"$laststamp GMT\"",
               isdel=>\'0'
            );
         }
      }
   }

   if (1){ # process new records
      my $skiplevel=0;
      my $recno=0;
      $datastream->ResetFilter();
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
            if ($queryparam ne "FORCEALL"){
               if ($recno>50){  # limit record-handing in one pass
                  last;
               } 
            } 
         }until(!defined($rec));
      }
   }
   if ($queryparam ne "FORCEALL"){
      my $dataop=$datastream->Clone();
      $datastream->ResetFilter();
      my @flt=({
         sectokenid=>'B2AC4CD49142F15BE1E20804E1438EA246792B36D991FBF3F32CCE1870AA4DD7', 
                  wfhandeled=>\'1',
                  findmdate=>'<now-3d',
                  isdel=>\'1'
               },
               {
         sectokenid=>'B2AC4CD49142F15BE1E20804E1438EA246792B36D991FBF3F32CCE1870AA4DD7', 
                  wfhandeled=>\'1',
                  mdate=>'>now-12h',
                  isdel=>\'0',
                  execptionperm=>"![EMPTY]"
               },

      );




      $datastream->SetFilter(\@flt);
      $datastream->SetCurrentView(@datastreamview);
      $datastream->SetCurrentOrder("+findcdate","+id");
      my ($rec,$msg)=$datastream->getFirst();

      if (defined($rec)){
         do{
            msg(INFO,"cleanup finding id=$rec->{id}");
            $self->analyseRecord($datastream,$rec,$res);
            ($rec,$msg)=$datastream->getNext();
            if (defined($msg)){
               msg(ERROR,"db record problem: %s",$msg);
               return({exitcode=>1,msg=>$msg});
            }
         }until(!defined($rec));
      }
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
   msg(INFO,"  SecTokenID:$rec->{sectokenid}");
   msg(INFO,"  wfhandeled:$rec->{wfhandeled}");
   msg(INFO,"  isdel:     $rec->{isdel}");

   if ($rec->{isdel} eq "1" || $rec->{execptionperm} ne ""){
      if ($rec->{wfhandeled} eq "1"){
         my $dataop=$dataobj->Clone();
         my $srcsys="secscan::finding";
         my $srcid=$rec->{sectokenid};
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
      }
      return(); 
   }



   my $ipaddr=$rec->{ipaddr};

   my $aresult=$self->{ipaddress}->Analyse({ipaddr=>$ipaddr});


   if (ref($aresult) ne "HASH" ||
       $aresult->{exitcode} ne "0"){
      msg(ERROR,"invalid Analyse result for IP-Address $ipaddr");
      print STDERR Dumper($aresult);
      die();
   }
   $aresult=$aresult->{result};

   my $reponsibleid;
   my %altreponsibleid;

   if (ref($aresult->{'Admin-C'}) eq "ARRAY"){
      if (exists($aresult->{'Admin-C'}->[0]->{userid})){
         $reponsibleid=$aresult->{'Admin-C'}->[0]->{userid};
      }
      for(my $c=1;$c<=$#{$aresult->{'Admin-C'}};$c++){
         if (exists($aresult->{'Admin-C'}->[$c]->{userid})){
            $altreponsibleid{$aresult->{'Admin-C'}->[$c]->{userid}}++;
         }
      }
   }
   if (ref($aresult->{'Tech-C'}) eq "ARRAY"){
      for(my $c=0;$c<=$#{$aresult->{'Tech-C'}};$c++){
         if (exists($aresult->{'Tech-C'}->[$c]->{userid})){
            $altreponsibleid{$aresult->{'Tech-C'}->[$c]->{userid}}++;
         }
      }
   }


   # print STDERR Dumper($aresult);
   # printf STDERR ("\nresp=%s\n",$reponsibleid);
   # printf STDERR ("\nalt=%s\n",Dumper(\%altreponsibleid));
   # exit(1);




   # 
   #  Now we have a reponsibleid and we can start a workflow
   # 
   my ($WfRec,$msg);
   if ($rec->{execptionperm} eq "" && defined($reponsibleid)){
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
            my $newrec={
                  secfindingreponsibleid=>$reponsibleid,
                  detaildescription=>$rec->{detailspec} 
            };
            if (keys(%altreponsibleid)){
               $newrec->{secfindingaltreponsibleid}=
                  [sort(keys(%altreponsibleid))];
            }
            msg(WARN,"debug wfreactivate for wfhead $WfRec->{id} needed");
            if ($wfop->nativProcess('wfreactivate',$newrec,$WfRec->{id})){
               msg(INFO,"ok - it was reactivated $WfRec->{id}");
            }
         }
         elsif($WfRec->{step} eq "secscan::workflow::FindingHndl::main"){
            if ($WfRec->{secfindingreponsibleid} ne $reponsibleid){
               my $wfop=$self->{wf}->Clone(); 
               my $newrec={
                     secfindingreponsibleid=>$reponsibleid,
                     detaildescription=>$rec->{detailspec} 
               };
               if (keys(%altreponsibleid)){
                  $newrec->{secfindingaltreponsibleid}=
                     [sort(keys(%altreponsibleid))];
               }
               msg(WARN,"debug wfreassign for wfhead $WfRec->{id} needed");
               if ($wfop->nativProcess('wfreassign',$newrec,$WfRec->{id})){
                  msg(INFO,"ok - it was reassigned $WfRec->{id}");
               }
            }
         }
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
               $newrec->{secfindingaltreponsibleid}=[
                  sort(keys(%altreponsibleid))
               ];
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
   if ($rec->{execptionperm} ne ""){
      if (!$rec->{hstate}){
         $upd->{hstate}="AUTOANALYSED";
      }
   }
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
      if (1){
         my $newcomments="";
         if (exists($aresult->{notes}) && $aresult->{notes} ne ""){
            $newcomments=$aresult->{notes};
         }
         if (trim($rec->{comments}) ne trim($newcomments)){
            $upd->{comments}=$newcomments;
         }
      }
   }
   if (keys(%$upd)){
      if ($rec->{mdate} ne ""){
         $upd->{mdate}=$rec->{mdate};  # don't change mdate in  of table
      }
      if (!$dataop->ValidatedUpdateRecord($rec,$upd,{id=>\$rec->{id}})){
         msg(ERROR,"ValidatedUpdateRecord failed on upd");
         msg(ERROR,"rec=".Dumper($rec));
         msg(ERROR,"upd=".Dumper($upd));
      }
   }


}


1;
