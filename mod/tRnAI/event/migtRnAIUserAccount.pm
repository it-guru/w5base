package tRnAI::event::migtRnAIUserAccount;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
use kernel::Event;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}


sub migtRnAIUserAccount
{
   my $self=shift;

   my $e=getModuleObject($self->Config,'tRnAI::useraccount');
   my $op=getModuleObject($self->Config,'tRnAI::lnkuseraccountsystem');

   foreach my $rec ($e->getHashList('ALL')) {
      printf ("Process $rec->{fromappl} $rec->{name}\n");
      my $newrec={
         reltyp=>'PRIM',
         useraccount=>$rec->{name},
         system=>$rec->{system}
      };
      if (!$op->ValidatedInsertRecord($newrec)){
        printf STDERR ("Fail: %s\n",Dumper($newrec));
      }
   }
   return({exitcode=>0,msg=>'ok'});
}

1;
