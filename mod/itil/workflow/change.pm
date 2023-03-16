package itil::workflow::change;
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
   $self->{history}=[qw(insert modify delete)];


   return($self);
}


sub Init
{
   my $self=shift;

   $self->AddFields(
   );

   $self->AddGroup("itilchange",translation=>'itil::workflow::change');
}


sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;

   return($self->InitFields(
      new kernel::Field::Interface(    
                name       =>'changemanagerid',
                translation=>'itil::workflow::change',
                group      =>'state',
                label      =>'Change-Manager ID',
                container  =>'headref'),

      new kernel::Field::Text(    
                name       =>'changemanager',
                weblinkon  =>['changemanagerid'=>'userid'],
                weblinkto  =>'base::user',
                translation=>'itil::workflow::change',
                group      =>'state',
                label      =>'Change-Manager',
                container  =>'headref'),

      new kernel::Field::Date(    
                name       =>'changestart',
                translation=>'itil::workflow::change',
                group      =>'itilchange',
                label      =>'Planned start',
                alias      =>'eventstart'),

      new kernel::Field::Date(    
                name       =>'changeend',
                translation=>'itil::workflow::change',
                group      =>'itilchange',
                label      =>'Planned end',
                alias      =>'eventend'),

      new kernel::Field::Textarea(
                name       =>'changedescription',
                translation=>'itil::workflow::change',
                htmlwidth  =>'350px',
                searchable =>0,
                label      =>'Change Description',
                group      =>'itilchange',
                container  =>'headref'),

      new kernel::Field::Textarea(
                name       =>'changefallback',
                htmlwidth  =>'350px',
                translation=>'itil::workflow::change',
                searchable =>0,
                label      =>'Change Fallback',
                group      =>'itilchange',
                container  =>'headref'),

      new kernel::Field::Link(  
                name       =>'essentialdatahash',
                history    =>0,
                label      =>'hashed essential change data',
                container  =>'headref'),

      new kernel::Field::Link(  
                name       =>'rescheduledatahash',
                history    =>0,
                label      =>'hashed data detecting change reschedule',
                container  =>'headref'),

      new kernel::Field::KeyText(
                name       =>'primaffectedapplication',
                translation=>'itil::workflow::change',
                xlswidth   =>'30',
                keyhandler =>'kh',
                readonly   =>1,
                htmldetail =>0,
                vjointo    =>'itil::appl',
                vjoinon    =>['primaffectedapplicationid'=>'id'],
                vjoindisp  =>'name',
                container  =>'headref',
                group      =>'affected',
                label      =>'prim affected Application'),

      new kernel::Field::KeyText(
                name       =>'primaffectedapplicationid',
                htmldetail =>0,
                translation=>'itil::workflow::change',
                searchable =>0,
                readonly   =>1,
                keyhandler =>'kh',
                container  =>'headref',
                group      =>'affected',
                label      =>'prim affected Application ID'),


   ));
}


sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   return("itil::workflow::change::".$shortname);
}  


sub getNextStep
{
   my $self=shift;
   my $currentstep=shift;
   my $WfRec=shift;

   if($currentstep=~m/::main$/){
      return($self->getStepByShortname('publishpreview',$WfRec));
   }

   return($self->SUPER::getNextStep($currentstep,$WfRec));
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


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return(qw(ALL)) if (defined($rec));
   return(undef);
}


sub getDetailBlockPriority                # posibility to change the block order
{
   return("itilchange",'state',"affected","flow","source");
}


sub isOptionalFieldVisible
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   my $name=$param{field}->Name();

   return(1) if ($name eq 'relations');
   return($self->SUPER::isOptionalFieldVisible($mode,%param));
}


