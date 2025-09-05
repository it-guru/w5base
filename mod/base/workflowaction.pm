package base::workflowaction;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'10px',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'ActionID',
                dataobjattr   =>'wfaction.wfactionid'),
                                  
      new kernel::Field::Link(
                name          =>'ascid',        # only for other ordering
                label         =>'ActionID',  
                dataobjattr   =>'wfaction.wfactionid'),
                                  
      new kernel::Field::Text(
                name          =>'wfheadid',
                weblinkto     =>'base::workflow',
                weblinkon     =>['wfheadid'=>'id'],
                sqlorder      =>'none',
                label         =>'WorkflowID',
                dataobjattr   =>'wfaction.wfheadid'),

      new kernel::Field::Text(
                name          =>'wfname',
                vjointo       =>'base::workflow',
                vjoinon       =>['wfheadid'=>'id'],
                vjoindisp     =>'name',
                sqlorder      =>'none',
                group         =>['default','actiondata'],
                searchable    =>'0',
                label         =>'Workflow Name'),

      new kernel::Field::Text(
                name          =>'wfclass',
                vjointo       =>'base::workflow',
                vjoinon       =>['wfheadid'=>'id'],
                vjoindisp     =>'class',
                sqlorder      =>'none',
                htmldetail    =>'0',
                searchable    =>'0',
                label         =>'Workflow Class'),

      new kernel::Field::Text(
                name          =>'wfnature',
                vjointo       =>'base::workflow',
                vjoinon       =>['wfheadid'=>'id'],
                vjoindisp     =>'nature',
                sqlorder      =>'none',
                htmldetail    =>'0',
                searchable    =>'0',
                label         =>'Workflow Nature'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Action',
                sqlorder      =>'none',
                dataobjattr   =>'wfaction.name'),

      new kernel::Field::Text(
                name          =>'translation',
                label         =>'Translation Base',
                sqlorder      =>'none',
                dataobjattr   =>'wfaction.translation'),

      new kernel::Field::Select(
                name          =>'privatestate',
                group         =>'actiondata',
                sqlorder      =>'none',
                label         =>'Private State',
                transprefix   =>'privatestate.',
                value         =>['0','1'],
                dataobjattr   =>'wfaction.privatestate'),

      new kernel::Field::EffortNumber(
                name          =>'effort',
                sqlorder      =>'none',
                group         =>'booking',
                unit          =>'min',
                label         =>'Effort',
                dataobjattr   =>'wfaction.effort'),

      new kernel::Field::Date(
                name          =>'bookingdate',
                group         =>'booking',
                label         =>'Booking date',
                dataobjattr   =>'wfaction.bookingdate'),

      new kernel::Field::Textarea(
                name          =>'effortcomments',            # label for effort lists
                group         =>'actiondata',
                depend        =>['comments','effortlabel'],
                htmldetail    =>0,
                searchable    =>0,
                label         =>'effort description',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   return("$current->{effortlabel}:\n".$current->{comments});
                }),

      new kernel::Field::Text(
                name          =>'effortlabel',            # label for effort lists
                depend        =>['comments','wfheadid'],
                htmldetail    =>0,
                searchable    =>0,
                label         =>'effort label',
                dataobjattr   =>'wfhead.shortdescription'),

      new kernel::Field::Text(
                name          =>'creatorposix',            # posix id of creator contact
                depend        =>['creatorid'],
                htmldetail    =>0,
                searchable    =>0,
                group         =>'source',
                label         =>'creator posix',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;

                   my $user=getModuleObject($self->getParent->Config,"base::user");
                   $user->SetFilter({userid=>\$current->{creatorid}});
                   my ($urec,$msg)=$user->getOnlyFirst(qw(posix));

                   return($urec->{posix});
                }),

      new kernel::Field::Textarea(
                name          =>'comments',
                htmlheight    =>'auto',
                sqlorder      =>'none',
                group         =>'actiondata',
                label         =>'Comments',
                dataobjattr   =>'wfaction.comments'),

      new kernel::Field::Container(
                name        =>'additional',  # public 
                group       =>'additional',
                label       =>'Additional',  # informations
                uivisible   =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   return(1) if ($mode eq "ViewEditor");
                   my $rec=$param{current};
                   if (!defined($rec->{$self->Name()})){
                      return(0);
                   }
                   return(1);
                },
                dataobjattr =>'wfaction.additional'),

      new kernel::Field::Interface(
                name       =>'intiatornotify',
                container  =>'actionref',
                label      =>'send note to initiator'),

      new kernel::Field::Container(
                name        =>'actionref',   # secure
                group       =>'additional',
                label       =>'Action Ref',  # informations
                uivisible   =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   return(1) if ($self->getParent->IsMemberOf("admin"));
                   return(0);
                },
                dataobjattr =>'wfaction.actionref'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'wfaction.srcsys'),
                                  
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'wfaction.srcid'),
                                  
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'wfaction.srcload'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'wfaction.createuser'),

      new kernel::Field::Link(
                name          =>'creatorid',
                selectfix     =>1,
                label         =>'CreatorID',
                dataobjattr   =>'wfaction.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'wfaction.modifyuser'),

      new kernel::Field::MDate( 
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'wfaction.modifydate'),
                                  
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'wfaction.createdate'),
                                  
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'wfaction.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'wfaction.realeditor'),
   );
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->setDefaultView(qw(id name editor comments mdate));
   $self->setWorktable("wfaction");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable left outer join wfhead ".
            "on $worktable.wfheadid=wfhead.wfheadid ";

   return($from);
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   if ($name eq ""){
      $self->LastMsg(ERROR,"invalid action '%s' specified",$name);
      return(0);
   }
   my $translation=trim(effVal($oldrec,$newrec,"translation"));
   if ($translation eq ""){
      $newrec->{translation}=$self->Self;
   }
   my $owner=trim(effVal($oldrec,$newrec,"owner"));
   if ($owner!=0){
      $newrec->{owner}=$owner;
   }
   $newrec->{name}=$name;

   if (!defined($oldrec) && $newrec->{bookingdate} eq ""){
      $newrec->{bookingdate}=NowStamp("en");
   }
   if (effVal($oldrec,$newrec,"bookingdate") eq ""){
      $newrec->{bookingdate}=NowStamp("en");
   }
   if (exists($newrec->{intiatornotify}) &&
       ($newrec->{intiatornotify} eq "" ||
        $newrec->{intiatornotify} eq "0")){
      $newrec->{intiatornotify}=0;
   }

   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my %param=@_;
   my $userid=$self->getCurrentUserId();

   return("ALL") if ($self->IsMemberOf(["admin",
                                        "workflow.manager",
                                        "workflow.admin"]));
   return("ALL") if ($rec->{creator}==$userid);
   return(undef) if ($param{resultname} eq "HistoryResult" &&
                     $rec->{privatestate}>=1);
   return("header","default","booking","actiondata","source");
   # eine Analyse des betreffenden Workflows, ob "booking" sichtbar gemacht
   # werden darf, wäre an dieser Stelle zu aufwendig. Es existiert also ein
   # gap, dass man nativ die Workflow-Action-Efforts aller User auflisten 
   # könnte (per deeplink)
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my %param=@_;
   return("default","actiondata","booking") if ($self->IsMemberOf(["admin",
                                        "workflow.admin"]));
   if (defined($rec) && $rec->{wfheadid}>0){
      my $wf=$self->getPersistentModuleObject("wf","base::workflow");
      $wf->ResetFilter();
      $wf->SetFilter({id=>\$rec->{wfheadid}});
      my ($WfRec,$msg)=$wf->getOnlyFirst(qw(ALL));

      if (defined($WfRec)){
         return(undef) if ($WfRec->{stateid}>=20);
         my $userid=$self->getCurrentUserId();
         if (defined($rec) && $userid == $rec->{creatorid} &&
             $rec->{cdate} ne ""){
            my $d=CalcDateDuration($rec->{cdate},NowStamp("en"));
            if ($d->{totalminutes}<5000){ # modify only allowed for 3 days
               return("actiondata","booking");
            }
         }
         my @grps=$wf->isWriteValid($WfRec,%param);
         return("actiondata") if (grep(/^ALL$/,@grps) ||
                                  grep(/^actions$/,@grps) ||
                                  grep(/^flow$/,@grps));
      }
   }
   return(undef);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   return(1) if ($self->IsMemberOf(["admin","workflow.admin"]));
   return(0);
}

