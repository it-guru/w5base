package itil::ext::staticinfoabo;
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
use Data::Dumper;
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


sub getControlData
{
   my $self=shift;
   my $app=$self->getParent();

   return([
#           'itil::appl' =>   {id  =>'100000001',
#                                              name=>'STEVeventinfobyorg'},
#           'itil::appl' =>   {id  =>'100000002',
#                                              name=>'STEVeventinfobyfunction'},
           'itil::appl' =>   {id  =>'100000003',
                                              name=>'STEVapplchanged'},
           'itil::appl' =>   {id  =>'100000004',
                                              name=>'STEVchangeinfobyfunction'},
           'itil::appl' =>   {id  =>'100000005',
                                              name=>'STEVchangeinfobydepfunc'},
          ]);

}




1;
