package CRaS::event::CRaSVerfiyDubs;
#  W5Base Framework
#  Copyright (C) 2025  Hartmut Vogler (it@guru.de)
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



sub CRaSVerfiyDubs
{
   my $self=shift;

   my $CsrDubCount=0;
   my $CsrCheckCount=0;

   my $csr=$self->getPersistentModuleObject("csr","CRaS::csr");

   $csr->SetFilter({state=>['1','5']});

   my @chkList=$csr->getHashList(qw(state name cdate mdate id));
   my %renewRequest=();

   foreach my $csrrec (@chkList){
      $CsrCheckCount++;
      if ($csrrec->{state} eq "5"){
         $renewRequest{$csrrec->{name}}++;
      }
   }
   msg(INFO,"CRaS: CsrCheckCount=$CsrCheckCount");
   foreach my $reqName (sort(keys(%renewRequest))){
      if ($renewRequest{$reqName} ne "1"){
         msg(WARN,"CRaS: inconsistent renew count ".$renewRequest{$reqName}.
                  " for CN=".$reqName);
         $CsrDubCount++;
      }
   }

   my %capturedRequest;
   foreach my $csrrec (@chkList){
      if ($csrrec->{state} eq "1"){
         $capturedRequest{$csrrec->{name}}++;
      }
   }


   foreach my $reqName (sort(keys(%renewRequest))){
      if (exists($capturedRequest{$reqName})){
         if ($capturedRequest{$reqName}>1){
            msg(WARN,"doublicate renew requests from ".$reqName.
                     " in state captured");
            $CsrDubCount++;
         }
      }
   }

#   printf STDERR ("renewRequest=%s\n",Dumper(\%renewRequest));
#   printf STDERR ("capturedRequest=%s\n",Dumper(\%capturedRequest));

   if ($CsrDubCount>0){
      return({exitcode=>1,exitmsg=>'DubCount:'.$CsrDubCount});
   }

   return({exitcode=>0,exitmsg=>'OK'});
}




