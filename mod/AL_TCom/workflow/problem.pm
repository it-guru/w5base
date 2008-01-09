package AL_TCom::workflow::problem;
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
use Data::Dumper;
use itil::workflow::problem;
use AL_TCom::lib::workflow;
@ISA=qw(itil::workflow::problem AL_TCom::lib::workflow);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}


sub isOptionalFieldVisible
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   my $name=$param{field}->Name();

   return(1) if ($name eq "relations");
   return($self->SUPER::isOptionalFieldVisible($mode,%param));
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated
   if (!$self->isRecordMandatorReadable($rec) &&
       !$self->isPostReflector($rec)){
      return("header","default","itilchange","affected","relations","source","state");
   }
   return($self->SUPER::isViewValid($rec));
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated
   my @edit;

   return(@edit);  # ALL means all groups - else return list of fieldgroups
}


sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),"affected","relations");
}






1;
