package base::workflow::DataIssue;
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

   $self->LoadSubObjs("ext/DataIssue","DI");
   foreach my $objname (keys(%{$self->{DI}})){
      my $obj=$self->{DI}->{$objname};
      foreach my $entry (@{$obj->getControlRecord()}){
         $self->{da}->{$entry->{dataobj}}=$entry;
         $self->{da}->{$entry->{dataobj}}->{DI}=$objname;
      }
   }

   return($self);
}

sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;


   #printf STDERR ("Query in getDynamicFields=%s\n",
   #               Dumper(scalar(Query->MultiVars())));
   my $affectedobject;
   if (defined($param{current})){
      $affectedobject=$param{current}->{affectedobject};
   }
   else{
      Query->Param("Formated_affectedobject");
   }
   my $dst;
   foreach my $dstobj (sort(keys(%{$self->{da}}))){
      if ($self->{da}->{$dstobj}->{dataobj}=~m/::/){
         push(@$dst,$self->{da}->{$dstobj}->{dataobj},
              $self->{da}->{$dstobj}->{target});
      }
   }
   my ($DataIssueName,$dataobjname)=split(/;/,$affectedobject);
   my @dynfields=$self->InitFields(
                   new kernel::Field::Select(  
                             name               =>'affectedobject',
                             htmleditwidth      =>'350px',
                             translation        =>'base::workflow::DataIssue',
                             getPostibleValues  =>\&getObjectList,
                             htmldetail    =>sub {
                                my $self=shift;
                                my $mode=shift;
                                my %param=@_;
                                my $current=$param{current};
                                return(1) if ($current->{affectedobject} ne "");
                                return(0);
                             },

                             label              =>'affected Dataobject Type',
                             container          =>'additional'),
                   new kernel::Field::MultiDst(  
                             name               =>'dataissueobjectname',
                             translation        =>'base::workflow::DataIssue',
                             label              =>'affected Dataobject',
                             htmldetail    =>sub {
                                my $self=shift;
                                my $mode=shift;
                                my %param=@_;
                                my $current=$param{current};
                                my $f1=$self->getParent->
                                        getField("affectedobjectid");
                                my $f2=$self->getParent->
                                        getField("altaffectedobjectname");
                                my $fval1=$f1->RawValue($current);
                                my $fval2=$f2->RawValue($current);
                                my $current=$param{current};
                                if ($fval1 ne "" || $fval2 ne ""){
                                   return(1);
                                }
                                return(0);
                             },
                             dst                =>$dst,
                             selectivetyp       =>1,
                             altnamestore       =>'altaffectedobjectname',
                             dsttypfield        =>'affectedobjectinstance',
                             dstidfield         =>'affectedobjectid'),
                   new kernel::Field::Text(  
                             name               =>'affectedobjectid',
                             htmldetail         =>0,
                             readonly           =>1,
                             translation        =>'base::workflow::DataIssue',
                             label              =>'affected Dataelement ID',
                             container          =>'additional'),
                   new kernel::Field::Text(  
                             name               =>'affectedobjectinstance',
                             htmldetail         =>0,
                             readonly           =>1,
                             translation        =>'base::workflow::DataIssue',
                             label           =>'affected Dataelement instance',
                             container          =>'additional'),
                   new kernel::Field::Link(  
                             name               =>'altaffectedobjectname',
                             translation        =>'base::workflow::DataIssue',
                             label              =>'affected Dataelement Name',
                             container          =>'additional'),
                   new kernel::Field::Link(  
                             name               =>'dataissuemetric',
                             translation        =>'base::workflow::DataIssue',
                             history            =>0,
                             label              =>'DataIssue Metrics',
                             container          =>'additional'),
                   new kernel::Field::Link(  
                             name               =>'dataissuerulecount',
                             translation        =>'base::workflow::DataIssue',
                             history            =>0,
                             label              =>'DataIssue total rule count',
                             container          =>'additional'),
                   new kernel::Field::Link(  
                             name               =>'dataissueactiverulecount',
                             translation        =>'base::workflow::DataIssue',
                             history            =>0,
                             label              =>'DataIssue active rule count',
                             container          =>'additional'),
                   new kernel::Field::Link(  
                             name               =>'DATAISSUEOPERATIONSRC',
                             translation        =>'base::workflow::DataIssue',
                             label              =>'DataIssue Source',
                             container          =>'additional'),
                   new kernel::Field::Link(  
                             name               =>'DATAISSUEOPERATIONOBJ',
                             translation        =>'base::workflow::DataIssue',
                             label              =>'DataIssue Operation Obj',
                             container          =>'additional'),
                   new kernel::Field::Link(  
                             name               =>'DATAISSUEOPERATIONMOD',
                             translation        =>'base::workflow::DataIssue',
                             label              =>'DataIssue Operation Mode',
                             container          =>'additional'),
                   new kernel::Field::Link(  
                             name               =>'DATAISSUEOPERATIONFLD',
                             translation        =>'base::workflow::DataIssue',
                             label              =>'DataIssue Operation Fields',
                             container          =>'additional'),
                   new kernel::Field::Text(
                             name               =>'involvedcostcenter',
                             htmldetail         =>0,
                             searchable         =>0,
                             container          =>'headref',
                             label              =>'Involved CostCenter'),
                   new kernel::Field::Text(
                             name               =>'involvedaccarea',
                             htmldetail         =>0,
                             searchable         =>0,
                             container          =>'headref',
                             label              =>'Involved Accounting Area'),

                 );
