package TS::qrule::MandatorCheck;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

If there is a mandator record which installed/active, but referes to
a group which is marked as "disposed of wasted", this will produce
a DataIssue for admins.
The admin needs to cleanup posible existing datas and set the 
mandator also to "disposed of wasted".

=head3 IMPORTS

NONE

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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
use base::qrule::MandatorCheck;
@ISA=qw(base::qrule::MandatorCheck);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub isQruleApplicable
{
   my $self=shift;
   my $rec=shift;

   if ($rec->{cistatusid}==4){
      return(1);
   }
   return(0);
}



1;
