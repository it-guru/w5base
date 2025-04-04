package SMNow::event::sngroup;
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
use kernel::Event;
@ISA=qw(kernel::Event);

our @SNVIEW=qw(mdate fullname sys_id type);

our @AMVIEW=qw(mdate fullname supervisoremail deleted);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->{timeout}=1800;

   return($self);
}

sub exttrim
{
   my $s=shift;
   my $out="".$s; 
   $out=~s/[^A-Z.0-9&a-z_+@ÄÖÜ\/(:#!,)äöü-]*$//;
   $out=~s/^[^A-Z.0-9&a-z_+@ÄÖÜ\/(:#!,)äöü-]*//;
   return($out);
}

sub Init
{
   my $self=shift;


   $self->RegisterEvent("sngroup","sngroup",timeout=>$self->{timeout});
}

sub sngroup
{
   my $self=shift;
   my $queryparam=shift;


   my $joblog=getModuleObject($self->Config,"base::joblog");
   my $sgrp=getModuleObject($self->Config,"SMNow::sys_user_group");
   my $mgrp=getModuleObject($self->Config,"tsgrpmgmt::grp");
   my $agrp=getModuleObject($self->Config,"tsacinv::group");
   my $opagrp=$agrp->Clone();
   my $opsgrp=$sgrp->Clone();
   my $opmgrp=$mgrp->Clone();
   my %dataobj=(agrp=>$opagrp,sgrp=>$opsgrp,mgrp=>$opmgrp);


   return({}) if ($sgrp->isSuspended());
   # if ping failed ...
   if (!$sgrp->Ping()){
      # check if there are lastmsgs
      # if there, send a message to interface partners
      my $infoObj=getModuleObject($self->Config,"itil::lnkapplappl");
      return({}) if ($infoObj->NotifyInterfaceContacts($sgrp));
      msg(ERROR,"no ping posible to ".$sgrp->Self());
      return({});
   }

   # precheck - to find missing AG problem with SM.Now
   msg(INFO,"start query for precheck - check against missing groups");
   
   $sgrp->ResetFilter();
   $sgrp->SetFilter({
      active=>1,
      type=>'*52e03b172b703d10c0fb4cfbad01a081* '.
            '*0551bb172b703d10c0fb4cfbad01a0b0* '.
            '*d98b56fcfc8aded85dcff689977724aa* '.
            '*654da04a2b61651053504cfbad01a094* '.
            '*297a61de2b30fd90c0fb4cfbad01a086* '.
            '*dcd035702b1c3150c0fb4cfbad01a05b*',
      mdate=>'<now-6h'   
   });
   my @l=$sgrp->getHashList(qw(fullname));

   if ($#l<50){
      msg(ERROR,"SM.Now result of fullquery groups seems not plausible n=".
          ($#l+1));
      return({exitcode=>'100',exitmsg=>'ERROR group count was '.($#l+1)});
   }

   foreach my $rec (@l){
      msg(INFO,"found $rec->{fullname} in SM.Now");
   }
   my $mistakeDateStamp;
   foreach my $rec (@l){
      $mgrp->ResetFilter();
      $mgrp->SetFilter({fullname=>\$rec->{fullname}});
      my ($chkrec,$msg)=$mgrp->getOnlyFirst(qw(id));
      if (!defined($chkrec)){
         $mgrp->Log(WARN,"backlog",
                  "missing group $rec->{fullname} with mdate in SM.Now older ".
                  "then 6h - mdate in SM.Now is ".$rec->{mdate});
         if (!defined($mistakeDateStamp) ||
             $mistakeDateStamp gt $rec->{mdate}){
            $mistakeDateStamp=$rec->{mdate};
         }
      }
   }
   if (defined($mistakeDateStamp)){
      msg(WARN,"start repair sync with mistakeDateStamp=$mistakeDateStamp");
   }
      
   my $srcsys=$self->Self;

   my @incloader=(
      {
         dataobj=>$sgrp,
         recpos=>0,
         cnt=>0,
         initflt=>{active=>1,
                   type=>'*52e03b172b703d10c0fb4cfbad01a081* '.
                         '*0551bb172b703d10c0fb4cfbad01a0b0* '.
                         '*d98b56fcfc8aded85dcff689977724aa* '.
                         '*654da04a2b61651053504cfbad01a094* '.
                         '*297a61de2b30fd90c0fb4cfbad01a086* '.
                         '*dcd035702b1c3150c0fb4cfbad01a05b*'},
         view=>\@SNVIEW
      },
      {
         dataobj=>$agrp,
         recpos=>1,
         cnt=>0,
         initflt=>{deleted=>\'0'},
         view=>\@AMVIEW
      }
   );

   # for refresh-debugging clear incloader
   #@incloader=();

   my $looplimit=100;
   if ($queryparam eq "reset"){
      $looplimit=1000000;
   } 

   foreach my $incloader (@incloader){
      my $dataobj=$incloader->{dataobj};
      # find restart point
      $joblog->SetFilter({name=>[$self->Self()],
                          exitcode=>\'0',
                          event=>'IncLoad::'.$dataobj->Self});
      $joblog->SetCurrentOrder('cdate');
      
      $joblog->Limit(1);
      my ($firstrec,$msg)=$joblog->getOnlyFirst(qw(ALL));
      
      my $start;
      
      if (defined($firstrec)){
         $start="$firstrec->{exitmsg}";
      }
      if (defined($mistakeDateStamp) && defined($start) &&
          $start gt $mistakeDateStamp){
         msg(WARN,"overwrite sync start for mdate ".$dataobj->Self." ".
                  "from $start to $mistakeDateStamp");
         $start=$mistakeDateStamp;
         $looplimit=1000000;
      }
    

      msg(INFO,"processing delta query starting from mdate>=$start"); 
      sleep(1);
      my $flt=$incloader->{initflt};
      if ($queryparam eq ""){
         if (defined($start)){
            $flt->{mdate}='>="'.$start.'"';
         }
      }
      else{
         #msg(WARN,"quering without start parameter - ".
         #         "reset or direct group selected");
      }
      if ($queryparam ne "" && $queryparam ne "reset"){
            $flt->{name}=$queryparam;
      }
      $dataobj->ResetFilter();
      $dataobj->SetFilter($flt);
      $dataobj->SetCurrentView(@{$incloader->{view}});
      $dataobj->SetCurrentOrder("+mdate");
      my ($grprec,$msg)=$dataobj->getFirst();
      my $laststamp;
      if (defined($grprec)){
         my $c=0;
         do{
            $incloader->{cnt}++;
            msg(INFO,"process ".$incloader->{dataobj}->Self().
                     "($incloader->{cnt}): $grprec->{fullname} ".
                     "'$grprec->{mdate}'");
            if (defined($laststamp) && $laststamp gt $grprec->{mdate}){
               msg(WARN,"data stream ".$dataobj->Self()." not in mdate order");
               msg(WARN,"old=$laststamp new=$grprec->{mdate}");
            }
            $laststamp=$grprec->{mdate};
            if ($start eq $grprec->{mdate}){
               $c--;
            }
            my $firstseenon=$dataobj->Self;
            my @p=(undef,undef,undef,undef);
            $p[$incloader->{recpos}]=$grprec;

            $self->handleSRec(\%dataobj,$firstseenon,undef,@p);
            ($grprec,$msg)=$dataobj->getNext();
            if (defined($msg)){
               msg(ERROR,"db record problem: %s",$msg);
               return({exitcode=>1,msg=>$msg});
            }
         }until(!defined($grprec) || $c++>$looplimit);
      }
      if (($queryparam eq "" ||
           $queryparam eq "reset") &&
          defined($laststamp)){    # letzten Zeitstempel im Joblog "merken"
         msg(INFO,"store stamp $laststamp for ".$dataobj->Self);
         $joblog->ValidatedInsertRecord({
            pid=>$$,
            name=>$self->Self,
            event=>'IncLoad::'.$dataobj->Self,
            exitcode=>0,
            exitmsg=>$laststamp,
            exitstate=>'ok'
         });
      }
   }
   msg(INFO,"loop end");


   if ($queryparam ne "reset"){
      $mgrp->ResetFilter();    # Refresh process
      if ($queryparam eq ""){
         $mgrp->ResetFilter();
      }
      else{
         $mgrp->SetFilter({fullname=>$queryparam});
      }
      $mgrp->SetCurrentOrder("chkdate");
      $mgrp->SetCurrentView(qw(ALL));
      #$mgrp->Limit(25000,1);
      $mgrp->Limit(250,1);
      #$mgrp->Limit(20,1);
      my ($mgrprec,$msg)=$mgrp->getFirst();
      if (defined($mgrprec)){
         do{
            my $skipRefresh=0;
            if ($mgrprec->{cistatusid}>4){
               my $nativeFullname=$mgrprec->{fullname};
               $nativeFullname=~s/\[\d+\]$//;
               my $chkObj=$mgrp->Clone();
               $chkObj->SetFilter({fullname=>$nativeFullname,cistatusid=>\'4'});
               my ($chkrec,$msg)=$chkObj->getOnlyFirst(qw(id));
               if (defined($chkrec)){
                  $skipRefresh++;
                  msg(INFO,"skip refresh while already new record ".
                           "for $mgrprec->{fullname}");
               }
            }
            

            if (!$skipRefresh){
               msg(INFO,"process refresh ".
                        "$mgrprec->{fullname} $mgrprec->{mdate}");
               $self->handleSRec(\%dataobj,undef,$mgrprec);
            }
            ($mgrprec,$msg)=$mgrp->getNext();
         }until(!defined($mgrprec));
      }
   }


   return({exitcode=>0,msg=>'OK'}); 
}

sub map_sgrp_flags
{
   my $oldrec=shift;
   my $newrec=shift;
   my $sgrprec=shift;

   my $type=$sgrprec->{type};

   if (!defined($sgrprec)){
      $newrec->{iscoordinator}=undef;
      $newrec->{ischmimpl}=undef;
      $newrec->{ismanager}=undef;
      $newrec->{isinmassign}=undef;
      $newrec->{ischmapprov}=undef;
      $newrec->{isrespall}=undef;
      $newrec->{admingroup}=undef;
   }

   my %f;

   $f{ischmapprov}=in_array($type,"change_approver") ? 1 : 0;
   $f{ischmimpl}=in_array($type,"change_implementer") ? 1 : 0;
   $f{isinmassign}=in_array($type,"incident") ? 1 : 0;

   foreach my $flag (keys(%f)){
      if (!defined($oldrec) || $oldrec->{$flag} ne  $f{$flag}){
         $newrec->{$flag}=$f{$flag};
      }
   }


}

sub handleSRec
{
   my $self=shift;
   my $dataobj=shift;
   my $firstseenon=shift;
   my $oldrec=shift;
   my $sgrprec=shift;
   my $agrprec=shift;

   my @comments;

   if (!defined($oldrec)){         # records from SM or AM
      my $msgnote;
      if (defined($sgrprec)){
         my $snid=$sgrprec->{sys_id};
         $dataobj->{mgrp}->SetFilter({snid=>\$snid});
         $msgnote="join snid=$snid to";
      }
      elsif (defined($agrprec)){
         my $amid=$agrprec->{lgroupid};
         $dataobj->{mgrp}->SetFilter({amid=>\$amid});
         $msgnote="join amid=$amid to";
      }
      else{
         die('havy problem');
      }
      $dataobj->{mgrp}->SetCurrentOrder("NONE");
      my ($r,$msg)=$dataobj->{mgrp}->getOnlyFirst(qw(ALL));
      if (!defined($r)){  # mit Ids war der Datensatz nicht zu finden
         msg(INFO,"can not find oldrec in tsgrpmgmt by id");
         $dataobj->{mgrp}->ResetFilter();
         if (defined($sgrprec)){
            my $fullname=exttrim($sgrprec->{fullname});
            $dataobj->{mgrp}->SetFilter({fullname=>\$fullname});
         }
         elsif (defined($agrprec)){
            my $fullname=exttrim($agrprec->{fullname});
            $fullname=~s/\[[0-9]+\]$//;
            $dataobj->{mgrp}->SetFilter({fullname=>\$fullname});
         }
         else{
            die('havy problem');
         }
         ($r,$msg)=$dataobj->{mgrp}->getOnlyFirst(qw(ALL));
         if (defined($r)){
            #msg(WARN,"$msgnote w5baseid=$r->{id} fullname=$r->{fullname}");
         }
      }
      $oldrec=$r;
   }
   if (!defined($sgrprec)){        # refresh records
      if (defined($oldrec)){
         my $sncheck;
         if ($oldrec->{snid} ne ""){
            $sncheck=$oldrec->{snid};
         }
         else{
            my $chksnid=$oldrec->{sys_id};
            $sncheck=$chksnid;
         }
         if ($sncheck ne ""){
            $dataobj->{sgrp}->SetFilter({sys_id=>\$sncheck});
            $dataobj->{sgrp}->SetCurrentOrder("NONE");
            my ($r,$msg)=$dataobj->{sgrp}->getOnlyFirst(@SNVIEW);
            $sgrprec=$r;
         }
      }
   }
   if (!defined($agrprec)){        # read additional AssetManager Data
      my @sflt;
      if (defined($oldrec) && $oldrec->{amid} ne ""){
         push(@sflt,{lgroupid=>\$oldrec->{amid}});
      }
      if (defined($sgrprec)){
         if ($sgrprec->{fullname} ne ""){
            push(@sflt,{deleted=>\'0',fullname=>\$sgrprec->{fullname}});
         }
      }
      if ($#sflt!=-1){
         $dataobj->{agrp}->SetFilter(\@sflt);
         my @l=$dataobj->{agrp}->getHashList(@AMVIEW);
         if ($#l==0){
           $agrprec=$l[0];
         }
         elsif($#l>0){
            my %n;
            map({$n{$_->{fullname}}++} @l);
            if (keys(%n)==1){
               $agrprec=$l[0];
               push(@comments,"groupname not unique in AssetManager");
            }
            else{  # seems to be a rename - we only use record by id
               if (defined($oldrec) && $oldrec->{amid} ne ""){
                  L: foreach my $arec (@l){
                     if ($arec->{lgroupid} eq $oldrec->{amid}){
                        $agrprec=$arec;
                        last L;
                     }
                  }
               }
               else{
                  push(@comments,"unknown groupid problem in  AssetManager");
               }
            }
         }
      }
   }




   my $newrec;
   $newrec->{chkdate}=NowStamp("en");
   if (defined($sgrprec) || defined($agrprec)){  # General
      $newrec->{chkdate}=NowStamp("en");
      $newrec->{srcload}=NowStamp("en");
      $newrec->{cistatusid}=4;
   }

   if (defined($sgrprec)){                            # SM Handling
      msg(INFO,"handling of SMNow Group=".Dumper($sgrprec));
      if ($sgrprec->{fullname} ne exttrim($sgrprec->{fullname})){
         push(@comments,"leading or trailing whitespaces on group ".
                       "'".exttrim($sgrprec->{fullname})."' in SMNow");
      }
      if ($sgrprec->{fullname} ne uc($sgrprec->{fullname})){
         push(@comments,"invalid lower case characters on group ".
                       "'".exttrim($sgrprec->{fullname})."' in SMNow");
      }
      if (!defined($oldrec) || $oldrec->{snid} ne $sgrprec->{sys_id}){
         $newrec->{snid}=$sgrprec->{sys_id};
      }
      map_sgrp_flags($oldrec,$newrec,$sgrprec);
      $newrec->{sndate}=NowStamp("en");
      if (defined($oldrec) && $#comments==-1){  # only if no errors
         if ($sgrprec->{fullname} ne $oldrec->{fullname}){
            $dataobj->{sgrp}->Log(WARN,"backlog",
                     "SM.Now interface rename from ".$oldrec->{fullname}." to ".
                     $sgrprec->{fullname}." detected");
            my $newfullname=uc($sgrprec->{fullname});
            $dataobj->{mgrp}->ResetFilter();
            my $chknewfullname=uc($newfullname);
            $dataobj->{mgrp}->SetFilter({fullname=>\$chknewfullname});
            my ($chkrec,$msg)=$dataobj->{mgrp}->getOnlyFirst(qw(ALL));
            if (defined($chkrec) &&
                $chkrec->{id} ne $oldrec->{id}){
               # group already created by f.e. SM9
               $dataobj->{sgrp}->Log(WARN,"backlog",
                        "Meta-group was already new created but it was ".
                        "a rename on id ".
                        "$chkrec->{id} - deaktivating this group now");
               $dataobj->{mgrp}->ValidatedUpdateRecord($chkrec,{
                     cistatusid=>'6',
                     snid=>undef,
                     sndate=>undef,
                     amid=>undef,
                     amdate=>undef,
                     comments=>'data trash by rename operation - '.
                               'SM.Now bevor AM rename',
                     },{
                     id=>$chkrec->{id}
               });
            }
            $newrec->{fullname}=uc($newfullname);
         }
      }
   }
   else{
      my $resetsmflags=1;
      if (defined($oldrec) && $oldrec->{sndate} ne ""){
         $resetsmflags=0;
         my $nowstamp=NowStamp("en");
         my $dur=CalcDateDuration($oldrec->{sndate},$nowstamp);
         if (defined($dur)){
            if ($dur->{totaldays}>14){
               $resetsmflags=1;
            }
         }
      }

     
      if ($resetsmflags){ 
         map_sgrp_flags($oldrec,$newrec,undef);
      }
   }


   if (defined($agrprec)){                            # AM Handling
      if ($agrprec->{fullname} ne exttrim($agrprec->{fullname})){
         push(@comments,"leading or trailing whitespaces on group ".
                        "'".exttrim($agrprec->{fullname})."' in AssetManager");
      }
      if (!defined($oldrec) || $oldrec->{amid} ne $agrprec->{lgroupid}){
         $newrec->{amid}=$agrprec->{lgroupid};
      }
      if ($agrprec->{deleted} eq "0"){
         $newrec->{amdate}=NowStamp("en");
      }

      my $supervisoremail=exttrim($agrprec->{supervisoremail});
      if ($supervisoremail ne "" && !exists($newrec->{contactemail})){
         $supervisoremail=~s/[,;].*//; # use only first, if multiple specified
         $supervisoremail=trim($supervisoremail);
         if (!($supervisoremail=~m/^\S+\@\S+\.\S+$/)){
            push(@comments,"invalid supervisoremail format in AssetManager");
         }
         else{
            if (!defined($oldrec) || 
                $oldrec->{contactemail} ne $supervisoremail){
               $newrec->{contactemail}=$supervisoremail;
            }
         }
      }

      if (defined($oldrec)){   # rename check (detect on AM rename)
         if ($oldrec->{fullname} ne 
             uc(exttrim($agrprec->{fullname}))){ # rename op
            #msg(WARN,"rename request detected on metagroup id $oldrec->{id} ".
            #         "from '$oldrec->{fullname}' to '$agrprec->{fullname}'");
            my $newfullname=exttrim($agrprec->{fullname});

            my $smchecked=0;

            if (uc($newfullname) ne uc($oldrec->{fullname})){
               $dataobj->{sgrp}->ResetFilter();
               $dataobj->{sgrp}->SetFilter({fullname=>\$newfullname});
               $dataobj->{sgrp}->SetCurrentOrder("NONE");
               my ($srec,$msg)=$dataobj->{sgrp}->getOnlyFirst(@SNVIEW);
               if (defined($srec)){
                  $smchecked=2;
                  $sgrprec=$srec;
               }
               else{
                  $smchecked=1;
                  $sgrprec=undef;
               }
            }
            else{  # only a case change did not need to check against SM9
               $smchecked=1;
            }


            if ($smchecked){
               $dataobj->{mgrp}->ResetFilter();
               my $chknewfullname=uc($newfullname);
               $chknewfullname=~s/\[[0-9]+\]$//;
               $dataobj->{mgrp}->SetFilter({fullname=>\$chknewfullname});
               my ($chkrec,$msg)=$dataobj->{mgrp}->getOnlyFirst(qw(ALL));
               if (defined($chkrec) &&
                   $chkrec->{id} ne $oldrec->{id}){ 
                           # group already created by f.e. SM9
                  #msg(WARN,"group was already new created but it was ".
                  #         "a rename on id ".
                  #         "$chkrec->{id} - deaktivating this group now");
                  $dataobj->{mgrp}->ValidatedUpdateRecord($chkrec,{
                     cistatusid=>'6',
                     snid=>undef,
                     sndate=>undef,
                     amid=>undef,
                     amdate=>undef,
                     comments=>'data trash by rename operation - '.
                               'SM bevor AM rename',
                     },{
                     id=>$chkrec->{id}
                  });
               }
               $newrec->{fullname}=uc($newfullname);
               $newrec->{cistatusid}=4;
               if (defined($sgrprec)){ # maybee there is a new smrec
                  $newrec->{snid}=$sgrprec->{sys_id};
               }
               else{
                  $newrec->{snid}=undef;
                  $newrec->{sndate}=undef;
               }
            }
         }
      }
      if (!defined($oldrec) || 
          $oldrec->{iscfmassign} ne "1"){
         $newrec->{iscfmassign}=1;
      }
   }

   my $lastseen=365;
   my %lastseen;
   {
      foreach my $f (qw(sndate amdate mdate)){
         my $d=effVal($oldrec,$newrec,$f);
         if ($d ne ""){
            my $nowstamp=NowStamp("en");
            my $dur=CalcDateDuration($d,$nowstamp);
            if (defined($dur)){
               $lastseen{$f}=$dur->{totaldays};
               if ($lastseen>$dur->{totaldays}){
                  $lastseen=$dur->{totaldays};
               }
            }
         }
      }
      {  # reset last seen - if its longer then 4 weeks in the past
         if (exists($lastseen{amdate}) && $lastseen{amdate}>28){
            $newrec->{amdate}=undef;
            $newrec->{amid}=undef;
            $newrec->{iscfmassign}=undef;
         }
         if (exists($lastseen{sndate}) && $lastseen{sndate}>28){
            $newrec->{sndate}=undef;
            $newrec->{snid}=undef;
            $newrec->{iscfmassign}=undef;
            map_sgrp_flags($oldrec,$newrec,undef);
         }
      }
      #printf STDERR Dumper(\%lastseen); 
      #printf STDERR Dumper($newrec); 
   }
   #msg(INFO,"lastseen = $lastseen");

   my $istelit=0;
   my $fullname=effVal($oldrec,$newrec,"fullname");
   if (($fullname=~m/^(TIT)([. ][^.]+)*$/)){
      $istelit=1;
   }
   if ($lastseen>6){
      $newrec->{cistatusid}=6;   # länger als 6 Tage nirgends gesehen
   }
   elsif ($lastseen>3){
      $newrec->{cistatusid}=5;   # länger als 3 Tage nirgends gesehen
   }
   if (defined($oldrec) && $lastseen>180){
      #msg(WARN,"delete of group $oldrec->{fullname} in $self");
      if (defined($oldrec)){
         $dataobj->{mgrp}->ValidatedDeleteRecord($oldrec);
      }
   }
   else{
      if (!defined($oldrec)){
         if (defined($sgrprec)){
            $newrec->{fullname}=uc(exttrim($sgrprec->{fullname}));
         }
         elsif (defined($agrprec)){
            $newrec->{fullname}=uc(exttrim($agrprec->{fullname}));
         }
         $newrec->{srcsys}=$firstseenon;
      }
      # consistence Checks
      if (effVal($oldrec,$newrec,"isinmassign")){
         my $fullname=effVal($oldrec,$newrec,"fullname");
         if ($istelit && (!defined($lastseen{amdate}) || $lastseen{amdate}>1)){
            push(@comments,"missing incident assignmentgroup in AssetManager");
         }
         if ($istelit && exttrim($fullname)=~m/\.CA$/){
            push(@comments,"not allowed incident assignmentgroup ".
                           "flag on .CA group");
         }
      }
      if (effVal($oldrec,$newrec,"isresp4all") eq "0"){
         if ($istelit){
            push(@comments,"no responsible for all set in SM - ".
                           "based on TelIT rules");
         }
      }
      if ($istelit){
         my $chkfullname=$fullname;
         $chkfullname=~s/\[\d+\]$//;
         if (exttrim($chkfullname)=~m/[^a-z0-9_.-]/i){
            push(@comments,"invalid character in assignmentgroup ".
                           "based on TelIT rules");
         }
      }
      my $comments=join("\n",@comments);
      if (effVal($oldrec,$newrec,"comments") ne $comments){
         $newrec->{comments}=$comments;
      }

      if (!defined($oldrec)){
         msg(INFO,"$self Insert INS:".Dumper($newrec));
         $dataobj->{mgrp}->ValidatedInsertRecord($newrec);
      }
      else{
         if ($oldrec->{cistatusid}>5 && $newrec->{cistatusid}<6){
            msg(INFO,"check reactivation of metassigment group");
            my $chkname=effVal($oldrec,$newrec,"fullname");
            $chkname=~s/\[[0-9]+\]$//;
            if ($chkname ne ""){
               $dataobj->{mgrp}->SetFilter({fullname=>\$chkname});
               my @l=$dataobj->{mgrp}->getHashList(qw(ALL));
               if ($#l!=-1 && $l[0]->{id} ne $oldrec->{id}){
                  msg(INFO,"no reactivation, ".
                           "because record with same name already exists");
                  $newrec=undef;
               }
            }
            else{
               msg(INFO,"no reactivation, because new name can not be created");
               $newrec=undef;
            }
         }
         #if ($oldrec->{cistatusid}>4 && $newrec->{cistatusid}>4){
         #   msg(INFO,"no updates on old records");
         #   $newrec=undef;
         #}
         if (defined($newrec)){
            $dataobj->{mgrp}->ValidatedUpdateRecord($oldrec,$newrec,{
               id=>$oldrec->{id}
            });
         }
      }
   }
}


1;
