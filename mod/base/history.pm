package base::history;
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
      new kernel::Field::Id(        name        =>'id',
                                    sqlorder    =>'desc',
                                    label       =>'W5BaseID',
                                    dataobjattr =>'history.id'),
                                  
      new kernel::Field::Text(      name        =>'name',
                                    label       =>'Fieldname',
                                    dataobjattr =>'history.name'),

      new kernel::Field::Text(      name        =>'dataobject',
                                    label       =>'Dataobject',
                                    dataobjattr =>'history.dataobject'),

      new kernel::Field::Text(      name        =>'dataobjectid',
                                    label       =>'DataobjectID',
                                    dataobjattr =>'history.dataobjectid'),

      new kernel::Field::Text(      name        =>'operation',
                                    label       =>'Operation',
                                    dataobjattr =>'history.operation'),

      new kernel::Field::Textarea(  name        =>'oldstate',
                                    label       =>'Old State',
                                    dataobjattr =>'history.oldstate'),

      new kernel::Field::Textarea(  name        =>'newstate',
                                    label       =>'New State',
                                    dataobjattr =>'history.newstate'),

      new kernel::Field::Textarea(  name        =>'comments',
                                    label       =>'Comments',
                                    dataobjattr =>'history.comments'),

      new kernel::Field::Creator(   name        =>'creator',
                                    label       =>'Creator',
                                    dataobjattr =>'history.createuser'),

      new kernel::Field::CDate(     name        =>'cdate',
                                    sqlorder    =>'desc',
                                    label       =>'Inscription-Date',
                                    dataobjattr =>'history.createdate'),

      new kernel::Field::Editor(    name        =>'editor',
                                    label       =>'Editor',
                                    dataobjattr =>'history.editor'),

      new kernel::Field::RealEditor(name        =>'realeditor',
                                    label       =>'RealEditor',
                                    dataobjattr =>'history.realeditor'),

   );
   $self->{dontSendRemoteEvent}=1;
   $self->setDefaultView(qw(cdate editor name newstate));
   $self->setWorktable("history");
   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
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
