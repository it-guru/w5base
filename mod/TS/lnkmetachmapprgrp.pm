package TS::lnkmetachmapprgrp;
#  W5Base Framework
#  Copyright (C) 2017  Markus Zeis (w5base@zeis.email)
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
use tsgrpmgmt::lnkmetagrp;
@ISA=qw(tsgrpmgmt::lnkmetagrp);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->getField('group')->{vjoineditbase}={'ischmapprov'=>\1,
                                              'cistatusid'=>[3,4]};
   return($self);
}


sub getParentFieldGroup
{
   my $self=shift;

   return('chm');
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   if (!defined($rec) ||
       $self->isWriteOnParentValid($rec,$self->getParentFieldGroup())) {
      return('default');
   }

   return(undef);
}


sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;

   if ($mode eq 'select') {
      my $where="metagrpmgmt.is_chmapprov=1 AND ".
                "metagrpmgmt.cistatus in (3,4)";
      return($where);
   }
   
   return(undef);
}



1;
