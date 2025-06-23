package itil::lnksystemcontact;
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
                name          =>'system',
                htmlwidth     =>'100px',
                label         =>'System',
                vjointo       =>'itil::system',
                vjoinon       =>['refid'=>'id'],
                vjoindisp     =>'name'),
      insertafter=>'id'
   );

   $self->AddFields(
      new kernel::Field::Link(
                name          =>'systemcistatusid',
                htmlwidth     =>'100px',
                label         =>'System CI-Status',
                vjointo       =>'itil::system',
                vjoinon       =>['refid'=>'id'],
                vjoindisp     =>'cistatusid',
                dataobjattr   =>'system.cistatus'),
      insertafter=>'id'
   );

   $self->{secparentobj}='itil::system';
   $self->setDefaultView(qw(system targetname cdate editor));
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @filter=@_;


   my $from=$self->SUPER::getSqlFrom($mode,@filter);
   my ($worktable,$workdb)=$self->getWorktable();

   $from.=" left outer join system ".
          "on ${worktable}.refid=system.id ";

   return($from);
}


1;
