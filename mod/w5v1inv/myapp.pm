package w5v1inv::myapp;
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
use kernel::App::Web;
use kernel::App::Web::Listedit;
use Data::Dumper;
@ISA=qw(kernel::App::Web::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->DataObj->{'cistatus'}=$self->getDataObj("base::cistatus");
   return($self);
}

sub getValidFunctions
{
   my ($self)=@_;
   return(qw(Main Result View Edit));
}


sub Main
{
   my ($self)=@_;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css'],
                           body=>1,form=>1,
                           title=>'W5Base V2');
  # $self->DataObj('cistatus')->SetFilter(id=>[1,2]);
   printf("<input type=text><br>");
   print $self->HtmlBottom(body=>1,form=>1);
}



1;
