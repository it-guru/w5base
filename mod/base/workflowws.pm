package base::workflowws;
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


      new kernel::Field::Id(
                name          =>'id',
                label         =>'WorkspaceID',
                sqlorder      =>'none',
                dataobjattr   =>'wfworkspace.id'),
                                  
      new kernel::Field::Text(
                name          =>'wfheadid',
                label         =>'WorkflowID',
                sqlorder      =>'none',
                dataobjattr   =>'wfworkspace.wfheadid'),

      new kernel::Field::MultiDst (
                name          =>'fwdtargetname',
                htmlwidth     =>'450',
                htmleditwidth =>'400',
                label         =>'mapped in Workspace of',
                dst           =>['base::grp' =>'fullname',
                                 'base::user'=>'fullname'],
                dsttypfield   =>'fwdtarget',
                dstidfield    =>'fwdtargetid'),
                                  
      new kernel::Field::Link(
                name          =>'fwdtarget',
                label         =>'fwdtarget',
                sqlorder      =>'none',
                dataobjattr   =>'wfworkspace.fwdtarget'),

      new kernel::Field::Link(
                name          =>'fwdtargetid',
                label         =>'fwdtargetid',
                sqlorder      =>'none',
                dataobjattr   =>'wfworkspace.fwdtargetid'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'none',
                label         =>'Creation-Date',
                dataobjattr   =>'wfworkspace.createdate'),
   );
   $self->setDefaultView(qw(wfheadid fwdtargetname cdate));
   $self->setWorktable("wfworkspace");
   return($self);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL") if ($self->IsMemberOf(["admin",
                                        "workflow.manager",
                                        "workflow.admin"]));
   return(undef);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL") if ($self->IsMemberOf(["admin",
                                        "workflow.manager",
                                        "workflow.admin"]));
   return(undef);
}





1;
