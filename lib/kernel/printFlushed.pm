package kernel::printFlushed;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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

sub printFlushedStart
{
   my $self=shift;
   if (!exists($self->{Apache2RequestUtilrequest})){
      $self->{Apache2RequestUtilrequest}=Apache2::RequestUtil->request;
      my $r=$self->{Apache2RequestUtilrequest};
      $r->no_cache(1);
      $r->content_type("text/html");
      $r->print("<html>");
      $r->print("<style>");
      $r->print("xmp{padding:0;margin:0;font-size:11px}");
      $r->print("body{background:white}");
      $r->print("</style>");
      $r->print("<script language='JavaScript'>");
      $r->print("var oldY=0;");
      $r->print("function l(){");
      $r->print("if (document.body.scrollTop==oldY){");
      $r->print("window.scrollTo(0,100000);");
      $r->print("oldY=document.body.scrollTop;");
      $r->print("}");
      $r->print("else{");
      $r->print("oldY=-1");
      $r->print("}");
      $r->print("}");
      $r->print("</script>");
      $r->print("<head>");
      $r->print("<body>");
   }
}

sub printFlushed
{
   my $self=shift;
   my @l=@_;
   if (!exists($self->{Apache2RequestUtilrequest})){
      $self->printFlushedStart();
   }
   my $r=$self->{Apache2RequestUtilrequest};

   foreach my $line (@l){
      $line="<xmp>".$line."</xmp>";
      $line.="<script language='JavaScript'>l();</script>";
      if (length($line<256)){
         $line.=" " x (255-length($line));
      }
      $r->print($line."\r\n");
   }
}

sub printFlushedFinish
{
   my $self=shift;

   if (!exists($self->{Apache2RequestUtilrequest})){
      $self->printFlushedStart();
   }
   my $r=$self->{Apache2RequestUtilrequest};
   $r->print("</body>");
   $r->print("</html>");
}


1;
