package AL_TCom::businessservice;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
use kernel::Field;
use itil::businessservice;
@ISA=qw(itil::businessservice);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->getField("application")->{weblinkto}="AL_TCom::appl";
   $self->getField("srcapplication")->{vjointo}="AL_TCom::appl";

   $self->AddFields(
      new kernel::Field::Contact(
                name          =>'requestor',
                group         =>'contactpersons',
                label         =>'Requestor',
                vjoinon       =>'requestorid'),

      new kernel::Field::Link(
                name          =>'requestorid',
                label         =>'Requestor ID',
                group         =>'contactpersons',
                dataobjattr   =>"businessservice.contact1"),

#      new kernel::Field::Contact(
#                name          =>'slmgr',
#                group         =>'contactpersons',
#                label         =>'responsible service level manager',
#                vjoinon       =>'slmgrid'),
#
#      new kernel::Field::Link(
#                name          =>'slmgrid',
#                label         =>'responsible service level manager ID',
#                group         =>'contactpersons',
#                dataobjattr   =>"businessservice.contact2"),
#
#      new kernel::Field::Contact(
#                name          =>'itsowner',
#                group         =>'contactpersons',
#                label         =>'responsible IT-Service owner',
#                vjoinon       =>'itsownerid'),
#
#      new kernel::Field::Link(
#                name          =>'itsownerid',
#                label         =>'responsible IT-Service owner ID',
#                group         =>'contactpersons',
#                dataobjattr   =>"businessservice.contact3"),
#
#      new kernel::Field::Contact(
#                name          =>'eventmgr',
#                group         =>'contactpersons',
#                label         =>'responsible event manager',
#                vjoinon       =>'eventmgrid'),
#
#      new kernel::Field::Link(
#                name          =>'eventmgrid',
#                label         =>'responsible event manager ID',
#                group         =>'contactpersons',
#                dataobjattr   =>"businessservice.contact4"),
#
#      new kernel::Field::Contact(
#                name          =>'procdesi',
#                group         =>'contactpersons',
#                label         =>'responsible process designer',
#                vjoinon       =>'procdesiid'),
#
#      new kernel::Field::Link(
#                name          =>'procdesiid',
#                label         =>'responsible process designer ID',
#                group         =>'contactpersons',
#                dataobjattr   =>"businessservice.contact5"),
#
   );
   $self->AddGroup("contactpersons",translation=>'AL_TCom::businessservice');



   return($self);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my @l=$self->SUPER::getDetailBlockPriority(@_);
   my $inserti=$#l;
   for(my $c=0;$c<=$#l;$c++){
      $inserti=$c+1 if ($l[$c] eq "desc");
   }
   splice(@l,$inserti,$#l-$inserti,("contactpersons",@l[$inserti..($#l+-1)]));
   return(@l);

}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   my @l=$self->SUPER::isViewValid($rec);

   if (in_array(\@l,["desc","ALL"])){
      push(@l,"contactpersons");
   }

   return(@l);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my @l=$self->SUPER::isWriteValid($rec);

   if (in_array(\@l,["desc","ALL"])){
      push(@l,"contactpersons");
   }

   return(@l);
}









1;
