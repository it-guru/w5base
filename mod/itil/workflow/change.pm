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
                label      =>'Change-Planed-Start',
                alias      =>'eventstart'),

      new kernel::Field::Date(    
                name       =>'changeend',
                translation=>'itil::workflow::change',
                group      =>'itilchange',
                label      =>'Change-Planed-End',
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


sub getNotifyDestinations
{
   my $self=shift;
   my $mode=shift;    # "direct" | "all"
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
   my @fl=qw(semid sem2id tsmid tsm2id);
   my @ifid;
   foreach my $rec ($appl->getHashList(@fl)){
      push(@tobyfunc,$rec->{tsmid})  if ($rec->{tsmid}>0);
      push(@ccbyfunc,$rec->{tsm2id}) if ($rec->{tsm2id}>0);
      push(@tobyfunc,$rec->{semid})  if ($rec->{semid}>0);
      push(@ccbyfunc,$rec->{sem2id}) if ($rec->{sem2id}>0);
   }
   if ($mode eq "all"){
      my $aa=getModuleObject($self->Config,"itil::lnkapplappl");
      my $aaflt=[{toapplid=>$applid,
                  cistatusid=>[4],
                  fromapplcistatus=>[3,4,5]}];
      $aa->SetFilter($aaflt);
      foreach my $aarec ($aa->getHashList(qw(fromapplid toapplid contype
                                           toapplcistatus))){
         next if ($aarec->{contype}==4 ||
                  $aarec->{contype}==5 ||
                  $aarec->{contype}==3 );   # uncritical  communications
         if (!in_array($applid,$aarec->{fromapplid})){ # von der anderen
            push(@ifid,$aarec->{fromapplid});           # seite eingetragen
         }
      }
   }
   if ($mode eq "all" && $#ifid!=-1){

      $appl->ResetFilter();
      $appl->SetFilter({id=>\@ifid,cistatusid=>"<=4"});
      foreach my $rec ($appl->getHashList(@fl,"name")){
         $ifappl->{$rec->{name}}=1;
         push(@tobyfunc,$rec->{tsmid})  if ($rec->{tsmid}>0);
         push(@ccbyfunc,$rec->{tsm2id}) if ($rec->{tsm2id}>0);
      }
   }
   $ia->LoadTargets($emailto,'*::appl',\'changenotify',$applid);
   $ia->LoadTargets($emailto,'base::staticinfoabo',\'STEVchangeinfobyfunction',
                             '100000004',\@tobyfunc,default=>1);
   $ia->LoadTargets($emailcc,'base::staticinfoabo',\'STEVchangeinfobydepfunc',
                             '100000005',\@ccbyfunc,default=>1);
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

   my %d=(step=>'base::workflow::mailsend::waitforspool',
          emailsignatur=>'ChangeNotification');
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
   if (!$self->getParent->isDataInputFromUserFrontend()){
      if ($WfRec->{stateid}>=16){
         push(@l,"wfforcerevise");
      }
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

      # itil::chmmgmt chmgrteam no more used, see 14246971890003
      #
      #if ($param->{note}=~m/\[chm\.\S+\]/){
      #   my $usrgrp=getModuleObject($self->Config,"base::lnkgrpuserrole"); 
      #   my $chm=getModuleObject($self->Config,"itil::chmmgmt"); 
      #   $chm->SetFilter({id=>$WfRec->{affectedapplicationid}});
      #   foreach my $chmrec ($chm->getHashList(qw(chmgrteamid chmgrfmbid))){
      #      if ($chmrec->{chmgrfmbid} ne ""){
      #         push(@{$param->{addcctarget}},$chmrec->{chmgrfmbid});
      #      }
      #      elsif ($chmrec->{chmgrteamid} ne ""){
      #         $usrgrp->ResetFilter();
      #         $usrgrp->SetFilter({grpid=>\$chmrec->{chmgrteamid},
      #                             cistatusid=>[4,5],
      #                             grpcistatusid=>[4],
      #                             nativrole=>[orgRoles()]});
      #         foreach my $lnkrec ($usrgrp->getHashList(qw(userid))){
      #            # message not needed in errorlog
      #            #msg(INFO,"add userid '$lnkrec->{userid}'");
      #            push(@{$param->{addcctarget}},$lnkrec->{userid});
      #         }
      #      }
      #   }
      #   push(@{$param->{addcctarget}});
      #}
   }
}




sub generateMailSet
{
   my $self=shift;
   my ($WfRec,$additional,$emailprefix,$emailpostfix,
       $emailtext,$emailsep,
       $emailsubheader)=@_;
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
      $baseurl=~s#/auth/.*$##;
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
   #my $rel=$self->getField("relations",$WfRec);
   #my $reldata=$rel->ListRel($WfRec->{id},"mail",{name=>\'consequenceof'});
   #push(@emailprefix,$rel->Label().":");
   #push(@emailtext,$reldata);
   #push(@emailsubheader,0);
   #push(@emailsep,0);
   #push(@emailpostfix,"");
   #delete($ENV{HTTP_FORCE_LANGUAGE});

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
   return(1) if ($self->getParent->IsMemberOf($mandator,"RCHManager","down"));
   return(1) if ($self->getParent->IsMemberOf("admin"));

   # itil::chmmgmt chmgrteam no more used, see 14246971890003
   #
   #my $aid=$WfRec->{affectedapplicationid};
   #$aid=[$aid] if (ref($aid) ne "ARRAY");
   #my $chmmgmt=getModuleObject($self->getParent->Config,"itil::chmmgmt");
   #$chmmgmt->SetFilter({id=>$aid});
   #foreach my $arec ($chmmgmt->getHashList(qw(chmgrteamid))){
   #   if ($arec->{chmgrteamid} ne ""){
   #      return(1) if ($self->getParent->IsMemberOf($arec->{chmgrteamid}));
   #   }
   #}
   

   return(0);
}




#######################################################################
package itil::workflow::change::extauthority;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $msg=$self->T("Externel authority");
   my $templ;
   if (grep(/^wfaddnote$/,@$actions)){
      $templ.=$self->getDefaultNoteDiv($WfRec,$actions,'height'=>'50');
   }
   $templ.=<<EOF;
<div class=Question><table border=0><tr><td>$msg</td></tr></table></div>
EOF
   return($templ);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my %buttons=();

   if ($self->getParent->can("isPostReflector") &&
       $self->getParent->isPostReflector($WfRec)){
      $buttons{"PostReflection"}=$self->T('initiate postreflection');
   }
   if ($self->getParent->isChangeManager($WfRec)){
      $buttons{"PublishInfo"}=$self->T('publish change notification');
   }
   if (grep(/^wfaddnote$/,@$actions)){
      $buttons{"wfaddnote"}=$self->T('add note');
   }
   return(%buttons);
}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(160) if ($WfRec->{state}<20);
   return(120);
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

   if ($action eq "PostReflection"){
      if ($self->getParent->can("isPostReflector") &&
          $self->getParent->isPostReflector($WfRec)){
         if (!$self->StoreRecord($WfRec,
             {step=>'itil::workflow::change::postreflection'})){
            return(0);
         }
         return(1);
      }
   }
   elsif ($action eq "PublishInfo"){
      my @WorkflowStep=Query->Param("WorkflowStep");
      if (defined($WfRec)){
         my @WorkflowStep=Query->Param("WorkflowStep");
         push(@WorkflowStep,$self->getParent->getStepByShortname(
                                                  "askpublishmode",$WfRec));
         Query->Param("WorkflowStep"=>\@WorkflowStep);
      }
      return(0);
   }
   elsif ($action eq "wfaddnote"){
      my $note=Query->Param("note");
      my $effort=Query->Param("Formated_effort");
      my $h={};
      $h->{note}=$note                     if ($note ne "");
      $h->{effort}=$effort                 if ($effort ne "");
      return($self->nativProcess($action,$h,$WfRec,$actions));
   }

   return($self->SUPER::Process($action,$WfRec));
}