sub StoreRecord
{
   my $self=shift;
   my $wfheadid=shift;
   my $name=shift;
   my $data=shift;
   my $comments=shift;
   my $effort=shift;
   my $additional=shift;

   my %rec=%{$data};
   $rec{wfheadid}=$wfheadid;
   $rec{name}=$name;
   $rec{comments}=$comments;
   $rec{effort}=$effort if (defined($effort) && $effort!=0);
   $rec{additional}=$additional if (defined($additional) && 
                                  ref($additional) eq "HASH" &&
                                  keys(%$additional));

   if (!($rec{wfheadid}=~/^\d{3,20}$/)){
      $self->LastMsg(ERROR,"invalid wfheadid StoreRecord in StoreRecord");
      Stacktrace(); 
      return(0);
   }
   my $parent=$self->getParent();

   my $wf=$self->getPersistentModuleObject("wf","base::workflow");
   my ($WfRec,$class,$step)=$wf->getWfRec($wfheadid);

   if (!defined($WfRec)){
      $self->LastMsg(ERROR,"invalid wfheadid '$rec{wfheadid}' for ".
                           "StoreRecord in StoreRecord");
      Stacktrace(); 
      return(0);
   }
   my $bk=$self->ValidatedInsertRecord(\%rec);

   #######################################################################
   # Hack to call PostProcess in related Workflow (f.e. for 
   # postMail Handling)
   if ($bk){
      if (defined($wf->{SubDataObj}->{$class})){
         my $stepobj=$wf->{SubDataObj}->{$class}->getStepObject($self->Config,
                                                                $step);
         if (defined($stepobj)){
            my $bk=$stepobj->PostProcess("addWfAction.".$name,
                                         $WfRec,undef,%rec);
         }
      }
      else{
        msg(ERROR,"workflowaction StoreRecord class $class does not exist ".
                  "anymore - posible deleted workflow class");
        Stacktrace(1);
      }
   }
   #######################################################################


   return($bk);
}

