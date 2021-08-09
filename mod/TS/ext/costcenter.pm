package TS::ext::costcenter;
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


sub GetCostcenterTypes
{
   my $self=shift;
   my @d=();   # key=>'value' pairs (value = translated)
   return(\@d);
}

sub ValidateCONumber    # this method needs to be renamed in validateCostcenter
{                       # in the future
   my $self=shift;
   my $dataobj=shift; # target object for which the check is done
   my $fieldname=shift;
   my $oldrec=shift;
   my $newrec=shift;


   if (!defined($oldrec) || 
       (defined($newrec) && exists($newrec->{$fieldname}))){
      my $conummer=uc(effVal($oldrec,$newrec,$fieldname));
      if ($dataobj eq "finance::costcenter"){
         return(1) if ($conummer=~m/^\S+\[\d+\]/);
      }
      else{
         return(1) if ($conummer eq ""); # allow empty entries
      }

      if ((
   !($conummer=~m/^[0-9]{5,10}$/) &&  # für CO und Kostenstellen 
   !($conummer=~m/^[A-Z,0-9][0-9]{8}[A-Z,0-9]$/) &&
   !($conummer=~m/^[A-Z]-[A-Z,0-9]{10}$/) &&
   !($conummer=~m/^[0-9]{4}$/) &&  # SAP USA
   !($conummer=~m/^[A-Z0-9]{4}[0-9]{6}$/) &&  # OFI Kostenstelle
   !($conummer=~m/^Y-[A-Z0-9]{3}-[A-Z0-9]{3}-[0-9]{1,2}-[0-9]{5,7}$/) && # DTT
   !($conummer=~m/^[A-Z]-[A-Z0-9]{3}-[0-9]{8,10}$/) &&  # OFI PSP Top
   !($conummer=~m/^[A-Z]-[A-Z0-9]{3}-[0-9]{8,10}-[0-9]{2}$/) &&  #OFI E2
   !($conummer=~m/^[A-Z]-[A-Z0-9]{3}-[0-9]{8,10}-[0-9]{2}-[0-9]{2,4}$/) &&  # E3
   !($conummer=~m/^[A-Z]-[A-Z0-9]{3}-[0-9]{8,10}-[0-9]{2}-[0-9]{2,4}-[0-9]{2,4}$/) &&  # E3
   !($conummer=~m/^[A-Z]-[0-9]{6,12}-[A-Z,0-9]{3,6}$/) )){
         return(0);
      }
      $conummer=~s/^0+//g;
      if (defined($newrec) && exists($newrec->{$fieldname})){
         $newrec->{$fieldname}=$conummer;
      }
   }

   return(1);
}





1;
