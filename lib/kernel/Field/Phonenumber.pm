package kernel::Field::Phonenumber;
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
@ISA    = qw(kernel::Field::Text);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{nowrap}=1;
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return({}) if (!exists($newrec->{$self->Name()}));
   my $newvalreq=$newrec->{$self->Name()};
   return({$self->Name()=>undef}) if ($newvalreq eq "");
   my $newvallist=$newvalreq;
   $newvallist=[$newvallist] if (ref($newvallist) ne "ARRAY");
   my $newvallist=[map({
         my $m=trim($_);
         if ($m ne ""){
            if (!($m=~m/^\s*[0-9\+\/)(-\s]*$/) ||
                 ($m=~m/\+.*\+/)){                # allow +xxx only once!
               $self->getParent->LastMsg(ERROR,
                            "invalid phonenumber format '%s'",$m);
               return(undef);
            }
            # normalice
            if (my ($pref,$num)=$m=~m/^([0-9\s]+)\/([0-9-\s]+)$/){
               $pref=~s/\s//g;
               $pref=~s/^00([^0])/+49 $1/g;
               $pref=~s/^0([^0])/+49 $1/g;
               $num=~s/\s//g;
               $m="$pref $num";
            }
            if (my ($num)=$m=~m/^([0-9\s]+)$/){
               $num=~s/\s//g;
               $num=~s/^00([^0])/+49 $1/;
               $num=~s/^0([^0])/+49 $1/;
               $num=~s/^\+49 17([0-9]{1})/+49 17$1 /;
               $num=~s/^\+49 16([0-9]{1})/+49 16$1 /;
               $m="$num";
            }
         }
         $m=lc($m);
         $m=undef if ($m eq "");
         $_=$m;
      } @{$newvallist})];
   if (ref($newvalreq) eq "ARRAY"){
      return({$self->Name()=>$newvallist});
   }
   return({$self->Name()=>$newvallist->[0]});
}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);

   if ($mode=~m/^HtmlDetail/){
      if ($d ne ""){
         my $dformfine="";
         my $dlist=$d;
         $dlist=[$d] if (ref($d) ne "ARRAY");
         foreach my $d (@$dlist){
            my $dform=$d;
            my $UserCache=$self->getParent-> 
                       Cache->{User}->{Cache}->{$ENV{REMOTE_USER}};
            if (ref($UserCache) eq "HASH"){
               my $jsdialcall=FormatJsDialCall($UserCache->{rec}->{dialermode},
                                   $UserCache->{rec}->{dialeripref},
                                   $UserCache->{rec}->{dialerurl},
                                   $d);
               if (defined($jsdialcall)){
                  my $t="click to dial with ".$UserCache->{rec}->{dialermode};
                  $dform="<span title=\"$t\" ".
                         "onclick=\"$jsdialcall\" class=sublink>".
                         $dform."</span>";
               }
            }
            $dformfine.="; " if ($dformfine ne "");
            $dformfine.=$dform;
         }
         return($dformfine);
      } 
      return($d);
   }
   else{
      return($self->SUPER::FormatedDetail($current,$mode));
   }
}







1;