sub NotifyForward
{
   my $self=shift;
   my $wfheadid=shift;
   my $fwdtarget=shift;
   my $fwdtargetid=shift;
   my $fwdname=shift;
   my $comments=shift;
   my %param=@_;
   my $emailcategory=["NotifyForward"];

   $param{mode}="FW:" if (!defined($param{mode}));  # default ist forward

   #printf STDERR ("fifi param=%s\n",Dumper(\%param));
   my $wf=getModuleObject($self->Config,"base::workflow");
   my $from;
   my @to=();
   msg(INFO,"forward: search in $fwdtarget id $fwdtargetid");
   if ($fwdtarget eq "base::user"){
      my $u=getModuleObject($self->Config,"base::user");
      $u->SetFilter(userid=>\$fwdtargetid);
      my ($rec,$msg)=$u->getOnlyFirst(qw(email));
      if (defined($rec)){
         push(@to,$rec->{email});
      }
      # if target is a base::user, from address must be correct set, to
      # get out of office notices. If target ist base::grp, fake from
      # can be used
      my $UserCache=$self->Cache->{User}->{Cache};
      if (defined($UserCache->{$ENV{REMOTE_USER}})){
         $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
      }
      if (defined($UserCache->{email}) &&
          $UserCache->{email} ne ""){
         $from=$UserCache->{email};
      }
   }
   elsif ($fwdtarget eq "base::grp"){
      my $grp=$self->{grp};
      if (!defined($grp)){
         $grp=getModuleObject($self->Config,"base::grp");
         $self->{grp}=$grp;
      }
      $grp->ResetFilter();
      if ($fwdtargetid ne ""){ 
         $grp->SetFilter(grpid=>\$fwdtargetid);
      }
      else{
         $grp->SetFilter(fullname=>\$fwdname);
      }
      my @acl=$grp->getHashList(qw(grpid users));
      my %u=();
      #msg(INFO,"d=%s",Dumper(\@acl));
      foreach my $grprec (@acl){
      #msg(INFO,"d=%s %s",ref($grprec->{users}),Dumper($grprec));
         if (defined($grprec->{users}) && ref($grprec->{users}) eq "ARRAY"){
            foreach my $usr (@{$grprec->{users}}){
               $u{$usr->{email}}=1;
            }
         }
      }
      @to=keys(%u);
   }
   if (defined($param{addtarget}) && ref($param{addtarget}) eq "ARRAY"){
      my $u=getModuleObject($self->Config,"base::user");
      foreach my $uid (@{$param{addtarget}}){
         $u->ResetFilter();
         $u->SetFilter(userid=>\$uid);
         my ($rec,$msg)=$u->getOnlyFirst(qw(email));
         if (defined($rec) && $rec->{email} ne ""){
            push(@to,$rec->{email});
         }
      }
   }
   my $wf=$self->{workflow};
   if (!defined($wf)){
      $wf=getModuleObject($self->Config,"base::workflow");
      $self->{workflow}=$wf;
   }
   my $subject=$self->Config->Param("SITENAME");
   $subject.=" " if ($subject ne "");
   $subject.=$self->T($param{mode});
   if (defined($param{forcesubject})){
      $subject.=" " if ($subject ne "");
      $subject.=$param{forcesubject};
   }
   else{
      my ($wfrec,$msg)=$wf->getOnlyFirst({id=>\$wfheadid},qw(name));
      if (defined($wfrec)){
         $subject.=" " if ($subject ne "" && $wfrec->{name} ne "");
         $subject.=$wfrec->{name};
      }
   }
   if ($self->Config->Param("W5BaseOperationMode") eq "dev"){ 
      msg(INFO,"forward subject: %s",$subject);
      msg(INFO,"forward    wfid: %s",$wfheadid);
      msg(INFO,"forward    from: %s",$from);
      msg(INFO,"forward      to: %s",join(", ",@to));
      msg(INFO,"forward comment: %s",$comments);
   }
   if ($#to==-1){
      msg(ERROR,"no mail send, because there is no target found");
      return;
   }
   my $workflowname="$wfheadid";
   if (defined($param{workflowname})){
      $workflowname="'".$param{workflowname}." ID:".$wfheadid."'";
   }
   if ($comments=~m/^\s*$/){
      if ($param{mode} eq "FW:"){
         $comments=sprintf($self->T(
           'The Workflow %s has been forwared to you without comments').".",
           $workflowname);
      }
      elsif ($param{mode} eq "APRREQ:"){
         $comments=sprintf($self->T(
           'An approve for Workflow %s has been requested to you without comments').".",
           $workflowname);
      }
   }
   else{
      if ($param{mode} eq "FW:"){
         $comments.="\n\n".sprintf($self->T(
           'The Workflow %s has been forwared to you').".",$workflowname);
      }
      elsif ($param{mode} eq "APRREQ:"){
         $comments.="\n\n".sprintf($self->T(
           'An approve for Workflow %s has been requested to you').".",
           $workflowname);
      }
      elsif ($param{mode} eq "INQUIRY:"){
         $comments.="\n\n".sprintf($self->T(
           'Please use the add note aktion in the workflow, to answer this inquiry').".",
           $workflowname);
      }
   }
   if ($param{mode} ne ""){
      my $modecategory=$param{mode};
      $modecategory=~s/:$//;
      push(@$emailcategory,"ForwardMode:$modecategory");
   }
   
   my $url=$self->getAbsolutByIdUrl($wfheadid,{dataobj=>'base::workflow'});

   if (defined($url)){
      $comments.="\n\n\n".$self->T("Edit").":\n";
      $comments.=$url;
      $comments.="\n\n";
   }
   my %adr=(emailfrom=>$from,
            emailto  =>\@to);

   if ($param{emailfrom} ne ""){
      $adr{emailfrom}=$param{emailfrom};
   }
   if ($adr{emailfrom} eq ""){
      delete($adr{emailfrom});
   }
   if ($param{sendercc}){
      if (defined($from) && $from ne 'no_reply@w5base.net'){
         $adr{emailcc}=[$from];
      }
      else{
         # get from out of UserCache
         my $UserCache=$self->Cache->{User}->{Cache};
         if (defined($UserCache->{$ENV{REMOTE_USER}})){
            $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
         }
         if (defined($UserCache->{email}) &&
             $UserCache->{email} ne ""){
            $adr{emailcc}=[$UserCache->{email}];
         }
      }
   }
   if (defined($param{sendcc})){
      $param{sendcc}=[$param{sendcc}] if (ref($param{sendcc}) ne "ARRAY");
      $adr{emailcc}=[] if (!defined($adr{emailcc}));
      push(@{$adr{emailcc}},@{$param{sendcc}});
   }

   if (defined($param{addcctarget}) && ref($param{addcctarget}) eq "ARRAY"){
      my $u=getModuleObject($self->Config,"base::user");
      foreach my $uid (@{$param{addcctarget}}){
         $u->ResetFilter();
         $u->SetFilter(userid=>\$uid);
         my ($rec,$msg)=$u->getOnlyFirst(qw(email));
         if (defined($rec) && $rec->{email} ne ""){
            $adr{emailcc}=[] if (!defined($adr{emailcc}));
            push(@{$adr{emailcc}},$rec->{email});
         }
      }
   }

   my $emailpostfix="";
   my $baseurl;
   if ($ENV{SCRIPT_URI} ne ""){
      $baseurl=$ENV{SCRIPT_URI};
      $baseurl=~s/\/auth\/.*$//;
   }
   my $jobbaseurl=$self->Config->Param("EventJobBaseUrl");
   if ($jobbaseurl ne ""){
      $jobbaseurl=~s#/$##;
      $baseurl=$jobbaseurl;
   }
   if (lc($ENV{HTTP_FRONT_END_HTTPS}) eq "on"){
      $baseurl=~s/^http:/https:/i;
   }

   if ($baseurl ne ""){
      my $lang=$self->Lang();
      $lang="?HTTP_ACCEPT_LANGUAGE=$lang";
      my $imgtitle="current state of workflow";
      $emailpostfix="<img title=\"$imgtitle\" class=status border=0 ".
             "src=\"$baseurl/public/base/workflow/ShowState/$wfheadid$lang\">";
   }

   my $labelhead=$self->T("LABEL:".$param{mode});
   if ($labelhead eq "LABEL:".$param{mode}){
      $labelhead=$param{mode};
   }
   if (!($labelhead=~m/:$/)){
      $labelhead.=":";
   }
   

   if (my $id=$wf->Store(undef,{
           class    =>'base::workflow::mailsend',
           step     =>'base::workflow::mailsend::dataload',
           directlnktype =>'base::workflow',
           directlnkid   =>$wfheadid,
           directlnkmode =>"mail.".$param{mode},
           name     =>$subject,%adr,
           emailhead=>$labelhead,
           emailpostfix=>$emailpostfix,
           emailtext=>$comments,
           emailcategory=>$emailcategory
          })){
      my %d=(step=>'base::workflow::mailsend::waitforspool');
      my $r=$wf->Store($id,%d);
   }
}

