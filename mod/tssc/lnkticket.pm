package tssc::lnkticket;
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
use tssc::lnk;
@ISA=qw(tssc::lnk);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::MultiDst(
                name          =>'priority',
                group         =>'status',
                label         =>'Priority',
                translation   =>'tssc::lnk',
                dst           =>['tssc::inm'=>'priority',
                                 'tssc::prm'=>'priority',  
                                 'tssc::chm'=>'urgency'],  
                dsttypfield   =>'dstobj',
                dstidfield    =>'dst'),

      new kernel::Field::MultiDst(
                name          =>'status',
                group         =>'status',
                label         =>'Status',
                dst           =>['tssc::inm'    =>'status',
                                 'tssc::prm'    =>'status',  
                                 'tssc::chm'    =>'status'],  
                dsttypfield   =>'dstobj',
                dstidfield    =>'dst'),
   );
   
   $self->setDefaultView(qw(linenumber dst status sysmodtime));
   return($self);
}

sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),qw(src dst status));
}

sub initSqlWhere
{
   my $self=shift;
   my $where=$self->SUPER::initSqlWhere() .
             "AND screlationm1.depend_filename IN".
             " ('problem','rootcause','cm3r')";
   return($where);
}


1;
