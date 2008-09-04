package kernel::QuickFind;
#  W5Base Framework
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
#
use vars qw(@ISA);
use strict;
use kernel;
use kernel::Universal;
use kernel::cgi;

@ISA=qw(kernel::Universal);

sub new
{
   my $type=shift;
   my $self=bless({@_},$type);
   return($self);
}

sub addDirectLink
{
   my $self=shift;
   my $dataobj=shift;
   my %param=@_;
   my $d="";

   $param{AllowClose}=1;
   my $detailx=$dataobj->DetailX();
   my $detaily=$dataobj->DetailY();
   my $target="../../".$dataobj->Self()."/Detail";
   $target=~s/::/\//g;
   my $qstr=kernel::cgi::Hash2QueryString(%param);

   my $onclick="openwin(\"$target?$qstr\",\"_blank\",".
               "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
               "resizable=yes,scrollbars=no\")";


   $d.="<img align=right border=0 ".
       "src=\"../../../public/base/load/directlink.gif\">";
   $d="<div style=\"margin:2px\"><a class=sublink href=JavaScript:$onclick>".
      $d."</a></div>";

   return($d);
}


1;

