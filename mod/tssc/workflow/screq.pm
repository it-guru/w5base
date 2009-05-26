package tssc::workflow::screq;
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
   $self->{history}=[qw(insert modify delete)];

   return($self);
}

sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;

   return($self->InitFields(

      new kernel::Field::Date (
                name          =>'screqlastsync',
                group         =>'init',
                label         =>'last sync to SC',
                container     =>'headref'),

      new kernel::Field::Select (
                name          =>'scsyncronisationstate',
                readonly      =>1,
                value         =>['fixlink','w5base2extern','extern2w5base'],
                group         =>'init',
                translation   =>'base::workflowaction',
                label         =>'Sync state',
                alias         =>'directlnkmode'),

      new kernel::Field::Text (
                name          =>'scworkflowid',
                group         =>'init',
                label         =>'SC WorkflowID',
                container     =>'headref'),
    ));
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
   return("default","state","flow","header","relations","init","history");
}


sub getDetailBlockPriority            # posibility to change the block order
{
   return("init","flow");
}


sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   return("tssc::workflow::screq::".$shortname);
}


sub getNextStep
{
   my $self=shift;
   my $currentstep=shift;
   my $WfRec=shift;

   if($currentstep eq ""){
      return($self->getStepByShortname("dataload",$WfRec)); 
   }
   if($currentstep=~m/::dataload$/){
      return($self->getStepByShortname("main",$WfRec)); 
   }
   return(undef);
}

sub isOptionalFieldVisible
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   my $name=$param{field}->Name();

   return(0) if ($name eq "relations");
   return(1) if ($name eq "prio");
   return(1) if ($name eq "name");
   return(1) if ($name eq "shortactionlog");
   return(0) if ($name eq "detaildescription");
   return(0);
}

sub Init
{  
   my $self=shift;

   $self->AddGroup("init",translation=>'tssc::workflow::screq');
   return(1);
}


sub getWorkflowMailName
{
   my $self=shift;

   my $workflowname=$self->getParent->T($self->Self(),$self->Self());
   return($workflowname);
}


sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;
   my $app=$self->getParent;
#   my $userid=$self->getParent->getCurrentUserId();
#   my $isadmin=$self->getParent->IsMemberOf("admin");
   my $stateid=$WfRec->{stateid};
#   my $lastworker=$WfRec->{owner};
#   my $creator=$WfRec->{openuser};
#   my $initiatorid=$WfRec->{initiatorid};
   my @l=();
#   my $iscurrent=$self->isCurrentForward($WfRec);
#   my $isworkspace=0;


#   if (!$iscurrent){  # check Workspace only if not current
#      $isworkspace=$self->isCurrentWorkspace($WfRec); 
#   }
#   my $iscurrentapprover=0;
   if ($stateid<21){
      push(@l,"extrefresh");
   }

   return(@l);
}



#######################################################################
package tssc::workflow::screq::step;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);


#sub getPosibleButtons
#{
#   my $self=shift;
#   my $WfRec=shift;
#   my $actions=shift;
#   my @WorkflowStep=Query->Param("WorkflowStep");
#   my %b=();
#   my @saveables=grep(!/^wfbreak$/,@$actions);
#   if ($#saveables!=-1){
#      %b=(SaveStep=>$self->T('Save')) if ($#{$actions}!=-1);
#   }
#   if (defined($WfRec->{id})){
#      if (grep(/^wfbreak$/,@$actions)){
#         $b{BreakWorkflow}=$self->T('abbort request');
#      }
#   }
#   return(%b);
#}

sub generateWorkspacePages
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $divset=shift;
   my $selopt=shift;
   my $tr="tssc::workflow::screq";
   my $class="display:none;visibility:hidden";

   my $defop;
   if (grep(/^scresync$/,@$actions)){
      $$selopt.="<option value=\"scresync\">".
                $self->getParent->T("scresync",$tr).
                "</option>\n";
      $$divset.="<div id=OPscresync class=\"$class\">".
                "</div>";
   }
   $self->SUPER::generateWorkspacePages($WfRec,$actions,$divset,$selopt);
   $defop="nop";
   return($defop);
}

sub processExternalData
{
   my $self=shift;
   my $scid=shift;
   my $WfRec=shift;

   msg(DEBUG,"processing screfresh event for ".$WfRec->{scworkflowid});
   my $sc=$self->getSC();
   return(undef) if (!defined($sc));
   msg(DEBUG,"connect to ServiceCenter seems to be successfull");
   my $searchResult;
   if (!defined($searchResult=$sc->IncidentSearch(
                  'number'=>$WfRec->{scworkflowid},
                  'search.open.flag'=>'either'))){
      printf STDERR ("ERROR: ServiceCenter SearchIncident failed\n");
   }
   if (defined($searchResult)){
   #   printf STDERR ("SC=%s\n",Dumper($searchResult));
      $self->handleExternalData($WfRec,$searchResult);
 
   }
   $sc->Logout();
   msg(DEBUG,"logout on ServiceCenter OK");
   return(1);
}


sub handleExternalData
{
   my $self=shift;
   my $WfRec=shift;
   my $searchResult=shift;
   my $record=$searchResult->{record};
   printf STDERR ("fifi default HandelNewSCdata %s\n",Dumper($record));
}

sub getSC
{
   my $self=shift;
   my $app=$self->getParent->getParent();

   my $sc;
   eval("use SC::Customer::TSystems;\$sc=new SC::Customer::TSystems;");
   return(undef) if (!defined($sc));

   my $dataobjconnect=$app->Config->Param('DATAOBJCONNECT');
   my $dataobjuser=$app->Config->Param('DATAOBJUSER');
   my $dataobjpass=$app->Config->Param('DATAOBJPASS');
   my $SCuri=$dataobjconnect->{tsscui};
   my $SCuser=$dataobjuser->{tsscui};
   my $SCpass=$dataobjpass->{tsscui};

   if (!$sc->Connect($SCuri,$SCuser,$SCpass)){
      printf STDERR ("ERROR: ServiceCenter connect failed\n");
      printf STDERR ("ERROR: $SCuser \@ $SCuri\n");
      return(undef);
   }
   if (!$sc->Login()){
      printf STDERR ("ERROR: SC URL=$SCuri\n");
      printf STDERR ("ERROR: SC User=$SCuser\n");
      printf STDERR ("ERROR: SC Pass=$SCpass\n");
      printf STDERR ("ERROR: ServiceCenter login failed\n");
      $sc->Logout();
      return(undef);
   }
   return($sc);
}


sub triggerSync
{
   my $self=shift;
   my $id=shift;

   my $app=$self->getParent->getParent();
   my $res;

   if ($id ne ""){
      $res=$app->W5ServerCall("rpcReloadW5Server","tssc::W5Server::scsync");
     
      if (defined($res) && $res->{exitcode}==0){
         if ($self->getParent->getParent->Action->StoreRecord(
             $id,"info",
             {translation=>'base::workflow::actions'},"Sync",undef)){
            return(1);
         }
      }
      else{
         if ($self->getParent->getParent->Action->StoreRecord(
             $id,"info",
             {translation=>'base::workflow::actions'},
                          "Sync request failed",undef)){
            return(1);
         }
      }
   }
}




#######################################################################
package tssc::workflow::screq::wait4external;
use vars qw(@ISA);
use kernel;
@ISA=qw(tssc::workflow::screq::step);


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

   return("80");
}





1;
