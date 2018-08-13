package kernel::Output::MultiDelete;
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
use kernel::FormaterMultiOperation;
use Data::Dumper;
@ISA    = qw(kernel::FormaterMultiOperation);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub IsModuleSelectable
{
   my $self=shift;

   return(1);
}

sub Label
{
   return("multi delete");
}

sub Description
{
   return("With this module it is able to delete multiple records at one step");
}


sub Init
{
   my $self=shift;
   my $app=$self->getParent->getParent();

   $self->Context->{opobj}=getModuleObject($app->Config,$app->Self());
   $self->SUPER::Init();
   return(undef);
}

sub MultiOperationActionOn
{
   my $self=shift;
   my $app=shift;
   my $id=shift;

   my $opobj=$self->Context->{opobj};
   my $idfield=$app->IdField();

   my $fail=0;
   $opobj->ResetFilter();
   $opobj->SetFilter({$idfield->Name()=>\$id});
   $opobj->SetCurrentView(qw(ALL));
   my @dellist;
   $opobj->ForeachFilteredRecord(sub{
                      push(@dellist,$_);
                     });
   foreach my $rec (@dellist){
      if (!($opobj->SecureValidatedDeleteRecord($rec))){
         $fail=1;
      }
   }
   return(1) if (!$fail);
   return(0);
}

sub MultiOperationActor
{
   my $self=shift;
   my $app=shift;

   return($self->SUPER::MultiOperationActor($app,$app->T("Start",$self->Self)));
}


sub MultiOperationBottom
{
   my $self=shift;
   my $app=shift;

   delete($self->Context->{opobj});
   return(1);
}

sub getRecordImageUrl
{
   my $self=shift;

   return("../../../public/base/load/icon_multidelete.gif");
}


1;
