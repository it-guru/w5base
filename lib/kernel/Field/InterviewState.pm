package kernel::Field::InterviewState;
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
use kernel::Field::Textarea;
@ISA    = qw(kernel::Field::Select kernel::InterviewField);


sub new
{
   my $type=shift;
   my $self={@_};
   $self->{group}='interview'              if (!defined($self->{qc}));
   $self->{name}='interviewst'             if (!defined($self->{name}));
   $self->{label}='Interview state'        if (!defined($self->{label}));
   $self->{history}=0;
   $self->{readonly}=1;
   $self->{htmldetail}=0;
   $self->{searchable}=0;
   $self->{onRawValue}=\&onRawValue;
   my $o=bless($type->SUPER::new(%$self),$type);
   return($o);
}

sub onRawValue
{
   my $self=shift;
   my $current=shift;
   my $parent=$self->getParent();
   my $idname=$parent->IdField->Name();
   my $id=$current->{$idname};
   my $parent=$self->getParent->SelfAsParentObject();
   my $answered=$self->getAnsweredQuestions($parent,$idname,$id);
   my $total=$self->getTotalActiveQuestions($parent,$idname,$id,$answered);
   my $state={TotalActiveQuestions=>$total,
              AnsweredQuestions=>$answered};
              
   return($state);
}

sub FormatedResult
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);
   if ($mode=~m/^Html/){
      my $total=$#{$d->{TotalActiveQuestions}}+1;
      my $todo=0;
      if ($total>0){
         foreach my $q (@{$d->{TotalActiveQuestions}}){
            if (!exists($d->{AnsweredQuestions}->{interviewid}->{$q->{id}})){
               $todo++;
            }
         }
         if ($todo>0){
            return("Total: $total<br>\nOpen: $todo");
         }
      }
      return("OK");
      return("Total: $total\n");
   }

  # return($d); 
   return($mode); 
}






1;
