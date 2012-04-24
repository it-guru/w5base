package TS::applnor;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
use kernel::Field;
use itil::applnor;
@ISA=qw(itil::applnor);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);


   foreach my $module (@{$self->{allModules}}){
      if (in_array([qw(MSystemOS MHardwareOS)],$module)){
         $self->AddFields(
            new kernel::Field::Text(
               name          =>$module."AMassignments",
               label         =>"AssetManager Assignments",
               group         =>$module,
               extLabelPostfix=>": ".$module,
               searchable    =>0,
               onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
               container     =>"additional"),
            new kernel::Field::Text(
               name          =>$module."AMPortfolioIDs",
               label         =>"AssetManager PortfolioIDs",
               group         =>$module,
               extLabelPostfix=>": ".$module,
               searchable    =>0,
               onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
               container     =>"additional"),
         );
      }
   }


   return($self);
}

sub autoFillAutogenField
{
   my $self=shift;
   my $fld=shift;
   my $current=shift;
   my $c=$self->Cache();
   $c->{autoFillAutogenField}={} if (!exists($c->{autoFillAutogenField}));
   $c=$c->{autoFillAutogenField};



   if ($fld->{name} eq "MSystemOSDeliveryContactID" ||
       $fld->{name} eq "MHardwareOSDeliveryContactID"){
      my %pid=();
      my $gfld=$self->getField($fld->{group}."AMassignments",$current);
      my $refid=$gfld->RawValue($current);
      if (defined($refid) && $#{$refid}>=0){
         my $o=getModuleObject($self->Config,"tsacinv::group");
         $o->SetFilter({name=>$refid});
         foreach my $r ($o->getHashList(qw(users))){
            foreach my $urec (@{$r->{users}}){
               $pid{$urec->{user}}++ if ($urec->{user} ne "");
            }
         };
         $self->autoFillAddResultCache([$fld->{name},
                                        [keys(%pid)],
                                        $current->{srcparentid}]);
      }
   }
   elsif ($fld->{name} eq "MSystemOSAMassignments"){
      my %pid=();
      my $gfld=$self->getField("MSystemOSAMPortfolioIDs",$current);
      my $refid=$gfld->RawValue($current);
      if (defined($refid) && $#{$refid}>=0){
         my $o=getModuleObject($self->Config,"tsacinv::system");
         $o->SetFilter({systemid=>$refid});
         foreach my $r ($o->getHashList(qw(assignmentgroup))){
            $pid{$r->{assignmentgroup}}++ if ($r->{assignmentgroup} ne "");
         };
         $self->autoFillAddResultCache([$fld->{name},
                                        [keys(%pid)],
                                        $current->{srcparentid}]);
      }
   }
   elsif ($fld->{name} eq "MHardwareOSAMassignments"){
      my %pid=();
      my $gfld=$self->getField("MHardwareOSAMPortfolioIDs",$current);
      my $refid=$gfld->RawValue($current);
      if (defined($refid) && $#{$refid}>=0){
         my $o=getModuleObject($self->Config,"tsacinv::asset");
         $o->SetFilter({assetid=>$refid});
         foreach my $r ($o->getHashList(qw(assignmentgroup))){
            $pid{$r->{assignmentgroup}}++ if ($r->{assignmentgroup} ne "");
         };
         $self->autoFillAddResultCache([$fld->{name},
                                        [keys(%pid)],
                                        $current->{srcparentid}]);
      }
   }
   elsif ($fld->{name} eq "MSystemOSAMPortfolioIDs"){
      my $gfld=$self->getField("MApplDeliveryGroup",$current);
      my $refid=$gfld->RawValue($current);
      my $r=$self->autoFillGetResultCache("systemsystemid",
                                          $current->{srcparentid});
      $self->autoFillAddResultCache([$fld->{name},
                                     $r,
                                     $current->{srcparentid}]);
   }
   elsif ($fld->{name} eq "MHardwareOSAMPortfolioIDs"){
      my %pid=();
      my $gfld=$self->getField("MSystemOSAMPortfolioIDs",$current);
      my $refid=$gfld->RawValue($current);
      if (defined($refid) && $#{$refid}>=0){
         my $o=getModuleObject($self->Config,"itil::system");
         $o->SetFilter({systemid=>$refid});
         foreach my $rec ($o->getHashList(qw(asset))){
            if (defined($rec)){
               $pid{$rec->{asset}}++ if ($rec->{asset} ne "");
            }
         }
         $self->autoFillAddResultCache([$fld->{name},
                                        [keys(%pid)],
                                        $current->{srcparentid}]);
      }
   }
   return($self->SUPER::autoFillAutogenField($fld,$current));
}









1;
