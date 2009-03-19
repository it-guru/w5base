package faq::menu::root;
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
use Data::Dumper;
use kernel;
use kernel::MenuRegistry;
@ISA=qw(kernel::MenuRegistry);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub Init
{
   my $self=shift;

   $self->RegisterObj("faq",
                      "faq::QuickFind",
                      func=>'Main',
                      defaultacl=>['valid_user']);
   
#   $self->RegisterObj("faq.forum",
#                      "faq::forum",
#                      defaultacl=>['valid_user']);
#   
#   $self->RegisterObj("faq.forum.topic",
#                      "faq::forumtopic",
#                      defaultacl=>['admin']);
#   
#   $self->RegisterObj("faq.forum.topic.new",
#                      "faq::forumtopic",
#                      func=>'New',
#                      defaultacl=>['admin']);
   
   $self->RegisterObj("faq.article",
                      "faq::article");
   
   $self->RegisterObj("faq.article.new",
                      "faq::article",
                      func=>'New',
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("faq.forum",
                      "faq::forum",
                      func=>'Main',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("faq.forum.board",
                      "faq::forumboard",
                      func=>'Main',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("faq.forum.board.new",
                      "faq::forumboard",
                      func=>'New',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("faq.forum.topic",
                      "faq::forumtopic",
                      func=>'Main',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("faq.forum.topic.new",
                      "faq::forumtopic",
                      func=>'New',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("faq.forum.topic.read",
                      "faq::forumtopicread",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("faq.forum.entry",
                      "faq::forumentry",
                      func=>'Main',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("faq.article.acl",
                      "faq::acl",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("faq.category",
                      "faq::category",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("faq.category.new",
                      "faq::category",
                      defaultacl=>['admin'],
                      func=>'New');
   
   return($self);
}



1;
