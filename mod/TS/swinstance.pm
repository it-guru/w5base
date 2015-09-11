package TS::swinstance;
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
use itil::swinstance;
@ISA=qw(itil::swinstance);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Link(
                name          =>'acinmassignmentgroupid',
                group         =>'control',
                label         =>'Incient Assignmentgroup ID',
                dataobjattr   =>'swinstance.acinmassignmentgroupid'),

      new kernel::Field::TextDrop(
                name          =>'acinmassingmentgroup',
                label         =>'Incident Assignmentgroup',
                group         =>'inmchm',
                vjoineditbase =>{isinmassign=>\'1'},
                vjointo       =>'tsgrpmgmt::grp',
                vjoinon       =>['acinmassignmentgroupid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'scapprgroupid',
                group         =>'control',
                label         =>'Change Approvergroup ID',
                dataobjattr   =>'swinstance.scapprgroupid'),

      new kernel::Field::TextDrop(
                name          =>'scapprgroup',
                label         =>'Change Approvergroup',
                vjoineditbase =>{ischmapprov=>\'1'},
                group         =>'inmchm',
                vjointo       =>'tsgrpmgmt::grp',
                vjoinon       =>['scapprgroupid'=>'id'],
                vjoindisp     =>'fullname'),
   );
 
   return($self);
}



sub isWriteValid
{
   my $self=shift;
   my @l=$self->SUPER::isWriteValid(@_);
   if (grep(/^(default|ALL)$/,@l)){
      push(@l,"inmchm");
   }
   return(@l);
}

sub isViewValid
{
   my $self=shift;
   my @l=$self->SUPER::isViewValid(@_);
   if (grep(/^(default|ALL)$/,@l)){
      push(@l,"inmchm");
   }
   return(@l);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my @l=$self->SUPER::getDetailBlockPriority(@_);
   my $inserti=$#l;
   for(my $c=0;$c<=$#l;$c++){
      $inserti=$c+1 if ($l[$c] eq "default");
   }
   splice(@l,$inserti,$#l-$inserti,("inmchm",@l[$inserti..($#l+-1)]));
   return(@l);

}  







1;
