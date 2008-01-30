package tsacinv::qrule::compareSystem;
#  W5Base Framework
#  Copyright (C) 2007  Hartmut Vogler (it@guru.de)
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
use kernel::QRule;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return(["itil::system","OSY::system","AL_TCom::system"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   if ($rec->{systemid} ne ""){
      my $par=getModuleObject($self->getParent->Config(),"tsacinv::system");
      $par->SetFilter({email=>\$rec->{email}});
      my ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      if (!defined($parrec)){
         return(3,['systemid not found in AssetCenter']);
      }
      my $upd={};
      my @failtext;
    #  foreach my $fld (qw(office_phone office_street office_zipcode 
    #                      office_facsimile)){
    #     if ($rec->{$fld}=~m/^\s*$/ && $wiwrec->{$fld} ne ""){
    #        $upd->{$fld}=$wiwrec->{$fld};
    #     }
    #  }
      if (keys(%$upd)){
         if ($dataobj->ValidatedUpdateRecord($rec,$upd,{id=>\$rec->{id}})){
            push(@failtext,"some fields has been updated");
         }
         else{
            push(@failtext,$self->getParent->LastMsg());
            return(3,{failtext=>\@failtext});
         }
      }
      return(0,{failtext=>\@failtext});
   }
   return(0,undef);
}



1;
