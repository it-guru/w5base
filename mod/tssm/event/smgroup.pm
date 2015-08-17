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

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->{timeout}=1800;

   return($self);
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
         view=>[qw(mdate fullname)]
      },
      {
         dataobj=>$agrp,
         recpos=>1,
         initflt=>{deleted=>\'0'},
         view=>[qw(mdate fullname)]
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
      if ($queryparam ne "reset"){
         if (defined($start)){
            $flt->{mdate}='>="'.$start.'"';
         }
      }
      else{
         msg(WARN,"quering without start parameter - reset is selected");
      }
      if ($queryparam ne "" && $queryparam ne "reset"){
            $flt->{fullname}=\$queryparam;
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
      msg(INFO,"store queryparam $queryparam for ".$dataobj->Self);
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


   if ($queryparam eq ""){
      $mgrp->ResetFilter();    # Refresh process
      $mgrp->SetFilter({cistatusid=>"<6"});
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

   if (!defined($oldrec)){         # records from SM or AM
      if (defined($sgrprec)){
         $dataobj->{mgrp}->SetFilter({smid=>\$sgrprec->{id}});
      }
      elsif (defined($agrprec)){
         $dataobj->{mgrp}->SetFilter({amid=>\$agrprec->{lgroupid}});
      }
      else{
         die('havy problem');
      }
      $dataobj->{mgrp}->SetCurrentOrder("NONE");
      my ($r,$msg)=$dataobj->{mgrp}->getOnlyFirst(qw(ALL));
      if (!defined($r)){  # mit Ids war der Datensatz nicht zu finden
         $dataobj->{mgrp}->ResetFilter();
         if (defined($sgrprec)){
            $dataobj->{mgrp}->SetFilter({fullname=>\$sgrprec->{fullname}});
         }
         elsif (defined($agrprec)){
            $dataobj->{mgrp}->SetFilter({fullname=>\$agrprec->{fullname}});
         }
         else{
            die('havy problem');
         }
         ($r,$msg)=$dataobj->{mgrp}->getOnlyFirst(qw(ALL));
      }
      $oldrec=$r;
   }
   if (!defined($sgrprec)){        # refresh records
      if (defined($oldrec)){
         $dataobj->{sgrp}->SetFilter({id=>\$oldrec->{smid}});
        
         $dataobj->{sgrp}->SetCurrentOrder("NONE");
         my ($r,$msg)=$dataobj->{sgrp}->getOnlyFirst(qw(ALL));
         $sgrprec=$r;
      }
   }
   if (!defined($agrprec)){        # read additional AssetManager Data
      my $sflt;
      if (defined($oldrec) && $oldrec->{amid} ne ""){
         $sflt={lgroupid=>\$oldrec->{amid}};
      }
      elsif (defined($sgrprec)){
         if ($sgrprec->{fullname} ne ""){
            $sflt={deleted=>\'0',fullname=>\$sgrprec->{fullname}};
         }
      }
      if (defined($sflt)){
         $dataobj->{agrp}->SetFilter($sflt);
         my @l=$dataobj->{agrp}->getHashList(qw(ALL));
         if ($#l>0){
            my %n;
            map({$n{$_->{fullname}}++} @l);
            msg(ERROR,"not unique group for search on %s",join(", ",keys(%n)));
         }
         elsif ($#l==0){
           $agrprec=$l[0];
         }
         my ($r,$msg)=$dataobj->{agrp}->getOnlyFirst(qw(ALL));
         $agrprec=$r;
         
      }
   }


   if (!defined($cgrprec)){        # read additional ServiceCenter Data
      my $sflt;
      if (defined($oldrec) && $oldrec->{scid} ne ""){
         $sflt={id=>\$oldrec->{scid}};
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
   if (defined($sgrprec) || defined($cgrprec) || defined($agrprec)){  # General
      $newrec->{chkdate}=NowStamp("en");
      $newrec->{srcload}=NowStamp("en");
      $newrec->{cistatusid}=4;
   }
   else{
      $newrec->{chkdate}=NowStamp("en");
      $newrec->{cistatusid}=5;
   }

   if (defined($sgrprec)){                            # SM Handling
      if (!defined($oldrec) || $oldrec->{smid} ne $sgrprec->{id}){
         $newrec->{smid}=$sgrprec->{id};
      }
      $newrec->{smdate}=NowStamp("en");
   }
   else{
      if (defined($oldrec)){
         $newrec->{smid}=undef   if ($oldrec->{smid} ne "");
         $newrec->{smdate}=undef if ($oldrec->{smdate} ne "");
      }
   }

   if (defined($cgrprec)){                            # SC Handling
      if (!defined($oldrec) || $oldrec->{scid} ne $cgrprec->{id}){
         $newrec->{scid}=$cgrprec->{id};
      }
      $newrec->{scdate}=NowStamp("en");
   }
   else{  # war mal da, ist nun aber wieder weg
      if (defined($oldrec)){
         $newrec->{scid}=undef   if ($oldrec->{scid} ne "");
         $newrec->{scdate}=undef if ($oldrec->{scdate} ne "");
      }
   }

   if (defined($agrprec)){                            # AM Handling
      if (!defined($oldrec) || $oldrec->{amid} ne $agrprec->{lgroupid}){
         $newrec->{amid}=$agrprec->{lgroupid};
      }
      $newrec->{amdate}=NowStamp("en");
      if (defined($oldrec)){   # rename check
         if ($oldrec->{fullname} ne $agrprec->{fullname}){ # rename event
            msg(INFO,"rename detected on metagroup id $oldrec->{id}\n".
                     "from '$oldrec->{fullname}' to '$agrprec->{fullname}'");
            $dataobj->{sgrp}->SetFilter({fullname=>\$agrprec->{fullname}});
            $dataobj->{sgrp}->SetCurrentOrder("NONE");
            my ($r,$msg)=$dataobj->{sgrp}->getOnlyFirst(qw(ALL));
            if (defined($r)){
               $sgrprec=$r;
               $newrec->{fullname}=$sgrprec->{fullname};
               $newrec->{smid}=$sgrprec->{id};
               $newrec->{cistatusid}=4;
               $newrec->{srcload}=$sgrprec->{mdate};
            }
         }
      }
   }
   else{  # war mal da, ist nun aber wieder weg
      if (defined($oldrec)){
         $newrec->{amid}=undef   if ($oldrec->{amid} ne "");
         $newrec->{amdate}=undef if ($oldrec->{amdate} ne "");
      }
   }

   if (!defined($oldrec)){
      if (defined($sgrprec)){
         $newrec->{fullname}=$sgrprec->{fullname};
      }
      elsif (defined($agrprec)){
         $newrec->{fullname}=$agrprec->{fullname};
      }
      $newrec->{smid}=$sgrprec->{id};
      $newrec->{srcsys}=$firstseenon;
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


1;
