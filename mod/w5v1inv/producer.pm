package w5v1inv::producer;
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
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Id(      name         =>'id',
                                  label        =>'W5BaseID',
                                  size         =>'10',
                                  dataobjattr  =>'dropbox_herstell.id'),
      new kernel::Field::Text(    name         =>'name',
                                  label        =>'Producername',
                                  dataobjattr  =>'dropbox_herstell.name'),
   );
   $self->setDefaultView(qw(name id));
   return($self);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return(qw(ALL));

}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5v1"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1);
}


sub getSqlFrom
{
   my $self=shift;

   return("dropbox_herstell");
}


1;
