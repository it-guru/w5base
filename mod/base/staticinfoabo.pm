package base::staticinfoabo;
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
use kernel::DataObj::Static;
use kernel::App::Web::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::Static);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(      name     =>'id',
                                  label    =>'Info Source ID'),
      new kernel::Field::Text(    name     =>'name',
                                  label    =>'Info Name'),
      new kernel::Field::Text(    name     =>'fullname',
                                  depend   =>['translation','name'],
                                  searchable=>0,
                                  onRawValue=>sub{
                                     my $self=shift;
                                     my $current=shift;
                                     my $name=$self->Name();
                                     return($self->getParent->T(
                                    $current->{name},$current->{translation}));
                                  },
                                  label    =>'Info Fullname'),
      new kernel::Field::Boolean( name     =>'force',
                                  label    =>'Force Abo Handling'),
      new kernel::Field::Text(    name     =>'translation',
                                  label    =>'Info Translation')
   );
   $self->LoadSubObjs("ext/staticinfoabo","staticinfoabo");
   $self->{'data'}=[];
   foreach my $obj (values(%{$self->{staticinfoabo}})){
      my $ctrl=$obj->getControlData();
      while(my $trans=shift(@$ctrl)){
         my $rec=shift(@$ctrl);
         my $r={id         =>$rec->{id},
                translation=>$trans,
                name       =>$rec->{name},
                force      =>$rec->{force}};
         push(@{$self->{'data'}},$r);
      }
   }
   $self->setDefaultView(qw(id name fullname));
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
