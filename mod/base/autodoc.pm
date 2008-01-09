package base::autodoc;
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
use kernel::config;
use kernel::App::Web;
use kernel::Output;
use Data::Dumper;
@ISA    = qw(kernel::App::Web);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}  

sub getValidWebFunctions
{  
   my ($self)=@_;
   return(qw(Main MainImage));
}

sub Main
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css'],
                           body=>1,form=>1);
   my $gdavailable=0;
   eval("use GD;");
   $gdavailable=1 if ($@ eq "");
   if ($gdavailable){
      print("<style>body{background:silver}</style>");
      print("<table width=100% height=100%>");
      print("<tr><td align=center valign=center><img border=1 src=\"MainImage\"></td>");
      print("</table>");
   }
   else{
      print("GD fail<br>");
   }
   print $self->HtmlBottom(body=>1,form=>1);
}

sub MainImage
{
   my $self=shift;
   print $self->HttpHeader("image/jpeg");
   my $im;
   eval("use GD;\$im=new GD::Image(600,400);");
   return(undef) if ($@ ne "");

   my $white = $im->colorAllocate(255,255,255);
   my $black = $im->colorAllocate(0,0,0);
   my $silver = $im->colorAllocate(244,244,244);
   my $red   = $im->colorAllocate(255,0,0);
   my $blue  = $im->colorAllocate(0,0,255);

   # make the background transparent and interlaced
   $im->interlaced('true');
   $im->setAntiAliased($black);
   $im->setThickness(2);
   $im->string(GD::Font->MediumBold,200,200,"Application",$black);
   $im->string(GD::Font->MediumBold,200,220,"System",$black);
   $im->string(GD::Font->MediumBold,200,240,"Customer Contract",$black);

   $im->rectangle(0,0,599,399,$black);
   $im->arc(80,50,100,50,0,360,$black);
   $im->fill(50,50,$silver);
   $im->string(GD::Font->MediumBold,50,50,"Test",$black);

   # make sure we are writing to a binary stream
   binmode STDOUT;
   print $im->gif;
}
1;
