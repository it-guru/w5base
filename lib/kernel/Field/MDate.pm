package kernel::Field::MDate;
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
use Data::Dumper;
@ISA    = qw(kernel::Field::Date);


sub new
{
   my $type=shift;
   my %param=@_;
   $param{history}=0  if (!defined($param{history}));
   $param{readonly}=1 if (!defined($param{readonly}));
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub Unformat
{
   my $self=shift;
   my $formated=shift;
   my $rec=shift;
   return({$self->Name()=>NowStamp("en")});
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $val=$newrec->{$self->Name()};
   $val=NowStamp("en") if (!defined($val));

   if (defined($oldrec)){
      if ($W5V2::OperationContext eq "QualityCheck"){
         if (exists($newrec->{$self->Name()})){
            return({$self->Name()=>$newrec->{$self->Name()}});
         }
      }
   }
   if ($W5V2::OperationContext eq "Kernel"){
      if (defined($newrec->{$self->Name()})){
         return({$self->Name()=>$val});
      }
      else{
         return({});
      }
   }
   return({$self->Name()=>$val});
}

sub Uploadable
{
   my $self=shift;

   return(0);
}







1;
