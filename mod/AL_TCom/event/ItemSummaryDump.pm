package AL_TCom::event::ItemSummaryDump;
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
use kernel::Event;
use File::Temp qw(tempfile);

@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub ItemSummaryDump
{
   my $self=shift;

   my $o=getModuleObject($self->Config,"AL_TCom::appl");
   $o->SetFilter({name=>'W5Base/Darwin Netcool(P) GecCo(P) CCP(P)'});
   $o->SetFilter({name=>'CD-DWH_N_PROD'});
   my $f=$o->getField("itemsummary");
   open(F,">".$self->Config->Param("INSTDIR").
              "/static/tmp/ItemSummaryDump.xml");
   printf F ("<root>\n");
   foreach my $rec ($o->getHashList(qw(itemsummary name id))){
      printf F ("%s\n\n",hash2xml($rec));
   }
   printf F ("</root>\n");
   close(F);
   return({exitcode=>0});
}
1;
