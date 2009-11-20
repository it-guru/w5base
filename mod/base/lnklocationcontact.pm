package base::lnklocationcontact;
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
                name          =>'location',
                htmlwidth     =>'100px',
                label         =>'Location',
                vjointo       =>'base::location',
                vjoinon       =>['refid'=>'id'],
                vjoindisp     =>'name'),
      insertafter=>'id'
   );
   $self->{secparentobj}='base::location';
   $self->setDefaultView(qw(location targetname cdate editor));
   return($self);
}
1;
