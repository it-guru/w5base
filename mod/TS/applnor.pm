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
      if (in_array([qw(MSystemOS MSystemMF)],$module)){
         $self->AddFields(
            new kernel::Field::Text(
               name          =>$module."AMSecurityFlag",
               label         =>"AssetManager SecurityFlag",
               group         =>$module,
               htmldetail    =>$self->{displayall},
               extLabelPostfix=>": ".$module,
               searchable    =>0,
               onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
               container     =>"additional"),
         );

      }
      if (in_array([qw(MSystemOS MHardwareOS)],$module)){
         $self->AddFields(
            new kernel::Field::Text(
               name          =>$module."SCassignments",
               label         =>"AssetManager iAssignments",
               group         =>$module,
               htmldetail    =>$self->{displayall},
               extLabelPostfix=>": ".$module,
               searchable    =>0,
               onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
               container     =>"additional"),
            new kernel::Field::Text(
               name          =>$module."AMPortfolioIDs",
               label         =>"AssetManager PortfolioIDs",
               group         =>$module,
               htmldetail    =>$self->{displayall},
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
      my $gfld=$self->getField($fld->{group}."SCassignments",$current);
      my $refid=$gfld->RawValue($current);
      if (defined($refid) && $#{$refid}>=0){
         my $o=getModuleObject($self->Config,"tssc::group");
         $o->SetFilter({name=>$refid});
         foreach my $r ($o->getHashList(qw(users))){
            foreach my $urec (@{$r->{users}}){
               $pid{uc($urec->{luser})}++ if ($urec->{luser} ne "");
            }
         };
         $self->autoFillAddResultCache([$fld->{name},
                                        [keys(%pid)],
                                        $current->{srcparentid}]);
      }
   }
   elsif (($fld->{name}=~m/^MSystem.*SCassignments$/) ||
          ($fld->{name}=~m/^MSystem.*AMSecurityFlag$/)){
      my %pid=();
      my %secmod=();
      my $gfld=$self->getField("MSystemOSAMPortfolioIDs",$current);
      my $refid=$gfld->RawValue($current);
      if (defined($refid) && $#{$refid}>=0){
         my $o=getModuleObject($self->Config,"tsacinv::system");
         $o->SetFilter({systemid=>$refid});
         foreach my $r ($o->getHashList(qw(iassignmentgroup securitymodel))){
            $pid{$r->{iassignmentgroup}}++ if ($r->{iassignmentgroup} ne "");
            $secmod{$r->{securitymodel}}++ if ($r->{securitymodel} ne "");
         };
         $self->autoFillAddResultCache([$fld->{group}."SCassignments",
                                        [keys(%pid)],
                                        $current->{srcparentid}],
                                       [$fld->{group}."AMSecurityFlag",
                                        [keys(%secmod)],
                                        $current->{srcparentid}]);
      }
   }
   elsif ($fld->{name} eq "MHardwareOSSCassignments"){
      my %pid=();
      my $gfld=$self->getField("MHardwareOSAMPortfolioIDs",$current);
      my $refid=$gfld->RawValue($current);
      if (defined($refid) && $#{$refid}>=0){
         my $o=getModuleObject($self->Config,"tsacinv::asset");
         $o->SetFilter({assetid=>$refid});
         foreach my $r ($o->getHashList(qw(iassignmentgroup))){
            $pid{$r->{iassignmentgroup}}++ if ($r->{iassignmentgroup} ne "");
         };
         $self->autoFillAddResultCache([$fld->{name},
                                        [keys(%pid)],
                                        $current->{srcparentid}]);
      }
   }
   elsif ($fld->{name} eq "MSystemOSAMPortfolioIDs"){
      my $gfld=$self->getField("MApplDeliveryGroup",$current);
      my $refid=$gfld->RawValue($current);
      my $r=$self->autoFillGetResultCache($fld->{group}."systemsystemid",
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
   elsif (my ($grp)=$fld->{name}=~m/^(.*)DeliveryOrgs$/){ # temp hack
      my $gfld=$self->getField($grp."DeliveryGroup",$current);
      my $ref=$gfld->RawValue($current);
      my @org=();
      foreach my $r (@$ref){
         if ($r=~m/.*\.SK$/){
            push(@org,"T-Systems Slovakia s.r.o");
         }
         elsif ($r=~m/.*\.HU$/){
            push(@org,"IT Services Hungary");
         }
         elsif ($r=~m/^DTAG\.TSI($|\..*)/){
            push(@org,"T-Systems International GmbH");
         }
         elsif ($ref=~m/^DTAG\.TDG($|\..*)/){
            push(@org,"T-Deutschland");
         }
         else{
            push(@org,"Other/Unknown");
         }
      }
      $self->autoFillAddResultCache(
         [$fld->{name},
          \@org, $current->{srcparentid}]);
   }
   elsif (my ($grp)=$fld->{name}=~m/^(.*)DeliveryCountries$/){ # temp hack
      my @country=();
      my $gfld=$self->getField($grp."DeliveryGroup",$current);
      my $ref=$gfld->RawValue($current);
      foreach my $r (@$ref){
         if (($r=~m/.*\.SK$/)){
            push(@country,"SK");
         }
         elsif (($r=~m/.*\.HU$/)){
            push(@country,"HU");
         }
         elsif (($r=~m/.*\.CZ$/)){
            push(@country,"CZ");
         }
         else{
            push(@country,"DE");
         }
      }
      my $gfld=$self->getField($grp."SCassignments",$current);
      if (defined($gfld)){
         my $ref=$gfld->RawValue($current);
         foreach my $r (@$ref){
            if (($r=~m/^\S+\.\S+\.SK\..*/)){
               push(@country,"SK");
            }
            elsif (($r=~m/^\S+\.\S+\.HU\..*/)){
               push(@country,"HU");
            }
            elsif (($r=~m/^\S+\.\S+\.CZ\..*/)){
               push(@country,"CZ");
            }
            else{
               push(@country,"DE");
            }
         }
      }
      $self->autoFillAddResultCache(
         [$fld->{name},
          \@country,$current->{srcparentid}]);
   }
   return($self->SUPER::autoFillAutogenField($fld,$current));
}


sub resolvUserID
{
   my $self=shift;
   my $uid=shift;

   my $rec=$self->SUPER::resolvUserID($uid);
   if (!defined($rec) && (!$uid=~m/(\s|^\s*$)/)){
      my $wiw=getModuleObject($self->Config,"tswiw::user");
      $wiw->SetFilter({uid=>\$uid});
      my ($wiwrec,$msg)=$wiw->getOnlyFirst(qw(office_zipcode office_location 
                                              office_street));
      if (defined($wiwrec)){
         return($wiwrec);
      }
      else{
         return({office_location=>'invalid who is who user entry '.$uid});
      }
   }
   return($rec);
}









1;
