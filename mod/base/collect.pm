package base::collect;
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
use kernel::App::Web::HierarchicalList;
use kernel::DataObj::DB;
use kernel::Field;
use File::Temp qw(tempfile);
use Fcntl qw(SEEK_SET);
use MIME::Base64;
use File::Temp(qw(tmpfile));
@ISA=qw(kernel::App::Web::HierarchicalList kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Id(       name       =>'fid',
                                   label      =>'W5BaseID',
                                   size       =>'10',
                                   dataobjattr=>'collect.fid'),
   );
   $self->setWorktable("collect");
   $self->setDefaultView(qw(fullname contentsize parentobj entrytyp editor));
   $self->{PathSeperator}="/";
   $self->{locktables}="collect write,fileacl write,contact write";
   return($self);
}

1;
