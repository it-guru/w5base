package TS::lnkcampuschmapprgrp;
#  W5Base Framework
#  Copyright (C) 2017  Markus Zeis (w5base@zeis.email)
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
use TS::lnkmetachmapprgrp;
@ISA=qw(TS::lnkmetachmapprgrp);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'campus',
                htmlwidth     =>'100px',
                label         =>'Campus',
                vjointo       =>'TS::campus',
                vjoinon       =>['refid'=>'id'],
                vjoindisp     =>'fullname'),
      insertafter=>'id'
   );
   $self->{secparentobj}='TS::campus';
   $self->getField('refid')->{htmldetail}=0;
   $self->setDefaultView(qw(campus group responsibility));

   return($self);
}



1;
