package kernel::Field::DRange;
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
use kernel::date;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{dayonly}=0                    if (!defined($self->{dayonly}));
   $self->{readonly}=1;
   $self->{htmldetail}=0;
   $self->{searchable}=1;
   $self->{timezone}="GMT"               if (!defined($self->{timezone}));
   return($self);
}


sub getFieldHelpUrl
{
   my $self=shift;

   if (defined($self->{FieldHelp})){
      if (ref($self->{FieldHelp}) eq "CODE"){
         return(&{$self->{FieldHelp}}($self));
      }
      return($self->{FieldHelp});
   }
   return("../../base/load/tmpl/FieldHelp.DRange");
}

sub preProcessFilter
{
   my $self=shift;
   my $hflt=shift;
   my $changed=0;

   if (defined($hflt->{$self->{name}}) &&
       $hflt->{$self->{name}} ne ""){
      my $w=$hflt->{$self->{name}};
      my $parsedw=$self->getParent->PreParseTimeExpression($w,$self->{tz});
    
      my @exp=split(/ and /i,$parsedw);
      if ($parsedw ne $w && $#exp==1){
         $self->getParent->SetNamedFilter("DRange_".$self->{name},
           [ {rangem=>$parsedw}, {ranges=>$exp[0]}, {rangee=>$exp[1]} ]
         );
      }
      else{
         $self->getParent->LastMsg(ERROR,"invalid filter expresion on DRange");
         return(undef);
      }
      delete($hflt->{$self->{name}});
      $changed++;
   }

   return($changed);
}







1;
