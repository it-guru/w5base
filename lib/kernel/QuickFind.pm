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

sub addPhoneNumbers
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $k=shift;
   my $ntypes=shift;
   my $d="";

   if (exists($rec->{$k}) && ref($rec->{$k}) eq "ARRAY"){
      foreach my $prec (@{$rec->{$k}}){
         if (grep(/^$prec->{name}$/,@$ntypes)){
            my $phonelabel=$prec->{shortedcomments};
            if ($phonelabel=~m/^\s*$/){
               $phonelabel=$dataobj->T($prec->{name},
                              $dataobj->Self,"base::phonelnk");
            }
            if (ref($dataobj->{PhoneLnkUsage}) eq "CODE"){
               my %tr=&{$dataobj->{PhoneLnkUsage}}($dataobj);
               if (exists($tr{$phonelabel})){
                  $phonelabel=$tr{$phonelabel};
               }
            }
            $d.="<tr><td valign=top>$phonelabel</td>";
            $d.="<td valign=top>$prec->{phonenumber}</td></tr>";
         }
      }
   }
   if ($d ne ""){
      $d="<tr height=1><td height=1><img src=\"../../base/load/empty.gif\" ".
          "width=180 height=1></td><td height=1></td></tr>".$d;
   }
   return($d);

}

sub addDirectLink
{
   my $self=shift;
   my $dataobj=shift;
   my $param=shift;
   my $d="";

   my $onclick=$dataobj;
   if (ref($param) eq "HASH"){
      my %param=%$param;
      $param{AllowClose}=1;
      my $detailx=$dataobj->DetailX();
      my $detaily=$dataobj->DetailY();
      my $target="../../".$dataobj->Self()."/Detail";
      if ($dataobj->Self() eq "base::workflow"){
         $target="../../".$dataobj->Self()."/Process";
      }
      $target=~s/::/\//g;
      my $qstr=kernel::cgi::Hash2QueryString(%param);

      $onclick="JavaScript:openwin(\"$target?$qstr\",\"_blank\",".
                  "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
                  "resizable=yes,scrollbars=no\")";
   }


   $d.="<img align=right border=0 ".
       "src=\"../../../public/base/load/directlink.gif\">";
   $d="<div style=\"float:right;margin:2px\"><a class=sublink href=$onclick>".
      $d."</a></div>";
 

   return($d);
}

sub addVisualLink
{
   my $self=shift;
   my $dataobj=shift;
   my $param=shift;
   my $d="";

   my $onclick;
   my $target;
   my $qstr;

   if ($dataobj->can("generateContextMap")){
      my $detailx=$dataobj->DetailX();
      my $detaily=$dataobj->DetailY();
      $target="../../".$dataobj->Self()."/Map/".$param;
      $target=~s/::/\//g;
      
      $onclick="openwin(\"$target\",\"_blank\",".
                  "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
                  "resizable=yes,scrollbars=no\");return(false);";


      $d.="<img align=right border=0 ".
          "src=\"../../../public/base/load/visual_small.gif\">";
      $d="<div style=\"float:right;margin:2px\">".
         "<a class=sublink href=\"$target\" onclick='$onclick'>".
         $d."</a></div>";
   }

   return($d);
}


1;

