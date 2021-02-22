package TS::workflow::change;
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
use tssm::lib::io qw(identifyW5UserFromGroup);

@ISA=qw(itil::workflow::change );

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
   my @l=();

   return($self->SUPER::getDynamicFields(%param),
          $self->InitFields(
           new kernel::Field::Date(
                     name          =>'approvalphaseentry',
                     label         =>'date approval phase entered',
                     htmldetail    =>0,
                     container     =>'headref')));
}


sub addSRCLinkToFacility
{
   my $self=shift;
   my $d=shift;
   my $current=shift;

   if ($d ne ""){
      if (defined($current->{srcsys}) &&
          $current->{srcsys} eq "tssm::event::smchange"){
         return("tssm::chm",['srcid'=>'changenumber']);
      }
   }
   return($self->SUPER::addSRCLinkToFacility($d,$current));

}


sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;

   my @l=$self->SUPER::getPosibleActions($WfRec);

   return(@l) if (!defined($WfRec->{affectedapplicationid}));

   my $isChmgr=$self->isChangeManager($WfRec);
   my $phase=$WfRec->{additional}{ServiceManagerPhase}[0];

   if ($phase=~m/^30/ && $self->notifyValid($WfRec,'confirm')) {
      my $state=$self->getNotifyConfirmState();
      my $smtask=getModuleObject($self->Config,'tssm::chmtask');
      $smtask->SetFilter({changenumber=>\$WfRec->{srcid},
                          status=>["$state"]});
      my ($rec,$msg)=$smtask->getOnlyFirst(qw(ALL));

      push(@l,'chmnotifyconfirm') if (defined($rec));
   }

   return(@l) if (!$isChmgr);

   if ($phase=~m/^40/) {
      my $approvalstate=$WfRec->{additional}{ServiceManagerApprovalState}[0];
      my $chmmgr=$self->chmAuthority($WfRec);

      my @notifies=grep({$_->{name} eq 'sendchangeinfo' &&
                         $_->{comments}=~/^Approval request sent/}
                         @{$WfRec->{shortactionlog}});

      if ($#notifies==-1) {
         if (($approvalstate eq 'pending' ||
              $approvalstate eq 'denied') && $chmmgr eq 'TIT') {
            push(@l,'chmnotifyapprove');
         }
      }
      else {
         if (($approvalstate eq 'pending' ||
              $approvalstate eq 'denied')) {
            @notifies=grep({$_->{name} eq 'sendchangeinfo' &&
                            ($_->{comments}=~/^Approval request sent/   ||
                             $_->{comments}=~/^Approval reminder sent$/ ||
                             $_->{comments}=~/^Rescheduled info sent$/)}
                            @{$WfRec->{shortactionlog}});

            if ($#notifies!=-1) {
               my $rescheduledata;
               my $lastnotify=$notifies[-1];
               my $wfa=getModuleObject($self->Config,"base::workflowaction");
               $wfa->ResetFilter();
               $wfa->SetFilter({id=>\$lastnotify->{id}});
               my ($act,$msg)=$wfa->getOnlyFirst(qw(actionref));

               if (ref($act->{actionref}) eq "HASH") {
                  $rescheduledata=$act->{actionref}{rescheduledata}[0];
               }

               if ($lastnotify->{cdate} < $WfRec->{approvalphaseentry} ||
                   (defined($rescheduledata) &&
                    $rescheduledata ne $WfRec->{rescheduledatahash})) {
                  push(@l,'chmnotifyreschedule');
               }
               else {
                  push(@l,'chmnotifyremind')
               }
            }
         }
      }

      if ($chmmgr ne 'TIT') {
         push(@l,qw(chmnotifyapproveall
                    chmnotifyapprovecritical
                    chmnotifyapprovedirect));
      }
   }

   push(@l,qw(chmnotifyrejectdirect
              chmnotifyrejectcritical
              chmnotifyrejectall));

   return(@l);
}


sub activateMailSend
{
   my $self=shift;
   my $WfRec=shift;
   my $wf=shift;
   my $id=shift;
   my $newmailrec=shift;
   my $action=shift;

   my %d=(step=>'base::workflow::mailsend::waitforspool');
   if (Query->Param('NotifyMode') ne 'announce') {
      $d{emailsignatur}='ChangeNotification: Telekom IT';
   }
   $self->linkMail($WfRec->{id},$id);
   if (my $r=$wf->Store($id,%d)){
      return(1);
   }
   return(0);
}


sub getNextStep
{
   my $self=shift;
   my $currentstep=shift;
   my $WfRec=shift;

   if ($currentstep=~m/::extauthority$/) {
      if ($self->isChangeManager($WfRec)) {
         return($self->getStepByShortname('individualnote',$WfRec));
      }
      else {
         return($self->getStepByShortname('publishpreview',$WfRec));
      }
   }
   if ($currentstep=~m/::individualnote$/) {
      return($self->getStepByShortname('publishpreview',$WfRec));
   }

   return($self->SUPER::getNextStep($currentstep,$WfRec));
}


sub getStepByShortname
{
   my $self=shift;
   my $name=shift;
   my $WfRec=shift;

   if (($name eq 'individualnote') ||
       ($name eq 'publishpreview')) {
      return("TS::workflow::change::".$name);
   }

   return($self->SUPER::getStepByShortname($name,$WfRec));
}


