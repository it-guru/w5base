package kernel::Field::TRange;
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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
use Text::ParseWords;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self={@_};
   $self->{depend}=[] if (!defined($self->{depend}));
   $self->{htmldetail}=0 if (!defined($self->{htmldetail}));
   $self->{readonly}=1   if (!defined($self->{readonly}));
   $self->{noselect}=1   if (!defined($self->{noselect}));
   if (!defined($self->{uivisible})){
      $self->{uivisible}=sub{
          my $self=shift;
          my $mode=shift;
          return(($mode eq "SearchMask") ? 1 : 0);
      };
   }
   $self=bless($type->SUPER::new(%$self),$type);
   push(@{$self->{depend}},$self->{dsttypfield},$self->{dstidfield});
   if (ref($self->{dst}) ne "ARRAY" && $self->{dst} ne ""){
      push(@{$self->{depend}},$self->{dst}); # the type is loaded from a field
   }
   return($self);
}


sub addTRangeFilter
{
   my $self=shift;
   my $baseflt=shift;
   my $flt=shift;

   my $args=[];
   my $trange=$flt->{$self->Name()};
   $trange=${$trange} if (ref($trange) eq "SCALAR");
   if (ref($trange) eq "ARRAY"){
      $args=$trange;
   }
   else{
      if ($trange ne ""){
         $args=[$trange];
      }
   }
   if ($#{$args}!=0){
      $self->getParent->LastMsg(ERROR,"can not identify time range");
      return(undef);
   }
   my $res=$self->getParent->ExpandTRangeExpression($args->[0],
      undef,undef,undef,
      {
         align=>'day'
      }
   );
   if (!defined($res)){
      $self->getParent->LastMsg(ERROR,"can not parse time range");
      msg(ERROR,"TRange acces to $args->[0]");
      return(undef);
   }
   my $s=$res->[0];
   my $e=$res->[1];
   
   my @addflt=(
              {$self->{depend}->[0]=>"<=\"$e\""},
              {$self->{depend}->[1]=>"<=\"$e\" AND >=\"$s\""},
              {$self->{depend}->[2]=>">=\"$s\""}
             );
   push(@$baseflt,\@addflt);
   return(1);
}


sub SetFilter
{
   my $self=shift;
   my $flt=shift;

   if (1){
     if (ref($flt) eq "ARRAY"){
        if (ref($flt->[0]) eq "HASH"){
           if (exists($flt->[0]->{$self->Name()})){
              if (!$self->addTRangeFilter($flt,$flt->[0])){
                 return(undef);
              }
           }
        }
        if (ref($flt->[0]) eq "ARRAY"){
           foreach my $subflt (@{$flt->[0]}){
              if (exists($subflt->{$self->Name()})){
                 if (!$self->addTRangeFilter($flt,$subflt)){
                    return(undef);
                 }
              }
           }
        }
     }
     return(1);
   }
   $self->getParent->LastMsg(ERROR,"invalid timerange filter");
   return(undef);
}


1;
