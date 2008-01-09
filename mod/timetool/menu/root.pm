package timetool::menu::root;
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
use Data::Dumper;
use kernel;
use kernel::MenuRegistry;
@ISA=qw(kernel::MenuRegistry);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub Init
{
   my $self=shift;

   $self->RegisterObj("timetool",
                      "tmpl/welcome",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("timetool.tplan",
                      "timetool::tplan",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("timetool.tplan.workgroup",
                      "timetool::workgroup",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("timetool.tplan.workgroup.new",
                      "timetool::workgroup",
                      func=>'New',
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("timetool.tspan",
                      "timetool::tspan",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("timetool.tspan.new",
                      "timetool::tspan",
                      func=>'New',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("timetool.timeplan",
                      "timetool::timeplan",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("timetool.timeplan.new",
                      "timetool::timeplan",
                      func=>'New',
                      defaultacl=>['valid_user']);
   
   
   return(1);
}



1;
