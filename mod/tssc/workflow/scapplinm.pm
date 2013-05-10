package tssc::workflow::scapplinm;
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
use tssc::workflow::screq;
@ISA=qw(tssc::workflow::screq);

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
      new kernel::Field::KeyText(
                name          =>'affectedapplication',
                translation   =>'itil::workflow::base',
                xlswidth      =>'30',
                keyhandler    =>'kh',
                readonly      =>1,
                vjointo       =>'itil::appl',
                vjoinon       =>['affectedapplicationid'=>'id'],
                vjoindisp     =>'name',
                container     =>'headref',
                group         =>'affected',
                label         =>'Affected Application'),

      new kernel::Field::KeyText(
                name          =>'affectedapplicationid',
                htmldetail    =>0,
                translation   =>'itil::workflow::base',
                searchable    =>0,
                readonly      =>1,
                keyhandler    =>'kh',
                container     =>'headref',
                group         =>'affected',
                label         =>'Affected Application ID'),

      new kernel::Field::Text(
                name          =>'scassignmentgroup',
                label         =>'SC Incident Assignmentgroup',
                container     =>'headref'),

      new kernel::Field::Select(
                name          =>'reqnature',
                label         =>'Request nature',
                htmleditwidth =>'60%',
                value         =>["Software","Hardware","Administration"],
                container     =>'headref'),

      $self->SUPER::getDynamicFields(%param),

   ));
}





sub IsModuleSelectable
{
   my $self=shift;
   my %env=@_;
   if ($self->getParent->IsMemberOf("admin")){
      return(1);
   }
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

   my @actions=$self->SUPER::getPosibleActions($WfRec);
   push(@actions,"nop") if ($stateid<21);
   return(@actions);
}

sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   return("tssc::workflow::scapplinm::".$shortname);
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
      return("tssc::workflow::screq::Wait4SC");
   }
   return(undef);
}





#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/base/load/workflow_admin.jpg?".$cgi->query_string());
#}





#######################################################################
package tssc::workflow::scapplinm::dataload;
use vars qw(@ISA);
use kernel;
use tssc::workflow::screq;
@ISA=qw(tssc::workflow::screq::step);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   
   my $oldval=Query->Param("Formated_prio");
   $oldval="5" if (!defined($oldval));
   my $d="<select name=Formated_prio>";
   my @l=("high"=>3,"normal"=>5,"low"=>8);
   while(my $n=shift(@l)){
      my $i=shift(@l);
      $d.="<option value=\"$i\"";
      $d.=" selected" if ($i==$oldval);
      $d.=">".$self->T($n,"base::workflow")."</option>";
   }
   $d.="</select>";


   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width="100%">
<tr>
<td class=fname>%name(label)%:</td>
<td colspan=3 class=finput>%name(detail)%</td>
</tr>
<tr>
<td class=fname>%affectedapplication(label)%:</td>
<td colspan=3 class=finput>%affectedapplication(detail)%</td>
</tr>
<tr>
<td class=fname width="20%">%reqnature(label)%:</td>
<td class=finput>%reqnature(detail)%</td>
</tr>
<tr>
<td class=fname width="20%">%prio(label)%:</td>
<td class=finput>$d</td>
</tr>
<tr>
<td class=fname width="20%" valign=top>%detaildescription(label)%:</td>
<td class=finput>%detaildescription(detail)%</td>
</tr>
</table>
EOF
   return($templ);
}

sub addInitialParameters
{
   my $self=shift;
   my $newrec=shift;
   my $targetsys=$newrec->{targetsys};
   if (ref($targetsys) eq "ARRAY"){
      $targetsys=$targetsys->[0];
      $newrec->{targetsys}=$targetsys;
   }
   $newrec->{step}="tssc::workflow::scapplinm::wait4sc";
   $newrec->{directlnktype}="tssc::incident";
   $newrec->{directlnkmode}="w5base2extern";
   return(1);
}



sub nativProcess
{
   my $self=shift;
   my $action=shift;
   my $h=shift;
   my $WfRec=shift;
   my $actions=shift;


   if ($action eq "NextStep"){
      $h->{stateid}=6;
      $h->{eventend}=undef;
      $h->{closedate}=undef;

      if ($W5V2::OperationContext ne "Kernel"){
         $h->{eventstart}=NowStamp("en");
      }
      if (!$self->addInitialParameters($h)){
         if (!$self->getParent->LastMsg()){
            $self->LastMsg(ERROR,
                   "unknown error while addInitialParameters");
         }
         return(0);
      }
      my $applid=$h->{affectedapplicationid};
      if ($applid eq ""){
         $self->LastMsg(ERROR,"invalid application");
         return(0);
      }
      my $appl=getModuleObject($self->Config,"TS::appl");
      if (!defined($appl)){
         $self->LastMsg(ERROR,"can't connect to TS::appl - contact admin");
         return(0);
      }
      $appl->SetFilter({id=>\$applid});
      my ($arec)=$appl->getOnlyFirst(qw(acinmassingmentgroup));
      if ($arec->{acinmassingmentgroup} eq ""){
         $self->LastMsg(ERROR,"can't find a valid incident assignmentgroup");
         return(0);
      }
      $h->{scassignmentgroup}=$arec->{acinmassingmentgroup};
      if (my $id=$self->StoreRecord($WfRec,$h)){
         $h->{id}=$id;
         $self->PostProcess($action,$h,$actions);
      }
      else{
         return(0);
      }
      return(1);
   }
   return(undef);
}


