package tssm::event::smgroup;
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
use tssm::lib::io;
@ISA=qw(kernel::Event tssm::lib::io);

our @SMVIEW=qw(mdate fullname
               iscoordinator isimplementor ismanager isinmassignment 
               isapprover isrespall
               admingroup);

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
   $out=~s/[^A-Z.0-9&a-z_+@���\/(:#!,)���-]*$//;
   $out=~s/^[^A-Z.0-9&a-z_+@���\/(:#!,)���-]*//;
   return($out);
}

sub Init
{
   my $self=shift;


   $self->RegisterEvent("smgroup","smgroup",timeout=>$self->{timeout});
}

sub smgroup
{
   my $self=shift;
   my $queryparam=shift;

   

   my $joblog=getModuleObject($self->Config,"base::joblog");
   my $sgrp=getModuleObject($self->Config,"tssm::group");
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


   my $srcsys=$self->Self;

   my @incloader=(
      {
         dataobj=>$sgrp,
         recpos=>0,
         initflt=>{active=>1},
         view=>\@SMVIEW
      },
      {
         dataobj=>$agrp,
         recpos=>1,
         initflt=>{deleted=>\'0'},
         view=>\@AMVIEW
      }
   );

   # for refresh-debugging clear incloader
   my @incloader=();

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
            $flt->{fullname}=$queryparam;
      }
      #printf STDERR ("fifi flt=%s\n",Dumper($flt));
      $dataobj->SetCurrentView(@{$incloader->{view}});
      $dataobj->SetCurrentOrder("mdate");
      $dataobj->SetFilter($flt);
      my ($grprec,$msg)=$dataobj->getFirst();
      my $laststamp;
      if (defined($grprec)){
         my $c=0;
         do{
            msg(INFO,"process $grprec->{fullname} $grprec->{mdate}");
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
         }until(!defined($grprec) || $c++>100);
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
         my $smid=$sgrprec->{id};
         $dataobj->{mgrp}->SetFilter({smid=>\$smid});
         $msgnote="join smid=$smid to";
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
         my $smcheck;
         if ($oldrec->{smid} ne ""){
            $smcheck=$oldrec->{smid};
         }
         else{
            my $chksmid=$oldrec->{fullname};
            $chksmid=~s/\[\d+\]$//;
            $smcheck=$chksmid;
         }
         if ($smcheck ne ""){
            $dataobj->{sgrp}->SetFilter({id=>\$smcheck});
            $dataobj->{sgrp}->SetCurrentOrder("NONE");
            my ($r,$msg)=$dataobj->{sgrp}->getOnlyFirst(@SMVIEW);
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

   my @smfldmap=('isapprover'     =>'ischmapprov',
                 'isinmassignment'=>'isinmassign',
                 'admingroup'     =>'smadmgrp',
                 'ismanager'      =>'ischmmgr',
                 'isimplementor'  =>'ischmimpl',
                 'iscoordinator'  =>'ischmcoord',
                 'isrespall'      =>'isresp4all'
   );
   if (defined($sgrprec)){                            # SM Handling
      if ($sgrprec->{fullname} ne exttrim($sgrprec->{fullname})){
         push(@comments,"leading or trailing whitespaces on group ".
                       "'".exttrim($sgrprec->{fullname})."' in ServiceManager");
      }
      if ($sgrprec->{fullname} ne uc($sgrprec->{fullname})){
         push(@comments,"invalid lower case characters on group ".
                       "'".exttrim($sgrprec->{fullname})."' in ServiceManager");
      }
      if (!defined($oldrec) || $oldrec->{smid} ne $sgrprec->{id}){
         $newrec->{smid}=$sgrprec->{id};
      }

      while(my ($sfld,$fld)=splice(@smfldmap,0,2)){
         if (!defined($oldrec) || 
             $oldrec->{$fld} ne $sgrprec->{$sfld}){
            $newrec->{$fld}=$sgrprec->{$sfld};
         }
      }

      my $groupmailbox=exttrim($sgrprec->{groupmailbox});
      if ($groupmailbox ne ""){
         $groupmailbox=~s/[,;].*//; # use only first, if multiple specified
         $groupmailbox=trim($groupmailbox);
         if (!($groupmailbox=~m/^\S+\@\S+\.\S+$/)){
            push(@comments,"invalid groupmailbox format in ServiceManager");
         }
         else{
            if (!defined($oldrec) || 
                $oldrec->{contactemail} ne $groupmailbox){
               $newrec->{contactemail}=$groupmailbox;
            }
         }
      }
      $newrec->{smdate}=NowStamp("en");
   }
   else{
      my $resetsmflags=1;
      if (defined($oldrec) && $oldrec->{smdate} ne ""){
         $resetsmflags=0;
         my $nowstamp=NowStamp("en");
         my $dur=CalcDateDuration($oldrec->{smdate},$nowstamp);
         if (defined($dur)){
            if ($dur->{totaldays}>14){
               $resetsmflags=1;
            }
         }
      }

     
      if ($resetsmflags){ 
         foreach my $fld (values(@smfldmap)){
            if (!defined($oldrec) || 
                $oldrec->{$fld} ne ""){
               $newrec->{$fld}=undef;
            }
         }
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
               my ($srec,$msg)=$dataobj->{sgrp}->getOnlyFirst(@SMVIEW);
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
                     smid=>undef,
                     smdate=>undef,
                     smadmgrp=>undef,
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
                  $newrec->{smid}=$sgrprec->{id};
               }
               else{
                  $newrec->{smid}=undef;
                  $newrec->{smdate}=undef;
                  $newrec->{smadmgrp}=undef;
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
      foreach my $f (qw(smdate amdate mdate)){
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
   }
   msg(INFO,"lastseen = $lastseen");

   my $istelit=0;
   my $fullname=effVal($oldrec,$newrec,"fullname");
   if (($fullname=~m/^(TIT)([. ][^.]+)*$/)){
      $istelit=1;
   }
   if ($lastseen>6){
      $newrec->{cistatusid}=6;   # l�nger als 6 Tage nirgends gesehen
   }
   elsif ($lastseen>3){
      $newrec->{cistatusid}=5;   # l�nger als 3 Tage nirgends gesehen
   }
   if ($lastseen>180){
      #msg(WARN,"delete of group $oldrec->{fullname} in $self");
      $dataobj->{mgrp}->ValidatedDeleteRecord($oldrec);
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
         #print STDERR "INS:".Dumper($newrec);
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