#######################################################################
package itil::workflow::change::postreflection;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $msg=$self->T("post reflection: please correct the desiered data");
   my $templ;
   if (grep(/^wfaddnote$/,@$actions)){
      $templ.=$self->getDefaultNoteDiv($WfRec,$actions,'height'=>'50');
   }
   my @acl=$self->getParent->isWriteValid($WfRec);
   
   if ($#acl!=-1){
      $templ.=<<EOF;
<div class=Question><table border=0><tr><td>$msg</td></tr></table></div>
EOF
   }
   return($templ);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my %buttons;
   if ($self->getParent->can("isPostReflector") &&
       $self->getParent->isPostReflector($WfRec)){
      if ($WfRec->{stateid}!=21){
         $buttons{"FinishReflection"}=$self->T('finish postreflection');
      }
      else{
         $buttons{"InitReflection"}=$self->T('init postreflection');
      }
   }
   if ($self->getParent->isChangeManager($WfRec)){
      $buttons{"PublishInfo"}=$self->T('publish change notification');
   }
   if (grep(/^wfaddnote$/,@$actions)){
      $buttons{"wfaddnote"}=$self->T('add note');
   }
   return(%buttons);
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(160) if ($WfRec->{state}<20);
   return(120);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "FinishReflection"){
      if ($self->getParent->can("isPostReflector") &&
          $self->getParent->isPostReflector($WfRec)){
         if (!$self->StoreRecord($WfRec,
             {stateid=>21})){
            return(0);
         }
         return(1);
      }
   }
   if ($action eq "PublishInfo"){
      my @WorkflowStep=Query->Param("WorkflowStep");
      if (defined($WfRec)){
         my @WorkflowStep=Query->Param("WorkflowStep");
         push(@WorkflowStep,$self->getParent->getStepByShortname(
                                                  "askpublishmode",$WfRec));
         Query->Param("WorkflowStep"=>\@WorkflowStep);
      }
      return(0);
   }
   if ($action eq "InitReflection"){
      if ($self->getParent->can("isPostReflector") &&
          $self->getParent->isPostReflector($WfRec)){
         if (!$self->StoreRecord($WfRec,
             {stateid=>17})){
            return(0);
         }
         return(1);
      }
   }
   elsif ($action eq "wfaddnote"){
      my $note=Query->Param("note");
      my $effort=Query->Param("Formated_effort");
      my $h={};
      $h->{note}=$note                     if ($note ne "");
      $h->{effort}=$effort                 if ($effort ne "");
      return($self->nativProcess($action,$h,$WfRec,$actions));
   }
   return($self->SUPER::Process($action,$WfRec));
}