sub getNotifyDestinations
{
   my $self=shift;
   my $mode=shift;    # direct|critical|all
   my $WfRec=shift;
   my $emailto=shift;
   my $emailcc=shift;
   my $ifappl=shift;
   my $ia=getModuleObject($self->Config,"base::infoabo");
   my $applid=$WfRec->{affectedapplicationid};
   $applid=[$applid] if (ref($applid) ne "ARRAY");

   my $appl=getModuleObject($self->Config,"itil::appl");
   my @tobyfunc;
   my @ccbyfunc;
   $appl->ResetFilter();
   $appl->SetFilter({id=>$applid});
   my @fl=qw(tsmid tsm2id);
   my @ifid;

   foreach my $rec ($appl->getHashList(@fl)){
      push(@tobyfunc,$rec->{tsmid})  if ($rec->{tsmid}>0);
      push(@ccbyfunc,$rec->{tsm2id}) if ($rec->{tsm2id}>0);
   }

   if ($mode ne "direct"){
      my $aa=getModuleObject($self->Config,"itil::lnkapplappl");

      # interface appls of prim. affected applications
      my $aaflt=[{fromapplid=>$applid,
                  cistatusid=>[4],
                  toapplcistatus=>[3,4,5]}];
      $aa->SetFilter($aaflt);
      foreach my $aarec ($aa->getHashList(qw(toapplid contype 
                                             gwapplid gwappl2id))){
         next if ($mode eq "critical" &&
                  ($aarec->{contype}==4 ||
                   $aarec->{contype}==5 ||
                   $aarec->{contype}==3));   # uncritical  communications
         # if mode=all, no filter on contype 3,4,5 is done, which
         # meens ALL interface applications of the direct affected
         # applications are used as "relevant applications".
         if (!in_array($applid,$aarec->{toapplid})){
            push(@ifid,$aarec->{toapplid});
         }
      }
      #######################################################################
      # gateway application handling
      my $aagwflt=[
         {
             gwapplid=>$applid,
             cistatusid=>[4],
             toapplcistatus=>[3,4,5],
             fromapplcistatus=>[3,4,5]
         },
         {
             gwappl2id=>$applid,
             cistatusid=>[4],
             toapplcistatus=>[3,4,5],
             fromapplcistatus=>[3,4,5]
         }
      ];
      $aa->ResetFilter();
      $aa->SetFilter($aagwflt);
      foreach my $aarec ($aa->getHashList(qw(toapplid fromapplid contype 
                                             gwapplid gwappl2id))){
         next if ($mode eq "critical" &&
                  ($aarec->{contype}==4 ||
                   $aarec->{contype}==5 ||
                   $aarec->{contype}==3));   # uncritical  communications
         # if mode=all, no filter on contype 3,4,5 is done, which
         # meens ALL interface applications of the direct affected
         # applications are used as "relevant applications".
         if (!in_array($applid,$aarec->{toapplid})){
            push(@ifid,$aarec->{toapplid});
         }
         if (!in_array($applid,$aarec->{fromapplid})){
            push(@ifid,$aarec->{fromapplid});
         }
      }
      #######################################################################


      # interface appls with critical interface
      # to prim. affected applications on its side
      $aaflt=[{toapplid=>$applid,
               cistatusid=>[4],
               fromapplcistatus=>[3,4,5]}];
      $aa->ResetFilter();
      $aa->SetFilter($aaflt);
      foreach my $aarec ($aa->getHashList(qw(fromapplid contype))){
         next if ($aarec->{contype}==4 ||
                  $aarec->{contype}==5 ||
                  $aarec->{contype}==3 );   # uncritical  communications
         if (!in_array($applid,$aarec->{fromapplid}) &&
             !in_array(\@ifid,$aarec->{fromapplid})){
            push(@ifid,$aarec->{fromapplid});        
         }
      }

      if ($#ifid!=-1) {
         $appl->ResetFilter();
         $appl->SetFilter({id=>\@ifid,cistatusid=>"<=4"});
         foreach my $rec ($appl->getHashList(@fl,qw(name id))){
            $ifappl->{$rec->{id}}=$rec->{name};
            push(@tobyfunc,$rec->{tsmid})  if ($rec->{tsmid}>0);
            push(@ccbyfunc,$rec->{tsm2id}) if ($rec->{tsm2id}>0);
         }
      }
   }

   # infoabos
   $ia->LoadTargets($emailto,'*::appl',\'changenotify',$applid);
   $ia->LoadTargets($emailto,'base::staticinfoabo',\'STEVchangeinfobyfunction',
                             '100000004',\@tobyfunc,default=>1);
   $ia->LoadTargets($emailcc,'base::staticinfoabo',\'STEVchangeinfobydepfunc',
                             '100000005',\@ccbyfunc,default=>1);

   # detect infocontacts
   my $lnkcontactobj=getModuleObject($self->Config,'itil::lnkapplcontact');
   my $uobj=getModuleObject($self->Config,'base::user');

   $lnkcontactobj->SetFilter({refid=>$applid,
                              croles=>'*roles=?infocontact?=roles*'});
   $lnkcontactobj->SetCurrentView(qw(targetid refid));
   my $applcontacts=$lnkcontactobj->getHashIndexed(qw(targetid refid));
   my @infocontactids=keys(%{$applcontacts->{targetid}});

   $uobj->SetFilter({userid=>\@infocontactids,
                     cistatusid=>'<5',
                     email=>'![EMPTY]'});
   my @infocontacts=$uobj->getHashList(qw(userid email));
   
   foreach my $user (@infocontacts) {
      my $email=$user->{email};
      my $target=$applcontacts->{targetid}->{$user->{userid}};

      my @applids=();
      if (ref($target) eq 'ARRAY') {
         @applids=map({$_->{refid}} @$target);
      }
      if (ref($target) eq 'HASH') {
         @applids=($target->{refid});
      }

      if (exists($emailto->{$email})) {
         if (ref($emailto->{$email} eq 'ARRAY')) {
            push(@{$emailto->{$email}},@applids);
         }
      }
      else {
         $emailto->{$email}=\@applids;
      }
   }


   foreach my $to (keys(%$emailto)) {
      delete($emailcc->{$to});
   }

   return(undef);
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
   $self->linkMail($WfRec->{id},$id);
   if (my $r=$wf->Store($id,%d)){
      return(1);
   }
   return(0);
}


sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;
   my @l=qw(wffollowup);
   my $eventend=$WfRec->{eventend};
   my $age;
   if ($eventend ne ""){
      my $d=CalcDateDuration($eventend,NowStamp("en"));
      $age=$d->{totalminutes};
   }
   if (!defined($age) || $age<5000){ # note add allowed 3.5 days after eventend
      if ($self->isChangeManager($WfRec)) {
         push(@l,"wfaddnote");
      }
      else {
         my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"write");
         my $m=$WfRec->{mandatorid};
         $m=[$m] if (ref($m) ne "ARRAY");
         foreach my $ms (@$m){
            if (grep(/^$ms$/,@mandators)){
               push(@l,"wfaddnote");
               last;
            }
         }
      }
   }
   if (!$self->getParent->isDataInputFromUserFrontend()){
      if ($WfRec->{stateid}>=16){
         push(@l,"wfforcerevise");
      }
   }
   if (defined($WfRec->{affectedapplicationid})) {
      if ($self->notifyValid($WfRec,'all')) {
         push(@l,qw(chmnotifyall chmnotifycritical chmnotifydirect));
      }
#      if ($self->notifyValid($WfRec,'critical')) {
#         push(@l,'chmnotifycritical');
#      }
#      if ($self->notifyValid($WfRec,'direct')) {
#         push(@l,'chmnotifydirect');
#      }
   }

   return(@l);
}


