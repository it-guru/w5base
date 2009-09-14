package itil::lnkapplinteranswer;
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
use base::interanswer;
@ISA=qw(base::interanswer);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'application',
                htmlwidth     =>'100px',
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if (defined($current));
                   return(0);
                },
                label         =>'Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['parentid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'appl.name'),
      insertafter=>'id'
   );
   $self->getField("parentobj")->{searchable}=0;
   $self->getField("parentid")->{searchable}=0;
   $self->{secparentobj}='itil::appl';
   $self->setDefaultView(qw(application name answer mdate editor));
   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my $j=$self->SUPER::getSqlFrom();

   return("$j join appl on $worktable.parentid=appl.id");
}


1;
