package itil::workflow::problem;
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
use itil::workflow::base;
@ISA=qw(kernel::WfClass itil::workflow::base);

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
      new kernel::Field::Textarea(name       =>'problemsolution',
                                  group      =>'itilproblem',
                                  label      =>'Solution',
                                  container  =>'headref'),

   ));
}

sub Init
{
   my $self=shift;

   $self->AddGroup("itilproblem",translation=>'itil::workflow::problem');
}





sub IsModuleSelectable
{
   my $self=shift;
   my $context=shift;
   return(1) if ($self->getParent->IsMemberOf("admin"));
   return(0);
}

sub InitWorkflow
{
   my $self=shift;

   return(undef);
}

sub getDetailBlockPriority                # posibility to change the block order
{  
   return("itilproblem");
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
   return(1) if ($name eq "prio");

   return(0);
}  

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return(qw(ALL)) if (defined($rec));
   return(undef);
}









#######################################################################
package itil::workflow::problem::extauthority;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $msg=$self->T("Externel authority");
   my $templ=<<EOF;
<br><div class=Question><table border=0><tr><td>$msg</td></tr></table></div>
EOF
   return($templ);
}


sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
#   if ($self->getParent->can("isPostReflector") &&
#       $self->getParent->isPostReflector($WfRec)){
#      return("PostReflection"=>$self->T('initiate postreflection'));
#   }
   return();
}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(0);
}

sub Validate
{
   my $self=shift;

   return(1);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   return($self->SUPER::Process($action,$WfRec,$actions));
}



1;
