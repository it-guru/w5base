package OSY::system;
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
use kernel::Field;
use itil::system;
@ISA=qw(itil::system);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'acassingmentgroup',
                label         =>'AssetManager Assignmentgroup',
                group         =>'admin',
                weblinkto     =>'none',
                readonly      =>1,
                async         =>'1',
                vjointo       =>'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'assignmentgroup'),
      new kernel::Field::TextDrop(
                name          =>'aciassingmentgroup',
                label         =>'AssetManager Incident Assignmentgroup',
                group         =>'admin',
                weblinkto     =>'none',
                readonly      =>1,
                async         =>'1',
                vjointo       =>'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'iassignmentgroup'),
      new kernel::Field::SubList(
                name          =>'techapplications',
                label         =>'Applications technical contact',
                group         =>'applications',
                subeditmsk    =>'subedit.appl',
                allowcleanup  =>1,
                htmldetail    =>0,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=4"}],
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['appl','tsm','businessteam','oncallphones']),

   );
   $self->{workflowlink}->{workflowtyp}=[qw(OSY::workflow::diary
                                            base::workflow::DataIssue 
                                            AL_TCom::workflow::incident 
                                            AL_TCom::workflow::change
                                            TS::workflow::incident 
                                            TS::workflow::change
                                           )];
   $self->{workflowlink}->{workflowstart}=\&calcWorkflowStart;

   return($self);
}

sub calcWorkflowStart
{  
   my $self=shift;
   my $r={};

   my %env=('frontendnew'=>'1');
   my $wf=getModuleObject($self->Config,"base::workflow");
   my @l=$wf->getSelectableModules(%env);

   if (grep(/^OSY::workflow::diary$/,@l)){
      $r->{'OSY::workflow::diary'}={
                                          name=>'Formated_system'
                                       };
   }
   return($r);
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default admin logsys physys ipaddresses systemclass 
             opmode applications software 
             contacts misc attachments control source));
}








1;
