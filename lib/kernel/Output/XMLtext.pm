package kernel::Output::XMLtext;
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
use base::load;
use kernel::Output::XMLV01;
@ISA    = qw(kernel::Output::XMLV01);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub IsModuleSelectable
{
   return(0);
}
sub getRecordImageUrl
{
   return("../../../public/base/load/icon_xml.gif");
}
sub Label
{
   return("Output to XML text");
}
sub Description
{
   return("Format as lowlevel XML-File language neutral - text/plain. Use for IE raw XML Download");
}

sub MimeType
{
   return("text/plain");
}



sub ProcessHead
{
   my ($self,$fh,$rec,$msg)=@_;
   my $d;
   my $app=$self->getParent->getParent();  # IE/Excel not works correct on UTF8
   $d="<?xml version=\"1.0\" encoding=\"iso-8859-1\" ?>\n<root>\n";
   return($d);
}


sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$msg)=@_;
   my $d=$self->SUPER::ProcessLine($fh,$viewgroups,$rec,$msg);

   $d=UTF8toLatin1($d);

   return($d);
}





1;
