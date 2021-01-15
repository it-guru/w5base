package kernel::Field::Email;
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
@ISA    = qw(kernel::Field::Text);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return({}) if (!exists($newrec->{$self->Name()}));
   my $newvalreq=$newrec->{$self->Name()};
   my $newvallist=$newvalreq;
   $newvallist=[$newvallist] if (ref($newvallist) ne "ARRAY");
   my $newvallist=[map({
         my $m=trim($_);
         if ($m ne ""){
            if (!($m=~m/^\S+\@\S+\.\S+$/) &&
                !($m=~m/^".+" <\S+\@\S+\.\S+>$/) &&
                !($m=~m/^".+" <>$/) ){
               $self->getParent->LastMsg(ERROR,
                            "invalid E-Mail address format '%s'",$m);
               return(undef);
            }
         }
         if (my ($name,$mail)=$m=~m/^"(.+)" <(.*)>$/){
            $m='"'.$name.'" <'.lc($mail).'>';
         }
         else{
            $m=lc($m);
         }
         $m=~s/^(smtp:)//i;
         if (!($m=~m/^".*" <.*>$/)){
            $m=~s/[^a-z0-9_\.\@-]//gi;
         }
         $m;
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
   my $name=$self->Name();
   my $app=$self->getParent();
   
   if ($mode eq "HtmlDetail"){
      $d=[$d] if (ref($d) ne "ARRAY");
      return(join("; ",map({ my $m=$_;
                             $m=~s/</&lt;/g;
                             $m=~s/>/&gt;/g;
                             my $ml=$_;
                             $ml=~s/"/&quote;/g;
                            "<a class=emaillink tabindex=-1 ".
                            "href=\"mailto:$ml\">$m</a>"
                           } @{$d})));
   }
   return($self->SUPER::FormatedDetail($current,$mode));
}









1;
