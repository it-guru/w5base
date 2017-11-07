package base::explorer;
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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
   return(qw(Main Explore));
}

sub Main
{
   my ($self)=@_;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css'],
                           js=>['spin.js','toolbox.js'],
                           title=>$self->T($self->Self()));
   print $self->getAppTitleBar();


   print(<<EOF);
<iframe frameborder=0 id=workspace src='Explore' style='width:100%;margin:0; padding:0; overflow:hidden; z-index:999999;'></iframe>
<script>
function ExplorerSetSize()
{
   var h=getViewportHeight();
   var tb=document.getElementById("TitleBar");
   var ws=document.getElementById("workspace");
   var newh=h-tb.offsetHeight-4;
   ws.style.height=newh+'px';

}

function ExplorerResize()
{
   var h=getViewportHeight();
   var ws=document.getElementById("workspace");
   ws.style.height='10px';
   window.setTimeout('ExplorerSetSize();',100);
}
function ExplorerInit()
{
   ExplorerResize();
}
addEvent(window, "resize", ExplorerResize);
addEvent(window, "load",   ExplorerInit);
</script>
EOF




   print $self->HtmlBottom(body=>1,form=>1);
}

sub Explore
{
   my $self=shift;

   print $self->HttpHeader("text/html");
   my $opt={
      static=>{
      }
   };

   my $prog=$self->getParsedTemplate("tmpl/base.explorer",$opt);
   utf8::encode($prog);
   print($prog);
}


1;
