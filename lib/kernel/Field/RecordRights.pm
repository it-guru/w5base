package kernel::Field::RecordRights;
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{group}="source"      if (!defined($self->{group}));


   my @l=(
      new kernel::Field::Interface(
                name          =>'recordRead',
                group         =>$self->{group},
                uploadable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                #depend        =>['ALL'],
                label         =>'Rights: read on fieldgroups',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my @l=$self->getParent->isViewValid($current);
                   return() if ($#l==-1 || ($#l==0 && !defined($l[0])));
                   return(\@l);
                }),
      new kernel::Field::Interface(
                name          =>'recordWrite',
                group         =>$self->{group},
                uploadable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                #depend        =>['ALL'],
                label         =>'Rights: write on fieldgroups',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my @l=$self->getParent->isWriteValid($current);
                   return() if ($#l==-1 || ($#l==0 && !defined($l[0])));
                   return(\@l);
                }),
      new kernel::Field::Interface(
                name          =>'recordDelete',
                group         =>$self->{group},
                uploadable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                #depend        =>['ALL'],
                label         =>'Rights: delete record',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   if ($self->getParent->isDeleteValid($current)){
                      return(1);
                   }
                   return(0);
                }),
   );


   return(@l);
}
1;
