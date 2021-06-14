package base::workflow::Archive;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","header","state");
}

sub getDetailBlockPriority            # posibility to change the block order
{
   return("header","default","state");
}

sub IsModuleSelectable
{
   return(0);
}


sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;


   my @dynfields=$self->InitFields(
                   new kernel::Field::Container(  
                             name               =>'internalarchievedheadref',
                             readonly           =>1,
                             htmldetail         =>'NotEmpty',
                             uivisible          =>1,
                             group              =>'state',
                             translation        =>'base::workflow::Archive',
                             label              =>'headref',
                             onRawValue    =>sub {
                                   my $self=shift;
                                   my $current=shift;
                                   my $d=$current->{headref};
                                   if (ref($d) ne "HASH"){
                                      my %h=Datafield2Hash($d);
                                      return(\%h);
                                   }
                                   return($d);
                             }),
                   new kernel::Field::Container(  
                             name               =>'internalarchievedadditional',
                             readonly           =>1,
                             htmldetail         =>'NotEmpty',
                             uivisible          =>1,
                             group              =>'state',
                             translation        =>'base::workflow::Archive',
                             label              =>'additional',
                             onRawValue    =>sub {
                                   my $self=shift;
                                   my $current=shift;
                                   my $d=$current->{additional};
                                   if (ref($d) ne "HASH"){
                                      my %h=Datafield2Hash($d);
                                      return(\%h);
                                   }
                                   return($d);
                             }),
                 );
   return(@dynfields);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}




sub isOptionalFieldVisible
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   my $name=$param{field}->Name();

   return(1) if ($self->IsMemberOf("admin"));

   return(1) if ($name eq "name");
   return(0);
}



sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;
   my $app=$self->getParent;
   my $userid=$self->getParent->getCurrentUserId();
   my $isadmin=$self->getParent->IsMemberOf("admin");
   my $stateid=$WfRec->{stateid};
   my $lastworker=$WfRec->{owner};
   my $creator=$WfRec->{openuser};
   my $initiatorid=$WfRec->{initiatorid};
   my @l=();
   return(@l);
}


sub getWorkflowMailName
{
   my $self=shift;

   my $workflowname=$self->getParent->T($self->Self(),$self->Self());
   return($workflowname);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/archive.jpg?".$cgi->query_string());
}


#######################################################################
package base::workflow::Archive::Archive;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("0");
}


1;
