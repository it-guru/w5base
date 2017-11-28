package finance::ext::DataIssue;
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
   my $d=[ 
           {
             dataobj   =>'finance::custcontract',
             target    =>'name',
             targetid  =>'id'
           },
           {
             dataobj   =>'finance::costcenter',
             target    =>'name',
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

   if ($affectedobject=~m/::custcontract$/){
      if ($newrec->{affectedobject}=~m/::custcontract$/){
         # create link to config Management
         $newrec->{directlnktype}=$newrec->{affectedobject};
         $newrec->{directlnkid}=$newrec->{affectedobjectid};
         $newrec->{directlnkmode}="DataIssue";
      }
      my $obj=getModuleObject($self->getParent->Config,$affectedobject);
      my $affectedobjectid=effVal($oldrec,$newrec,"directlnkid");
      $obj->SetFilter(id=>\$affectedobjectid);
      my ($confrec,$msg)=$obj->getOnlyFirst(qw(databossid mandatorid mandator));
      if (defined($confrec)){
         if ($confrec->{databossid} ne ""){
            $newrec->{fwdtarget}="base::user";
            $newrec->{fwdtargetid}=$confrec->{databossid};
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
   if ($affectedobject=~m/::costcenter$/){
      if (defined($newrec) &&
          $newrec->{affectedobject}=~m/::costcenter$/){
         # create link to config Management
         $newrec->{directlnktype}=$newrec->{affectedobject};
         $newrec->{directlnkid}=$newrec->{affectedobjectid};
         $newrec->{directlnkmode}="DataIssue";
      }
      my $obj=getModuleObject($self->getParent->Config,$affectedobject);
      my $affectedobjectid=effVal($oldrec,$newrec,"directlnkid");
      $obj->SetFilter(id=>\$affectedobjectid);
      my ($confrec,$msg)=$obj->getOnlyFirst(qw(databossid));
      if (defined($confrec)){
         if ($confrec->{databossid} ne ""){
            $newrec->{fwdtarget}="base::user";
            $newrec->{fwdtargetid}=$confrec->{databossid};
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
