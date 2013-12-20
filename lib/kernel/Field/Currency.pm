package kernel::Field::Currency;
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
@ISA    = qw(kernel::Field::Number);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{align}='right' if (!defined($self->{align}));
   $self->{unit}='Euro'   if (!defined($self->{unit}));
   $self->{precision}=2 if (!defined($self->{precision}));
   return($self);
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   return($self->SUPER::FormatedDetail($current,$mode)) if ($mode eq "edit");
   my $d=$self->RawValue($current);


   if ($mode eq "HtmlDetail"          || $mode=~m/^[>]{0,1}HtmlV01$/ ||
       $mode eq "HtmlSubList" ||
       $mode=~m/^[>]{0,1}AscV01$/     || $mode=~m/^[>]{0,1}CsvV01$/){
      if (defined($d)){
         my $format=sprintf("%%.%df",$self->{precision});
         $d=sprintf($format,$d);
         if (defined($self->{minprecision})){
            my $n=int($self->{minprecision});
            $d=~s/^(.*\.\d{$n}[^0]*).*$/$1/e;
            #$d=~s/^(.*\.{$n}\d[^0]*).*$/$1/e;
         }
         $d=~s/\./,/g;
         if ($mode eq "HtmlDetail"          || $mode=~m/^[>]{0,1}HtmlV01$/ ||
             $mode=~m/^[>]{0,1}AscV01$/ ){
            while($d=~m/\d\d\d\d/){
               $d=~s/(\d)(\d\d\d[,\.])/$1.$2/;
            };
         }
         if ($mode eq "HtmlDetail" && $self->{unit} ne ""){
            $d.=" ".$self->unit($mode,$current);
         }
      }
   }

   return($d);
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

sub getXLSformatname
{
   my $self=shift;
   my $data=shift;
   return("number.".$self->precision());
}




1;
