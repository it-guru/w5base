package AL_TCom::workflow::custorder;
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
      new kernel::Field::Select(  name        =>'ordertyp',
                                  selectwidth =>'80%',
                                  label       =>'Order-Type',
                                  defaultvalue=>'contractbased',
                                  value       =>['contractbased',
                                                 'test1','test2'],
                                  group       =>'mailsend',
                                  container   =>'headref'),
      ));

}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/workflow-infoabo.jpg?".$cgi->query_string());
}


sub IsModuleSelectable
{
   my $self=shift;
   my $acl;

#   $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
#                          "base::workflow",
#                          func=>'New',
#                          param=>'WorkflowClass=AL_TCom::workflow::custorder');
#   if (defined($acl)){
#      return(1) if (grep(/^read$/,@$acl));
#   }
   return(1) if ($self->getParent->IsMemberOf("admin"));
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
   return("default","state","flow","header");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(1) if (!defined($rec));
   return("default") if ($rec->{state}<=20 &&
                         ($self->getParent->getCurrentUserId()==$rec->{owner} ||
                          $self->getParent->IsMemberOf("admin")));
   return(undef);
}

sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   return("AL_TCom::workflow::custorder::".$shortname);
}


sub getNextStep
{
   my $self=shift;
   my $currentstep=shift;
   my $WfRec=shift;

   if($currentstep eq "AL_TCom::workflow::custorder::ordertyp"){
      return($self->getStepByShortname("orderdesc",$WfRec)); 
   }
   elsif($currentstep eq "AL_TCom::workflow::custorder::orderdesc"){
      return($self->getStepByShortname("verify",$WfRec)); 
   }
   elsif($currentstep eq ""){
      return($self->getStepByShortname("ordertyp",$WfRec)); 
   }
   return(undef);
}

sub isOptionalFieldVisible
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   my $name=$param{field}->Name();

   return(1) if ($name eq "prio");
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
   my @l=();

   msg(INFO,"valid operations=%s",join(",",@l));

   return(@l);
}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(300);
}


#######################################################################
package AL_TCom::workflow::custorder::ordertyp;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub generateStoredWorkspace
{
   my $self=shift;
   my $WfStep=shift;
   my @steplist=@_;
   my $d="";

   $d=<<EOF;
<tr>
<td class=fname width=20%>%ordertyp(label)%:</td>
<td class=finput>%ordertyp(storedworkspace)%</td>
</tr>
EOF

   return($self->SUPER::generateStoredWorkspace($WfStep,@steplist).$d);
}

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr>
<td class=fname width=20%>%ordertyp(label)%:</td>
<td class=finput>%ordertyp(detail)%</td>
</tr>
</table>
EOF
   return($templ);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   foreach my $v (qw(ordertyp)){
      if ((!defined($oldrec) || exists($newrec->{$v})) && $newrec->{$v} eq ""){
         $self->LastMsg(ERROR,"field '%s' is empty",
                        $self->getField($v)->Label());
         return(0);
      }
   }
   $newrec->{step}=$self->getNextStep();

   return(1);
}



#######################################################################
package AL_TCom::workflow::custorder::orderdesc;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub generateStoredWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my @steplist=@_;
   my $d="";

   $d=<<EOF;
<tr>
<td class=fname width=20%>%name(label)%:</td>
<td class=finput>%name(storedworkspace)%</td>
</tr>
<tr>
<td class=fname width=20%>%detaildescription(label)%:</td>
<td class=finput>%detaildescription(storedworkspace)%</td>
</tr>
EOF

   return($self->SUPER::generateStoredWorkspace($WfRec,@steplist).$d);
}

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my @steplist=Query->Param("WorkflowStep");
   pop(@steplist);
   my $StoredWorkspace=$self->SUPER::generateStoredWorkspace($WfRec,@steplist);


   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
$StoredWorkspace
<tr>
<td class=fname width=20%>%name(label)%:</td>
<td class=finput>%name(detail)%</td>
</tr>
<tr>
<td colspan=2 class=fname>%detaildescription(label)%:<br>
%detaildescription(detail)%</td>
</tr>
</table>
EOF
   return($templ);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   foreach my $v (qw(ordertyp)){
      if ((!defined($oldrec) || exists($newrec->{$v})) && $newrec->{$v} eq ""){
         $self->LastMsg(ERROR,"field '%s' is empty",
                        $self->getField($v)->Label());
         return(0);
      }
   }
   $newrec->{step}=$self->getNextStep();

   return(1);
}





























#######################################################################
package AL_TCom::workflow::custorder::verify;
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
   my @steplist=Query->Param("WorkflowStep");
   pop(@steplist);
   my $StoredWorkspace=$self->SUPER::generateStoredWorkspace($WfRec,@steplist);

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
$StoredWorkspace
<tr>
<td class=fname width=20%>%ordertyp(label)%:</td>
<td class=finput>%ordertyp(detail)%</td>
</tr>
</table>
EOF
   return($templ);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   foreach my $v (qw(ordertyp)){
      if ((!defined($oldrec) || exists($newrec->{$v})) && $newrec->{$v} eq ""){
         $self->LastMsg(ERROR,"field '%s' is empty",
                        $self->getField($v)->Label());
         return(0);
      }
   }

   $self->LastMsg(ERROR,"no way");
   return(0);


   $newrec->{step}=$self->getNextStep();

   return(1);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

#   if ($action eq "NextStep"){
#      my $h=$self->getWriteRequestHash();
#      $h->{stateid}=1;
#      $h->{eventstart}=NowStamp("en");
#      $h->{eventend}=undef;
#      $h->{closedate}=undef;
#      if (!$self->StoreRecord($WfRec,$h)){
#         return(0);
#      }
#   }
   return($self->SUPER::Process($action,$WfRec));
}



1;
