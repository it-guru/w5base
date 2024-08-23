package kernel::Field::Objects;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my %self=(@_);
   $self{uivisible}=0 if (!defined($self{uivisible}));
   $self{searchable}=0 if (!defined($self{searchable}));
   my $self=bless($type->SUPER::new(%self),$type);
   if (!defined($self->{sqlorder})){
      $self->{sqlorder}='NONE';
   }
   return($self);
}

#sub getBackendName     # returns the name/function to place in select
#{
#   my $self=shift;
#   my $mode=shift;
#   my $db=shift;
#   if ($mode eq "select"){
#      return("__raw_container_.".$self->{dataobjattr});
#   }
#   return($self->SUPER::getBackendName($mode,$db));
#}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);
   my $name=$self->Name();
   if ($mode eq "SOAP"){
#      my $xml;
#      if (ref($d) eq "HASH" && keys(%$d)){
#         foreach my $k (sort(keys(%$d))){
#            my $val=$d->{$k};
#            $val=[$val] if (ref($val) ne "ARRAY");
#            foreach my $vval (@$val){
#               $xml.="<item><name>$k</name><value>".
#                     quoteSOAP($vval)."</value></item>";
#            }
#         }
#      }
      return(undef);
   }
   if ($mode=~m/html/i){
      if (defined($d) && ref($d) eq "ARRAY" ){
         my $r=$self->arrayhash2table(0,$d);
         return($r);
      }
      return(undef);
   }
#   if ($mode=~m/edit/i){
#      return(undef);
#   }
   $d=Dumper($d);
   return($d);
}

sub arrayhash2table
{
   my $self=shift;
   my $loopcount=shift;
   my $ad=shift;
   return("...") if ($loopcount>3);

   my $r="<table border=1 class=objectframe>"; 
   foreach my $d (@$ad){
      $r.="<tr><td>";
      $r.="<table class=containerframe>"; 
      foreach my $k (sort(keys(%{$d}))){
         $r.="<tr>"; 
         my $descwidth="width=1%";
         if (defined($self->{desccolwidth})){
            $descwidth="width=$self->{desccolwidth}"; 
         }
         $r.="<td class=containerfname $descwidth valign=top>$k</td>"; 
         my $dk=$d->{$k};
         if (ref($dk) eq "HASH"){
            $r.="<td class=containerfval valign=top>".
                $self->arrayhash2table($loopcount+1,[$dk]).
                "</td>"; 
         }
         else{
            $dk=[$dk] if (ref($dk) ne "ARRAY");
            my $dd=quoteHtml(join(", ",@{$dk}));
            $dd="&nbsp;" if ($dd=~m/^\s*$/);
            #$dd=~s/\n/<br>\n/g;
            if ($dd=~m/\n/ || $dd=~m/\S{40}/){
               $dd="<table ".
                  "style=\"width:100%;table-layout:fixed;padding:0;margin:0\">".
                   "<tr><td><div class=multilinetext ".
                   "style=\"height:auto;border-style:none\">".
                   "<pre class=multilinetext>$dd</pre></div></td></tr></table>";
            }
            $r.="<td class=containerfval valign=top>$dd</td>"; 
         }
         $r.="</tr>"; 
      }
      $r.="</table>"; 
      $r.="</td></tr>";
   }
   $r.="</table>"; 
   return($r);
}





sub RawValue
{
   my $self=shift;
   my $current=shift;

   return($self->SUPER::RawValue($current)) if (exists($self->{onRawValue}));
#   if (exists($current->{"w5___raw_container___".$self->Name})){
#      $current->{$self->Name}=$current->{"w5___raw_container___".$self->Name};
#      delete($current->{"w5___raw_container___".$self->Name});
#   }
#   if (ref($current->{$self->Name}) ne "HASH"){
#      my %h=Datafield2Hash($current->{$self->Name});
#   #   CompressHash(\%h);  # should not be Standard
#      $current->{$self->Name}=\%h;
#   }
   return($current->{$self->Name});
}

#sub finishWriteRequestHash
#{
#   my $self=shift;
#   my $oldrec=shift;
#   my $newrec=shift;
#   my $p=$self->getParent;
#
#   my $oldhash;
#   my $changed=0;
#   foreach my $fo ($p->getFieldObjsByView([$p->getCurrentView()],
#                                          current=>$newrec,oldrec=>$oldrec)){
#      if (exists($fo->{container}) && $fo->{container} eq $self->Name()){
#         if (exists($newrec->{$fo->Name()})){
#            if (!defined($oldhash)){ # read oldhash value only if a entry
#               my %oldcopy;          # of the container is specified in newrec
#               %oldcopy=%{$self->RawValue($oldrec)} if (defined($oldrec));
#               $oldhash=\%oldcopy; 
#            }
#            my $centryname=$fo->Name();
#            if (defined($fo->{containergroup})){
#               $centryname=$fo->{containergroup}.".".$centryname;
#            }
#            $oldhash->{$centryname}=$newrec->{$fo->Name()};
#            delete($newrec->{$fo->Name()});
#            $changed=1;
#         }
#      }
#   }
#   if (ref($newrec->{$self->Name}) eq "HASH"){
#      my %wr=%{$newrec->{$self->Name}};
#      foreach my $k (keys(%wr)){
#         if (exists($wr{$k}) && !defined($wr{$k})){
#            delete($wr{$k});
#         }
#      }
#      $newrec->{$self->Name}=Hash2Datafield(%wr);
#   }
#   if ($changed){
#      $newrec->{$self->Name}="" if (!defined($newrec->{$self->Name}));
#      $newrec->{$self->Name}.=Hash2Datafield(%{$oldhash});
#   }
#   # preparing the hash - > todo
#
#   return(undef);
#}

sub copyFrom
{
   my $self=shift;
   my $oldrec=shift;
   return(undef);
}








1;
