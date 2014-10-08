package kernel::Field::Percent;
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
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{_permitted}->{precision}=1;

   return($self);
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);
   my $name=$self->Name();
   $self->{precision}=2 if (!defined($self->{precision}));
   if ($mode eq "edit" && !defined($self->{vjointo}) && 
       !defined($self->{container})){
      if (defined($d)){
         my $format=sprintf("%%.%df",$self->{precision});
         $d=sprintf($format,$d);
         $d=~s/\./,/g;
      }
      my $fromquery=Query->Param("Formated_$name");
      if (defined($fromquery)){
         $d=$fromquery;
      }
      my $readonly=0;
      if ($self->readonly($current)){
         $readonly=1;
      }
      my $oldunit=$self->{unit};
      $self->{unit}="%";
      my $d=$self->getSimpleInputField($d,$readonly);
      $self->{unit}=$oldunit;
      return($d);
   }

   if ($mode=~m/^[>]{0,1}Html.*$/ ||
       $mode=~m/^[>]{0,1}AscV01$/     || $mode=~m/^[>]{0,1}CsvV01$/){
      if (defined($d)){
         my $format=sprintf("%%.%df",$self->{precision});
         $d=sprintf($format,$d);
         $d=~s/\./,/g;
      }
      $d.=" %" if ($d ne "");
      if ($mode=~m/^Html/){
         $d=~s/\s/&nbsp;/g;
      }
      if (exists($self->{background})){
         $d=$self->BackgroundColorHandling($mode,$current,$d);
      }

   }

   return($d);
}

sub Unformat
{
   my $self=shift;
   my $formated=shift;
   my $rec=shift;
 
   if ($formated->[0]=~m/^\s*$/){
      $formated->[0]=undef;
   }
   else{
      $formated->[0]=~s/,/\./g;
   }
   return($self->SUPER::Unformat($formated,$rec));
}

sub getXLSformatname
{
   my $self=shift;
   my $data=shift;
   return("number.".$self->precision());
}











1;
