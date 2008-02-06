package itil::ext::DataIssue;
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
             dataobj   =>'itil::appl',
             target    =>'name',
             targetid  =>'id'
           },
           {
             dataobj   =>'itil::system',
             target    =>'name',
             targetid  =>'id'
           },
         ];


   return($d);
}


sub completeWriteRequest
{
   my $self=shift;
   my $newrec=shift;
   if ($newrec->{affectedobject}=~m/::appl$/){
      if ($newrec->{affectedobject}=~m/::appl$/){
         # create link to config Management
         $newrec->{directlnktype}=$newrec->{affectedobject};
         $newrec->{directlnkid}=$newrec->{affectedobjectid};
         $newrec->{directlnkmode}="DataIssue";
      }
      my $obj=getModuleObject($self->getParent->Config,
                              $newrec->{directlnktype});
      $obj->SetFilter(id=>\$newrec->{directlnkid});
      my ($confrec,$msg)=$obj->getOnlyFirst(qw(databossid mandatorid mandator));
      if (defined($confrec)){
         if ($confrec->{databossid} ne ""){
            $newrec->{fwdtarget}="base::user";
            $newrec->{fwdtargetid}=$confrec->{databossid};
         }
         if ($confrec->{mandatorid} ne ""){
            $newrec->{mandatorid}=$confrec->{mandatorid};
         }
         if ($confrec->{mandator} ne ""){
            $newrec->{mandator}=$confrec->{mandator};
         }
      }
   }
   printf STDERR ("completeWriteRequest=%s\n",Dumper($newrec));
   return(1);
}




1;
