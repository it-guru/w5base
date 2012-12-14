package base::event::QualityCheck;
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

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;

   my $qualitycheckduration=$self->Config->Param("QualityCheckDuration");
   $qualitycheckduration="600" if ($qualitycheckduration eq "");
   $self->{qualitycheckduration}=$qualitycheckduration;



   $self->RegisterEvent("QualityCheck","QualityCheck",
                        timeout=>$self->{qualitycheckduration}+120); 
   return(1);
}

sub QualityCheck
{
   my $self=shift;
   my $dataobj=shift;
   msg(DEBUG,"starting QualityCheck");
   my %dataobjtocheck=$self->LoadQualitCheckActivationLinks();
   #msg(INFO,Dumper(\%dataobjtocheck));
   if ($dataobj eq ""){
      foreach my $dataobj (sort(keys(%dataobjtocheck))){
            msg(INFO,"calling QualityCheck for '$dataobj'");
            my $bk=$self->W5ServerCall("rpcCallEvent","QualityCheck",$dataobj);
            if (!defined($bk->{AsyncID})){
               msg(ERROR,"can't call QualityCheck for ".
                         "dataobj '$dataobj' Event");
            }
      }
   }
   else{
      my $obj=getModuleObject($self->Config,$dataobj);
      if (defined($obj)){
         my $basefilter;
         if (!grep(/^0$/,keys(%{$dataobjtocheck{$dataobj}})) &&
             $dataobj ne "base::workflow"){
            msg(INFO,"set (basefilter) mandatorid filter='%s'",
                     join(",",keys(%{$dataobjtocheck{$dataobj}})));
            $basefilter={mandatorid=>[keys(%{$dataobjtocheck{$dataobj}})]};
         }
         return($self->doQualityCheck($basefilter,$obj));
      }
      else{
         return({exitcode=>1,msg=>"invalid dataobject '$dataobj' specified"});
      }
   }
   
   return({exitcode=>0,msg=>'ok'});
}

sub doQualityCheck
{
   my $self=shift;
   my $basefilter=shift;
   my $dataobj=shift;
 
   msg(INFO,"doQualityCheck in Object $dataobj");

   my @view=("qcok");
   if (my $lastqcheck=$dataobj->getField("lastqcheck")){
      unshift(@view,"lastqcheck");
   }
   my $idfieldobj=$dataobj->IdField();
   if (defined($idfieldobj)){
      push(@view,$idfieldobj->Name());
   }
   my $qualitycheckduration=$self->{qualitycheckduration};
   my $time=time();
   my $total=0;
   my $c=0;
   my $loopmax=10;
   my $firstid;
   do{
      $dataobj->ResetFilter();
      if (defined($basefilter)){
         $dataobj->SetNamedFilter("MANDATORID",$basefilter);
      }
      if (!($dataobj->SetFilterForQualityCheck(@view))){
         return({exitcode=>0,msg=>'ok'});
      }
      $dataobj->Limit($loopmax,0,0);
      my ($rec,$msg)=$dataobj->getFirst(unbuffered=>1);
      $c=0;
      if (defined($rec)){
         do{
            msg(DEBUG,"check record start");
            my $qcokobj=$dataobj->getField("qcok");
            if (defined($qcokobj)){
               my $qcok=$qcokobj->RawValue($rec); 
               msg(DEBUG,"qcok=$rec->{qcok}");
            }
            else{
               return({exitcode=>1,msg=>'no qcok field'});
            }
            $total++;
            $c++;
            my $curidname=$idfieldobj->Name();
            my $curid=$idfieldobj->RawValue($rec);
            if ($self->LastMsg()>0){
               msg(ERROR,"error messages while check of ".
                         $curidname."='".$curid."' in ".
                         $dataobj->Self());
               $self->LastMsg("");
            }
            msg(DEBUG,"check record end");
            if ( $curid eq $firstid){ 
               return({exitcode=>0,
                       msg=>'ok '.$total.' records checked = all'});
            }
            if (time()-$time>$qualitycheckduration){ 
               msg(DEBUG,"Quality check end by ".
                         "QualityCheckDuration=$qualitycheckduration");
               return({exitcode=>0,
                       msg=>'ok '.$total.' records checked = partial'});
               last;
            }
            if (!defined($firstid)){
               $firstid=$curid;
            }
            ($rec,$msg)=$dataobj->getNext();
         }until(!defined($rec) ||  $c>=$loopmax-1);
      }
      if (!defined($rec)){
         msg(DEBUG,"rec not defined - end of loop check");
         last;
      }
      sleep(1);
   }until(0);


   return({exitcode=>0,msg=>'ok'});
}


sub LoadQualitCheckActivationLinks
{
   my $self=shift;

   my $lnkq=getModuleObject($self->Config,"base::lnkqrulemandator");
   my %dataobjtocheck;
   $lnkq->ResetFilter();
   $lnkq->SetCurrentView("dataobj","mandatorid");
   my ($rec,$msg)=$lnkq->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         msg(INFO,"dataobject=$rec->{dataobj} ".
                  "mandatorid=$rec->{mandatorid}");
         if ($rec->{dataobj} ne ""){
            my $mandatorid=$rec->{mandatorid};
            $mandatorid=0 if (!defined($mandatorid));
            if ($rec->{dataobj}=~m/::workflow::/){
               $dataobjtocheck{'base::workflow'}->{$mandatorid}++;
            }
            else{
               $dataobjtocheck{$rec->{dataobj}}->{$mandatorid}++;
            }
         }
         ($rec,$msg)=$lnkq->getNext();
      }until(!defined($rec));
   }
   return(%dataobjtocheck);
}

1;