#   if (defined($self->getParent->


   return(@dynfields);
}

sub getObjectList
{
   my $self=shift;
   my $app=$self->getParent->getParent();

   my @l;
   foreach my $k (sort({$app->T($a,$a) cmp $app->T($b,$b)} 
                       keys(%{$self->getParent->{da}}))){
      push(@l,$k,$app->T($k,$k));
   }
   return(@l);

}


sub DataIssueCompleteWriteRequest
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   foreach my $objname (keys(%{$self->{DI}})){
      my $obj=$self->{DI}->{$objname};
      if ($obj->can("DataIssueCompleteWriteRequest")){
         if (!($obj->DataIssueCompleteWriteRequest($oldrec,$newrec))){
            return(undef);
         }
      }
   }
   if ($newrec->{fwdtargetid} eq "" ||
       $newrec->{fwdtarget} eq ""){
      $newrec->{fwdtargetid}=effVal($oldrec,$newrec,"fwdtargetid");
      $newrec->{fwdtarget}=effVal($oldrec,$newrec,"fwdtarget");
   }
   if ($newrec->{fwdtargetid} eq "" ||
       $newrec->{fwdtarget} eq ""){
      my $grpobj=getModuleObject($self->getParent->Config(),"base::grp");
      $grpobj->SetFilter({name=>\'admin'});
      my ($grprec,$msg)=$grpobj->getOnlyFirst(qw(grpid));
      if (defined($grprec)){
         $newrec->{fwdtargetid}=$grprec->{grpid}; 
         $newrec->{fwdtarget}="base::grp"; 
         return(1);
      }
      return(undef);
    
   }
   return(1);
}


