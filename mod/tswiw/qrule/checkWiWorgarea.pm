package tswiw::qrule::checkWiWorgarea;
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
use strict;
use vars qw(@ISA);
use kernel;
use kernel::QRule;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return(["tswiw::orgarea"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $errorlevel=0;
   my @qmsg;

   if ($rec->{shortname} eq ""){
      push(@qmsg,"no tOuSD value");
      $errorlevel=3;
   }
   else{
      my $c="[\(\)a-zA-Z0-9_-\@ ]";
      if (!($rec->{shortname}=~m/^$c+$/)){
         push(@qmsg,"tOuSD includes invalid characters. valids are: $c");
      }
   }
   return($errorlevel,{qmsg=>\@qmsg});
}



1;
