package AL_TCom::event::p800check;
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


   $self->RegisterEvent("p800check","p800check");
   return(1);
}

sub p800check
{
   my $self=shift;
   my $app=$self->getParent;
   my $wf=getModuleObject($self->Config,"base::workflow");

   my $start=$app->ExpandTimeExpression("01.01.2006","en","CET");
   my $end=$app->ExpandTimeExpression("31.01.2006","en","CET");
   my $srcsys="p800check";
   my $srcid="1";
   my %rec=(srcsys=>$srcsys,
            srcid=>$srcid,
            name=>'P800 Report - 01/2006 - Vertrag: 1-1234',
            stateid=>1,
            openuser=>'11630108220001',
            eventstart=>$start,
            p800_app_changecount=>44,
            p800_app_changecount_technical=>4,
            p800_app_changecount_software=>40,
            p800_app_incidentcount=>4,
            p800_sys_count=>15,
            eventend=>$end,
            class=>'AL_TCom::workflow::P800',
            step=>'AL_TCom::workflow::P800::dataload');

   $wf->ValidatedInsertOrUpdateRecord(\%rec,{srcsys=>\$srcsys,srcid=>\$srcid});
}

1;

