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
use TS::system;
@ISA=qw(TS::system);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);


#   $self->AddFields(
#      new kernel::Field::Select(
#                name          =>'exposurelevel',
#                group         =>'sec',
#                label         =>'Exposure Level',
#                allowempty    =>1,
#                weblinkto     =>"none",
#                vjointo       =>'base::itemizedlist',
#                vjoinbase     =>{
#                   selectlabel=>\'AL_TCom::system::exposurelevel',
#                },
#                vjoineditbase =>{
#                   selectlabel=>\'AL_TCom::system::exposurelevel',
#                   cistatusid=>\'4'
#                },
#                vjoinon       =>['rawexposurelevel'=>'name'],
#                vjoindisp     =>'displaylabel',
#                depend        =>['additional'],
#                searchable    =>0,
#                htmleditwidth =>'200px'),
#
#      new kernel::Field::Interface(
#                name          =>'rawexposurelevel',
#                group         =>'sec',
#                label         =>'raw ExposureLevel',
#                uploadable    =>0,
#                container     =>'additional'),
#   );


   # BETA - diese Funktion ist noch im Aufbau!
   $self->AddVJoinReferenceRewrite("itil::appl"=>"AL_TCom::appl");



   return($self);
}






1;
