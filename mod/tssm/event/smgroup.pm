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
               isapprover
               admingroup);

our @AMVIEW=qw(mdate fullname supervisoremail);


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
   my $cgrp=getModuleObject($self->Config,"tssc::group");
   my $opagrp=$agrp->Clone();
   my $opsgrp=$sgrp->Clone();
   my $opmgrp=$mgrp->Clone();
   my $opcgrp=$cgrp->Clone();
   my %dataobj=(agrp=>$opagrp,sgrp=>$opsgrp,mgrp=>$opmgrp,cgrp=>$opcgrp);

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
         msg(WARN,"quering without start parameter - ".
                  "reset or direct group selected");
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
      $mgrp->Limit(20,1);
      my ($mgrprec,$msg)=$mgrp->getFirst();
      if (defined($mgrprec)){
         do{
            msg(INFO,"process refresh $mgrprec->{fullname} $mgrprec->{mdate}");
            $self->handleSRec(\%dataobj,undef,$mgrprec);
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
   my $cgrprec=shift;

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
            $dataobj->{mgrp}->SetFilter({fullname=>\$fullname});
         }
         else{
            die('havy problem');
         }
         ($r,$msg)=$dataobj->{mgrp}->getOnlyFirst(qw(ALL));
         if (defined($r)){
            msg(WARN,"$msgnote w5baseid=$r->{id} fullname=$r->{fullname}");
         }
      }
      $oldrec=$r;
   }
   if (!defined($sgrprec)){        # refresh records
      if (defined($oldrec) && $oldrec->{smid} ne ""){
         my $smid=$oldrec->{smid};
         $dataobj->{sgrp}->SetFilter({id=>\$smid});
        
         $dataobj->{sgrp}->SetCurrentOrder("NONE");
         my ($r,$msg)=$dataobj->{sgrp}->getOnlyFirst(@SMVIEW);
         $sgrprec=$r;
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


   if (!defined($cgrprec)){        # read additional ServiceCenter Data
      my $sflt;
      if (defined($oldrec) && $oldrec->{scid} ne ""){
         $sflt={id=>\$oldrec->{scid}};
      }
      elsif (defined($oldrec) && $oldrec->{fullname} ne ""){
         $sflt={fullname=>\$oldrec->{fullname}};
      }
      elsif (defined($sgrprec)){
         if ($sgrprec->{fullname} ne ""){
            $sflt={fullname=>\$sgrprec->{fullname}};
         }
      }
      if (defined($sflt)){
         $dataobj->{cgrp}->SetFilter($sflt);
         my ($r,$msg)=$dataobj->{cgrp}->getOnlyFirst(qw(ALL));
         $cgrprec=$r;
      }
   }



   my $newrec;
   $newrec->{chkdate}=NowStamp("en");
   if (defined($sgrprec) || defined($cgrprec) || defined($agrprec)){  # General
      $newrec->{chkdate}=NowStamp("en");
      $newrec->{srcload}=NowStamp("en");
      $newrec->{cistatusid}=4;
   }

   if (defined($sgrprec)){                            # SM Handling
      if ($sgrprec->{fullname} ne exttrim($sgrprec->{fullname})){
         push(@comments,"leading or trailing whitespaces on group ".
                       "'".exttrim($sgrprec->{fullname})."' in ServiceManager");
      }
      if (!defined($oldrec) || $oldrec->{smid} ne $sgrprec->{id}){
         $newrec->{smid}=$sgrprec->{id};
      }

      my @fldmap=('isapprover'     =>'ischmapprov',
                  'isinmassignment'=>'isinmassign',
                  'admingroup'     =>'smadmgrp',
                  'ismanager'      =>'ischmmgr',
                  'isimplementor'  =>'ischmimpl',
                  'iscoordinator'  =>'ischmcoord');
      while(my ($sfld,$fld)=splice(@fldmap,0,2)){
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

   if (defined($cgrprec)){                            # SC Handling
      if ($cgrprec->{fullname} ne exttrim($cgrprec->{fullname})){
         push(@comments,"leading or trailing whitespaces on group ".
                        "'".exttrim($cgrprec->{fullname})."' in ServiceCenter");
      }
      if (!defined($oldrec) || $oldrec->{scid} ne $cgrprec->{id}){
         $newrec->{scid}=$cgrprec->{id};
      }
      $newrec->{scdate}=NowStamp("en");
   }

   if (defined($agrprec)){                            # AM Handling
      if ($agrprec->{fullname} ne exttrim($agrprec->{fullname})){
         push(@comments,"leading or trailing whitespaces on group ".
                        "'".exttrim($agrprec->{fullname})."' in AssetManager");
      }
      if (!defined($oldrec) || $oldrec->{amid} ne $agrprec->{lgroupid}){
         $newrec->{amid}=$agrprec->{lgroupid};
      }
      $newrec->{amdate}=NowStamp("en");

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
         if ($oldrec->{fullname} ne exttrim($agrprec->{fullname})){ # rename op
            msg(WARN,"rename detected on metagroup id $oldrec->{id}\n".
                     "from '$oldrec->{fullname}' to '$agrprec->{fullname}'");
            my $newfullname=exttrim($agrprec->{fullname});
            $dataobj->{sgrp}->SetFilter({fullname=>\$newfullname});
            $dataobj->{sgrp}->SetCurrentOrder("NONE");
            my ($srec,$msg)=$dataobj->{sgrp}->getOnlyFirst(@SMVIEW);
            if (defined($srec)){
               $sgrprec=$srec;
               $dataobj->{mgrp}->ResetFilter();
               $dataobj->{mgrp}->SetFilter({fullname=>\$newfullname});
               my ($chkrec,$msg)=$dataobj->{mgrp}->getOnlyFirst(qw(ALL));
               if (defined($chkrec)){ # group already created by f.e. SM9
                  msg(WARN,"group was already new created but it was ".
                           "a rename on id ".
                           "$chkrec->{id} - deaktivating this group now");
                  $dataobj->{mgrp}->ValidatedUpdateRecord($chkrec,{
                     cistatusid=>'6',
                     smid=>undef,
                     smdate=>undef,
                     amid=>undef,
                     amdate=>undef,
                     scid=>undef,
                     scdate=>undef,
                     comments=>'data trash by rename operation - '.
                               'SM bevor AM rename',
                     },{
                     id=>$chkrec->{id}
                  });
               }
               $newrec->{fullname}=$sgrprec->{fullname};
               $newrec->{smid}=$sgrprec->{id};
               $newrec->{cistatusid}=4;
               $newrec->{srcload}=$sgrprec->{mdate};
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
      foreach my $f (qw(smdate scdate amdate)){
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
      $newrec->{cistatusid}=6;   # länger als 6 Tage nirgends gesehen
   }
   elsif ($lastseen>3){
      $newrec->{cistatusid}=5;   # länger als 3 Tage nirgends gesehen
   }
   if ($lastseen>180){
      msg(WARN,"delete of group $oldrec->{fullname} in $self");
      $dataobj->{mgrp}->ValidatedDeleteRecord($oldrec);
   }
   else{
      if (!defined($oldrec)){
         if (defined($sgrprec)){
            $newrec->{fullname}=$sgrprec->{fullname};
         }
         elsif (defined($agrprec)){
            $newrec->{fullname}=$agrprec->{fullname};
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
      if ($istelit){
         if (exttrim($fullname)=~m/[^a-z0-9_.-]/i){
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
         #print STDERR "UPD:".Dumper($newrec);
         $dataobj->{mgrp}->ValidatedUpdateRecord($oldrec,$newrec,{
            id=>$oldrec->{id}
         });
      }
   }
}


1;
