package base::workflowrepjob;
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
                label         =>'Workflow Report JobID',
                sqlorder      =>'none',
                dataobjattr   =>'wfrepjob.id'),

      new kernel::Field::Text(
                name          =>'targetfile',
                label         =>'WebFS target file/URL/Mail',
                dataobjattr   =>'wfrepjob.targetfile'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Report name',
                dataobjattr   =>'wfrepjob.reportname'),

      new kernel::Field::Number(
                name          =>'mday',
                label         =>'due day',
                default       =>'1',
                dataobjattr   =>'wfrepjob.mday'),

      new kernel::Field::Text(
                name          =>'runmday',
                label         =>'run on day',
                dataobjattr   =>'wfrepjob.runmday'),

      new kernel::Field::Text(
                name          =>'fltclass',
                label         =>'Filter: Class',
                dataobjattr   =>'wfrepjob.flt_class'),

      new kernel::Field::Text(
                name          =>'fltstep',
                label         =>'Filter: Step',
                dataobjattr   =>'wfrepjob.flt_step'),

      new kernel::Field::Text(
                name          =>'fltname',
                label         =>'Filter: Name',
                dataobjattr   =>'wfrepjob.flt_name'),

      new kernel::Field::Text(
                name          =>'fltdesc',
                label         =>'Filter: Description',
                dataobjattr   =>'wfrepjob.flt_desc'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'wfrepjob.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'wfrepjob.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'wfrepjob.createdate'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'wfrepjob.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'wfrepjob.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'wfrepjob.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'wfrepjob.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'wfrepjob.realeditor'),


                                  
   );
   $self->setDefaultView(qw(targetfile name cdate));
   $self->setWorktable("wfrepjob");
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