sub Notify
{
   my $self=shift;
   my $mode=shift;   # INFO | WARN | ERROR
   my $subject=shift;
   my $text=shift;
   my %param=@_;

   my $sitename=$self->Config->Param("SiteName");
   $sitename="W5Base" if ($sitename eq "");


   my $wf=getModuleObject($self->Config,"base::workflow");
   my $name;
   if ($mode ne ""){
      $name=$sitename.": ".$mode.": ".$subject;
   }
   else{
      $name=$subject;
   }

   if (defined($param{dataobj}) &&
       defined($param{dataobjid})){
      my $url=$wf->getAbsolutByIdUrl($param{dataobjid},{
         dataobj=>$param{dataobj}
      });
      if (defined($url)){
         $text.="\nDirectLink:\n";
         $text.=$url;
         $text.="\n\n";
      }
   }
   if ($param{faqkey} ne ""){
      my $faq=getModuleObject($self->Config(),"faq::article");
      if (defined($faq)){
         my $further=$faq->getRawArticles($param{faqkey});
         if ($further ne ""){
            $text.=$further;
         }
      }
   }




   my %mailset=(class    =>'base::workflow::mailsend',
                step     =>'base::workflow::mailsend::dataload',
                name     =>$name,
                emailtext=>$text);

   #
   # If infoHash is specified, the Information will be checked, if
   # the same information is within the last 24h is already mailed.
   # If it is, not additional mail will be generated.
   #
   if (exists($param{infoHash}) &&
       $param{infoHash} ne ""){ # reduce doublicate mails
      $mailset{md5sechash}=$param{infoHash}; # md5sechash used as store
      $wf->SetFilter({md5sechash=>\$mailset{md5sechash},
                      createdate=>'>now-1d'});
      my @l=$wf->getHashList(qw(createdate id));
      if ($#l!=-1){
         return();
      }
      $wf->ResetFilter();
   }


   foreach my $target (qw(emailfrom emailto emailcc emailbcc)){
      if (exists($param{$target})){
         if (ref($param{$target}) ne "ARRAY"){
            $param{$target}=[split(/[;,]/,$param{$target})];
         }
      }
   }
   if ($param{adminbcc}){
      $param{emailbcc}=[] if (!defined($param{emailbcc}));
      my $grpuser=getModuleObject($self->Config,"base::lnkgrpuser");
      $grpuser->SetFilter({grpid=>\'1'});
      foreach my $lnkrec ($grpuser->getHashList(qw(userid roles))){
         if (ref($lnkrec->{roles}) eq "ARRAY"){
            if (grep(/^(RMember)$/,@{$lnkrec->{roles}})){
               push(@{$param{emailbcc}},$lnkrec->{userid});
            }
         }
      }

   }
   my $user=getModuleObject($self->Config,"base::user");
   my $grp=getModuleObject($self->Config,"base::grp");
   foreach my $target (qw(emailfrom emailto emailcc emailbcc)){
      if (exists($param{$target})){
         for(my $c=0;$c<=$#{$param{$target}};$c++){
            if ($param{$target}->[$c]=~m/^\d{10,20}$/){  # target is a userid
               $user->ResetFilter();
               $user->SetFilter({userid=>\$param{$target}->[$c],
                                 cistatusid=>"<6"});
               my ($urec)=$user->getOnlyFirst(qw(fullname email));
               if (defined($urec)){
                  if ($target eq "emailfrom" && $param{$target."fake"}){
                     $param{$target}->[$c]="\"".$urec->{fullname}."\" <>";
                  }
                  else{
                     $param{$target}->[$c]=$urec->{email};
                  }
               }
               else{
                  $param{$target}->[$c]=undef;
               }
             #  else{
             #     $param{$target}->[$c]='"invalid ref($param{$target}->[$c])" '.
             #                           '<null\@network>';
             #  }
            }
            elsif (my ($group)=
                      $param{$target}->[$c]=~m/^groupmembers:(\S+)$/){ # w5group
               $grp->ResetFilter();
               $grp->SetFilter({fullname=>\$group,
                                 cistatusid=>"<6"});
               my ($grec)=$grp->getOnlyFirst(qw(users));
               if (defined($grp)){
                  $param{$target}->[$c]=undef;
                  foreach my $u (@{$grec->{users}}){
                     if (!in_array($param{$target},$u->{email})){
                        push(@{$param{$target}},$u->{email});
                     }
                  }
               }
            }
            elsif ($param{$target}->[$c]=~m/^W5SUPPORT$/){ # target central Sup
               $user->ResetFilter();
               $user->SetFilter({isw5support=>\'1',
                                 cistatusid=>"<6"});
               my ($urec)=$user->getOnlyFirst(qw(email));
               if (defined($urec)){
                  $param{$target}->[$c]=$urec->{email};
               }
            }
            elsif ($param{$target}->[$c]=~m/^[a-z0-9]{2,8}$/){ # target posixid
               $user->ResetFilter();
               $user->SetFilter({posix=>\$param{$target}->[$c],
                                 cistatusid=>"<6"});
               my ($urec)=$user->getOnlyFirst(qw(email));
               if (defined($urec)){
                  $param{$target}->[$c]=$urec->{email};
               }
               else{
                  $param{$target}->[$c]='"invalid ref($param{$target}->[$c])" '.
                                        '<null\@network>';
               }
            }
            else{  # target is already a email address
               my $x;
            }
         }
      }
   }
   foreach my $target (qw(emailto emailcc emailbcc emailtemplate 
                          allowsms smstext emailcategory)){
      if (exists($param{$target})){
         $mailset{$target}=$param{$target};
      }
   }
   if (!exists($param{emailfrom})){
      $mailset{emailfrom}="\"W5Base-Notify\" <none\@null.com>";
      $mailset{emailfrom}="\"W5Base-Notify\" <>"; # is better, because no
   }                                              # out of office notes goes
   else{                                          # to the internet
      $mailset{emailfrom}=$param{emailfrom};
   }

   if (my $id=$wf->Store(undef,\%mailset)){
      my %d=(step=>'base::workflow::mailsend::waitforspool');
      my $r=$wf->Store($id,%d);
   }
}


