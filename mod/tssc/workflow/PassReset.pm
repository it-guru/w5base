package tssc::workflow::PassReset;
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

sub Init
{
   my $self=shift;
   $self->AddGroup("absentreqhead");
   return($self->SUPER::Init(@_));
}



sub IsModuleSelectable
{
   my $self=shift;
   my $acl;

#   $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
#                          "base::workflow",
#                          func=>'New',
#                          param=>'WorkflowClass=tssc::workflow::PassReset');
#   if (defined($acl)){
#      return(1) if (grep(/^read$/,@$acl));
#   }
   return(1) if ($self->getParent->IsMemberOf("admin"));
   return(0);
}

sub Init
{
   my $self=shift;
   $self->AddGroup("passresethead");
   return($self->SUPER::Init(@_));
}

sub InitWorkflow
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getParent->getCurrentUserId();
   my $u=getModuleObject($self->Config,"base::user");
   $u->SetFilter({userid=>\$userid});
   my ($rec,$msg)=$u->getOnlyFirst(qw(surname givenname email posix 
                                      office_phone));
   Query->Param("Formated_passresetposix"=>$rec->{posix});
   Query->Param("Formated_passresetsurname"=>$rec->{surname});
   Query->Param("Formated_passresetgivenname"=>$rec->{givenname});
   Query->Param("Formated_passresetemail"=>$rec->{email});
   Query->Param("Formated_passresetcontactphone"=>$rec->{office_phone});


   
}


sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my @l=();

   return(
          $self->InitFields(
           new kernel::Field::Select(
                name          =>'passresetsys',
                label         =>'Application',
                value         =>['ServiceCenter Prod',
                                 'ServiceCenter Test'],
                group         =>'passresethead',
                container     =>'headref'),

           new kernel::Field::Text(
                name          =>'passresetposix',
                frontreadonly =>1,
                label         =>'WiW-Account',
                group         =>'passresethead',
                container     =>'headref'),

           new kernel::Field::Text(
                name          =>'passresetgivenname',
                frontreadonly =>1,
                label         =>'Givenname',
                group         =>'passresethead',
                container     =>'headref'),

           new kernel::Field::Text(
                name          =>'passresetsurname',
                frontreadonly =>1,
                label         =>'Surname',
                group         =>'passresethead',
                container     =>'headref'),

           new kernel::Field::Text(
                name          =>'passresetemail',
                frontreadonly =>1,
                label         =>'E-Mail',
                group         =>'passresethead',
                container     =>'headref'),

           new kernel::Field::Text(
                name          =>'passresetcontactphone',
                label         =>'Contact-Phone',
                group         =>'passresethead',
                container     =>'headref'),

         ));

}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("passresethead","flow","default","header","state");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
#   return(1) if (!defined($rec));
#   return("default") if ($rec->{state}<=7 &&
#                         ($self->getParent->getCurrentUserId()==$rec->{owner} ||
#                          $self->getParent->IsMemberOf("admin")));
   return(undef);
}

sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   return("tssc::workflow::PassReset::".$shortname);
}


sub getNextStep
{
   my $self=shift;
   my $currentstep=shift;
   my $WfRec=shift;

   if($currentstep eq "tssc::workflow::PassReset::finish"){
      return($self->getStepByShortname("finish",$WfRec)); 
   }
   elsif($currentstep=~m/^.*::workflow::PassReset::verify$/){
      return($self->getStepByShortname("process",$WfRec)); 
   }
   elsif($currentstep=~m/^.*::workflow::PassReset::dataload$/){
      return($self->getStepByShortname("verify",$WfRec)); 
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

   return(0) if ($name eq "prio");
   return(0) if ($name eq "name");
   return(1) if ($name eq "shortactionlog");
   return(0) if ($name eq "detaildescription");
   return(0);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return("passresethead","flow","state");
}


#sub getPosibleDirectActions
#{
#   my $self=shift;
#   my $WfRec=shift;
#   return("approve");
#}

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


sub CallResync
{
   my $self=shift;
   my $wfid=shift;
   my $userid=$self->getParent->getCurrentUserId();
   printf STDERR ("fifi Resync $wfid ===============\n");
   my $method="rpcCallSpooledEvent";
   my %p=(eventname=>'tsscResyncPassReset',
          spooltag=>'tsscResyncPassReset.'.$wfid,
          eventparam=>$wfid,
          redefine=>'0',
          firstcalldelay=>3,
          userid=>$userid);
   $self->W5ServerCall($method,%p);

}


#######################################################################
package tssc::workflow::PassReset::dataload;
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
   my $app=$self->getParent->getParent();
   
   my $d=<<EOF;
<tr height=1%>
<td class=fname width=20%>%passresetsys(label)%:</td>
<td class=finput>%passresetsys(storedworkspace)%</td>
</tr>
<tr height=1%>
<td class=fname width=20%>%passresetposix(label)%:</td>
<td class=finput>%passresetposix(storedworkspace)%</td>
</tr>
<tr height=1%>
<td class=fname width=20%>%passresetsurname(label)%:</td>
<td class=finput>%passresetsurname(storedworkspace)%</td>
</tr>
<tr height=1%>
<td class=fname width=20%>%passresetgivenname(label)%:</td>
<td class=finput>%passresetgivenname(storedworkspace)%</td>
</tr>
<tr height=1%>
<td class=fname width=20%>%passresetemail(label)%:</td>
<td class=finput>%passresetemail(storedworkspace)%</td>
</tr>
<tr height=1%>
<td class=fname width=20%>%passresetcontactphone(label)%:</td>
<td class=finput>%passresetcontactphone(storedworkspace)%</td>
</tr>
EOF

   return($self->SUPER::generateStoredWorkspace($WfRec,@steplist).$d);
}


sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $app=$self->getParent->getParent();

   my $d=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr height=1%>
<td class=fname width=20%>%passresetsys(label)%:</td>
<td class=finput>%passresetsys(detail)%</td>
</tr>
<tr height=1%>
<td class=fname width=20%>%passresetposix(label)%:</td>
<td class=finput>%passresetposix(detail)%</td>
</tr>
<tr height=1%>
<td class=fname width=20%>%passresetsurname(label)%:</td>
<td class=finput>%passresetsurname(detail)%</td>
</tr>
<tr height=1%>
<td class=fname width=20%>%passresetgivenname(label)%:</td>
<td class=finput>%passresetgivenname(detail)%</td>
</tr>
<tr height=1%>
<td class=fname width=20%>%passresetemail(label)%:</td>
<td class=finput>%passresetemail(detail)%</td>
</tr>
<tr height=1%>
<td class=fname width=20%>%passresetcontactphone(label)%:</td>
<td class=finput>%passresetcontactphone(detail)%</td>
</tr>
</table>
EOF
   $d.=$app->HtmlPersistentVariables(qw(Formated_passresetposix
                                        Formated_passresetsurname
                                        Formated_passresetgivenname
                                        Formated_passresetemail));

   return($d);
}

#sub Validate
#{
#   my $self=shift;
#   my $oldrec=shift;
#   my $newrec=shift;
#   my $origrec=shift;
#
#   foreach my $v (qw(name)){
#      if ((!defined($oldrec) || exists($newrec->{$v})) && $newrec->{$v} eq ""){
#         $self->LastMsg(ERROR,"field '%s' is empty",
#                        $self->getField($v)->Label());
#         return(0);
#      }
#   }
#   $newrec->{step}=$self->getNextStep();
#
#   return(1);
#}

#sub Process
#{
#   my $self=shift;
#   my $action=shift;
#   my $WfRec=shift;
#   my $actions=shift;
#
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
#   return($self->SUPER::Process($action,$WfRec));
#}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("200");
}

#######################################################################
package tssc::workflow::PassReset::verify;
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
<table border=0 cellspacing=0 cellpadding=0 width=100% height=110>
$StoredWorkspace
<tr><td colspan=2 align=center valign=top>
<div class=Question>
<table border=0 with=80%>
<tr>
<td>
With the next step you will request a reset of your password on the
selected system. Are you sure that you want to do this?
</td>
<td><input type=checkbox name=verified>
</td>
</tr>
</table>
</div>
</td>
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

   $newrec->{name}="Password Reset";

   foreach my $v (qw(name)){
      if ((!defined($oldrec) || exists($newrec->{$v})) && $newrec->{$v} eq ""){
         $self->LastMsg(ERROR,"field '%s' is empty",
                        $self->getField($v)->Label());
         return(0);
      }
   }
   $newrec->{step}=$self->getNextStep();

   return(1);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      if (!Query->Param("verified")){
         $self->LastMsg(ERROR,"request was not confirmed");
         return(0);
      }
      my $h=$self->getWriteRequestHash("web");
      $h->{stateid}=1;
      $h->{eventstart}=NowStamp("en");
      $h->{eventend}=undef;
      $h->{closedate}=undef;
      printf STDERR ("d=%s\n",Dumper($h));
      my $newid;
      if (!($newid=$self->StoreRecord($WfRec,$h))){
         return(0);
      }
      else{
         $self->getParent->CallResync($newid);
      }
   }

   return($self->SUPER::Process($action,$WfRec));
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("200");
}

#######################################################################
package tssc::workflow::PassReset::process;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $templ=<<EOF;
Waiting for processing the request throw ServiceCenter Admins
EOF
   return($templ);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   # for updates from event server
   return(1);
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("55");
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my $app=$self->getParent->getParent;
   return("resync"=>"resync") if ($app->IsMemberOf("admin"));
   return();
}


sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "resync"){
      $self->getParent->CallResync($WfRec->{id});
   }

   return($self->SUPER::Process($action,$WfRec));
}





1;
