package cms::dsp;
#  W5Base Framework - Content Management System - display tool
#  Copyright (C) 2007  Hartmut Vogler (it@guru.de)
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
   return(qw(page));
}

sub page
{
   my ($self)=@_;
   my ($func,$p)=$self->extractFunctionPath();

   print $self->HttpHeader("text/html");
   $p="/index.html" if ($p eq "");
   $p.="index.html" if ($p=~m/\/$/);
   $p=~s/^\///;
   print $self->ExpandPath($p);
}

sub ExpandPath
{
   my $self=shift;
   my $path=shift;

   my $tmplfile=$self->getSkinFile("cms/tmpl/$path");
   my $p;
   eval('use XML::Parser;$p = new XML::Parser();');
   if (!defined($p)){
      msg(ERROR,"can' create XML Parser");
      return(undef);
   }
   eval('$p->parsefile($tmplfile);');
   if ($@ ne ""){
      printf("ERROR: %s",$@);
      return(undef);
   }


   
   print "This is a test  path='$path' tmplfile='$tmplfile'";
   return("");
}


1;
