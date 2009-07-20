package kernel::config;
#  W5Base Framework
#  Copyright (C) 2002  Hartmut Vogler (hartmut.vogler@epost.de)
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
use kernel;
use FastConfig;
use kernel::Universal;
use vars(qw(@ISA));

@ISA=qw(kernel::Universal);



sub new
{
   my $type=shift;
   my $conffile=shift;
   my $self={};
   $self->{c}=new FastConfig();
   
   bless($self,$type);
}

sub getCurrentConfigName
{
   my $self=shift;
   return($self->{c}->getCurrentConfigName());
}


sub readconfig
{
   my $self=shift;
   return($self->{c}->readconfig(@_));
}

sub debug
{
   my $self=shift;
   return($self->{c}->readconfig(@_));
}

sub LoadIntoCurrentConfig
{
   my $self=shift;
   return($self->{c}->readconfig(@_));
}

sub Param($)
{
   my $self=shift;
   return($self->{c}->Param(@_));
}

sub varlist($)
{
   my $self=shift;
   return($self->{c}->VarList(@_));
}



1;
