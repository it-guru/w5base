package TCOM::ext::XLSExpand;
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
use Data::Dumper;
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
   my $d={in=>{'TCOM::custappl::custname' =>{label=>'T-Home AGname',
                                             out=>['itil::appl::name']},
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

   if (defined($in->{'TCOM::custappl::custname'})){
      my $appl=$self->getParent->getPersistentModuleObject('TCOM::custappl');
      $appl->SetFilter({custname=>$in->{'TCOM::custappl::custname'}});
      foreach my $applrec ($appl->getHashList(qw(id name))){
         $in->{'itil::appl::id'}->{$applrec->{id}}++;
         $in->{'itil::appl::name'}->{$applrec->{name}}++;
         if (exists($out->{'itil::appl::name'})){
            $out->{'itil::appl::name'}->{$applrec->{name}}++;
         }
      }
   }
   if (grep(/^itil::system::.*$/,keys(%{$out}))){
      return(0) if ($loopcount<2);
   }
   return(1);
}





1;
