package kernel::Form;
#  W5Base Framework
#  Copyright (C) 2002  Hartmut Vogler (it@guru.de)
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
#
use vars qw(@ISA);
use strict;
use kernel;
use kernel::Universal;

@ISA=qw(kernel::Universal);

sub new
{
   my $type=shift;
   my $self=bless({@_},$type);
   return($self);
}

sub Init   
{
   my $self=shift;
   return(1);
}

sub InitForm
{
   my $self=shift;
   my $form=shift;
   return(1);
}


sub Form
{
   my $self=shift;

   my $d="<table>";
   if (ref($self->getParent->{'FrontendFieldOrder'}) eq "ARRAY"){
      foreach my $name (@{$self->getParent->{'FrontendFieldOrder'}}){
         $d.="<tr><td width=1% nowrap>%$name(label)%</td>".
                 "<td>%$name(detail)%</td></tr>";
      }
   }
   $d.="</table>";
   return($d);
}

sub Fill
{
   my $self=shift;
   my $form=shift;
   my $page=shift;

}





sub Validate
{
   my $self=shift;
   my $newrec=shift;
   return(1);
}




1;