sub setClearingDestinations
{
   my $self=shift;
   my $newrec=shift;
   my $mandator=shift;

   my $clearinggrpname='ConfigMgmtClearing';
   my $clearinggrpvalid=0;

   my $grp=getModuleObject($self->Config,'base::grp');

   if ($mandator ne ""){
      $grp->ResetFilter();
      $grp->SetFilter({grpid=>\$mandator,cistatusid=>4});
      my ($mgrp,$msg)=$grp->getOnlyFirst(qw(grpid subunits));
      if (defined($mgrp)){
         foreach my $subgrp (@{$mgrp->{subunits}}){
             if ($subgrp->{name} eq $clearinggrpname){
                $clearinggrpname=$subgrp->{fullname};
                last;
             }
         }
      }
   }

   $grp->ResetFilter();
   $grp->SetFilter({fullname=>\$clearinggrpname,cistatusid=>4});
   my ($clearinggrp,$msg)=$grp->getOnlyFirst(qw(grpid));

   if (defined($clearinggrp)) {
      my @clearingcontacts=$self->getMembersOf($clearinggrp->{grpid},
                                               ["RMember"]);
      if ($#clearingcontacts!=-1) {
         $newrec->{fwdtarget}='base::grp';
         $newrec->{fwdtargetid}=$clearinggrp->{grpid};
         $newrec->{W5StatNotRelevant}=1;
         $clearinggrpvalid=1;
      }
   }


   if (!$clearinggrpvalid) {

      return(0) if (!defined($mandator));

      # now search a Config-Manager
      my @confmgr=$self->getMembersOf($mandator,["RCFManager"],"direct");
      {  # add posible deputies
         my @confmgr2=$self->getMembersOf($mandator,["RCFManager2"],"direct");
         foreach my $uid (@confmgr2){
            if (!in_array(\@confmgr,$uid)){
               push(@confmgr,$uid);
            }
         }
      }
      if ($#confmgr==-1){
         my @cf1=$self->getMembersOf($mandator,["RCFManager"],"up");
         if ($#cf1!=-1){
            push(@confmgr,$cf1[0]);
         }
         my @cf2=$self->getMembersOf($mandator,["RCFManager2"],"up");
         push(@confmgr,@cf2);
      }
      my $cfmgr1=shift(@confmgr);
      my $cfmgr2=shift(@confmgr);
      if ($cfmgr1 ne ""){
         $newrec->{fwdtarget}="base::user";
         $newrec->{fwdtargetid}=$cfmgr1;
      }
      if ($cfmgr2 ne ""){
         $newrec->{fwddebtarget}="base::user";
         $newrec->{fwddebtargetid}=$cfmgr2;
      }
   }

   return(1);
}


sub IsModuleSelectable
{
   return(0);
}

#sub IsModuleSelectable
#{
#   my $self=shift;
#   my $acl;
#
#   $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
#                          "base::workflow",
#                          func=>'New',
#                          param=>'WorkflowClass=base::workflow::DataIssue');
#   if (defined($acl)){
#      return(1) if (grep(/^read$/,@$acl));
#   }
#   return(1) if ($self->getParent->IsMemberOf("admin"));
#   return(0);
#}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","state","source","flow","header",
          "relations","init","history");
}

sub getDetailBlockPriority            # posibility to change the block order
{
   return("header","default","flow","state","source");
}



sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(1) if (!defined($rec));
   my @l;
#   push(@l,"default") if ($rec->{state}<=20 &&
#                         ($self->isCurrentForward() ||
#                          $self->getParent->IsMemberOf("admin")));
#   if (grep(/^default$/,@l) &&
#       ($self->getParent->getCurrentUserId() != $rec->{initiatorid} ||
#        $self->getParent->IsMemberOf("admin"))){
#      push(@l,"init");
#   }
   return(@l);
}




sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   return("base::workflow::DataIssue::".$shortname);
}


