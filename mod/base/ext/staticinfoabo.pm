package base::ext::staticinfoabo;
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
           'base::user' =>   {            id  =>'110000001',
               name=>'STEVuserchanged'},

           'base::grp' =>    {            id  =>'110000002',
               name=>'STEVqreportbyorg'},

           'base::workflow'=>{            id  =>'110000003',
               force=>1,   # not editable for users set to 1
               name=>'STEVwfstatsendWeek'},

           'base::user' =>   {            id  =>'110000004',
               name=>'STEVborderchange'},
          ]);

}




1;