sub getFollowupTargetUserids
{
   my $self=shift;
   my $WfRec=shift;
   my $param=shift;
   $self->SUPER::getFollowupTargetUserids($WfRec,$param);

   if (defined($WfRec->{affectedapplicationid}) &&
       ref($WfRec->{affectedapplicationid}) eq "ARRAY"){
      my $appl=getModuleObject($self->Config,"itil::appl");
      $appl->SetFilter({id=>$WfRec->{affectedapplicationid}});
      foreach my $arec ($appl->getHashList(qw(tsmid))){
         push(@{$param->{addtarget}},$arec->{tsmid}) if ($arec->{tsmid} ne "");
      }
   }
}


sub generateMailSet
{
   my $self=shift;
   my ($WfRec,$additional,$emailprefix,$emailpostfix,
       $emailtext,$emailsep,$emailsubheader)=@_;
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

   my $lang=$self->getParent->Lang();
   my @baseset=qw(srcid name changestart changeend affectedapplication 
                  changedescription);
   my $line=0;
   foreach my $field (@baseset){
      my $fo=$self->getField($field,$WfRec);
      my $sh=0;
      $sh=" " if ($field eq "wffields.eventaltdesciption" ||
                  $field eq "wffields.eventdesciption");
      if (defined($fo)){
         my $v=$fo->FormatedResult($WfRec,"HtmlMail");
         if ($v ne ""){

            if ($baseurl ne "" && $line==0){
               my $ilang="?HTTP_ACCEPT_LANGUAGE=$lang";
               my $imgtitle=$self->getParent->T("current state of workflow",
                                                "base::workflow");
               push(@emailpostfix,
                    "<img title=\"$imgtitle\" class=status border=0 ".
                    "src=\"$baseurl/public/base/workflow/".
                    "ShowState/$WfRec->{id}$ilang\">");
            }
            else{
               push(@emailpostfix,"");
            }
            my $label=$fo->Label();
            if ($field eq "srcid"){
               $label=$self->getParent->T("Changenumber",
               "itil::workflow::change");
            }
            push(@emailprefix,$label.":");

            my $data=$v;
            $data=~s/</&lt;/g;
            $data=~s/>/&gt;/g;
            if ($field eq "changedescription"){
               $data=~s/^AG\s+.+$//m;
               $data=trim($data);
            }
            if ($field eq "srcid"){
               $data.=" $baseurl/auth/base/workflow/ById/$WfRec->{id} " 
            }
            push(@emailtext,$data);
            push(@emailsubheader,$sh);
            push(@emailsep,0);
            $line++;
         }
      }
   }

   @$emailprefix=@emailprefix;
   @$emailpostfix=@emailpostfix;
   @$emailtext=@emailtext;
   @$emailsep=@emailsep;
   @$emailsubheader=@emailsubheader;
}


sub isChangeManager
{
   my $self=shift;
   my $WfRec=shift;

   my $mandator=$WfRec->{mandatorid};
   $mandator=[$mandator] if (!ref($mandator) eq "ARRAY");

   return(1) if ($self->getParent->IsMemberOf($mandator,
                                              ["RCHManager",
                                               "RCHManager2",
                                               "RCHOperator"],"down"));

   if ($WfRec->{mandator}->[0] eq 'none') { # mandator 'None'
      my %grps=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                                             ["RCHManager",
                                              "RCHManager2",
                                              "RCHOperator"],"direct");
      return(1) if (keys(%grps)>0);
   }

   return(0);
}


sub notifyValid
{
   my $self=shift;
   my $WfRec=shift;
   my $mode=shift;

   return($self->isChangeManager($WfRec));
}


#######################################################################
# this step is no longer used.
# Just for compatibility with old workflows in this step.
# mz 28.01.2016

package itil::workflow::change::extauthority;
use vars qw(@ISA);
use kernel;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;

   return(undef);
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(0);
}


sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my %b=();

   return(%b);
}


