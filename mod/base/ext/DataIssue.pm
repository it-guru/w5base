package base::ext::DataIssue;
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
use kernel::Universal;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub getControlRecord
{
   my $self=shift;
   my $d=[ { dataobj=>'none' },
           {
             dataobj   =>'base::projectroom',
             target    =>'name',
             targetid  =>'id'
           },
           {
             dataobj   =>'base::user',
             target    =>'fullname',
             targetid  =>'userid'
           },
           {
             dataobj   =>'base::location',
             target    =>'name',
             targetid  =>'id'
           },
           {
             dataobj   =>'base::grp',
             target    =>'fullname',
             targetid  =>'grpid'
           },
           {
             dataobj   =>'base::mandator',
             target    =>'name',
             targetid  =>'id'
           },
           {
             dataobj   =>'base::workflow',
             target    =>'name',
             targetid  =>'id'
           },
           {
             dataobj   =>'base::campus',
             target    =>'fullname',
             targetid  =>'id'
           },
         ];


   return($d);
}



sub DataIssueCompleteWriteRequest
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $affectedobject=effVal($oldrec,$newrec,"affectedobject");

   if ($affectedobject=~m/^base::mandator$/){
      # create link to config Management
      $newrec->{directlnktype}=effVal($oldrec,$newrec,"affectedobject");
      $newrec->{directlnkid}=effVal($oldrec,$newrec,"affectedobjectid");
      $newrec->{directlnkmode}="DataIssue";
   }
   if ($affectedobject=~m/^base::grp$/){
      # create link to config Management
      $newrec->{directlnktype}=effVal($oldrec,$newrec,"affectedobject");
      $newrec->{directlnkid}=effVal($oldrec,$newrec,"affectedobjectid");
      $newrec->{directlnkmode}="DataIssue";
   }
   if ($affectedobject=~m/^base::user$/){
      $newrec->{directlnktype}=effVal($oldrec,$newrec,"affectedobject");
      $newrec->{directlnkid}=effVal($oldrec,$newrec,"affectedobjectid");
      $newrec->{directlnkmode}="DataIssue";
      $newrec->{fwdtarget}="base::user";
      $newrec->{fwdtargetid}=effVal($oldrec,$newrec,"affectedobjectid");
   }
   if ($affectedobject=~m/^base::workflow$/){
      $newrec->{directlnktype}=effVal($oldrec,$newrec,"affectedobject");
      $newrec->{directlnkid}=effVal($oldrec,$newrec,"affectedobjectid");
      $newrec->{directlnkmode}="DataIssue";
      my $obj=getModuleObject($self->getParent->Config,$affectedobject);
      my $affectedobjectid=effVal($oldrec,$newrec,"affectedobjectid");
      $obj->SetFilter(id=>\$affectedobjectid);
      my ($WfRec,$msg)=$obj->getOnlyFirst(qw(ALL));
      $newrec->{srcsys}=$WfRec->{class};
      if (defined($WfRec)){
         return($obj->DataIssueCompleteWriteRequest($oldrec,$newrec,$WfRec));
      }
   }
   if (($affectedobject=~m/::projectroom$/) ||
       ($affectedobject=~m/::location$/)){
      if (defined($newrec->{affectedobject}) &&
          $newrec->{affectedobject} eq $affectedobject){
         # create link to config Management
         $newrec->{directlnktype}=$newrec->{affectedobject};
         $newrec->{directlnkid}=$newrec->{affectedobjectid};
         $newrec->{directlnkmode}="DataIssue";
      }
      my $obj=getModuleObject($self->getParent->Config,$affectedobject);
      my $affectedobjectid=effVal($oldrec,$newrec,"directlnkid");
      $obj->SetFilter(id=>\$affectedobjectid);
      my ($confrec,$msg)=$obj->getOnlyFirst(qw(databossid mandatorid mandator
                                             office_costcenter office_accarea));
      if (defined($confrec)){
         if ($confrec->{databossid} ne ""){
            $newrec->{fwdtarget}="base::user";
            $newrec->{fwdtargetid}=$confrec->{databossid};
            $newrec->{involvedcostcenter}=$confrec->{office_costcenter};
            $newrec->{involvedaccarea}=$confrec->{office_accarea};
         }
         if ($confrec->{mandatorid} ne ""){
            $newrec->{kh}->{mandatorid}=$confrec->{mandatorid};
            if (!defined($newrec->{fwdtargetid}) ||
                 $newrec->{fwdtargetid} eq ""){
               $self->getParent->setClearingDestinations(
                                    $newrec,
                                    $confrec->{mandatorid});
            }
         }
         if ($confrec->{mandator} ne ""){
            $newrec->{kh}->{mandator}=$confrec->{mandator};
         }
      }
   }
   if ($affectedobject=~m/::campus$/) {
      if (defined($newrec->{affectedobject}) &&
          $newrec->{affectedobject} eq $affectedobject){
         # create link to config Management
         $newrec->{directlnktype}=$newrec->{affectedobject};
         $newrec->{directlnkid}=$newrec->{affectedobjectid};
         $newrec->{directlnkmode}="DataIssue";
      }
      my $obj=getModuleObject($self->getParent->Config,$affectedobject);
      my $affectedobjectid=effVal($oldrec,$newrec,"directlnkid");
      $obj->SetFilter(id=>\$affectedobjectid);
      my ($confrec,$msg)=$obj->getOnlyFirst(qw(databossid 
                                               office_costcenter
                                               office_accarea));
      if (defined($confrec)){
         if ($confrec->{databossid} ne ""){
            $newrec->{fwdtarget}="base::user";
            $newrec->{fwdtargetid}=$confrec->{databossid};
            $newrec->{involvedcostcenter}=$confrec->{office_costcenter};
            $newrec->{involvedaccarea}=$confrec->{office_accarea};
         }
         else{
            $newrec->{fwdtarget}="base::grp";
            $newrec->{fwdtargetid}="1";
         }
      }
   }

   return(1);
}






1;
