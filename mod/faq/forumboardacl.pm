package faq::forumboardacl;
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
use kernel::App::Web;
use kernel::App::Web::AclControl;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::AclControl kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;

   $param{acltable}="forumboardacl";
   $param{param}->{modes}=[qw(read write answer moderate)];
   $param{param}->{translation}='faq::forumboardacl';
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   #
   # hier muß noch eine Prüfung rein, das nur Moderatoren Änderungen
   # vornehmen können.
   #

   if (!$self->IsMemberOf("admin")){
      my $userid=$self->getCurrentUserId();
      if (defined($rec) && $rec->{acltarget} eq "base::user" &&
          $userid==$rec->{acltargetid}){
         return(undef);
      }
   }
   return($self->SUPER::isWriteValid($rec));
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (!$self->IsMemberOf("admin")){
      my $userid=$self->getCurrentUserId();
      my $target=effVal($oldrec,$newrec,"acltarget");
      my $targetid=effVal($oldrec,$newrec,"acltargetid");
      if ($target eq "base::user" &&
          $userid==$targetid){
         $self->LastMsg(ERROR,"modification of self rights is not allowed");
         return(undef);
      }
   }

   return($self->SUPER::Validate($oldrec,$newrec,$origrec));
}





1;