#######################################################################
package itil::workflow::change::main;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspacePages
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $divset=shift;
   my $selopt=shift;
   my $height=shift;
   my $vButtons=shift;
   my $class='display:none;visibility:hidden';
   my $d;

   if (grep(/^wfaddnote$/,@$actions)) {
      $$selopt.='<option value="wfaddnote">'.
                    $self->T("wfaddnote",'base::workflow::actions').
                "</option>\n";
      $d=$self->getDefaultNoteDiv($WfRec,$actions,'height'=>'110');

      $$divset.='<div id=OPwfaddnote data-visiblebuttons="SaveStep"'.
                " class=\"$class\">$d</div>";
   }
   if (grep(/^chmnotifyall$/,@$actions)) {
      $$selopt.='<option value="chmnotifyall">'.
                    $self->T('notifyall','itil::workflow::change::main').
                "</option>\n";
      $d="<div class=Question><table border=0>".
           "<tr><td>".$self->T('helpnotifyall',$self->Self)."</td></tr>".
          "</table></div>";

      $$divset.='<div id=OPchmnotifyall data-visiblebuttons="NextStep"'.
                " class=\"$class\">$d</div>";
   }
   if (grep(/^chmnotifycritical$/,@$actions)) {
      $$selopt.='<option value="chmnotifycritical">'.
                    $self->T('notifycritical','itil::workflow::change::main').
                "</option>\n";
      $d="<div class=Question><table border=0>".
           "<tr><td>".$self->T('helpnotifycritical',$self->Self)."</td></tr>".
          "</table></div>";

      $$divset.='<div id=OPchmnotifycritical data-visiblebuttons="NextStep"'.
                " class=\"$class\">$d</div>";
   }
   if (grep(/^chmnotifydirect$/,@$actions)) {
      $$selopt.='<option value="chmnotifydirect">'.
                    $self->T('notifydirect','itil::workflow::change::main').
                "</option>\n";
      $d="<div class=Question><table border=0>".
           "<tr><td>".$self->T("helpnotifydirect",$self->Self)."</td></tr>".
          "</table></div>";

      $$divset.='<div id=OPchmnotifydirect data-visiblebuttons="NextStep"'.
                " class=\"$class\">$d</div>";
   }
}


sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my %b=();

   if (grep(/^wfaddnote$/,@$actions)){
      $b{SaveStep}=$self->T('Save','base::workflow::request::main');
   }
   if (grep(/^chmnotify/,@$actions)){
      $b{NextStep}=$self->T('next Step','kernel::WfStep');
   }
   return(%b);
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(206);
   #return(190) if ($WfRec->{state}<20);
   #return(120);
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
   my $op=Query->Param('OP');

   if ($action eq "NextStep") {
      if (($op eq "chmnotifyall"      || 
           $op eq "chmnotifycritical" || 
           $op eq "chmnotifydirect") && defined($WfRec)) {
         Query->Param("PublishMode"=>"all")      if $op eq "chmnotifyall";
         Query->Param("PublishMode"=>"critical") if $op eq "chmnotifycritical";
         Query->Param("PublishMode"=>"direct")   if $op eq "chmnotifydirect";
      }
   }

   return($self->SUPER::Process($action,$WfRec,$actions));
}


#######################################################################
package itil::workflow::change::postreflection;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;

sub new
{
   return(undef);
}



#######################################################################
package itil::workflow::change::publishpreview;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);


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
   my @emailsubheader=();
   my %additional=();
   my $info=Query->Param("PublishInfoMsg");
   $info=~s/</&lt;/g;
   $info=~s/>/&gt;/g;
   if (!($info=~m/^\s*$/)){
      push(@emailprefix,"");
      push(@emailtext,$info."\n\n");
      push(@emailsep,0);
      push(@emailsubheader,0);
      push(@emailpostfix,"");
   }
   $self->getParent->generateMailSet($WfRec,\%additional,
                    \@emailprefix,\@emailpostfix,\@emailtext,\@emailsep,
                    \@emailsubheader);
   return($self->generateNotificationPreview(emailtext=>\@emailtext,
                                             emailprefix=>\@emailprefix,
                                             emailsep=>\@emailsep,
                                             emailsubheader=>\@emailsubheader,
                                             cc=>\@emailcc,
                                             to=>\@email).
      $self->getParent->getParent->HtmlPersistentVariables(qw(PublishMode
                                                              PublishInfoMsg)));
}


sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;

   my %b=$self->SUPER::getPosibleButtons($WfRec);
   my %em=();
   my %cc=();
   my %ifappl=();
   my $PublishMode=Query->Param('PublishMode');
   $PublishMode="direct" if ($PublishMode eq "");
   $self->getParent->getNotifyDestinations($PublishMode,$WfRec,\%em,\%cc,
                                                               \%ifappl);
   my @email  =sort(keys(%em));
   my @emailcc=sort(keys(%cc));
   $self->Context->{CurrentTarget}=\@email;
   $self->Context->{CurrentTargetCC}=\@emailcc;
   delete($b{NextStep});
   delete($b{BreakWorkflow});
   $b{SaveStep}=$self->T('Send','itil::workflow::change');

   return(%b);
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(250);
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

      my $id=$WfRec->{id};
      $self->getParent->getParent->Action->ResetFilter();
      $self->getParent->getParent->Action->SetFilter({wfheadid=>\$id});
      my @l=$self->getParent->getParent->Action->getHashList(qw(cdate name));
      my $sendchangeinfocount=1;
      foreach my $arec (@l){
         $sendchangeinfocount++ if ($arec->{name} eq "sendchangeinfo");
      }
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
      my @emailsubheader=();

      my $headtext=$self->getParent->T("Changenumber","itil::workflow::change");

      my %additional=(headcolor=>'#e6e6e6',eventtype=>'Change',
                      headtext=>$headtext.": ".$WfRec->{srcid});
      my $info=Query->Param("PublishInfoMsg");
      $info=~s/</&lt;/g;
      $info=~s/>/&gt;/g;
      if (!($info=~m/^\s*$/)){
         push(@emailprefix,"");
         push(@emailtext,$info."\n\n");
         push(@emailsep,0);
         push(@emailsubheader,0);
         push(@emailpostfix,"");
      }
      $self->getParent->generateMailSet($WfRec,\%additional,
                       \@emailprefix,\@emailpostfix,\@emailtext,\@emailsep,
                       \@emailsubheader);
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
         if (!grep(/^$qemailfrom$/i,@emailto)){
            push(@emailcc,$emailfrom);
         }
      }
      
      #
      # load crator in cc
      #
      #if ($WfRec->{openuser} ne ""){
      #   $uobj->SetFilter({userid=>\$WfRec->{openuser}});
      #   my ($userrec,$msg)=$uobj->getOnlyFirst(qw(email));
      #   if (defined($userrec) && $userrec->{email} ne ""){
      #      my $e=$userrec->{email};
      #      my $qemailfrom=quotemeta($e);
      #      if (!grep(/^$qemailfrom$/,@emailto) &&
      #          !grep(/^$qemailfrom$/,@emailcc)){
      #         push(@emailcc,$e);
      #      }
      #   }
      #}

      my $newmailrec={
             class    =>'base::workflow::mailsend',
             step     =>'base::workflow::mailsend::dataload',
             name     =>$subject,
             emailfrom      =>$emailfrom,
             emailto        =>\@emailto,
             emailcc        =>\@emailcc,
             emailprefix    =>\@emailprefix,
             emailpostfix   =>\@emailpostfix,
             emailtext      =>\@emailtext,
             emailsep       =>\@emailsep,
             emailsubheader =>\@emailsubheader,
             additional     =>\%additional
            };

      if (my $id=$wf->Store(undef,$newmailrec)){
         if ($self->getParent->activateMailSend($WfRec,$wf,$id,
                                                $newmailrec,$action)){
            if ($wf->Action->StoreRecord(
                $WfRec->{id},"sendchangeinfo",
                {translation=>'itil::workflow::change'},
                "$sendchangeinfocount. notification",undef)){
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
