package itil::workflow::systemjob;
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
use kernel::WfClass;
@ISA=qw(kernel::WfClass);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;

   return($self->InitFields(
      new kernel::Field::Text(    name        =>'jobsystemname',
                                  label       =>'Systemname',
                                  container   =>'headref'),

      new kernel::Field::TextDrop(name        =>'jobname',
                                  vjointo     =>'itil::systemjob',
                                  vjoinon     =>['jobid'=>'id'],
                                  vjoindisp   =>'name',
                                  readonly    =>1,
                                  label       =>'Job Name'),

      new kernel::Field::Text(    name        =>'jobid',
                                  weblinkto   =>'itil::systemjob',
                                  weblinkon   =>['jobid'=>'id'],
                                  label       =>'JobID',
                                  container   =>'headref'),

      new kernel::Field::Textarea(name        =>'command',
                                  label       =>'Command',
                                  container   =>'headref'),

      new kernel::Field::Textarea(name        =>'pcode',
                                  label       =>'Programmcode',
                                  container   =>'headref')
   ));

}

sub allowAutoScroll
{
   return(0);
}



sub IsModuleSelectable
{
   my $self=shift;
   my $acl;

   return(0);
}

sub InitWorkflow
{
   my $self=shift;
   return(undef);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","state","flow","affected","source","header");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   return("base::workflow::diary::".$shortname);
}


sub getNextStep
{
   my $self=shift;
   my $currentstep=shift;
   my $WfRec=shift;

   if($currentstep eq "base::workflow::diary::finish"){
      return($self->getStepByShortname("finish",$WfRec)); 
   }
   elsif($currentstep=~m/^.*::workflow::diary::dataload$/){
      return($self->getStepByShortname("main",$WfRec)); 
   }
   elsif($currentstep eq ""){
      return($self->getStepByShortname("dataload",$WfRec)); 
   }
   return(undef);
}

sub isOptionalFieldVisible
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   my $name=$param{field}->Name();

   return(1) if ($name eq "name");
   return(1) if ($name eq "shortactionlog");
   return(1) if ($name eq "detaildescription");
   return(0);
}

sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;
   my $app=$self->getParent;
   my $userid=$self->getParent->getCurrentUserId();
   return();
}


#######################################################################
package itil::workflow::systemjob::dataload;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   foreach my $v (qw(name)){
      if ((!defined($oldrec) || exists($newrec->{$v})) && $newrec->{$v} eq ""){
         $self->LastMsg(ERROR,"field '%s' is empty",
                        $self->getField($v)->Label());
         return(0);
      }
   }
   if (!defined($newrec->{eventstart})){
      $newrec->{eventstart}=$self->getParent->ExpandTimeExpression('now');
   }
   $newrec->{eventend}=undef if (!defined($newrec->{eventend}));
   $newrec->{closedate}=undef if (!defined($newrec->{closedate}));
   $newrec->{stateid}=1 if (!defined($newrec->{stateid}));

   return(1);
}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(0);
}

#######################################################################
package itil::workflow::systemjob::pending;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;
   $newrec={step=>$newrec->{step}};

   my $res;
   if (defined($res=$self->W5ServerCall("rpcCallSerialEvent",
                                        "systemjob",$oldrec->{id})) &&
       $res->{exitcode}==0){
printf STDERR ("fifi systemjob exitcode = 0\n");
      $newrec->{stateid}=6;
      return(1);
   }
printf STDERR ("fifi systemjob fail=%s\n",Dumper($res));

   return(0);
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(0);
}

#######################################################################
package itil::workflow::systemjob::process;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   return("");
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   return(1);
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;
   my $app=$self->getParent->getParent;

   return(60) if ($app->IsMemberOf("admin"));
   return(0);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $app=$self->getParent->getParent;
   my %p=();
   %p=("Restart"=>"Restart Job") if ($app->IsMemberOf("admin"));
   return(%p);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "Restart"){
      my $res;
      $self->getParent->getParent->
            Store($WfRec->{id},{detaildescription=>'',stateid=>9,
                                command=>'',pcode=>''});

      if (defined($res=$self->W5ServerCall("rpcCallSerialEvent",
                                           "systemjob",$WfRec->{id})) &&
          $res->{exitcode}==0){
         msg(DEBUG,"send ok");
      }
   }
   return($self->SUPER::Process($action,$WfRec,$actions));
}




1;
