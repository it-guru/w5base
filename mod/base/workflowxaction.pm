package base::workflowxaction;
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
use base::workflowaction;
@ISA=qw(base::workflowaction);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->getField("translation")->{'searchable'}=0;
   $self->getField("privatestate")->{'searchable'}=0;

   $self->AddFields(
      new kernel::Field::CDate(
                name        =>'xcdate',
                htmldetail  =>0,
                label       =>'Action-Date',
                dataobjattr =>'wfaction.createdate'),
      insertafter=>'wfheadid');

   $self->AddFields(
      new kernel::Field::Text(
                name        =>'xwfclass',
                htmldetail  =>0,
                label       =>'Workflow-Class',
                dataobjattr =>'wfhead.wfclass'),
      insertafter=>'wfheadid');

   $self->AddFields(
      new kernel::Field::Text(
                name        =>'xwfname',
                htmldetail  =>0,
                label       =>'Workflow-Name',
                dataobjattr =>'wfhead.shortdescription'),
      insertafter=>'wfheadid');
   $self->setDefaultView(qw(id name wfname editor comments xcdate));

   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   if (Query->Param("search_sscdate") ne ""){
      return("$worktable left outer join wfhead ".
             "on $worktable.wfheadid=wfhead.wfheadid");
   }
   return("wfhead left outer join $worktable ".
          "on $worktable.wfheadid=wfhead.wfheadid");
}




1;
