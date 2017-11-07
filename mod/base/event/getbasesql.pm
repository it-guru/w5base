package base::event::getbasesql;
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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
use kernel::Event;
use SQL::Beautify;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getbasesql
{
   my $self=shift;
   my $dataobj=shift;
   my $o=getModuleObject($self->Config,$dataobj);

   $o->SetFilter();
   $o->SetCurrentView(qw(ALL));
   $o->SetCurrentOrder(qw(NONE));
   
   my $rawsql=$o->getSqlSelect();
   printf STDERR ("\n\nraw:\n%s\n",$rawsql);

   my $sql = SQL::Beautify->new(uc_keywords=>1,spaces => 3);
   $sql->query($rawsql);
   my $nice_sql = $sql->beautify;


   printf ("\n\nCREATE or REPLACE VIEW \"$dataobj\" AS\n%s\n",$nice_sql);


   return({exitcode=>0,msg=>'ok'});
}


1;
