package kernel::Field::RecordUrl;
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
   $self{name}="urlofcurrentrec"        if (!defined($self{name}));
   $self{label}="URL of record"         if (!defined($self{label}));
   $self{readonly}=1                    if (!defined($self{readonly}));
   $self{htmldetail}=0                  if (!exists($self{htmldetail}));
   $self{searchable}=0                  if (!exists($self{searchable}));
   $self{align}="left"                  if (!defined($self{align}));
   $self{WSDLfieldType}="xsd:string"    if (!defined($self{WSDLfieldType}));
   my $self=bless($type->SUPER::new(%self),$type);
   return($self);
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);
   return($d);
}

sub Uploadable
{
   my $self=shift;

   return(0);
}


sub RawValue
{
   my $self=shift;
   my $current=shift;

   my $url="[inposible]";

   my $idobj=$self->getParent->IdField();


   if (defined($idobj)){
      my $id=$idobj->RawValue($current);
      if ($id ne ""){
         if ($self->getParent->can("getAbsolutByIdUrl")){
            $url=$self->getParent->getAbsolutByIdUrl($id,{});
         }
         else{
            msg(ERROR,"no getAbsolutByIdUrl method in ".
                      $self->getParent()." for id=$id");
         }
      }
   }
   $current->{$self->{name}}=$url;
   return($url); 
}











1;
