package tRnAI::department;
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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
use tRnAI::lib::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->{use_distinct}=1;

   $self->AddFields(
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Department',
                dataobjattr   =>'tRnAI_department.department'),

   );
   $self->setDefaultView(qw(name cdate mdate));
   $self->setWorktable("tRnAI_department");
   return($self);
}



sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="(select department from tRnAI_system ".
            " union ".
            " select department from tRnAI_instance) tRnAI_department";
   return($from);
}




sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;
   my $where="tRnAI_department.department<>''";
   return($where);
}



sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL") if ($self->tRnAI::lib::Listedit::isViewValid($rec));
   return(undef);
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}





1;
