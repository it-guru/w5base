package TS::ext::XLSExpand;
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
use kernel::XLSExpand;
@ISA=qw(kernel::XLSExpand);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}


sub GetKeyCriterion
{
   my $self=shift;
   my $d={
       out=>{
             'TS::appl::acapplname'=>{
                         label=>'IT-Inventar: AssetManager Applicationname',
                            in=>[qw(itil::appl::id)]},
             'TS::appl::scapprgroup'=>{
                         label=>'IT-Inventar: Change Approvergroup',
                            in=>[qw(itil::appl::id)]},
             'TS::appl::ictono'=>{
                         label=>'IT-Inventar: Applikation: ICTO-ID',
                            in=>[qw(itil::appl::id)]},
              }
         };
   return($d);
}

sub ProcessLine
{
   my $self=shift;
   my $line=shift;
   my $in=shift;
   my $out=shift;
   my $loopcount=shift;

 
   # output
   if (!exists($in->{'itil::appl::id'})){
      return(1);
   }
   if (defined($in->{'itil::appl::id'}) && 
       exists($out->{'TS::appl::acapplname'})){
      my $appl=$self->getParent->getPersistentModuleObject('TS::appl');
      my $id=[keys(%{$in->{'itil::appl::id'}})];
      $appl->SetFilter({id=>$id});
      foreach my $rec ($appl->getHashList("acapplname")){
         if ($rec->{"acapplname"} ne ""){
             $out->{'TS::appl::acapplname'}->{$rec->{"acapplname"}}++;
         } 
      }
   }
   if (defined($in->{'itil::appl::id'}) && 
       exists($out->{'TS::appl::scapprgroup'})){
      my $appl=$self->getParent->getPersistentModuleObject('TS::appl');
      my $id=[keys(%{$in->{'itil::appl::id'}})];
      $appl->SetFilter({id=>$id});
      foreach my $rec ($appl->getHashList("scapprgroup")){
         if ($rec->{"scapprgroup"} ne ""){
             $out->{'TS::appl::scapprgroup'}->{$rec->{"scapprgroup"}}++;
         } 
      }
   }
   if (defined($in->{'itil::appl::id'}) && 
       exists($out->{'TS::appl::ictono'})){
      my $appl=$self->getParent->getPersistentModuleObject('TS::appl');
      my $id=[keys(%{$in->{'itil::appl::id'}})];
      $appl->SetFilter({id=>$id});
      foreach my $rec ($appl->getHashList("ictono")){
         if ($rec->{"ictono"} ne ""){
             $out->{'TS::appl::ictono'}->{$rec->{"ictono"}}++;
         } 
      }
   }

   return(1);
}





1;
