package base::interviewtodocache;
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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
      new kernel::Field::Id(
                name          =>'id',
                label         =>'W5BaseID',
                dataobjattr   =>'interviewtodocache.id'),
                                  
      new kernel::Field::Text(
                name          =>'userid',
                label         =>'UserId',
                dataobjattr   =>'interviewtodocache.userid'),

      new kernel::Field::Text(
                name          =>'dataobject',
                label         =>'dataobject',
                dataobjattr   =>'interviewtodocache.dataobject'),

      new kernel::Field::Text(
                name          =>'dataobjectid',
                label         =>'dataobjectid',
                dataobjattr   =>'interviewtodocache.dataobjectid'),

      new kernel::Field::CDate(
                name          =>'cdate',
                label         =>'Creation-Date',
                dataobjattr   =>'interviewtodocache.createdate'),

      new kernel::Field::MDate(
                name          =>'mdate',
                label         =>'Modification-Date',
                dataobjattr   =>'interviewtodocache.modifydate')

   );
   $self->setDefaultView(qw(id userid dataobject dataobjectid));
   $self->setWorktable("interviewtodocache");
   return($self);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","source");
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
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

sub isDeleteValid
{
   my $self=shift;
   return(0) if (!$self->IsMemberOf("admin"));
   return(1);
}


1;
