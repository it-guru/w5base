package faq::forumtopicread;
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
use kernel::App::Web::Listedit;
use kernel::DataObj::DB;
use kernel::Field;
use faq::lib::forum;
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
                label         =>'Topic-Read ID',
                sqlorder      =>'desc',
                size          =>'10',
                dataobjattr   =>'forumtopicread.id'),
                                    
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Topic',
                searchable    =>1,
                readonly      =>1,
                htmlwidth     =>'450',
                dataobjattr   =>'forumtopic.name'),

      new kernel::Field::TextDrop(
                name          =>'forumboardname',
                label         =>'Boardname',
                readonly      =>1,
                vjointo       =>'faq::forumboard',
                vjoinon       =>['forumboard'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'forumboard',
                dataobjattr   =>'forumtopic.forumboard'),

      new kernel::Field::Link(
                name          =>'forumtopicid',
                label         =>'Topic ID',
                dataobjattr   =>'forumtopicread.forumtopic'),
                                    
      new kernel::Field::Creator(
                name          =>'creator',
                label         =>'Reader',
                dataobjattr   =>'forumtopicread.createuser'),

      new kernel::Field::Link(
                name          =>'creatorid',
                label         =>'ReaderID',
                dataobjattr   =>'forumtopicread.createuser'),
                                   
      new kernel::Field::Text(
                name          =>'clientipaddr',
                label         =>'ClientIP',
                dataobjattr   =>'forumtopicread.clientipaddr'),

      new kernel::Field::CDate(
                name          =>'cdate',
                label         =>'Read-Date',
                dataobjattr   =>'forumtopicread.createdate'),
   );
   $self->setDefaultView(qw(cdate name creator));
   $self->{DetailY}=520;
   $self->setWorktable("forumtopicread");
   return($self);
}


sub getSqlFrom
{  
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable";

   $from.=" left outer join forumtopic ".
          "on forumtopicread.forumtopic=forumtopic.id ";

   return($from);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL") if ($self->IsMemberOf("admin"));
   return(undef);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;

   return("header","default");
}










1;
