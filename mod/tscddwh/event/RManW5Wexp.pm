package tscddwh::event::RManW5Wexp;
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

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}


sub RManW5Wexp
{
   my $self=shift;
   my $debugwfid=shift;
   my $exitcode=0;

   my $wf=getModuleObject($self->Config,"base::workflow");
   my $wf2=getModuleObject($self->Config,"base::workflow");
   my $os=getModuleObject($self->Config,"W5Warehouse::objectsnap");

   $os->SnapStart("RMAWF");

   my %baseq;
   my @q;
   $baseq{class}=[grep(/^.*::(riskmgmt)$/,keys(%{$wf->{SubDataObj}}))];
   $baseq{isdeleted}=\'0';
   #$baseq{id}='15377719300021';

   {
      my %q=%baseq;
      $q{mdate}=">now-60d";
      push(@q,\%q);
   }
   {
      my %q=%baseq;
      $q{stateid}="<20";
      push(@q,\%q);
   }

   if ($debugwfid eq ""){
      $wf->SetFilter(\@q);
   }
   else{
      $wf->SetFilter({id=>\$debugwfid});
   }
   

   

   $wf->SetCurrentView(qw(
      name
      affectedapplication
      affectedapplicationid
      wffields.riskmgmtpoints
      wffields.riskbasetype
      wffields.extdescriskimpact
      wffields.extdescriskoccurrency
      wffields.extdescarisedate
      wffields.extdescdtagmonetaryimpact
      wffields.extdesctelitmonetaryimpact
      wffields.extdescriskdowntimedays
      wffields.ibipoints
      wffields.ibiprice
      wffields.riskmgmtcondition
      wffields.solutionopt
      wffields.itrmcriticality
      mdate
      cdate
      mandator
      mandatorid
      eventstart
      eventend
      detaildescription
      state
      relations
      id
   ));

   $wf->SetCurrentOrder(qw(mdate));

   my @fancy=qw(state 
      wffields.riskmgmtpoints
      wffields.riskbasetype
      wffields.extdescriskoccurrency
      wffields.extdescarisedate
      wffields.extdescdtagmonetaryimpact
      wffields.extdesctelitmonetaryimpact
      wffields.extdescriskdowntimedays
      wffields.ibipoints
      wffields.ibiprice
      wffields.riskmgmtcondition
      wffields.solutionopt
      wffields.applicationbase
   );


   my ($rec,$msg)=$wf->getFirst();
   if (defined($rec)){
      do{
          my %relids=();
          if (ref($rec->{relations}) eq "ARRAY"){
             foreach my $relrec (@{$rec->{relations}}){
                if ($relrec->{name} eq "riskmesure"){
                   $relids{$relrec->{dstwfid}}++;
                }
             }
          }
          if (keys(%relids)){
             $wf2->ResetFilter();
             $wf2->SetFilter({
                id=>[keys(%relids)],
                class=>\'itil::workflow::opmeasure'
             });
             my @l=$wf2->getHashList(qw(
                id 
                wffields.plannedstart 
                wffields.plannedend
                detaildescription
                eventstart
                eventend
                name
                shortactionlog
                state
             ));
             if ($#l!=-1){
                my @m;
                foreach my $mrec (@l){
                    my $subrec={
                       raw=>$mrec
                    };
                    for my $reqlang (qw(en de)){
                       $ENV{HTTP_FORCE_LANGUAGE}=$reqlang;
                       foreach my $fname (qw(state)){
                          my $fld=$wf2->getField($fname,$mrec);
                          my $xname=$fname;
                          $xname=~s/^.*\.//;
                          $subrec->{fancy}->{$reqlang}->{$xname}=
                             $fld->FormatedDetail($mrec,"XmlV01");
                       }
                       delete($ENV{HTTP_FORCE_LANGUAGE});
                    }
                    push(@m,$subrec);
                }
                $rec->{measureworkflow}=\@m;
             }
          }


          my $xrec={
             xmlroot=>{
                raw=>$rec
             }
          };
          for my $reqlang (qw(en de)){
             $ENV{HTTP_FORCE_LANGUAGE}=$reqlang;
             foreach my $fname (@fancy){
                my $fld=$wf->getField($fname,$rec);
                my $xname=$fname;
                $xname=~s/^.*\.//;
                $xrec->{xmlroot}->{fancy}->{$reqlang}->{$xname}=
                   $fld->FormatedDetail($rec,"XmlV01");
             }
             delete($ENV{HTTP_FORCE_LANGUAGE});
          }
          $xrec->{xmlroot}->{xmlstate}="OK";
          
          my $d=hash2xml($xrec);
          #print $d;
          if ($rec->{id} ne "15396714090001"){
             $os->SnapRecord($rec->{id},$rec->{name},"base::workflow",$d);
          }

          ($rec,$msg)=$wf->getNext();
       } until(!defined($rec));
   }
   $os->SnapEnd();


   return({exitcode=>$exitcode});
}




1;