sub PostProcess
{
   my $self=shift;
   my $action=shift;
   my $h=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      $self->triggerSync($h->{id});
   }
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      my $fo=$self->getField("affectedapplication");
      my $foval=Query->Param("Formated_".$fo->Name());
      if ($foval=~m/^\s*$/){
         $self->LastMsg(ERROR,"no application specified");
         return(0);
      }
      if (!$fo->Validate($WfRec,{$fo->Name=>$foval})){
         $self->LastMsg(ERROR,"unknown error") if (!$self->LastMsg());
         return(0);
      }
      my $h=$self->getWriteRequestHash("web");
      return($self->nativProcess($action,$h,$WfRec,$actions));
   }
   return($self->SUPER::Process($action,$WfRec,$actions));
}




sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("250");
}


#######################################################################
package tssc::workflow::scapplinm::main;
use vars qw(@ISA);
use kernel;
use tssc::workflow::screq;
@ISA=qw(tssc::workflow::screq::step);


sub generateWorkspacePages
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $divset=shift;
   my $selopt=shift;
   my $tr="base::workflow::adminrequest";
   my $class="display:none;visibility:hidden";

   if ($self->getParent->{ITIL_installed}){
      if (grep(/^wftrans2devreq$/,@$actions)){
         $$selopt.="<option value=\"wftrans2devreq\">".
                   $self->getParent->T("wftrans2devreq",$tr).
                   "</option>\n";
         my $d="<table width=\"100%\" border=0 cellspacing=0 cellpadding=0>".
               "<tr>".
               "<td colspan=2>Umwandeln in einen Entwickler-Request ".
               "für folgende Anwendung</td>".
               "</tr>".
               "<tr>".
               "<td width=15%>\%affectedapplication(label)\%: </td>".
               "<td>\%affectedapplication(detail)\%</td>".
               "</tr>".
               "<tr>".
               "<td colspan=2>".
               $self->getDefaultNoteDiv($WfRec,$actions,
                                        mode=>'native',height=>60).
               "</td>".
               "</tr>";
         $d.="</table>";
         $$divset.="<div id=OPwftrans2devreq class=\"$class\">$d</div>";
      }
   }

   return($self->SUPER::generateWorkspacePages($WfRec,$actions,$divset,$selopt));
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

#   foreach my $v (qw(name)){
#      if ((!defined($oldrec) || exists($newrec->{$v})) && $newrec->{$v} eq ""){
#         $self->LastMsg(ERROR,"field '%s' is empty",
#                        $self->getField($v)->Label());
#         return(0);
#      }
#   }

   return(1);
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(0) if ($WfRec->{stateid}>=21);
   return("240");
}


sub HandelNewSCdata
{
   my $self=shift;
   my $WfRec=shift;
   my $searchResult=shift;
   my $record=$searchResult->{record};

   if (lc($record->{'problem.status'}) ne "open"){
      my $wf=$self->getParent->getParent->Clone();
      $wf->Store($WfRec,{stateid=>21,
                         directlnkmode=>'finish',
                         closedate=>NowStamp("en"),
                         screqlastsync=>NowStamp("en")});
   }
}






#######################################################################
package tssc::workflow::scapplinm::wait4sc;
use vars qw(@ISA);
use kernel;
use tssc::workflow::screq;
@ISA=qw(tssc::workflow::screq::wait4external);



sub nativProcess
{
   my $self=shift;
   my $action=shift;
   my $h=shift;
   my $WfRec=shift;
   my $actions=shift;


   if ($action eq "extrefresh"){
      if ($WfRec->{scworkflowid} eq ""){
         $self->openNew($WfRec);
      }
      else{
         $self->processExternalData($WfRec->{scworkflowid},$WfRec);
      }
      return(1);
   }
}

