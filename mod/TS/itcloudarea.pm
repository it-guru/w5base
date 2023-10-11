package TS::itcloudarea;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
use itil::itcloudarea;
@ISA=qw(itil::itcloudarea);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Link(
                name          =>'acinmassignmentgroupid',
                readonly      =>1,
                label         =>'Incident Assignmentgroup ID',
                dataobjattr   =>'appl.acinmassignmentgroupid'),

      new kernel::Field::TextDrop(
                name          =>'acinmassingmentgroup',
                label         =>'Incident Assignmentgroup',
                group         =>'inm',
                readonly      =>1,
                vjointo       =>'tsgrpmgmt::grp',
                vjoinon       =>['acinmassignmentgroupid'=>'id'],
                vjoindisp     =>'fullname')
   );

   $self->AddFields(
      new kernel::Field::Text(
                name          =>'applictono',
                htmldetail    =>0,
                uploadable    =>0,
                readonly      =>1,
                group         =>'appl',
                explore       =>150,
                label         =>'Applications ICTO-ID',
                dataobjattr   =>'appl.ictono'),
     insertafter=>'appl'
   );




   return($self);
}


1;