sub getNextStep
{
   my $self=shift;
   my $currentstep=shift;
   my $WfRec=shift;

   if($currentstep eq ""){
      return($self->getStepByShortname("dataload",$WfRec)); 
   }
   elsif($currentstep=~m/::dataload$/){
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

   return(0) if ($name eq "prio");
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
   my $isadmin=$self->getParent->IsMemberOf("admin");
   my $stateid=$WfRec->{stateid};
   my $lastworker=$WfRec->{owner};
   my $creator=$WfRec->{openuser};
   my $initiatorid=$WfRec->{initiatorid};
   my @l=();
   my $iscurrent=$self->isCurrentForward($WfRec);

   if ($iscurrent){
      push(@l,"iscurrent");
   }

   if ($stateid==2 || $stateid==4){
      push(@l,"wfaddlnote");
   }
   if ($iscurrent && ($stateid==5)){
      push(@l,"nop");
      push(@l,"wfaddlnote");
   }
   if ($iscurrent && ($stateid==2 || $stateid==4)){
      push(@l,"wfdefer");
      #push(@l,"wfdifine");
      #push(@l,"wfforward");
      push(@l,"wfmailsend");
   }
   if ($iscurrent && $creator==$userid && ($stateid==16)){
      push(@l,"wfdireproc");
      push(@l,"wffine");
   }
   push(@l,"nop") if (($#l==-1 && $stateid<=20) &&
                      ($userid==$creator || $isadmin || $iscurrent));
   if ($creator==$userid && $stateid==2){
      push(@l,"wfbreak");
   }
   if ($isadmin){
      push(@l,"wfbreak");
      #push(@l,"wfforward");
   }
   return(@l);
}


sub getWorkflowMailName
{
   my $self=shift;

   my $workflowname=$self->getParent->T($self->Self(),$self->Self());
   return($workflowname);
}


sub NotifyUsers
{
   my $self=shift;

}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/issue.jpg?".$cgi->query_string());
}


sub ValidatePostpone    #validate postpone operation
{
   my $self=shift;
   my $WfRec=shift;
   my $Postpone=shift;
   my $dFromNow=shift;
   my $dFromStart=shift;

   my $cdate=$WfRec->{createdate};
   my $d1=CalcDateDuration($cdate,NowStamp("en"));

   if ($d1->{totaldays}>182){
      $self->LastMsg(ERROR,
        "DataIssue postpone not allowed starting from 6 months after creation");
      return(0);
   }
   if ($dFromNow->{totaldays}>8*7){
      $self->LastMsg(ERROR,
          "DataIssue postpone allowed only for max 8 weeks");
      return(0);
   }
   #msg(INFO,"ValidatePostpone in DataIssue d1=".Dumper($d1));
   #msg(INFO,"ValidatePostpone in DataIssue Postpone=$Postpone");
   #msg(INFO,"ValidatePostpone in DataIssue dFromNow=".Dumper($dFromNow));
   #msg(INFO,"ValidatePostpone in DataIssue dFromStart=".Dumper($dFromStart));

   my $stdRes=$self->SUPER::ValidatePostpone(
      $WfRec,$Postpone,$dFromNow,$dFromStart
   );
   return(0) if (!$stdRes);

   return(1);
}



#######################################################################
package base::workflow::DataIssue::dataload;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width="100%">
<tr>
<td class=fname width=20%>%affectedobject(label)%:</td>
<td class=finput>%affectedobject(detail)%</td>
</tr>
<tr>
<td class=fname width=20%>%dataissueobjectname(label)%:</td>
<td class=finput>%dataissueobjectname(detail)%</td>
</tr>
<tr>
<td class=fname width=20%>%name(label)%:</td>
<td class=finput>%name(detail)%</td>
</tr>
<tr>
<td class=fname valign=top width=20%>detailierte Beschreibung<br>des Datenproblems:</td>
<td class=finput>%detaildescription(detail)%</td>
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
   #printf STDERR ("fifi Validate $self\n");

#  nativ needed
#   - name
#   - detaildescription
#   - affectedobject
#   - affectedobjectid
#

   my $issuesrc=effVal($oldrec,$newrec,"DATAISSUEOPERATIONSRC");
   $newrec->{DATAISSUEOPERATIONSRC}="manual" if ($issuesrc eq "");
                                             # if src is "qualitycheck" there
                                             # is no need to inform the creator
                                             # on finish

   # requested from Quality Check
#   $newrec->{DATAISSUEOPERATIONOBJ}="itil::appl";
#   $newrec->{DATAISSUEOPERATIONMOD}="update";
#   $newrec->{DATAISSUEOPERATIONFLD}="name,xx";
#   $newrec->{headref}={name=>'hans',
#                       xx=>'wert von xx'};



   #$newrec->{name}="Kundenpriorität ist nicht korrekt eingetragen";
   #$newrec->{detaildescription}="xxo";

   foreach my $v (qw(name detaildescription)){
      if ((!defined($oldrec) || exists($newrec->{$v})) && $newrec->{$v} eq ""){
         $self->LastMsg(ERROR,"field '%s' is empty",
                        $self->getField($v)->Label());
         return(0);
      }
   }
   $newrec->{stateid}=2 if (!defined(effVal($oldrec,$newrec,"cistatusid")));

   $newrec->{affectedobject}=effVal($oldrec,$newrec,"affectedobject");
   $newrec->{affectedobjectid}=effVal($oldrec,$newrec,"affectedobjectid");
   $newrec->{step}=$self->getNextStep();
   if (!$self->getParent->DataIssueCompleteWriteRequest($oldrec,$newrec)){
      my $msg="can't complete Write Request - ".
              "DataIssueCompleteWriteRequest false";
      if ($W5V2::OperationContext eq "QualityCheck"){
         $self->LastMsg(INFO,$msg);
      }
      else{
         $self->LastMsg(ERROR,$msg);
      }
      return(undef);
   }


   # Validate, if target is an allowed target (f.e. extern is not allowed
   # and will be rerouted to admin)
   my $target=effVal($oldrec,$newrec,"fwdtarget");
   if ($target eq "base::user"){
      if ( !defined($oldrec) || effChanged($oldrec,$newrec,"fwdtargetid")){
         my $userid=effVal($oldrec,$newrec,"fwdtargetid");
         my $u=getModuleObject($self->getParent->Config(),"base::user");
         $u->SetFilter({userid=>\$userid});
         my ($urec,$msg)=$u->getOnlyFirst(qw(cistatusid usertyp));
         if (!defined($urec) || (
              $urec->{usertyp} ne "user" && 
              $urec->{usertyp} ne "service"  &&
              $urec->{usertyp} ne "function"
             ) || $urec->{cistatusid} ne "4"){
            $newrec->{fwdtargetid}="1";
            $newrec->{fwdtarget}="base::grp";
         }
      }
   }

   return(1);
}


sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      my $fo=$self->getField("dataissueobjectname");
      my $foval=Query->Param("Formated_".$fo->Name());
      if ($foval=~m/^\s*$/){
         $self->LastMsg(ERROR,"no object specified");
         return(0);
      }
      my $obj;
      if (!($obj=$fo->Validate($WfRec,{$fo->Name=>$foval}))){
         $self->LastMsg(ERROR,"unknown error") if (!$self->LastMsg());
         return(0);
      }

      my $h=$self->getWriteRequestHash("web");
      $h->{eventstart}=NowStamp("en");
      $h->{eventend}=undef;
      $h->{DATAISSUEOPERATIONSRC}="manual";
      if (my $id=$self->StoreRecord($WfRec,$h)){
         $h->{id}=$id;
      }
      else{
         return(0);
      }
      return(1);
   }

   return($self->SUPER::Process($action,$WfRec,$actions));
}



sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("100%");
}


#######################################################################
package base::workflow::DataIssue::main;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

#sub generateWorkspace
#{
#   my $self=shift;
#   my $WfRec=shift;
#   my $actions=shift;
#
#   my $divset="";
#   my $selopt="";
#
#   return("") if ($#{$actions}==-1);
#   $self->generateWorkspacePages($WfRec,$actions,\$divset,\$selopt);   
#   my $oldop=Query->Param("OP");
#   my $templ;
#   my $pa=$self->getParent->T("possible action");
#   $templ=<<EOF;
#<table width="100%" height=148 border=0 cellspacing=0 cellpadding=0>
#<tr height=1%><td width=1% nowrap>$pa &nbsp;</td>
#<td><select id=OP name=OP style="width:100%">$selopt</select></td></tr>
#<tr><td colspan=3 valign=top>$divset</td></tr>
#</table>
#<script language="JavaScript">
#function fineSwitch(s)
#{
#   var sa=document.forms[0].elements['SaveStep'];
#   if (s.value=="nop"){
#      if (sa){
#         sa.disabled=true;
#      }
#   }
#   else{
#      if (sa){
#         sa.disabled=false;
#      }
#   }
#}
#function InitDivs()
#{
#   var s=document.getElementById("OP");
#   divSwitcher(s,"$oldop",fineSwitch);
#}
#addEvent(window,"load",InitDivs);
#//InitDivs();
#//window.setTimeout(InitDivs,1000);   // ensure to disable button (mozilla bug)
#</script>
#EOF
#
#   return($templ);
#}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (defined($newrec->{stateid}) &&
       $newrec->{stateid}==21 ||
       $newrec->{stateid}==25){
      my $note="";
      if (defined($newrec->{note})){
         $note=$newrec->{note};
         delete($newrec->{note});
      }
      if ($self->getParent->getParent->Action->StoreRecord(
          $oldrec->{id},"wfobsolete",
          {translation=>'base::workflow::DataIssue'},$note,undef)){
         $newrec->{step}="base::workflow::DataIssue::finish";
         $newrec->{eventend}=$self->getParent->ExpandTimeExpression("now",
                                                                  "en","GMT");;
         $newrec->{closedate}=$self->getParent->ExpandTimeExpression("now",
                                                                  "en","GMT");;
         return(1);
      }
      return(0);
   }
   elsif (defined($newrec->{stateid}) &&
       $newrec->{stateid}==22){
       $newrec->{eventend}=$self->getParent->ExpandTimeExpression("now",
                                                                "en","GMT");;
       $newrec->{closedate}=$self->getParent->ExpandTimeExpression("now",
                                                                "en","GMT");;
   }
   else{
      if (!$self->getParent->DataIssueCompleteWriteRequest($oldrec,$newrec)){
         $self->LastMsg(ERROR,"can't complete Write Request");
         return(undef);
      }
   }

   return(1);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   
   if ($action eq "BreakWorkflow"){
      if ($action ne "" && !grep(/^wfbreak$/,@{$actions})){
         $self->LastMsg(ERROR,"invalid disalloed action requested");
         return(0);
      }
      my $oprec={};
      $oprec->{stateid}=22;
      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"wfbreak",
          {translation=>'base::workflow::request'},undef,undef)){
         $self->StoreRecord($WfRec,$oprec);
         $self->PostProcess($action,$WfRec,$actions);
         Query->Delete("note");
         return(1);
      }
   }
   elsif ($action eq "SaveStep"){
      my $op=Query->Param("OP");
      if ($action ne "" && !grep(/^$op$/,@{$actions})){
         $self->LastMsg(ERROR,"invalid disalloed action requested");
         return(0);
      }
      if ($op eq "wfaddlnote"){
         my $note=Query->Param("note");
         my $h={
            note=>$note
         };
         return($self->nativProcess($op,$h,$WfRec,$actions));
      }
      if ($op eq "wfdifine"){
         my $app=$self->getParent->getParent;
         my $note=Query->Param("note");
         $note=trim($note);
         my $oprec={};
         $oprec->{postponeduntil}=undef;
         if ($WfRec->{openuser} eq ""){
            $oprec->{stateid}=21;
            $oprec->{step}='base::workflow::DataIssue::finish';
            $oprec->{fwdtarget}=undef;
            $oprec->{fwdtargetid}=undef;
         }
         else{
            $oprec->{stateid}=16;
            $oprec->{fwdtarget}='base::user';
            $oprec->{fwdtargetid}=$WfRec->{openuser};
            $oprec->{eventend}=$self->getParent->ExpandTimeExpression("now",
                                                                 "en","GMT");;
         }
         if ($app->Action->StoreRecord($WfRec->{id},"wffine",
             {translation=>'base::workflow::DataIssue'},$note)){
            $self->StoreRecord($WfRec,$oprec);
            $self->PostProcess($action.".".$op,$WfRec,$actions);
            Query->Delete("note");
            return(1);
         }
         return(0);
      }
      if ($op eq "wffine"){
         my $app=$self->getParent->getParent;
         my $note=Query->Param("note");
         $note=trim($note);
         my $oprec={};
         $oprec->{postponeduntil}=undef;
         $oprec->{stateid}=21;
         $oprec->{step}='base::workflow::DataIssue::finish';
         $oprec->{fwdtarget}=undef;
         $oprec->{fwdtargetid}=undef;
         if ($app->Action->StoreRecord($WfRec->{id},"wffinish",
             {translation=>'base::workflow::DataIssue'},$note)){
            $self->StoreRecord($WfRec,$oprec);
            $self->PostProcess($action.".".$op,$WfRec,$actions);
            Query->Delete("note");
            return(1);
         }
         return(0);
      }
      if ($op eq "wfdireproc"){
         my $app=$self->getParent->getParent;
         my $note=Query->Param("note");
         $note=trim($note);
         my $oprec={};
         $oprec->{postponeduntil}=undef;
         $oprec->{eventend}=undef;
         $oprec->{stateid}=2;
         $oprec->{step}='base::workflow::DataIssue::main';
         $oprec->{affectedobject}=effVal($WfRec,$oprec,"affectedobject");
         $oprec->{affectedobjectid}=effVal($WfRec,$oprec,"affectedobjectid");
         if (!$self->getParent->DataIssueCompleteWriteRequest(undef,$oprec)){
            $self->LastMsg(ERROR,"can't complete Write Request");
            return(undef);
         }
         if ($app->Action->StoreRecord($WfRec->{id},"wfdireproc",
             {translation=>'base::workflow::DataIssue'},$note)){
            $self->StoreRecord($WfRec,$oprec);
            $self->PostProcess($action.".".$op,$WfRec,$actions);
            Query->Delete("note");
            return(1);
         }
         return(0);
      }
   }
   return($self->SUPER::Process($action,$WfRec,$actions));
}

