package kernel::Field::Duration;
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
   my %self=@_;
   $self{selectfix}=1  if (!defined($self{selectfix}));
   $self{autogen}=1    if (!defined($self{autogen}));
   $self{searchable}=0 if (!defined($self{searchable}));
   $self{readonly}=1   if (!defined($self{readonly}));
   $self{htmlwidth}="1%"  if (!defined($self{htmlwidth}));
   $self{align}="right"   if (!defined($self{align}));
   $self{visual}="auto"   if (!defined($self{visual}));
   my $self=bless($type->SUPER::new(%self),$type);
   return($self);
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $p=$self->getParent();

   return(undef) if (!defined($self->{depend}) ||
                     !(ref($self->{depend}) eq "ARRAY"));
   my $d1=undef;
   my $d2=undef;
   foreach my $fo ($p->getFieldObjsByView($self->{depend},current=>$current)){
      if ($fo->Name() eq $self->{depend}->[0]){
         $d1=$fo->RawValue($current);
         if (defined($d1)){
            $d1=$self->getParent->ExpandTimeExpression($d1,"en",
                                                       $fo->timezone,"GMT");
         }
      }
      if ($fo->Name() eq $self->{depend}->[1]){
         $d2=$fo->RawValue($current);
         if (defined($d2)){
            $d2=$self->getParent->ExpandTimeExpression($d2,"en",
                                                       $fo->timezone,"GMT");
         }
      }
   }
   my $prefix="";
   if (!defined($d2) || $d2 eq ""){
      $d2=NowStamp("en");
      $prefix="~ ";
   }
   if (my $duration=CalcDateDuration($d1,$d2,"GMT")){
      if ($mode eq "HtmlDetail" || $mode eq "HtmlV01" ||
          ($mode=~m/^XLS/i)){
         if ($self->{visual} eq "auto"){
            return($prefix.$duration->{string});
         }
         elsif ($self->{visual} eq "hours"){
            return($prefix.sprintf("%.2f",($duration->{totalminutes}/60.0)));
         }
         elsif ($self->{visual} eq "minutes"){
            return($prefix.sprintf("%d",int($duration->{totalminutes})));
         }
         elsif ($self->{visual} eq "seconds"){
            return($prefix.sprintf("%d",int($duration->{totalseconds})));
         }
      }
      return($duration->{totalminutes});
   }
   return(undef);
}






1;