sub getEffortSelect
{
   my $self=shift;
   my $name=shift;

   my @t=(''=>'',
          '10'=>'10 min',
          '20'=>'20 min',
          '30'=>'30 min',
          '40'=>'40 min',
          '50'=>'50 min',
          '60'=>'1 h',
          '90'=>'1,5 h',
          '120'=>'2 h',
          '150'=>'2,5 h',
          '180'=>'3 h',
          '210'=>'3,5 h',
          '240'=>'4 h',
          '300'=>'5 h',
          '360'=>'6 h',
          '420'=>'7 h',
          '480'=>'1 day',
          '720'=>'1,5 days',
          '960'=>'2 days');

   my $d="<select name=\"$name\" style=\"width:80px\">";
   my $oldval=Query->Param("Formated_effort");
   while(defined(my $min=shift(@t))){
      my $l=shift(@t);
      $d.="<option value=\"$min\"";
      $d.=" selected" if ($min==$oldval);
      $d.=">$l</option>";
   }
   $d.="</select>";
   return($d);

}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   if ($newrec->{name} eq "forwardto" || 
       ($newrec->{name} eq "reactivate" &&
        $self->Config->Param("W5BaseOperationMode") ne "test")){
      my %add=Datafield2Hash($newrec->{additional});
      my $fwdtarget=$add{ForwardTarget}->[0];
      my $fwdtargetid=$add{ForwardTargetId}->[0];
      my $fwdname=$add{ForwardToName}->[0];
      if ($newrec->{name} eq "reactivate"){
         my $wfheadid=effVal($oldrec,$newrec,"wfheadid");
         my $wf=getModuleObject($self->Config,"base::workflow");
         $wf->SetFilter({id=>\$wfheadid});
         my ($wfrec,$msg)=$wf->getOnlyFirst(qw(fwdtarget fwdtargetid 
                                               fwdtargetname)); 
         if (defined($wfrec)){
            $fwdtarget=$wfrec->{fwdtarget};
            $fwdtargetid=$wfrec->{fwdtargetid};
            $fwdname=$wfrec->{fwdtargetname};
         }
      }
      my $comments=$newrec->{comments};
      my $wfid=$newrec->{wfheadid};
      if ($fwdtarget ne "" && $fwdtargetid ne ""){
         $self->NotifyForward($wfid,$fwdtarget,$fwdtargetid,$fwdname,$comments);
      }
   }

   return($self->SUPER::FinishWrite($oldrec,$newrec));
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","actiondata","booking","default","additional","source");
}


package kernel::Field::EffortNumber;

use strict;
use vars qw(@ISA);
@ISA=qw(kernel::Field::Number);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;
   return(undef) if ($FormatAs eq "SOAP" ||
                     $FormatAs eq "XMLV01"); # security !!!
   if ($FormatAs eq "HtmlDetail" || $FormatAs eq "edit"){
      return($self->SUPER::FormatedDetail($current,$FormatAs));
   } 
   my $userid=$self->getParent->getCurrentUserId();
   return(undef) if ($FormatAs ne "HtmlWfActionlog" && 
                     $userid ne $current->{creatorid}); # security !!!
   return($self->SUPER::FormatedDetail($current,$FormatAs));
}



1;
