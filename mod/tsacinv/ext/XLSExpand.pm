package tsacinv::ext::XLSExpand;
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
use kernel::App::Web;
@ISA=qw(kernel::XLSExpand kernel::App::Web::Listedit);


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
   my $d={in=>{},
          out=>{'tsacinv::system::systemola'=>{label=>'AssetManager: System: SystemOLA',
                                               in=>[qw(itil::system::systemid)]},
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

   if (exists($out->{'tsacinv::system::systemola'})){
      my @flt=();
      my $ola=$self->getParent->getPersistentModuleObject('tsacinv::system');
      if (defined($in->{'itil::system::name'})){
         push(@flt,{systemname=>$in->{'itil::system::name'}});
      }
      if (defined($in->{'itil::system::systemid'})){
         if (ref($in->{'itil::system::systemid'}) ne "HASH"){
            $in->{'itil::system::systemid'}={$in->{'itil::system::systemid'}=>1}; 
         }
         my $id=[keys(%{$in->{'itil::system::systemid'}})];
         push(@flt,{systemid=>$id});
      }
      my $primode=$self->IsMemberOf("w5base.base.xlsexpand.read");
      $primode ? $ola->SetFilter(\@flt) : $ola->SecureSetFilter(\@flt);
 #     my $mode= $primode ? "A" : "B"; # bedingte zuweisung
      foreach my $rec ($ola->getHashList('systemola')){
         $out->{'tsacinv::system::systemola'}->{$rec->{'systemola'}}++;
      }
   }
   return(1);
}


sub getPriority
{
   return(10000);
}


1;
