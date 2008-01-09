package faq::lib::forum;
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
use kernel;

sub getShortLastworker
{
   my $self=shift;
   my $current=shift;
   my $lastentry=$current->{lastentry};
   my $d;
   my $maxlen=10;
   if ($lastentry ne ""){
      my $en=$self->getParent->getPersistentModuleObject("faq::forumentry");
      $en->SetFilter({id=>\$lastentry});
      my ($erec,$msg)=$en->getOnlyFirst(qw(creator));
      if (defined($erec) && $erec->{creator} ne ""){
         my $u=$self->getParent->getPersistentModuleObject("base::user");
         $u->SetFilter({userid=>\$erec->{creator}});
         my ($urec,$msg)=$u->getOnlyFirst(qw(surname));
         if (defined($urec)){
            $d=$urec->{surname};
         }
      }
   #   $d=$urec->{email} if ($d eq "");
   #   $d=substr($d,0,$maxlen-3)."..." if (length($d)>$maxlen);
   }
   return($d);
}


1;
