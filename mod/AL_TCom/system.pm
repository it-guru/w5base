package AL_TCom::system;
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
use kernel::Field;
use itil::system;
@ISA=qw(itil::system);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'acassingmentgroup',
                label         =>'AssetManager Assignmentgroup',
                group         =>'admin',
                weblinkto     =>'tsacinv::group',
                weblinkon     =>['acassingmentgroup'=>'name'],
                searchable    =>0,
                readonly      =>1,
                async         =>'1',
                vjointo       =>'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'assignmentgroup'),
      new kernel::Field::TextDrop(
                name          =>'accontrolcenter',
                label         =>'AM System ControlCenter',
                group         =>'admin',
                weblinkto     =>'tsacinv::group',
                weblinkon     =>['accontrolcenter'=>'name'],
                async         =>'1',
                searchable    =>0,
                readonly      =>1,
                vjointo       =>'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'controlcenter'),

      new kernel::Field::TextDrop(
                name          =>'accontrolcenter2',
                label         =>'AM Application ControlCenter',
                group         =>'admin',
                weblinkto     =>'tsacinv::group',
                weblinkon     =>['accontrolcenter2'=>'name'],
                async         =>'1',
                searchable    =>0,
                readonly      =>1,
                vjointo       =>'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'controlcenter2'),

      new kernel::Field::TextDrop(
                name          =>'acsystemname',
                label         =>'AssetManager Systemname',
                group         =>'logsys',
                async         =>'1',
                searchable    =>0,
                readonly      =>1,
                vjointo       =>'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'systemname'),
      new kernel::Field::Boolean(
                name          =>'acsoxrelevant',
                label         =>'AssetManager SOX relevant',
                group         =>'logsys',
                searchable    =>0,
                weblinkto     =>'NONE',
                async         =>'1',
                readonly      =>1,
                vjointo       =>'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'soxrelevant'),
   );

   return($self);
}






1;
