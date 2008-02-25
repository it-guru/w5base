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
use Data::Dumper;
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


   $self->RegisterEvent("QualityCheck","QualityCheck");
   return(1);
}

sub QualityCheck
{
   my $self=shift;
   my $dataobj=shift;
   msg(DEBUG,"starting QualityCheck");
   my $lnkq=getModuleObject($self->Config,"base::lnkqrulemandator");
   my %dataobjtocheck;
   if ($dataobj eq ""){
      $lnkq->ResetFilter();
      $lnkq->SetCurrentView("dataobj");
      my ($rec,$msg)=$lnkq->getFirst();
      if (defined($rec)){
         do{
            $dataobjtocheck{$rec->{dataobj}}++;
            ($rec,$msg)=$lnkq->getNext();
         }until(!defined($rec));
      }
   }
   else{
      my $obj=getModuleObject($self->Config,$dataobj);
      if (defined($obj)){
         return($self->doQualityCheck($obj));
      }
      else{
         return({exitcode=>1,msg=>"invalid dataobject '$dataobj' specified"});
      }
   }
   foreach my $dataobj (sort(keys(%dataobjtocheck))){
      if ($dataobj ne ""){
         msg(INFO,"calling QualityCheck for '$dataobj'");
         my $bk=$self->W5ServerCall("rpcCallEvent","QualityCheck",$dataobj);
         if (!defined($bk->{AsyncID})){
            msg(ERROR,"can't call QualityCheck for dataobj '$dataobj' Event");
         }
      }
   }
   
   return({exitcode=>0,msg=>'ok'});
}

sub doQualityCheck
{
   my $self=shift;
   my $dataobj=shift;
 
   msg(INFO,"doQualityCheck in Object $dataobj");
   $dataobj->ResetFilter();
   my @flt;
   if ($dataobj->getField("cistatusid")){
      push(@flt,{cistatusid=>[3,4]});
   }
   if ($dataobj->getField("mdate")){
      push(@flt,{mdate=>">now-28d"});
   }
   $dataobj->SetFilter(\@flt);
   $dataobj->SetCurrentView("qcok");

   my ($rec,$msg)=$dataobj->getFirst();
   if (defined($rec)){
      do{
         msg(DEBUG,"qcok=$rec->{qcok}");
         ($rec,$msg)=$dataobj->getNext();
      }until(!defined($rec));
   }


   return({exitcode=>0,msg=>'ok'});
}
1;
