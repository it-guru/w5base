package base::itemizedlist;
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
   $param{MainSearchFieldLines}=3 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                htmldetail    =>sub{
                   my ($self,$mode,%param)=@_;
                   return(defined($param{current}) ? 1 : 0);
                },
                label         =>'W5BaseID',
                dataobjattr   =>'itemizedlist.id'),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                htmldetail    =>sub{
                   my ($self,$mode,%param)=@_;
                   return(defined($param{current}) ? 1 : 0);
                },
                readonly      =>1,
                searchable    =>0,
                depend        =>['en_fullname','de_fullname'],
                onRawValue    =>sub{
                   my ($self,$current)=@_;
                   my $lang=$self->getParent->Lang();
                   if ($lang eq "de"){
                      return($current->{'de_fullname'});
                   }
                   return($current->{'en_fullname'});
                },
                label         =>'full name'),

      new kernel::Field::Text(
                name          =>'internalname',
                label         =>'internal name',
                dataobjattr   =>'itemizedlist.name'),

      new kernel::Field::Text(
                name          =>'selectlabel',
                label         =>'Select label',
                dataobjattr   =>'itemizedlist.selectlabel'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0"},
                default       =>'4',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'itemizedlist.cistatus'),


      new kernel::Field::Text(
                name          =>'en_fullname',
                label         =>'en fullname',
                dataobjattr   =>'itemizedlist.en_fullname'),

      new kernel::Field::Text(
                name          =>'de_fullname',
                label         =>'de fullname',
                dataobjattr   =>'itemizedlist.de_fullname'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                searchable    =>0,
                dataobjattr   =>'itemizedlist.comments'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'itemizedlist.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'itemizedlist.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'itemizedlist.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'itemizedlist.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'itemizedlist.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'itemizedlist.realeditor'),

   );
   $self->setDefaultView(qw(linenumber selectlabel fullname cistatus mdate));
   $self->setWorktable("itemizedlist");
   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
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
   return("header","default") if (!defined($rec) && $self->IsMemberOf("admin"));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}


sub isCopyValid
{
   my $self=shift;
   my $copyfrom=shift;
   return(1);
}






1;