sub getNotifyDestinations
{
   my $self=shift;
   my $mode=shift;    # direct|critical|all|approve|confirm
   my $WfRec=shift;
   my $emailto=shift;
   my $emailcc=shift;
   my $ifappl=shift;

   if ($mode eq 'direct' || $mode eq 'critical' || $mode eq 'all') {
      $self->SUPER::getNotifyDestinations($mode,$WfRec,$emailto,$emailcc,$ifappl);
 
      my $ia=getModuleObject($self->Config,"base::infoabo");
      my $applid=$WfRec->{affectedapplicationid};
      $applid=[$applid] if (ref($applid) ne "ARRAY");

      my $appl=getModuleObject($self->Config,"itil::appl");
      my @tobyfunc;
      $appl->ResetFilter();
      $appl->SetFilter({id=>$applid});
      my @fl=qw(applmgrid);
      foreach my $rec ($appl->getHashList(@fl)){
         push(@tobyfunc,$rec->{applmgrid})  if ($rec->{applmgrid}>0);
      }

      if (ref($ifappl) eq 'HASH'){
         my @ifid=keys(%$ifappl);
         if ($#ifid!=-1) {
            $appl->ResetFilter();
            $appl->SetFilter({id=>\@ifid,cistatusid=>"<=4"});
            foreach my $rec ($appl->getHashList(@fl)){
               push(@tobyfunc,$rec->{applmgrid}) if ($rec->{applmgrid}>0);
            }
         }
      }

      $ia->LoadTargets($emailto,'base::staticinfoabo',\'STEVchangeinfobyfunction',
                             '100000004',\@tobyfunc,default=>1);
#printf STDERR ("fifi to=%s req=%s\n",Dumper($emailto),Dumper(\@tobyfunc));
#printf STDERR ("fifi cc=%s req=%s\n",Dumper($emailcc),Dumper(\@ccbyfunc));
   }

   if ($mode eq 'confirm') {
      my $state=$self->getNotifyConfirmState();
      my @infogrps=$self->getImplementorGrp($WfRec,'"'.$state.'"');

      if ($self->chmAuthority($WfRec) ne 'TIT') {
         # only TelIT-Implementer will be informed about non-TelIT changes
         @infogrps=grep(/^TIT\./,@infogrps);
      }
      return(undef) if ($#infogrps==-1);

      my @appmail=$self->getNotifyDestinationsFromSMGroups(\@infogrps);

      foreach my $email (@appmail) {
         $emailto->{$email}=[] if (!exists($emailto->{$email}));
      }
   }

   if ($mode eq 'approve') {
      my $appgrps=$self->getApproverGrp($WfRec,'pending');
      return(undef) if ($#{$appgrps}==-1 || ref($appgrps) ne 'ARRAY');

      # groups from CHM TelIT must not be informed
      my @infogrps=grep(!/^TIT\..*\.CHM/,@$appgrps);

      if ($self->chmAuthority($WfRec) ne 'TIT') {
         # only TelIT-Approver will be informed about non-TelIT changes
         @infogrps=grep(/^TIT\./,@infogrps);
      }
      return(undef) if ($#infogrps==-1);

      my @appmail=$self->getNotifyDestinationsFromSMGroups(\@infogrps);

      foreach my $email (@appmail) {
         $emailto->{$email}=[] if (!exists($emailto->{$email}));
      }
   }
  
   return(undef);
}


sub notifyValid
{
   my $self=shift;
   my $WfRec=shift;
   my $mode=shift;

   my $phase=$WfRec->{additional}{ServiceManagerPhase}[0];

   if ($phase=~m/^40/ && ($mode eq 'all')) {
      return(1) if ($self->isChangeManager($WfRec));
   }
   if ($phase=~m/^30/ &&
       ($mode eq 'all' || $mode eq 'confirm')) {
      return(1) if ($self->isChangeManager($WfRec));

      my $userid=$self->getParent->getCurrentUserId();
      return(0) if (!$userid);

      my $smchm=getModuleObject($self->Config,'tssm::chm');
      $smchm->SetFilter({changenumber=>\$WfRec->{srcid}});
      my ($rec,$msg)=$smchm->getOnlyFirst(qw(coordinatorgrp));

      my $operator=$self->identifyW5UserFromGroup($rec->{coordinatorgrp});

      if ($operator==-1) {
         $self->LastMsg(ERROR,"Connection to SM9 failed");
         return(0);
      }

      return(1) if (in_array($operator,$userid));
   }

   return(0);
}


sub chmAuthority
{
   my $self=shift;
   my $WfRec=shift;

   if ($WfRec->{additional}{ServiceManagerChmMgr}[0]=~m/^TIT\./) {
      return('TIT');
   }

   return(undef);
}


sub formatTwoColumns
{
   my $self=shift;
   my $data=shift;
   my $width=shift;
   my $ret='';

   my @col1=sort(@$data);
   my @col2=splice(@col1,abs(@col1/2)+(@col1%2));

   for (my $i;$i<=$#col1;$i++) {
      $ret.=sprintf("%-${width}s",$col1[$i]);
      $ret.=$col2[$i] if ($i<=$#col2);
      $ret.="\n";
   }

   return($ret);
}


sub formatTaskList
{
   my $self=shift;
   my $l=shift;

   my $tobj=getModuleObject($self->Config,'tssm::chmtask');
   my %colnames;
   my $ret;

   foreach my $fname (keys(%{$l->[0]})) {
      $colnames{$fname}=$self->T($tobj->getField($fname)->label(),
                                 'tssm::chmtask');
   }

   $ret=sprintf("%-14s %s\n",$colnames{tasknumber},
                             $colnames{assignedto});
   $ret.="-"x45;
   $ret.="\n";

   foreach my $task (@$l) {
      $ret.=sprintf("%-14s %s\n",$task->{tasknumber},
                                 $task->{assignedto});
   }

   return($ret);
}


sub getPSO
{
   my $self=shift;
   my $WfRec=shift;

   my $tz='GMT';
   $tz=$ENV{HTTP_FORCE_TZ} if (defined($ENV{HTTP_FORCE_TZ}));

   my $oldlang;
   if (defined($ENV{HTTP_FORCE_LANGUAGE})) {
      $oldlang=$ENV{HTTP_FORCE_LANGUAGE};
   }

   my $obj=getModuleObject($self->Config,'tssm::chm_pso');
   $obj->SetFilter({changenumber=>\$WfRec->{srcid}});
   my @psolist=$obj->getHashList(qw(plannedstart plannedend applname));

   return(0) if (!$obj->Ping);

   my %ret;
   my $fo=$obj->getField('plannedstart');

   my $tztxt;
   foreach my $lang (qw(de en)) {
      my @pso;
      foreach my $i (0..$#psolist) {
         $ENV{HTTP_FORCE_LANGUAGE}=$lang;
         my ($start)=$fo->getFrontendTimeString('HtmlDetail',
                             $psolist[$i]->{plannedstart},$tz);
         (my $end,$tztxt)=$fo->getFrontendTimeString('HtmlDetail',
                                  $psolist[$i]->{plannedend},$tz);
         my $appl=$psolist[$i]->{applname};

         $start=~s/:\d\d$//;  # cut seconds
         $end  =~s/:\d\d$//;
         $appl =~s/\s(.*)$//; # cut ApplID

         push(@pso,{plannedstart=>$start,plannedend=>$end,applname=>$appl});
      }
      @pso=sort {$a->{applname} cmp $b->{applname}} @pso;
      $ret{$lang}=\@pso;
   }

   $ret{tz}=$tztxt;

   if (defined($oldlang)) {
      $ENV{HTTP_FORCE_LANGUAGE}=$oldlang;
   }
   else {
      delete($ENV{HTTP_FORCE_LANGUAGE});
   }

   return(\%ret);
}


sub getApproverGrp
{
   my $self=shift;
   my $WfRec=shift;
   my $flt=shift; # done|pending|all
   my %groups;

   $flt='all' if (!defined($flt));

   my @mod;
   push(@mod,'tssm::chm_approvereq')  if ($flt eq 'pending' || $flt eq 'all');
   push(@mod,'tssm::chm_approvallog') if ($flt eq 'done'    || $flt eq 'all');

   foreach my $m (@mod) {
      my $obj=getModuleObject($self->Config,$m);
      $obj->SetFilter({changenumber=>\$WfRec->{srcid}});

      foreach my $grp (@{$obj->getHashList('name')}) {
         $groups{$grp->{name}}++ if (defined($grp->{name}));
      }
      return(0) if (!$obj->Ping);
   }

   my @grplist=keys(%groups);
   return(\@grplist);
}


sub getImplementorGrp
{
   my $self=shift;
   my $WfRec=shift;
   my $taskstate=shift;

   $taskstate='*' if (!defined($taskstate));
   my %groups;

   my $obj=getModuleObject($self->Config,'tssm::chmtask');
   $obj->SetFilter({changenumber=>\$WfRec->{srcid},
                    status=>$taskstate});
   my %implgrps=map {$_->{assignedto}=>1}
                    $obj->getHashList(qw(assignedto));

   return(keys(%implgrps));
}


sub getNotifyConfirmState
{
   my $self=shift;

   return('Review by Implementor');
}


sub getNotifyDestinationsFromSMGroups
{
   my $self=shift;
   my $smgroups=shift;

   my $lnkobj=getModuleObject($self->Config,'tssm::lnkusergroup');
   my $userobj=getModuleObject($self->Config,'tssm::useraccount');

   return(0) if (ref($smgroups ne 'ARRAY') || $#{$smgroups}==-1);
   return(0) if (!$lnkobj->Ping);

   $lnkobj->SetFilter({lgroup=>$smgroups});
   my @grpuser=map {$_->{luser}} @{$lnkobj->getHashList('luser')};
   $userobj->SetFilter({id=>\@grpuser,profile_change=>'![empty]'});
   my %mailaddress=map {$_=>1}
                       grep(/^\S+\@\S+\.\S+$/,
                        map {$_->{email}} $userobj->getHashList('email'));

   return(keys(%mailaddress));
}


sub generateMailSet
{
   my $self=shift;
   my ($WfRec,$additional,$emailprefix,$emailpostfix,
       $emailtext,$emailsep,$emaillang,$emailsubheader)=@_;
   my @emailprefix=();
   my @emailpostfix=();
   my @emailtext=();
   my @emailsep=();
   my @emailsubheader=();

   @emailprefix=@$emailprefix       if (ref($emailprefix) eq "ARRAY");
   @emailpostfix=@$emailpostfix     if (ref($emailpostfix) eq "ARRAY");
   @emailtext=@$emailtext           if (ref($emailtext) eq "ARRAY");
   @emailsep=@$emailsep             if (ref($emailsep) eq "ARRAY");
   @emailsubheader=@$emailsubheader if (ref($emailsubheader) eq "ARRAY");

   my $baseurl;
   if ($ENV{SCRIPT_URI} ne ""){
      $baseurl=$ENV{SCRIPT_URI};
      $baseurl=~s|/auth/.*$||;
   }

   # order of Textblocks
   my @blocks=(qw(chgnr name start end pso chminfo description appl));

   $ENV{HTTP_FORCE_TZ}='CET';
   my %d;
   my $notifymode=Query->Param('NotifyMode');
   my $publishmode=Query->Param('PublishMode');
   my $pso=$self->getPSO($WfRec);

   foreach my $lang (qw(de en)) {
      $ENV{HTTP_FORCE_LANGUAGE}=$lang;
      push(@$emaillang,$lang);

      ## change
      $d{$lang}{chgnr}{prefix}=$self->getParent->T("Changenumber",
                                                   "itil::workflow::change");
      $d{$lang}{chgnr}{txt}=$WfRec->{srcid}.
                            "\n$baseurl/auth/base/workflow/ById/$WfRec->{id}";
      if ($baseurl ne "") {
         my $imgtitle=$self->getParent->T("current state of workflow",
                                          "base::workflow");
         my $ilang="?HTTP_ACCEPT_LANGUAGE=$lang";
         $d{$lang}{chgnr}{postfix}=
            "<img title=\"$imgtitle\" class=status border=0 ".
                 "src=\"$baseurl/public/base/workflow/ShowState/".
                       "$WfRec->{id}$ilang\">";
      }
      $d{$lang}{chgnr}{sep}="<a name=\"lang.$lang\"></a>" if ($lang eq 'en');

      ## title
      my $name=$self->getField('name',$WfRec);
      $d{$lang}{name}{prefix}=$self->T('Title');
      $d{$lang}{name}{txt}=$name->FormatedResult($WfRec,'HtmlMail');

      ## start / end
      my $cs=$self->getField('changestart',$WfRec);
      my $ce=$self->getField('changeend',$WfRec);
      $d{$lang}{start}{prefix}=$cs->Label();
      $d{$lang}{start}{txt}=$cs->FormatedResult($WfRec,'HtmlMail');
      $d{$lang}{end}{prefix}=$ce->Label();
      $d{$lang}{end}{txt}=$ce->FormatedResult($WfRec,'HtmlMail');

      ## PSO
      if ($notifymode ne 'reject') {
         $d{$lang}{pso}{prefix}=$self->getParent->T("fieldgroup.downtimesum",
                                                    "tssm::chm_pso");
         if (ref($pso) ne 'HASH') {
            $d{$lang}{pso}{txt}='???';
         }
         elsif ($#{$pso->{$lang}}==-1) {
            $d{$lang}{pso}{txt}=$self->T('No planned service outage documented');
         }
         else {
            my $psotxt=$self->T('All time data in timezone')." $pso->{tz}\n";
            foreach my $p (@{$pso->{$lang}}) {
               $psotxt.="$p->{plannedstart}&nbsp;-&nbsp;$p->{plannedend}";
               $psotxt.="&nbsp;$p->{applname}\n";
            }
            $d{$lang}{pso}{txt}=$psotxt;
         }
      }
      else {
         @blocks=grep(!/^pso$/,@blocks);
      }

      ## Changemanager info block
      my $chminfo;
      my $authority=$self->chmAuthority($WfRec);

      my $submitfld=$self->getField('approvalphaseentry');
      my $submit=$submitfld->FormatedResult($WfRec,'HtmlMail');

      my $note;
      if (defined(Query->Param('note_'.$lang)) &&
          Query->Param('note_'.$lang) ne '') {
         $note="\n<b>".$self->T('Remarks').":</b>\n";
         $note.=Query->Param("note_".$lang);
         $note.="\n" if ($notifymode ne 'reject');
      }

      if ($notifymode eq 'announce') {
         my $pendinggrps=$self->getApproverGrp($WfRec,'pending');
         my $pendingtxt;

         if (ref($pendinggrps) ne 'ARRAY') {
            $pendingtxt='???';
         }
         elsif ($#{$pendinggrps}==-1) {
            $pendingtxt=$self->T('None')."\n";
         }
         else {
            # show groups in 2 columns
            $pendingtxt=$self->formatTwoColumns($pendinggrps,33);
         }

         $chminfo=$self->getParsedTemplate(
                     "tmpl/ext.changenotify.".
                      "$notifymode.$publishmode.TIT",
                     {skinbase=>'TS',
                      static=>{pending=>$pendingtxt,
                               note=>$note}
                     });
      }
      
      if ($notifymode eq 'confirm') {
         my $taskstate=$self->getNotifyConfirmState();
         my $tobj=getModuleObject($self->Config,'tssm::chmtask');
         $tobj->SetFilter({changenumber=>\$WfRec->{srcid},
                           status=>\$taskstate});
         my $taskdetails=$tobj->getHashList(qw(tasknumber assignedto));
         my $tasklist=$self->formatTaskList($taskdetails);

         $chminfo=$self->getParsedTemplate(
                     "tmpl/ext.changenotify.$notifymode.TIT",
                     {skinbase=>'TS',
                      static=>{taskstatus=>$taskstate,
                               tasklist=>$tasklist,
                               note=>$note}
                     });
      }
      
      if ($notifymode eq 'approve') {
         my $tmpl;
         my $pendingtxt;
         my $approvedtxt;
         my $pendinggrps=$self->getApproverGrp($WfRec,'pending');
         my $approvedgrps=$self->getApproverGrp($WfRec,'done');
         
         if (defined($authority)) {
            $tmpl="tmpl/ext.changenotify.$notifymode.$authority";
         }
         else {
            $tmpl="tmpl/ext.changenotify.$notifymode.$publishmode";
         }

         if (ref($pendinggrps) ne 'ARRAY') {
            $pendingtxt='???';
         }
         elsif ($#{$pendinggrps}==-1) {
            $pendingtxt=$self->T('None')."\n";
         }
         else {
            $pendingtxt=$self->formatTwoColumns($pendinggrps,33);
         }

         if (ref($approvedgrps) ne 'ARRAY') {
            $approvedtxt='???';
         }
         elsif ($#{$approvedgrps}==-1) {
            $approvedtxt=$self->T('None')."\n";
         }
         else {
            $approvedtxt=$self->formatTwoColumns($approvedgrps,33);
         }
         $chminfo=$self->getParsedTemplate(
                            $tmpl,
                            {skinbase=>'TS',
                             static=>{submit=>$submit,
                                      pending=>$pendingtxt,
                                      approved=>$approvedtxt,
                                      note=>$note}
                            });
      }

      if ($notifymode eq 'remind') {
         my $tmpl;
         my $pendingtxt;

         my $pendinggrps=$self->getApproverGrp($WfRec,'pending');
         if (ref($pendinggrps) ne 'ARRAY') {
            $pendingtxt='???';
         }
         elsif ($#{$pendinggrps}==-1) {
            $pendingtxt=$self->T('None')."\n";
         }
         else {
            $pendingtxt=$self->formatTwoColumns($pendinggrps,33);
         }

         my @log=grep {$_->{name} eq 'sendchangeinfo' &&
                       ($_->{comments}=~m/^Approval request sent/ ||
                        $_->{comments} eq 'Approval reminder sent'||
                        $_->{comments}=~m/^\d+\. notification$/)
                      } @{$WfRec->{shortactionlog}};
         my $obj=getModuleObject($self->Config,'base::workflowaction');
         my $fo=$obj->getField('cdate');

         my ($lastNotify)=$fo->getFrontendTimeString('HtmlDetail',
                                                     $log[-1]->{cdate},
                                                     $lang);
         $lastNotify=~s/\s+.*$//; # cut time, only date is desired

         my $remindCnt=grep {$_->{comments} eq 'Approval reminder sent'}
                            @log;

         if ($authority ne 'TIT' && $remindCnt==0) {
            $tmpl='tmpl/ext.changenotify.remind1st';
         }
         else {
            $tmpl="tmpl/ext.changenotify.$notifymode";
         }

         $chminfo=$self->getParsedTemplate(
                            $tmpl,
                            {skinbase=>'TS',
                             static=>{submit=>$submit,
                                      approverequest=>$lastNotify,
                                      pending=>$pendingtxt,
                                      note=>$note}
                            });
      }

      if ($notifymode eq 'reschedule') {
         my $pendinggrps=$self->getApproverGrp($WfRec,'pending');
         my $pendingtxt;

         if (ref($pendinggrps) ne 'ARRAY') {
            $pendingtxt='???';
         }
         elsif ($#{$pendinggrps}==-1) {
            $pendingtxt=$self->T('None')."\n";
         }
         else {
            $pendingtxt=$self->formatTwoColumns($pendinggrps,33);
         }

         $chminfo=$self->getParsedTemplate(
                            "tmpl/ext.changenotify.$notifymode",
                            {skinbase=>'TS',
                             static=>{submit=>$submit,
                                      pending=>$pendingtxt,
                                      note=>$note}
                            });
      }
      
      if ($notifymode eq 'reject') {
         $chminfo=$self->getParsedTemplate(
                            "tmpl/ext.changenotify.$notifymode",
                            {skinbase=>'TS',
                             static=>{note=>$note}
                            });
      }

      $d{$lang}{chminfo}{prefix}="Changemanager Info";
      $d{$lang}{chminfo}{txt}=$chminfo;

      ## description
      my $desc=$self->getField('changedescription',$WfRec);
      $d{$lang}{description}{prefix}=$desc->Label();
      $d{$lang}{description}{txt}=$desc->FormatedResult($WfRec,'HtmlMail');

      ## applications
      my $appl=$self->getField('affectedapplication',$WfRec);
      $d{$lang}{appl}{prefix}=$appl->Label();
      $d{$lang}{appl}{txt}=$appl->FormatedResult($WfRec,'HtmlMail');
   }

   delete($ENV{HTTP_FORCE_LANGUAGE});

   foreach my $lang (@$emaillang) {
      foreach my $line (@blocks) {
         push(@$emailprefix,  $d{$lang}{$line}{prefix});
         push(@$emailtext,    $d{$lang}{$line}{txt});
         push(@$emailpostfix, $d{$lang}{$line}{postfix});
         push(@$emailsep,     $d{$lang}{$line}{sep});
      }
   }
}

#######################################################################
package TS::workflow::change::extauthority;
use vars qw(@ISA);
use kernel;
@ISA=qw(itil::workflow::change::main);

sub generateWorkspacePages
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $divset=shift;
   my $selopt=shift;
   my $height=shift;
   my $class='display:none;visibility:hidden';
   my $d;

   $self->SUPER::generateWorkspacePages($WfRec,$actions,$divset,$selopt,$height);

   if (grep(/^chmnotifyconfirm$/,@$actions)) {
      $$selopt.='<option value="chmnotifyconfirm">'.
                    $self->T('notifyconfirm').
                "</option>\n";
      $d="<div class=Question><table border=0>".
           "<tr><td>".$self->T("helpnotifyconfirm")."</td></tr>".
          "</table></div>";
      $$divset.='<div id=OPchmnotifyconfirm '.
                     'data-visiblebuttons="NextStep"'.
                " class=\"$class\">$d</div>";
   }

   if (grep(/^chmnotifyapprove$/,@$actions)) {
      $$selopt.='<option value="chmnotifyapprove">'.
                    $self->T('notifyapprove').
                "</option>\n";
      $d="<div class=Question><table border=0>".
           "<tr><td>".$self->T("helpnotifyapprove")."</td></tr>".
          "</table></div>";
      $$divset.='<div id=OPchmnotifyapprove '.
                     'data-visiblebuttons="NextStep"'.
                " class=\"$class\">$d</div>";
   }

   if (grep(/^chmnotifyapproveall$/,@$actions)) {
      $$selopt.='<option value="chmnotifyapproveall">'.
                    $self->T('notifyapproveall').
                "</option>\n";
      $d="<div class=Question><table border=0>".
           "<tr><td>".$self->T("helpnotifyall")."</td></tr>".
          "</table></div>";
      $$divset.='<div id=OPchmnotifyapproveall '.
                     'data-visiblebuttons="NextStep"'.
                " class=\"$class\">$d</div>";
   }

   if (grep(/^chmnotifyapprovecritical$/,@$actions)) {
      $$selopt.='<option value="chmnotifyapprovecritical">'.
                    $self->T('notifyapprovecritical').
                "</option>\n";
      $d="<div class=Question><table border=0>".
           "<tr><td>".$self->T("helpnotifycritical")."</td></tr>".
          "</table></div>";
      $$divset.='<div id=OPchmnotifyapprovecritical '.
                     'data-visiblebuttons="NextStep"'.
                " class=\"$class\">$d</div>";
   }

   if (grep(/^chmnotifyapprovedirect$/,@$actions)) {
      $$selopt.='<option value="chmnotifyapprovedirect">'.
                    $self->T('notifyapprovedirect').
                "</option>\n";
      $d="<div class=Question><table border=0>".
           "<tr><td>".$self->T("helpnotifydirect")."</td></tr>".
          "</table></div>";
      $$divset.='<div id=OPchmnotifyapprovedirect '.
                     'data-visiblebuttons="NextStep"'.
                " class=\"$class\">$d</div>";
   }

   if (grep(/^chmnotifyremind$/,@$actions)) {
      $$selopt.='<option value="chmnotifyremind">'.
                    $self->T('notifyremind').
                "</option>\n";
      $d="<div class=Question><table border=0>".
           "<tr><td>".$self->T("helpnotifyremind")."</td></tr>".
          "</table></div>";
      $$divset.='<div id=OPchmnotifyremind '.
                     'data-visiblebuttons="NextStep"'.
                " class=\"$class\">$d</div>";
   }

   if (grep(/^chmnotifyreschedule$/,@$actions)) {
      $$selopt.='<option value="chmnotifyreschedule">'.
                    $self->T('notifyreschedule').
                "</option>\n";
      $d="<div class=Question><table border=0>".
           "<tr><td>".$self->T("helpnotifyapprove")."</td></tr>".
          "</table></div>";
      $$divset.='<div id=OPchmnotifyreschedule '.
                     'data-visiblebuttons="NextStep"'.
                " class=\"$class\">$d</div>";
   }

   if (grep(/^chmnotifyrejectall$/,@$actions)) {
      $$selopt.='<option value="chmnotifyrejectall">'.
                    $self->T('notifyrejectall').
                "</option>\n";
      $d="<div class=Question><table border=0>".
           "<tr><td>".$self->T("helpnotifyall")."</td></tr>".
          "</table></div>";
      $$divset.='<div id=OPchmnotifyrejectall'.
                ' data-visiblebuttons="NextStep"'.
                " class=\"$class\">$d</div>";
   }

   if (grep(/^chmnotifyrejectcritical$/,@$actions)) {
      $$selopt.='<option value="chmnotifyrejectcritical">'.
                    $self->T('notifyrejectcritical').
                "</option>\n";
      $d="<div class=Question><table border=0>".
           "<tr><td>".$self->T("helpnotifycritical")."</td></tr>".
          "</table></div>";
      $$divset.='<div id=OPchmnotifyrejectcritical'.
                ' data-visiblebuttons="NextStep"'.
                " class=\"$class\">$d</div>";
   }

   if (grep(/^chmnotifyrejectdirect$/,@$actions)) {
      $$selopt.='<option value="chmnotifyrejectdirect">'.
                    $self->T('notifyrejectdirect').
                "</option>\n";
      $d="<div class=Question><table border=0>".
           "<tr><td>".$self->T("helpnotifydirect")."</td></tr>".
          "</table></div>";
      $$divset.='<div id=OPchmnotifyrejectdirect'.
                ' data-visiblebuttons="NextStep"'.
                " class=\"$class\">$d</div>";
   }
}


sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my %b=$self->SUPER::getPosibleButtons($WfRec,$actions);

   return(%b);
}


sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $op=Query->Param('OP');

   if ($action eq "NextStep" && defined($WfRec)) {
      if ($op eq "chmnotifyall") {
         Query->Param("PublishMode"=>"all");
         Query->Param("NotifyMode" =>"announce");
      }
      if ($op eq "chmnotifycritical") {
         Query->Param("PublishMode"=>"critical");
         Query->Param("NotifyMode" =>"announce");
      }
      if ($op eq "chmnotifydirect") {
         Query->Param("PublishMode"=>"direct");
         Query->Param("NotifyMode" =>"announce");
      }
      if ($op eq "chmnotifyconfirm") {
         Query->Param("PublishMode"=>"confirm");
         Query->Param("NotifyMode" =>"confirm");
      }
      if ($op eq "chmnotifyapprove") {
         Query->Param("PublishMode"=>"approve");
         Query->Param("NotifyMode" =>"approve");
      }
      if ($op eq "chmnotifyapproveall") {
         Query->Param("PublishMode"=>"all");
         Query->Param("NotifyMode" =>"approve");
      }
      if ($op eq "chmnotifyapprovecritical") {
         Query->Param("PublishMode"=>"critical");
         Query->Param("NotifyMode" =>"approve");
      }
      if ($op eq "chmnotifyapprovedirect") {
         Query->Param("PublishMode"=>"direct");
         Query->Param("NotifyMode" =>"approve");
      }
      if ($op eq "chmnotifyremind") {
         Query->Param("PublishMode"=>"approve");
         Query->Param("NotifyMode" =>"remind");
      }
      if ($op eq "chmnotifyreschedule") {
         Query->Param("PublishMode"=>"approve");
         Query->Param("NotifyMode" =>"reschedule");
      }
      if ($op eq "chmnotifyrejectall") {
         Query->Param("PublishMode"=>"all");
         Query->Param("NotifyMode" =>"reject");
      }
      if ($op eq "chmnotifyrejectcritical") {
         Query->Param("PublishMode"=>"critical");
         Query->Param("NotifyMode" =>"reject");
      }
      if ($op eq "chmnotifyrejectdirect") {
         Query->Param("PublishMode"=>"direct");
         Query->Param("NotifyMode" =>"reject");
      }
   }

   return($self->SUPER::Process($action,$WfRec,$actions));
}


#######################################################################
package TS::workflow::change::individualnote;
use vars qw(@ISA);
use kernel;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $colde='';
   my $colen='';

   my @queryparam=(qw(PublishMode NotifyMode
                      note_de note_en));
   foreach my $p (@queryparam) {
      if (defined(Query->Param($p))) {
         $self->UserEnv->{queryparam}{$p}=Query->Param($p);
      }
      elsif (defined($self->UserEnv->{queryparam}{$p})) {
         Query->Param($p=>$self->UserEnv->{queryparam}{$p});
      }
   }

   if (!$self->notesValid()) {
      $colde='color:red;' if (Query->Param('note_de')=~m/^\s*$/);
      $colen='color:red;' if (Query->Param('note_en')=~m/^\s*$/);
   }

   my $templ="<p style=\"padding-top:5;padding-left:5;$colde\">".
             'Zusatztext für den deutschsprachigen Teil</p>';
   $templ.=$self->getDefaultNoteDiv($WfRec,$actions,(height=>55,
                                                     mode  =>'simple',
                                                     name  =>'note_de'));
   $templ.="<p style=\"padding-left:5;$colen\">".
           'additional text for the english part</p>';
   $templ.=$self->getDefaultNoteDiv($WfRec,$actions,(height=>55,
                                                     mode  =>'simple',
                                                     name  =>'note_en'));
   $templ.=$self->getParent->getParent->HtmlPersistentVariables(
                                           qw(PublishMode NotifyMode));

   return($templ);
}


sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my %buttons=$self->SUPER::getPosibleButtons($WfRec);
   delete($buttons{BreakWorkflow});
   return(%buttons);
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(220);
}


sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   delete($self->UserEnv->{queryparam}) if ($action ne '');

   if ($action eq 'NextStep') {
      my $de=trim(Query->Param('note_de'));
      my $en=trim(Query->Param('note_en'));
      Query->Param(note_de=>$de);
      Query->Param(note_en=>$en);
      
      return(0) if (!$self->notesValid());
   }
   return($self->SUPER::Process($action,$WfRec,$actions));
}


sub notesValid
{
   my $self=shift;

   if (!defined(Query->Param('note_de')) ||
       !defined(Query->Param('note_en'))) {
      return(1);
   }

   my $de=Query->Param('note_de');
   my $en=Query->Param('note_en');
   if (($de=~m/^\s*$/ && $en=~m/\S+/) ||
       ($en=~m/^\s*$/ && $de=~m/\S+/)) {
      return(0);
   }

   return(1);
}


######################################################################
package TS::workflow::change::publishpreview;
use vars qw(@ISA);
use kernel;
@ISA=qw(itil::workflow::change::publishpreview);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;

   my @email=@{$self->Context->{CurrentTarget}};
   my @emailcc=@{$self->Context->{CurrentTargetCC}};
   my @emailprefix=();
   my @emailpostfix=();
   my @emailtext=();
   my @emailsep=();
   my @emaillang=();
   my @emailsubheader=();
   my %additional=();

   $self->getParent->generateMailSet($WfRec,\%additional,
                    \@emailprefix,\@emailpostfix,\@emailtext,\@emailsep,
                    \@emaillang,\@emailsubheader);

   my @fittedText=map {$self->getParent->cutIdenticalCharString($_,65)}
                      @emailtext;

   return($self->generateNotificationPreview(emailtext=>\@fittedText,
                                             emailprefix=>\@emailprefix,
                                             emailsep=>\@emailsep,
                                             emailsubheader=>\@emailsubheader,
                                             cc=>\@emailcc,
                                             to=>\@email).
             $self->getParent->getParent->HtmlPersistentVariables(
                                             qw(PublishMode NotifyMode
                                                note_de note_en)));
}


sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "SaveStep"){
      my $emailfrom="unknown\@w5base.net";
      my @emailto=@{$self->Context->{CurrentTarget}};
      my @emailcc=@{$self->Context->{CurrentTargetCC}};

      if ($#emailto==-1 && $#emailcc==-1) {
         $self->LastMsg(ERROR,"No recipients for this mail located");
         return(0);
      }

      my $id=$WfRec->{id};
      my $wf=getModuleObject($self->Config,"base::workflow");

      my $subject;
      my $sitename=$self->Config->Param("SITENAME");
      if ($sitename ne ""){
         $subject.=$sitename.": ";
      }
      $subject.=$WfRec->{srcid}.": " if ($WfRec->{srcid} ne "");
      $subject.=$WfRec->{name};
      $subject.=" - Change notification";

      my @emailprefix=();
      my @emailpostfix=();
      my @emailtext=();
      my @emailsep=();
      my @emaillang=();
      my @emailsubheader=();

      my $headtext=$self->getParent->T("Changenumber","itil::workflow::change");

      my %additional=(headcolor=>'#e6e6e6',eventtype=>'Change',
                      headtext=>$headtext.": ".$WfRec->{srcid});

      $self->getParent->generateMailSet($WfRec,\%additional,
                       \@emailprefix,\@emailpostfix,\@emailtext,\@emailsep,
                       \@emaillang,\@emailsubheader);
      #
      # calc from address
      #
      my $uobj=$self->getParent->getPersistentModuleObject("base::user");
      my $userid=$self->getParent->getParent->getCurrentUserId();
      $uobj->SetFilter({userid=>\$userid});
      my ($userrec,$msg)=$uobj->getOnlyFirst(qw(email));
      if (defined($userrec) && $userrec->{email} ne ""){
         $emailfrom=$userrec->{email};
         my $qemailfrom=quotemeta($emailfrom);
         if (!grep(/^$qemailfrom$/i,@emailto) &&
             !grep(/^$qemailfrom$/i,@emailcc)){
            push(@emailcc,$emailfrom);
         }
      }

      my @fittedText=map {$self->getParent->cutIdenticalCharString($_,65)}
                         @emailtext;
      my $newmailrec={
             class    =>'base::workflow::mailsend',
             step     =>'base::workflow::mailsend::dataload',
             name     =>$subject,
             emailtemplate  =>'changenotify',
             skinbase       =>'itil',
             emailfrom      =>$emailfrom,
             emailto        =>\@emailto,
             emailcc        =>\@emailcc,
             emailprefix    =>\@emailprefix,
             emailpostfix   =>\@emailpostfix,
             emailtext      =>\@fittedText,
             emailsep       =>\@emailsep,
             emaillang      =>\@emaillang,
             emailsubheader =>\@emailsubheader,
             additional     =>\%additional
            };
      if (my $id=$wf->Store(undef,$newmailrec)){
         if ($self->getParent->activateMailSend($WfRec,$wf,$id,
                                                $newmailrec,$action)){
            my $NotifyMode=Query->Param('NotifyMode');
            my $comment='';
            my %actionref=();

            if ($NotifyMode eq 'announce') {
               $comment='Announcement sent';
               $comment.=" (".Query->Param('PublishMode').")";
            }

            if ($NotifyMode eq 'confirm') {
               $comment='Confirm request sent';
            }

            if ($NotifyMode eq 'approve') {
               $comment='Approval request sent';
               $comment.=" (".Query->Param('PublishMode').")";
               $actionref{rescheduledata}=$WfRec->{rescheduledatahash};
            }

            if ($NotifyMode eq 'remind') {
               $comment='Approval reminder sent';
               $actionref{rescheduledata}=$WfRec->{rescheduledatahash};
            }

            if ($NotifyMode eq 'reschedule') {
               $comment='Rescheduled info sent';
               $actionref{rescheduledata}=$WfRec->{rescheduledatahash};
            }

            if ($NotifyMode eq 'reject') {
               $comment='Change rejection sent';
               $comment.=" (".Query->Param('PublishMode').")";
            }

            if ($wf->Action->StoreRecord(
                $WfRec->{id},"sendchangeinfo",
                {translation=>'itil::workflow::change',
                 actionref=>\%actionref},
                $comment)){
               Query->Delete("WorkflowStep");
               return(1);
            }
         }
      }
      else{
         return(0);
      }
      return(1);
   }
   return($self->SUPER::Process($action,$WfRec,$actions));
}



1;
