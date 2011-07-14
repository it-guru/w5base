package kernel::MyW5Base;
#  W5Base Framework
#  Copyright (C) 2002  Hartmut Vogler (hartmut.vogler@epost.de)
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
#
use vars qw(@ISA);
use strict;
use kernel::Plugable;

@ISA=qw(kernel::Plugable);

sub new
{
   no strict 'refs';
   my $type=shift;
   my $self=bless({@_},$type);
   $self->{isInitalized}=0;

   foreach my $method (qw(IdField getFieldList getFieldObjsByView
                          getField ViewEditor
                          isViewValid isWriteValid
                          getHashList ResetFilter
                          SetCurrentView 
                          getOnlyFirst)){
      *$method = sub {
            my $s = shift;
            $s->Init();
            my $dataobj=$s->getDataObj();
            return(undef) if (!defined($dataobj));
            return ($dataobj->$method(@_));
        }
   } 
   return($self);
}

sub getQueryTemplate
{
   my $self=shift;
   my $bb=$self->getDefaultStdButtonBar();
   return($bb);
}



1;

