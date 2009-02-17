package AL_TCom::P800causecheck;
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
use kernel::date;
use kernel::App::Web;
use AL_TCom::lib::workflow;
@ISA=qw(kernel::App::Web AL_TCom::lib::workflow);

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
   print(<<EOF);
<style>
td,th{
   white-space:nowrap;
}

</style>

EOF
   print("<table border=1>");
   print("<tr>");
   print("<th>interner Name</th>");
   print("<th>Workflow-DropDown (deutsch)</th>");
   print("<th>Workflow-DropDown (english)</th>");
   print("<th>Servicemodul (de-XLS Report)</th>");
   print("<th>Leistungs-Typ (de-XLS Report)</th>");
   print("<th>Tätigkeit (de-XLS Report)</th>");
   print("<th>Servicemodul (en-XLS Report)</th>");
   print("<th>Leistungs-Typ (en-XLS Report)</th>");
   print("<th>Tätigkeit (en-XLS Report)</th>");
   print("</tr>");
   my $t="AL_TCom::lib::workflow";
   foreach my $cause ($self->tcomcodcause(),"sw.addeff.swbase"){
      print("<tr>");
      printf("<td>%s</td>",$cause);
      $ENV{HTTP_FORCE_LANGUAGE}="de";
      printf("<td>%s</td>",$self->T($cause,$t));
      $ENV{HTTP_FORCE_LANGUAGE}="en";
      printf("<td>%s</td>",$self->T($cause,$t));
      $ENV{HTTP_FORCE_LANGUAGE}="de";
      my ($smodule)=$cause=~m/^(\S+?)\./;
      printf("<td>%s</td>",$self->T($smodule,$t));
      my ($styp)=$cause=~m/(\.\S+?\.)/;
      printf("<td>%s</td>",$self->T($styp,$t));
      my ($scause)=$cause=~m/^\S+\.\S+(\.\S+)$/;
      printf("<td>%s</td>",$self->T($scause,$t));
      $ENV{HTTP_FORCE_LANGUAGE}="en";
      my ($smodule)=$cause=~m/^(\S+?)\./;
      printf("<td>%s</td>",$self->T($smodule,$t));
      my ($styp)=$cause=~m/(\.\S+?\.)/;
      printf("<td>%s</td>",$self->T($styp,$t));
      my ($scause)=$cause=~m/^\S+\.\S+(\.\S+)$/;
      printf("<td>%s</td>",$self->T($scause,$t));
      print("</tr>");
      delete($ENV{HTTP_FORCE_LANGUAGE});
   }
   print("</table>");
}

1;
