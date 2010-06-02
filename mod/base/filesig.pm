package base::filesig;
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'filesig.keyid'),
                                                  
      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'filesig.cistatus'),

      new kernel::Field::Text(
                name          =>'parentobj',
                group         =>'sig',
                label         =>'Parentobj',
                dataobjattr   =>'filesig.parentobj'),

      new kernel::Field::Text(
                name          =>'parentid',
                group         =>'sig',
                label         =>'Parentrefid',
                dataobjattr   =>'filesig.parentid'),

      new kernel::Field::Text(
                name          =>'name',
                group         =>'sig',
                label         =>'name',
                dataobjattr   =>'filesig.name'),

      new kernel::Field::Text(
                name          =>'username',
                group         =>'sig',
                label         =>'user',
                dataobjattr   =>'filesig.username'),

      new kernel::Field::Textarea(
                name          =>'pk7',
                group         =>'sig',
                label         =>'PK7 Key',
                dataobjattr   =>'filesig.pemkey'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'filesig.comments'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'filesig.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'filesig.modifydate'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'filesig.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'filesig.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'filesig.realeditor')

   );
   $self->setDefaultView(qw(linenumber parentobj username name cistatus cdate mdate));
   $self->setWorktable("filesig");
   return($self);
}

#sub Initialize
#{
#   my $self=shift;
#
#   my @result=$self->AddDatabase(DB=>new kernel::database($self,"sigfilestore"));
#   return(@result) if (defined($result[0]) eq "InitERROR");
#   return(1) if (defined($self->{DB}));
#   return(0);
#}



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
   return("ALL") if ($self->IsMemberOf("admin"));
   return();
}





1;
