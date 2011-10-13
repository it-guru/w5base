package itcrm::event::mig;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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


   $self->RegisterEvent("MigrateITCRMdata","mig");
   return(1);
}

sub mig
{
   my $self=shift;

   my $objname="TCOM::custappl";
   msg(INFO,"Start migration of $objname");
   if (my $o=getModuleObject($self->Config,$objname)){
      my $wr=$o->Clone();
      $o->SetCurrentOrder(qw(NONE));
      $o->SetCurrentView(qw(businessownerid itmanagerid wbvid id));
      my ($rec,$msg)=$o->getFirst(unbuffered=>1);
      if (defined($rec)){
         do{
            if ($rec->{'wbvid'} ne "" && $rec->{id} ne ""){
               msg(INFO,"process $rec->{id} in $objname");
               $wr->ValidatedUpdateRecord($rec,{itmanagerid=>$rec->{wbvid}},
                                          {id=>$rec->{id}});
            }
            ($rec,$msg)=$o->getNext();
         } until(!defined($rec));
      }
   }
   
   my $objname="GHS::custappl";
   msg(INFO,"Start migration of $objname");
   if (my $o=getModuleObject($self->Config,$objname)){
      my $wr=$o->Clone();
      $o->SetCurrentOrder(qw(NONE));
      $o->SetCurrentView(qw(businessownerid itmanagerid itmgrid id));
      my ($rec,$msg)=$o->getFirst(unbuffered=>1);
      if (defined($rec)){
         do{
            if ($rec->{'itmgrid'} ne "" && $rec->{id} ne ""){
               msg(INFO,"process $rec->{id} in $objname");
               $wr->ValidatedUpdateRecord($rec,{itmanagerid=>$rec->{itmgrid}},
                                          {id=>$rec->{id}});
            }
            ($rec,$msg)=$o->getNext();
         } until(!defined($rec));
      }
   }

   return({exitcode=>0,msg=>'ok'});
}

1;
