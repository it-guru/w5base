package base::tztest;
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
use vars qw(@ISA $override);
use kernel;
use kernel::date;
use kernel::App::Web;
use POSIX;
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
   return(qw(Main));
}

sub Main
{
   my ($self)=@_;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>'default.css',
                           title=>$self->T($self->Self()));
   my @tzlist=qw(CET GMT UST);
   printf("<table border=1><tr><td></td>");
   foreach my $tz (@tzlist){
      printf("<th>%s</th>",$tz); 
   }
   printf("</tr>");



   printf("<tr><td>kernel::date::Localtime</td>");
   foreach my $tz (@tzlist){
      printf("<td>%s</td>",scalar(Localtime($tz)));
   }
   printf("</tr>");


   printf("<tr><td>localtime+ENV</td>");
   foreach my $tz (@tzlist){
      $ENV{TZ}=$tz;
      POSIX::tzset(); 
      printf("<td>%s</td>",scalar(localtime()));
   }
   printf("</tr>");

   printf("</table>");
   print $self->HtmlBottom(body=>1,form=>1);
}

1;