sub handleExternalData
{
   my $self=shift;
   my $WfRec=shift;
   my $searchResult=shift;
   my $app=$self->getParent->getParent();
   my $record=$searchResult->{record};

   msg(INFO,"Current state for $WfRec->{id} on ".
            "SC $searchResult->{recordid} = $record->{'problem.status'}");
#printf STDERR ("fifi rec=%s\n",Dumper($searchResult));
   if ($record->{'problem.status'} ne "Open"){ # hier müssen vermutlich 
                                               # noch mehr Stati berücksichtigt
                                               # werden.
      my $msg="no msg from SC";
      if (ref($searchResult->{activity}) eq "ARRAY"){
         foreach my $act (@{$searchResult->{activity}}){
            if ($act->{type} eq "Resolved"){
               $msg=$act->{operator}.":\n".$act->{description};
               last;
            }
         }
      }
      $app->Action->StoreRecord(
             $WfRec->{id},"note",
             {translation=>'base::workflowaction'},
             $msg,undef);
      $app->Store($WfRec,{stateid=>17,
                          directlnkmode=>'fixlink',
                          step=>'tssc::workflow::scapplinm::main',
                          closedate=>NowStamp("en"),
                          screqlastsync=>NowStamp("en")});
      $app->Action->NotifyForward($WfRec->{id},'base::user',
                                  $WfRec->{openuser},$WfRec->{openusername},
                                  'Your request has been processed.',
                                  mode=>'INFO');
   }
 #  printf STDERR ("fifi default HandelNewSCdata %s\n",Dumper($searchResult));
}


sub openNew
{
   my $self=shift;
   my $WfRec=shift;

   my $reportedby="W5BASE";
   my $reportedlastname="";
   my $reportedfirstname="";
   my $reportedemail="";
   my $wf=$self->getParent->getParent()->Clone();
   my $openuser=$WfRec->{openuser};
   my $urec;
   if ($openuser=~m/^\d+$/){
      my $user=getModuleObject($self->getParent->getParent()->Config,
                               "base::user");
      $user->SetFilter({userid=>\$openuser});
      ($urec)=$user->getOnlyFirst(qw(ALL));
   }
   if (defined($urec)){
      if ($urec->{posix} ne ""){
         $reportedby=uc($urec->{posix});
      }
      if ($urec->{surname} ne ""){
         $reportedlastname=$urec->{surname};
      }
      if ($urec->{givenname} ne ""){
         $reportedfirstname=$urec->{givenname};
      }
      if ($urec->{email} ne ""){
         $reportedemail=$urec->{email};
      }
   }
   msg(DEBUG,"try to connect to ServiceCenter");
   my $sc=$self->getSC();
   return(undef) if (!defined($sc));
   msg(DEBUG,"connect to ServiceCenter seems to be successfull");
   my ($IncidentNumber,$msg);
   msg(DEBUG,"sending scapplinm for scapplinm($WfRec->{id})");
   my $action;
   $action=$WfRec->{detaildescription};
   $action.="\r\n\r\nMit freundlichen Grüßen";


   my $subcategory2="OTHER";
   my $assignment=$WfRec->{scassignmentgroup};
   
   my %Incident=('brief.description'    =>$WfRec->{name},
                 'problem.shortname'    =>'TS_DE_BAMBERG_GUTENBERG_13',
                 'assignment'           =>$assignment,
                 'home.assignment'      =>'CSS.TCOM.W5BASE',
                 'priority.code'        =>'3',
                 'urgency'              =>'Medium',
                 'business.impact'      =>'Medium',
                 'dsc.criticality'      =>'Low',
                 'sla.relevant'         =>'No',
                 'category'             =>'ACCESS',
                 'company'              =>'T-Systems',
                 'subcategory1'         =>'PASSWORD',
                 'dsc.service'          =>$WfRec->{affectedapplication}->[0],
                 'subcategory2'         =>$subcategory2,
                 'reported.lastname'    =>$reportedlastname,
                 'reported.firstname'   =>$reportedfirstname,
                 'contact.lastname'     =>$reportedlastname,
                 'contact.firstname'    =>$reportedfirstname,
                 'contact.name'         =>$reportedby,
                 'referral.no'          =>"W5Base:".$WfRec->{id},
                 'contact.mail.address' =>$reportedemail,
                 'category.type'        =>'PASSWORD RESET',
                 'reported.by'          =>$reportedby,
                 'action'               =>$action);
   if (!defined($IncidentNumber=$sc->IncidentCreate(\%Incident))){
      printf STDERR ("ERROR: ServiceCenter CreateIncident failed\n");
      $msg=$sc->LastMessage();
      printf STDERR ("ERROR: msg=%s\n",$msg);
   }
   else{
      printf STDERR ("INFO:  CreateIncident is ok\n");
   }
   $sc->Logout();
   if ($IncidentNumber ne ""){
      my $okstep=$WfRec->{class};
      $wf->Action->StoreRecord(
             $WfRec->{id},"procinfo",
             {translation=>'base::workflow::actions'},
             "succsefuly created ".$IncidentNumber,undef);
      $wf->Store($WfRec,{stateid=>4,
                         eventend=>NowStamp("en"),
                         screqlastsync=>NowStamp("en"),
                         directlnkmode=>'extern2w5base',
                         scworkflowid=>$IncidentNumber});
   # 17 is close
   # 21 is finish
   }
   printf STDERR ("INFO:  Logout is ok\n\n");
   printf STDERR ("Incident Number=%s\n",$IncidentNumber);

   return(1);

}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

printf STDERR ("fifi action=$action\n");
}












1;
