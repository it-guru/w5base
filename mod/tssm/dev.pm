package tssm::dev;
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
use tssm::lib::io;

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
#   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'deviceid',
                label         =>'LogicalName',
                group         =>'source',
                dataobjattr   =>SELpref.'device2m1.logical_name'),

      new kernel::Field::Text(
                name          =>'configitemid',
                label         =>'ConfigItemID',
                uppersearch   =>1,
                dataobjattr   =>SELpref.'device2m1.id'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Title',
                searchable    =>0,
                dataobjattr   =>SELpref.'device2m1.title'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'CI-Name',
                ignorecase    =>1,
                dataobjattr   =>SELpref.'device2m1.ci_name'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                uppersearch   =>1,
                dataobjattr   =>SELpref.'device2m1.istatus'),

      new kernel::Field::Text(
                name          =>'model',
                label         =>'Model',
                searchable    =>0,
                dataobjattr   =>SELpref.'device2m1.model'),

      new kernel::Field::Text(
                name          =>'location',
                label         =>'Location',
                dataobjattr   =>SELpref.'device2m1.location'),

      new kernel::Field::Text(
                name          =>'assignmentgroup',
                label         =>'Assignmentgroup',
                weblinkto     =>'tssm::group',
                weblinkon     =>['assignmentgroup'=>'fullname'],
                dataobjattr   =>SELpref.'device2m1.assignment'),

      new kernel::Field::Text(
                name          =>'iassignmentgroup',
                label         =>'Incident Assignmentgroup',
                weblinkto     =>'tssm::group',
                weblinkon     =>['iassignmentgroup'=>'fullname'],
                dataobjattr   =>SELpref.
                                'device2m1.tsi_incident_assignment_group'),

      new kernel::Field::Text(
                name          =>'ucmdbid',
                label         =>'uCMDB ID',
                group         =>'source',
                dataobjattr   =>SELpref.'device2m1.ucmdb_id'),

      new kernel::Field::Text(
                name          =>'mandantkey',
                label         =>'MSS Key',
                group         =>'source',
                dataobjattr   =>SELpref.'device2m1.tsi_mandant'),

      new kernel::Field::Text(
                name          =>'mandantname',
                label         =>'MSS Mandant',
                group         =>'source',
                dataobjattr   =>SELpref.'device2m1.tsi_mandant_name'),

      new kernel::Field::MDate(
                name          =>'mdate',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                group         =>'source',
                dataobjattr   =>SELpref.'device2m1.sysmodtime'),
   );
   $self->setDefaultView(qw(fullname model));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssm"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getSqlFrom
{
   my $self=shift;
   my $from=TABpref."device2m1 ".SELpref."device2m1";
   return($from);
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

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","source");
}




1;
