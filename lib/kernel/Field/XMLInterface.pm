package kernel::Field::XMLInterface;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
# This field is for internal references. In diffrent to "Link" the field
# is accessable by W5API and XML download.
#

use strict;
use vars qw(@ISA);
use kernel;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self={@_};
   $self->{searchable}=0 if (!defined($self->{searchable}));
   $self->{htmldetail}=0 if (!defined($self->{htmldetail}));
   $self->{sqlorder}="NONE" if (!defined($self->{sqlorder}));
   #$self->{rawxml}=0        if (!defined($self->{rawxml}));
   $self->{uivisible}=sub {
      my $self=shift;
      my $mode=shift;
      if ($mode eq "ViewEditor"){
         if ($self->getParent->can("IsMemberOf")){
            return(1) if ($self->getParent->IsMemberOf("admin"));
         }
         if ($self->getParent->can("getParent") && 
             defined($self->getParent->getParent())){
            return(1) if ($self->getParent->getParent->IsMemberOf("admin"));
         }
         return(0);
      }
      if ($mode eq "HtmlDetail"){
         return(0);
      }
      return(1);
   } if (!defined($self->{uivisible}));
   $self=bless($type->SUPER::new(%$self),$type);
   return($self);
}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);
   if (!exists($d->{xmlroot})){
      $d={xmlroot=>{xmlstate=>'incorrect'}};
   }
   if (!exists($d->{xmlroot}->{xmlstate})){
      $d->{xmlroot}->{xmlstate}="unknown";
   }
   my $name=$self->Name();
   if ($mode eq "SOAP"){
      my $xml;
      return(quoteSOAP(hash2xml($d)));
   }
   if ($mode=~m/html/i){ # charset handling ist noch nicht optimal! - Eigentlich
      if (defined($d) && ref($d) eq "HASH" && keys(%{$d})>0){ # muss da noch
         my $r="<pre>".quoteHtml(hash2xml($d))."</pre>"; # eine latin1 Sonder-
         return($r);  # behandlung rein!
      }
      return(undef);
   }
   if ($mode=~m/edit/i){
      return(undef);
   }
   return($d);
}


sub hash2table
{
   my $self=shift;
   my $xpath=shift;
   my $loopcount=shift;
   my $d=shift;
   return("...") if ($loopcount>2);


   my $r="<table class=containerframe>" if ($loopcount==0);
   foreach my $k (sort(keys(%{$d}))){
      my $descwidth="width=1%";
      if (defined($self->{desccolwidth})){
         $descwidth="width=$self->{desccolwidth}";
      }
      my $dk=$d->{$k};
      if (ref($dk) eq "HASH"){
         $r.=$self->hash2table([@$xpath,$k],$loopcount+1,$dk);
      }
      else{
         my $label=join(".",@$xpath,$k);
         $r.="<td class=containerfname $descwidth valign=top>$label</td>";
         $dk=[$dk] if (ref($dk) ne "ARRAY");
         my $s1="";
         my $s2="";
         foreach my $subarray (@$dk){
            if (ref($subarray)){
               $s1.=$self->hash2table([@$xpath,$k],$loopcount+1,$subarray);
            }
            else{
               my $dd=$subarray;
               my $dd=quoteHtml(join(", ",@{$dk}));
               $dd="&nbsp;" if ($dd=~m/^\s*$/);
               #$dd=~s/\n/<br>\n/g;
               $s2.="<tr>";
               if ($dd=~m/\n/ || $dd=~m/\S{40}/){
                  $dd="<table ".
                  "style=\"width:100%;table-layout:fixed;padding:0;margin:0\">".
                  "<tr><td><div class=multilinetext ".
                  "style=\"min-width:100px;height:auto;border-style:none\">".
                  "<pre class=multilinetext>$dd</pre></div></td></tr></table>";
               }
               $s2.="<td class=containerfval valign=top>$dd</td>";
               $s2.="</tr>";
            }
         }
         $r.=$s2.$s1;
      }
   }
   $r.="</table>" if ($loopcount==0);
   return($r);
}

sub RawValue
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;    # ATTENTION! - This is not always set! (at now 03/2013)

   my $d=$self->SUPER::RawValue($current,$mode);

   if (defined($d) && ref($d) ne "HASH"){
      if (!($d=~m/^<xmlroot>/)){
         $d="<xmlroot>".$d."</xmlroot>";
      }
      if (!utf8::is_utf8($d)){  # handle if Backend has XML textData not in UTF8
         $d=latin1($d)->utf8();
      }
      $d=xml2hash($d);
   }
   return($d);
}






1;
