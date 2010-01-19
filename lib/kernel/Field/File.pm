package kernel::Field::File;
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
use Data::Dumper;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{sqlorder}="none";   
   return($self);
}

sub RawValue
{
   my $self=shift;
   my $current=shift;
   if (defined($self->{onDownloadUrl}) &&
          ref($self->{onDownloadUrl}) eq "CODE"){
      my $path=$ENV{SCRIPT_URI};
      $path=~s/\/(auth|public)\/.*/\/$1\//;
      my $parent=$self->getParent->Self;
      $parent=~s/::/\//g;
      my $url=$path.$parent."/".&{$self->{onDownloadUrl}}($self,$current);
      return($url);
   }
  
   return("< FileEntry >");

}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);
   my $name=$self->Name();
   if ($mode eq "HtmlDetail"){
      my $url;
      if (defined($self->{onDownloadUrl}) &&
          ref($self->{onDownloadUrl}) eq "CODE"){
         $url=&{$self->{onDownloadUrl}}($self,$current);
      }
      return("<a class=filelink href=\"$url\">$d</a>") if (defined($url));
   }
   if (($mode eq "edit" || $mode eq "workflow") && !defined($self->{vjointo})){
      return("<input type=file name=$name size=45>");
   }
   return($d);
}

sub Uploadable
{
   my $self=shift;

   return(0);
}









1;