sub Validate
{
   my $self=shift;

   return(1);
}


#######################################################################
package itil::workflow::change::askpublishmode;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $info=Query->Param("PublishInfoMsg");
   if (!defined($info)){
      $info=$self->getParent->T("MSG001");
   }
   my $templ=<<EOF;
<table width="100%" height="110" cellspacing=0 cellpadding=0>
<tr height="1%"><td>Benachrichtigungstext:</td></tr>
<tr><td>
<textarea name=PublishInfoMsg style="width:100%;height:100%">$info</textarea>
</td>
</tr></table>
EOF
   return($templ);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my %buttons=$self->SUPER::getPosibleButtons($WfRec);
   $buttons{"PublishDirect"}=$self->T('only direct contacts');
   $buttons{"PublishAll"}=$self->T('direct and interface contacts');
   delete($buttons{BreakWorkflow});
   delete($buttons{NextStep});
   return(%buttons);
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(150);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "PublishDirect"){
      Query->Param("PublishMode"=>"direct");
      if (defined($WfRec)){
         my @WorkflowStep=Query->Param("WorkflowStep");
         push(@WorkflowStep,"itil::workflow::change::publishpreview");
         Query->Param("WorkflowStep"=>\@WorkflowStep);
      }
   }
   if ($action eq "PublishAll"){
      Query->Param("PublishMode"=>"all");
      if (defined($WfRec)){
         my @WorkflowStep=Query->Param("WorkflowStep");
         push(@WorkflowStep,"itil::workflow::change::publishpreview");
         Query->Param("WorkflowStep"=>\@WorkflowStep);
      }
   }
   return($self->SUPER::Process($action,$WfRec));
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
   my $PublishMode=Query->Param("PublishMode");
   $PublishMode="direct" if ($PublishMode eq "");
   $self->getParent->getNotifyDestinations($PublishMode,$WfRec,\%em,\%cc,
                                                               \%ifappl);
   #msg(INFO,"IT-Eventnotification for ifappl: ".
   #         join(", ",sort(keys(%ifappl))));
   my @email=sort(keys(%em));
   $self->Context->{CurrentTarget}=\@email;
   $self->Context->{CurrentTargetCC}=[keys(%cc)];
   delete($b{NextStep}) if ($#email==-1);
   delete($b{BreakWorkflow});

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

   if ($action eq "NextStep"){
      my %em=();
      my %cc=();
      my %ifappl=();
      my $PublishMode=Query->Param("PublishMode");
      $PublishMode="direct" if ($PublishMode eq "");
      $self->getParent->getNotifyDestinations($PublishMode,$WfRec,\%em,\%cc,
                                                                  \%ifappl);
      my @emailto=sort(keys(%em));
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
      my $emailfrom="unknown\@w5base.net";
      my @emailcc=(keys(%cc));
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
   return($self->SUPER::Process($action,$WfRec));
}







1;
