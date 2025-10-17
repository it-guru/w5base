package azure::event::AZURE_KernelLoad;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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



# Modul to detect expiered SSL Certs based on Qualys scan data
sub AZURE_KernelLoad
{
   my $self=shift;
   my $kernelSubscriptionId=shift;

   if ($kernelSubscriptionId eq ""){
      return({exitcode=>1,exitmsg=>'missing kernelSubscriptionId'});
   }

   my $subs=getModuleObject($self->Config,"azure::subscription");
   my $obj=getModuleObject($self->Config,"azure::skus");

   my $start=NowStamp("en");

   my $skus=$subs->loadSkusTable($kernelSubscriptionId);
   if (ref($skus) eq "ARRAY"){
      my $c=0;
      foreach my $rec (@$skus){
         $c++;
         foreach my $location (@{$rec->{locations}}){
            my $fullname=$location."-".$rec->{resourceType}."-".$rec->{name};
            my $updrec={
               fullname=>$fullname,
               name=>$rec->{name},
               resourcetype=>$rec->{resourceType},
               location=>$location,
               srcload=>NowStamp("en")
            };
            if (ref($rec->{capabilities}) eq "ARRAY"){
               foreach my $caprec (@{$rec->{capabilities}}){
                  next if (!in_array($caprec->{name},[qw(
                      vCPUs vCPUsPerCore vCPUsAvailable MemoryGB 
                      MaxSizeGiB MinSizeGiB
                  )]));
                  $updrec->{lc($caprec->{name})}=$caprec->{value};
               }

            }
            $obj->ValidatedInsertOrUpdateRecord($updrec,
                                                {fullname=>\$fullname}); 

         }
      }
   }
   else{
      return({exitcode=>1,exitmsg=>'unexpected result from Azure skus call'});

   }
   $obj->BulkDeleteRecord({srcload=>'<"'.$start.' GMT"'});

   return({exitcode=>0,exitmsg=>'ok'});
}


1;
