package TS::ext::finishCITransfer;
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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


sub ProcessTransfer
{
   my $self=shift;
   my $dataobj=shift;
   my $dataobjid=shift;
   my $oldapplid=shift;
   my $newapplid=shift;
   my $parent=$self->getParent();

   if ($dataobj eq "itil::system"){
      my $a=$parent->getPersistentModuleObject("w5app","TS::appl");
      $a->SetFilter({id=>[$oldapplid,$newapplid]});
      $a->SetCurrentView(qw(id conumber acinmassingmentgroup));
      my $aById=$a->getHashIndexed(qw(id));

      my %upd;
      if (exists($aById->{id}->{$oldapplid}) && 
          exists($aById->{id}->{$newapplid})){
         if ($aById->{id}->{$oldapplid}->{acinmassingmentgroup} ne 
             $aById->{id}->{$newapplid}->{acinmassingmentgroup}){
            $upd{acinmassingmentgroup}=
               $aById->{id}->{$newapplid}->{acinmassingmentgroup};
         }
         if ($aById->{id}->{$oldapplid}->{conumber} ne 
             $aById->{id}->{$newapplid}->{conumber}){
            $upd{conumber}=
               $aById->{id}->{$newapplid}->{conumber};
         }
         if (keys(%upd)){
            my $s=$parent->getPersistentModuleObject("w5sys","TS::system");
            $s->SetFilter({id=>\$dataobjid});
            my @l=$s->getHashList(qw(ALL));
            foreach my $oldrec (@l){
               my $op=$s->Clone();
               if ($oldrec->{conumber} ne $upd{conumber} ||
                   $oldrec->{acinmassingmentgroup} ne 
                   $upd{acinmassingmentgroup}){
                  msg(INFO,"update on TS::system($dataobjid)");
                  msg(INFO,"data=".Dumper(\%upd));
                  $op->ValidatedUpdateRecord($oldrec,\%upd,{id=>\$dataobjid});
               }
            }
         }
      }
   }
}

1;
