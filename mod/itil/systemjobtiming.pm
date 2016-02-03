package itil::systemjobtiming;
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
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                htmldetail    =>0,
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'systemjobtiming.id'),
                                                  
     # new kernel::Field::Text(
     #           name          =>'name',
     #           htmldetail    =>0,
     #           readonly      =>1,
     #           label         =>'Name',
     #           dataobjattr   =>'systemjobtiming.id'),

     new kernel::Field::TextDrop(
                name          =>'job',
                htmlwidth     =>'250px',
                label         =>'Job',
                vjointo       =>'itil::systemjob',
                vjoinon       =>['jobid'=>'id'],
                vjoindisp     =>'name'),
                                  
      new kernel::Field::TextDrop(
                name          =>'system',
                htmlwidth     =>'100px',
                label         =>'System',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'tinterval',
                htmleditwidth =>'100%',
                transprefix   =>'ti.',
                label         =>'timing interval',
                value         =>[qw( 0 1 2 3 4)],
                dataobjattr   =>'systemjobtiming.tinterval'),

      new kernel::Field::Link(
                name          =>'tintervalid',
                label         =>'timing interval id',
                dataobjattr   =>'systemjobtiming.tinterval'),

      new kernel::Field::Select(
                name          =>'plannedhour',
                htmleditwidth =>'40px',
                label         =>'planned hour',
                value         =>[(0..23)],
                dataobjattr   =>'systemjobtiming.plannedhour'),

      new kernel::Field::Select(
                name          =>'plannedmin',
                htmleditwidth =>'40px',
                label         =>'planned min',
                value         =>[(0..59)],
                dataobjattr   =>'systemjobtiming.plannedmin'),

      new kernel::Field::Select(
                name          =>'plannedday',
                htmleditwidth =>'40px',
                label         =>'planned day',
                value         =>[(1..31)],
                dataobjattr   =>'systemjobtiming.plannedday'),

      new kernel::Field::Select(
                name          =>'plannedmon',
                htmleditwidth =>'40px',
                label         =>'planned month',
                value         =>[(1..12)],
                dataobjattr   =>'systemjobtiming.plannedmon'),

      new kernel::Field::Select(
                name          =>'plannedyear',
                htmleditwidth =>'40px',
                label         =>'planned year',
                value         =>[(2007..2050)],
                dataobjattr   =>'systemjobtiming.plannedyear'),

      new kernel::Field::Boolean(
                name          =>'plannedwdmon',
                label         =>'Planned monday',
                dataobjattr   =>'systemjobtiming.plannedwdmon'),

      new kernel::Field::Boolean(
                name          =>'plannedwdtue',
                label         =>'Planned thuesday',
                dataobjattr   =>'systemjobtiming.plannedwdtue'),

      new kernel::Field::Boolean(
                name          =>'plannedwdwed',
                label         =>'Planned wendesday',
                dataobjattr   =>'systemjobtiming.plannedwdwed'),

      new kernel::Field::Boolean(
                name          =>'plannedwdthu',
                label         =>'Planned thuesday',
                dataobjattr   =>'systemjobtiming.plannedwdthu'),

      new kernel::Field::Boolean(
                name          =>'plannedwdfri',
                label         =>'Planned friday',
                dataobjattr   =>'systemjobtiming.plannedwdfri'),

      new kernel::Field::Boolean(
                name          =>'plannedwdsat',
                label         =>'Planned saturday',
                dataobjattr   =>'systemjobtiming.plannedwdsat'),

      new kernel::Field::Boolean(
                name          =>'plannedwdsun',
                label         =>'Planned sunday',
                dataobjattr   =>'systemjobtiming.plannedwdsun'),


      new kernel::Field::Link(
                name          =>'systemid',
                label         =>'SystemID',
                dataobjattr   =>'systemjobtiming.systemid'),

      new kernel::Field::Link(
                name          =>'jobid',
                label         =>'SystemJobID',
                dataobjattr   =>'systemjobtiming.jobid'),

      new kernel::Field::Link(
                name          =>'lastjobid',
                label         =>'Last Workflow JobID',
                dataobjattr   =>'systemjobtiming.lastjobid'),

      new kernel::Field::Link(
                name          =>'lastjobstart',
                label         =>'Last Workflow Job Start',
                dataobjattr   =>'systemjobtiming.lastjobstart'),

      new kernel::Field::Link(
                name          =>'runcount',
                label         =>'Run Count',
                dataobjattr   =>'systemjobtiming.runcount'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'systemjobtiming.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'systemjobtiming.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'systemjobtiming.createuser'),

      new kernel::Field::Owner(
                name          =>'ownername',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'systemjobtiming.modifyuser'),

      new kernel::Field::Link(
                name          =>'owner',
                group         =>'source',
                label         =>'OwnerID',
                dataobjattr   =>'systemjobtiming.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'systemjobtiming.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'systemjobtiming.realeditor'),

   );
   $self->{use_distinct}=1;
   $self->setDefaultView(qw(linenumber system job tinterval cdate mdate));
   $self->setWorktable("systemjobtiming");
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   $newrec->{'name'}=$name;
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();
   return("header","default") if (!defined($rec));

   return("ALL");
   #return("ALL") if ($userid==$rec->{owner});
   return(undef);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));

   return("default");
}

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default acl systems control source));
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   $self->W5ServerCall("rpcReloadW5Server","itil::W5Server::controlcenter");

   return(1);
}








1;
