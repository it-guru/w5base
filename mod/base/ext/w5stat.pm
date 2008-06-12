package base::ext::w5stat;
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
use kernel::Universal;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}


sub processData
{
   my $self=shift;
   my $monthstamp=shift;
   my $currentmonth=shift;
   my ($year,$month)=$monthstamp=~m/^(\d{4})(\d{2})$/;
   my $count;


   msg(INFO,"starting collect of base::grp");
   my $grp=getModuleObject($self->getParent->Config,"base::grp");
   $grp->SetFilter({cistatusid=>\"4"});
   $grp->SetCurrentView(qw(ALL));
   msg(INFO,"getFirst of base::grp");$count=0;
   my ($rec,$msg)=$grp->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord('base::grp',$monthstamp,$rec);
         $count++;
         ($rec,$msg)=$grp->getNext();
      } until(!defined($rec));
   }
   msg(INFO,"FINE of base::grp $count records");


   my @wfstat=qw(id eventstart class step eventend stateid
                          fwdtarget fwdtargetid responsiblegrp);


   my $wf=getModuleObject($self->getParent->Config,"base::workflow");

   msg(INFO,"starting collect of base::workflow set1.1");
   $wf->SetFilter({eventend=>">=$month/$year AND <$month/$year+1M"});
   # not posible because sequential search
   #               {eventstart=>">=$month/$year AND <$month/$year+1M"}]);
   #               {eventstart=>"<$month/$year",eventend=>">$month/$year+1M"}]);
   $wf->SetCurrentView(@wfstat);
   $wf->SetCurrentOrder("NONE");
   my $c=0;

   msg(INFO,"getFirst of base::workflow set1.1");$count=0;
   my ($rec,$msg)=$wf->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord('base::workflow::active',
                                         $monthstamp,$rec);
         $count++;
         $c++;
         ($rec,$msg)=$wf->getNext();
      } until(!defined($rec));
   }
   msg(INFO,"FINE of base::workflow set1.1 $count records");

   msg(INFO,"starting collect of base::workflow set1.2");
   $wf->SetFilter({eventend=>"[EMPTY]"});
   $wf->SetCurrentView(@wfstat);
   $wf->SetCurrentOrder("NONE");
   my $c=0;

   msg(INFO,"getFirst of base::workflow set1.2");$count=0;
   my ($rec,$msg)=$wf->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord('base::workflow::active',
                                         $monthstamp,$rec);
         $count++;
         $c++;
         ($rec,$msg)=$wf->getNext();
      } until(!defined($rec));
   }
   msg(INFO,"FINE of base::workflow set1.2 $count records");

   msg(INFO,"starting collect of base::workflow set2");
   $wf->ResetFilter();
   $wf->SetFilter([{stateid=>"<20",fwdtarget=>'![EMPTY]'}]);
   $wf->SetCurrentView(@wfstat);
   $wf->SetCurrentOrder("NONE");
   my $c=0;

   msg(INFO,"getFirst of base::workflow set2");$count=0;
   my ($rec,$msg)=$wf->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord('base::workflow::notfinished',
                                         $monthstamp,$rec);
         $c++;
         $count++;
         ($rec,$msg)=$wf->getNext();
      } until(!defined($rec));
   }
   msg(INFO,"FINE of base::workflow set2 $count records");


}

sub processRecord
{
   my $self=shift;
   my $module=shift;
   my $month=shift;
   my $rec=shift;

   if ($module eq "base::grp"){
      my $name=$rec->{fullname};
      my $users=$rec->{users};
      $users=[] if (ref($users) ne "ARRAY");
      my $subunits=$rec->{subunits};
      $subunits=[] if (ref($subunits) ne "ARRAY");

      my $subunitcount=$#{$subunits}+1;
      my $userscount=$#{$users}+1;


      $self->getParent->storeStatVar("Group",$name,{key=>$rec->{grpid}},
                                     "Groups",1);
      $self->getParent->storeStatVar("Group",$name,{maxlevel=>0},
                                     "SubGroups",$subunitcount);

      $self->getParent->storeStatVar("Group",$name,{},"User",$userscount);
      $self->getParent->storeStatVar("Group",$name,{maxlevel=>0},
                                     "User.Direct",$userscount);
   }
   elsif ($module eq "base::workflow::notfinished"){
      if ($rec->{class} eq "base::workflow::DataIssue"){
         if (ref($rec->{responsiblegrp}) eq "ARRAY"){
            foreach my $resp (@{$rec->{responsiblegrp}}){
               $self->getParent->storeStatVar("Group",$resp,{},
                                              "base.DataIssue.open",1);
            }
         }
         msg(DEBUG,"response %s\n",Dumper($rec->{responsiblegrp}));
      }
   }
}


1;
