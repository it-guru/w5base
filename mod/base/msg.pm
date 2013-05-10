package base::msg;
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
use CGI;
@ISA=qw(kernel::App::Web);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(loading Empty));
}

sub loading
{
   my ($self)=@_;

   print $self->HttpHeader("text/html");
   my $t=$self->T($self->Self());
   $t="" if ($t eq $self->Self());

   print $self->HtmlHeader(style=>'default.css',
                           title=>$t);
   printf("<table width=\"100%%\" height=\"100%%\">".
          "<tr><td valign=center align=center>".
         "Loading ...".
         "</td></tr></table>");
   print $self->HtmlBottom(body=>1,form=>1);
}


1;
