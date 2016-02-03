package base::mailsignatur;
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
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'mailsignatur.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Sig-Name',
                dataobjattr   =>'mailsignatur.name'),

      new kernel::Field::Link(
                name          =>'userid',
                label         =>'Userid',
                dataobjattr   =>'mailsignatur.userid'),

      new kernel::Field::Email(
                name          =>'replyto',
                label         =>'Replyto',
                dataobjattr   =>'mailsignatur.replyto'),

      new kernel::Field::Email(
                name          =>'fromaddress',
                label         =>'From',
                dataobjattr   =>'mailsignatur.fromaddress'),
 
      new kernel::Field::Htmlarea(
                name          =>'htmlsig',
                searchable    =>0,
                group         =>'htmlsig',
                label         =>'HTML-Signatur',
                dataobjattr   =>'mailsignatur.htmlsig'),

      new kernel::Field::Textarea(
                name          =>'textsig',
                searchable    =>0,
                group         =>'textsig',
                label         =>'Text-Signatur',
                dataobjattr   =>'mailsignatur.textsig'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'mailsignatur.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'mailsignatur.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'mailsignatur.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'mailsignatur.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'mailsignatur.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'mailsignatur.realeditor'),

   );
   $self->setDefaultView(qw(linenumber name groupname cistatus cdate mdate));
   $self->setWorktable("mailsignatur");
   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   $newrec->{'name'}=$name;
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
   return("default","htmlsig","textsig") if ($self->IsMemberOf("admin"));
   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","htmlsig","textsig","source");
}






1;
