package TS::workflow::change;
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
use kernel::WfClass;
use itil::workflow::change;
@ISA=qw(itil::workflow::change );

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}


sub addSRCLinkToFacility
{
   my $self=shift;
   my $d=shift;
   my $current=shift;

   if ($d ne ""){
      if (defined($current->{srcsys}) &&
          $current->{srcsys} eq "tssc::event::scchange"){
         return("tssc::chm",['srcid'=>'changenumber']);
      }
      if (defined($current->{srcsys}) &&
          $current->{srcsys} eq "tssm::event::smchange"){
         return("tssm::chm",['srcid'=>'changenumber']);
      }
   }
   return($self->SUPER::addSRCLinkToFacility($d,$current));

}


1;
