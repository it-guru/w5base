package kernel::Field::Interview;
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
use kernel::InterviewField;
use kernel::Field::Percent;
@ISA    = qw(kernel::Field::Percent kernel::InterviewField);


sub new
{
   my $type=shift;
   my $self={@_};
   $self->{group}='interview'               if (!defined($self->{qc}));
   $self->{name}='interview'                if (!defined($self->{name}));
   $self->{label}='Interview result'        if (!defined($self->{label}));
   $self->{history}=0;
   $self->{readonly}=1;
   $self->{htmldetail}=0;
   $self->{searchable}=0;
   $self->{onRawValue}=\&onRawValue;
   my $o=bless($type->SUPER::new(%$self),$type);
   return($o,new kernel::Field::InterviewState());
}

sub onRawValue
{
   my $self=shift;
   my $current=shift;
   my $parent=$self->getParent();
   my $stf=$parent->getField("interviewst");
   my $st=$stf->RawValue($current); 

   if ($#{$st->{TotalActiveQuestions}}==-1){
      return(undef);
   }
   return($st->{qStat}->{totalStat});
}






1;