sub PostProcess
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;
   my %param=@_;
   my $aobj=$self->getParent->getParent->Action();
   my $workflowname=$self->getParent->getWorkflowMailName();

   if ($action eq "SaveStep.wfforward"){
      $aobj->NotifyForward($WfRec->{id},
                           $param{fwdtarget},
                           $param{fwdtargetid},
                           $param{fwdtargetname},
                           $param{note},
                           workflowname=>$workflowname,
                           sendercc=>1);
   }
   if ($action eq "addWfAction.wfmailsend"){
      if (defined($WfRec) && ($WfRec->{id}=~m/^\d{3,20}$/)){
         $self->getParent->getParent->ValidatedUpdateRecord($WfRec,{
            mdate=>NowStamp("en")
         },{id=>\$WfRec->{id}});
      }
   }
   if ($action=~m/^SaveStep\..*$/){
      Query->Delete("WorkflowStep");
      Query->Delete("note");
      Query->Delete("Formated_note");
      Query->Delete("Formated_effort");
   }

}



sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my @saveables=grep(!/^wfbreak$/,@$actions);
   return(0)  if ($#{$actions}==-1);
   return(20) if ($#saveables==-1);
   return(180);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my @WorkflowStep=Query->Param("WorkflowStep");
   my %b=();
   my @saveables=grep(!/^wfbreak$/,@$actions);
   if ($#saveables!=-1){
      %b=(SaveStep=>$self->T('Save')) if ($#{$actions}!=-1);
   }
   if (defined($WfRec->{id})){
      if (grep(/^wfbreak$/,@$actions)){
         $b{BreakWorkflow}=$self->T('abbort request');
      }
   }
   return(%b);
}  


sub generateWorkspacePages
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $divset=shift;
   my $selopt=shift;
   my $tr="base::workflow::actions";
   my $class="display:none;visibility:hidden";

#   if (grep(/^nop$/,@$actions)){
#      $$selopt.="<option value=\"nop\" class=\"$class\">".
#                $self->getParent->T("nop",$tr).
#                "</option>\n";
#      $$divset.="<div id=OPnop style=\"margin:15px\"><br>".
#                $self->getParent->T("The current workflow isn't forwared ".
#                "to you. At now there is no action nessasary.",$tr)."</div>";
#   }
   if (grep(/^wffine$/,@$actions)){
      $$selopt.="<option value=\"wffine\" class=\"$class\">".
                $self->getParent->T("wffine",$tr).
                "</option>\n";
      $$divset.="<div id=OPwffine>".
                "</div>";
   }
   if (grep(/^wfdifine$/,@$actions)){
      $$selopt.="<option value=\"wfdifine\" class=\"$class\">".
                $self->getParent->T("wfdifine",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfdifine>".$self->getDefaultNoteDiv($WfRec,$actions).
                "</div>";
   }
   if (grep(/^wfdireproc$/,@$actions)){
      $$selopt.="<option value=\"wfdireproc\" class=\"$class\">".
                $self->getParent->T("wfdireproc",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfdireproc>".$self->getDefaultNoteDiv($WfRec,$actions).
                "</div>";
   }
   $self->SUPER::generateWorkspacePages($WfRec,$actions,
                                               $divset,$selopt);
   return("wfaddlnote");
}



#######################################################################
package base::workflow::DataIssue::finish;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if ($newrec->{stateid}==21){
      $newrec->{eventend}=$self->getParent->ExpandTimeExpression("now",
                                                                 "en","GMT");;
      $newrec->{closedate}=$self->getParent->ExpandTimeExpression("now",
                                                               "en","GMT");;
      return(1);
   }
   return(0);
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("0");
}


1;
