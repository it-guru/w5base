package base::workflowkey;
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
                htmlwidth     =>'10px',
                label         =>'No.'),


      new kernel::Field::Text(
                name          =>'wfheadid',
                label         =>'WorkflowID',
                sqlorder      =>'none',
                dataobjattr   =>'wfkey.id'),
                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                sqlorder      =>'none',
                dataobjattr   =>'wfkey.name'),

      new kernel::Field::Text(
                name          =>'value',
                label         =>'Value',
                sqlorder      =>'none',
                dataobjattr   =>'wfkey.fval'),

      new kernel::Field::Date(
                name          =>'closedate',
                label         =>'Close-Date',
                sqlorder      =>'none',
                dataobjattr   =>'wfkey.closedate'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'none',
                label         =>'Creation-Date',
                dataobjattr   =>'wfkey.createdate'),
                                  
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                sqlorder      =>'none',
                label         =>'Editor Account',
                dataobjattr   =>'wfkey.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                sqlorder      =>'none',
                label         =>'real Editor Account',
                dataobjattr   =>'wfkey.realeditor'),
   );
   $self->setDefaultView(qw(wfheadid name value cdate));
   $self->setWorktable("wfkey");
   return($self);
}


sub initSearchQuery
{
   my $self=shift;

   Query->Param("search_cdate"=>'>now-60m');
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL") if ($self->getParent() && defined($rec));
   return("ALL") if ($self->IsMemberOf(["admin",
                                        "workflow.manager",
                                        "workflow.admin"]));
   return(undef);
}





1;
