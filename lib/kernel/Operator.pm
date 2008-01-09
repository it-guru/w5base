package kernel::Operator;
#  W5Base Framework
#  Copyright (C) 2002  Hartmut Vogler (hartmut.vogler@epost.de)
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
use Data::Dumper;

@ISA=qw();


sub IsModuleSelectable
{
   return(0);
}
sub IsModuleDownloadable
{
   return(0);
}
sub getRecordImageUrl
{
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/workflow.jpg?".$cgi->query_string());
}
sub Label
{
   my $self=shift;
   my $parent=$self->getParent->getParent;
   if (defined($parent)){
      return($self->getParent->getParent->T($self->Self,
             $self->getParent->getParent->Self(),$self->Self()));
   }
   return($self->getParent->T($self->Self,$self->Self));
}
sub Description
{
   return("bla bla bl sadfj sdfjh dsjfh sd fala bla bla bla sdfhaasfjda fjkasfhd klasfdlaksd6 d6 a6d5 fd65fc a8sdf5cvads");
   return("none");
}
sub MimeType
{
   return("text/plain");
}

1;

