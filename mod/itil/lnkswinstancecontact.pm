package itil::lnkswinstancecontact;
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
use base::lnkcontact;
@ISA=qw(base::lnkcontact);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'swinstance',
                htmlwidth     =>'100px',
                label         =>'Software Instance',
                vjointo       =>'itil::swinstance',
                vjoinon       =>['refid'=>'id'],
                vjoindisp     =>'fullname'),
      insertafter=>'id'
   );

   $self->AddFields(
      new kernel::Field::Link(
                name          =>'swinstancecistatusid',
                htmlwidth     =>'100px',
                label         =>'Software-Instance CI-Status',
                vjointo       =>'itil::swinstance',
                vjoinon       =>['refid'=>'id'],
                vjoindisp     =>'cistatusid',
                dataobjattr   =>'swinstance.cistatus'),
      insertafter=>'id'
   );

   $self->{secparentobj}='itil::swinstance';
   $self->setDefaultView(qw(swinstance targetname cdate editor));
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @filter=@_;


   my $from=$self->SUPER::getSqlFrom($mode,@filter);
   my ($worktable,$workdb)=$self->getWorktable();

   $from.=" left outer join swinstance ".
          "on ${worktable}.refid=swinstance.id ";

   return($from);
}


1;
