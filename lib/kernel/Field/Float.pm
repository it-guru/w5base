package kernel::Field::Float;
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
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{_permitted}->{precision}=1;              # Nachkommastellen
   $self->{align}='right' if (!defined($self->{align}));
   $self->{precision}=2   if (!defined($self->{precision}));

   return($self);
}

sub RawValue
{
   my $self=shift;
   my $d=$self->SUPER::RawValue(@_);
   if (defined($d)){    # normalisierung, damit die Daten intern immer
      $d=~s/,/./g;      # mit . als dezimaltrenner behandelt werden
   }
   return($d);
}



sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);

   my @formaton=qw( AscV01 HtmlDetail HtmlV01 HtmlSubList CsvV01);
   my $qmode=quotemeta($mode);
   if (grep(/^$qmode$/,@formaton)){
      if (defined($d)){
         my $format=sprintf("%%.%df",$self->precision());
         $d=sprintf($format,$d);
         $d=~s/\./,/g;
         $d.=" ".$self->{unit} if ($d ne "" && $mode eq "HtmlDetail");
      }
   }

   return($d);
}

sub getXLSformatname
{
   my $self=shift;
   my $data=shift;
   return("number.".$self->precision());
}




1;
