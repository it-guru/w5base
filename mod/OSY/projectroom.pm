package OSY::projectroom;
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
use kernel::Field;
use base::projectroom;
@ISA=qw(base::projectroom);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                group         =>'systems',
                subeditmsk    =>'subedit.system',
                vjointo       =>'OSY::lnkprojectroom',
                vjoinbase     =>{parentobj=>"itil::system"},
                vjoinon       =>['id'=>'projectroomid'],
                vjoindisp     =>['system','systemweblink',
                                 'parentobjname','systemshortdesc']),
      insertafter=>'name'
   );



   return($self);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default systems),$self->SUPER::getDetailBlockPriority(@_));
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my @grps=$self->SUPER::isWriteValid($rec);
   if (grep(/^default$/,@grps)){
      push(@grps,"systems");
   }
   return(@grps);
}





1;
