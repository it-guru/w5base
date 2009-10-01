package base::event::dbdump;
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
use Data::Dumper;
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

sub Init
{
   my $self=shift;
   $self->RegisterEvent("tinyDBDump","tinyDBDump");
   return(1);
}

sub tinyDBDump
{
   my $self=shift;
   my $appl=getModuleObject($self->Config,"itil::appl");
   $appl->ResetFilter();
   $appl->SetFilter(name=>'SEPT');
   $appl->SetCurrentOrder("NONE");
#   $appl->SetCurrentView(qw(id,name,systems));
   my $view=$appl->getHashList(qw(id name systems));

   msg(DEBUG,Dumper($view));
   return(0);
}

1;









