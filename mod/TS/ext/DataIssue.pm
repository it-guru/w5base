package TS::ext::DataIssue;
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
             dataobj   =>'TS::vou',
             target    =>'fullname',
             targetid  =>'id'
           },
           {
             dataobj   =>'TS::appl',
             target    =>'name',
             targetid  =>'id'
           },
           {
             dataobj   =>'TS::swinstance',
             target    =>'fullname',
             targetid  =>'id'
           },
           {
             dataobj   =>'TS::system',
             target    =>'name',
             targetid  =>'id'
           },
           {
             dataobj   =>'TS::asset',
             target    =>'name',
             targetid  =>'id'
           },
           {
             dataobj   =>'TS::campus',
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

   if (($affectedobject=~m/TS::vou$/)   ||
       ($affectedobject=~m/::vou$/)){
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
      my ($confrec,$msg)=$obj->getOnlyFirst(qw(databossid mandatorid mandator));
      if (defined($confrec)){
         if ($confrec->{databossid} ne ""){
            my $u=getModuleObject($self->getParent->Config,"base::user");
            $u->SetFilter({userid=>\$confrec->{databossid}});
            my ($urec)=$u->getOnlyFirst(qw(cistatusid
                                           office_costcenter office_accarea));
            if (defined($urec) && 
                $urec->{cistatusid}<5 && $urec->{cistatusid}>2){
               $newrec->{fwdtarget}="base::user";
               $newrec->{fwdtargetid}=$confrec->{databossid};
               $newrec->{involvedcostcenter}=$urec->{office_costcenter};
               $newrec->{involvedaccarea}=$urec->{office_accarea};
            }
            else{
               $newrec->{involvedcostcenter}=undef;
               $newrec->{involvedaccarea}=undef;
               $newrec->{fwdtarget}=undef;
               $newrec->{fwdtargetid}=undef;
            }
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
   #printf STDERR ("itil:DataIssueCompleteWriteRequest=%s\n",Dumper($newrec));
   return(1);
}





1;
