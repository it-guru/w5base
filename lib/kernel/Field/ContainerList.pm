package kernel::Field::ContainerList;
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
   
   return($self);
}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;
   my $name=$self->Name();
   my $d=$self->RawValue($current);
   $d=$self->FormatedDetailDereferncer($current,$FormatAs,$d);
   my $lang=$self->getParent->Lang();
      $d="<table border=0 ".
         "style=\"width:100%;table-layout:fixed;padding:0;".
                 "border-width:0;margin:0\">".
         "<tr><td><div class=multilinehtml>XXX</div></td></tr></table>";
   return($d);
}








1;
