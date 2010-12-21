package ucmdb::uclass;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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
use kernel::DataObj::Static;
use kernel::App::Web::Listedit;
use ucmdb::lib::io;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::Static ucmdb::lib::io);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(      name     =>'id',
                                  align    =>'left',
                                  searchable=>1,
                                  label    =>'class name'),
      new kernel::Field::Text(    name     =>'fullname',
                                  label    =>'display name'),
      new kernel::Field::Text(    name     =>'parent',
                                  weblinkto=>'ucmdb::uclass',
                                  weblinkon=>['parent'=>'id'],
                                  label    =>'parent class')
   );
   $self->{'data'}=sub {
      my $self=shift;
      my ($result,$fault)=$self->getAllClassesHierarchy();

      $self->{data}=$result; 
      return($result);
   };
   $self->setDefaultView(qw(id fullname parent));
   return($self);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}  
   



1;
