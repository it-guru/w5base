package crm::businessprocessacl;
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
use kernel::App::Web;
use kernel::App::Web::AclControl;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::AclControl kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;

   $param{acltable}="businessprocessacl";
   my $self=bless($type->SUPER::new(%param),$type);


   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'fullname',
                readonly      =>1,
                depend        =>['refid','aclmode'],
                label         =>'BusinessProcess',
                vjointo       =>'crm::businessprocess',
                vjoinon       =>['refid'=>'id'],
                vjoindisp     =>'fullname'),
      insertafter=>'refid'
   );
   $self->setDefaultView(qw(fullname acltargetname aclmode));

   return($self);
}



1;
