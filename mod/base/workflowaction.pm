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
use Data::Dumper;
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

      new kernel::Field::Number(
                name          =>'effort',
                sqlorder      =>'none',
                group         =>'actiondata',
                unit          =>'min',
                label         =>'Effort',
                dataobjattr   =>'wfaction.effort'),

      new kernel::Field::Textarea(
                name          =>'comments',
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
                name        =>'srcsys',
                group       =>'source',
                label       =>'Source-System',
                dataobjattr =>'wfaction.srcsys'),
                                  
      new kernel::Field::Text(
                name        =>'srcid',
                group       =>'source',
                label       =>'Source-Id',
                dataobjattr =>'wfaction.srcid'),
                                  
      new kernel::Field::Date(
                name        =>'srcload',
                group       =>'source',
                label       =>'Last-Load',
                dataobjattr =>'wfaction.srcload'),

      new kernel::Field::Creator(
                name        =>'creator',
                group       =>'source',
                label       =>'Creator',
                dataobjattr =>'wfaction.createuser'),

      new kernel::Field::Link(
                name          =>'creatorid',
                label         =>'CreatorID',
                dataobjattr   =>'wfaction.createuser'),

      new kernel::Field::Owner(
                name        =>'owner',
                group       =>'source',
                label       =>'Owner',
                dataobjattr =>'wfaction.modifyuser'),

      new kernel::Field::MDate( 
                name        =>'mdate',
                group       =>'source',
                label       =>'Modification-Date',
                dataobjattr =>'wfaction.modifydate'),
                                  
      new kernel::Field::CDate(
                name        =>'cdate',
                group       =>'source',
                label       =>'Creation-Date',
                dataobjattr =>'wfaction.createdate'),
                                  
      new kernel::Field::Editor(
                name        =>'editor',
                group       =>'source',
                label       =>'Editor',
                dataobjattr =>'wfaction.editor'),

      new kernel::Field::RealEditor(
                name        =>'realeditor',
                group       =>'source',
                label       =>'RealEditor',
                dataobjattr =>'wfaction.realeditor'),
   );
   $self->{history}=[qw(insert modify delete)];

   $self->setDefaultView(qw(id name editor comments mdate));
   $self->setWorktable("wfaction");
   return($self);
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
   return("header","default","actiondata","source");
   # eine Analyse der Action wäre zu aufwendig
#   if (defined($rec) && $rec->{wfheadid}>0){
#      my $wf=$self->getPersistentModuleObject("wf","base::workflow");
#      $wf->ResetFilter();
#      $wf->SetFilter({id=>\$rec->{wfheadid}});
#      my ($WfRec,$msg)=$wf->getOnlyFirst(qw(ALL));
#      if (defined($WfRec)){
#         my @grps=$wf->isViewValid($WfRec,%param);
#         return("ALL") if (grep(/^ALL$/,@grps) ||
#                           grep(/^actions$/,@grps) ||
#                           grep(/^flow$/,@grps));
#      }
#   }
#   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my %param=@_;
   return("default","actiondata") if ($self->IsMemberOf(["admin",
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
               return("actiondata");
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

   my %rec=%{$data};
   $rec{wfheadid}=$wfheadid;
   $rec{name}=$name;
   $rec{comments}=$comments;
   $rec{effort}=$effort if (defined($effort) && $effort!=0);
   return($self->ValidatedInsertRecord(\%rec));
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

   $param{mode}="FW:" if (!defined($param{mode}));  # default ist forward

   my $wf=getModuleObject($self->Config,"base::workflow");
   my $from='no_reply@w5base.net';
   my @to=();
   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   if (defined($UserCache->{email}) &&
       $UserCache->{email} ne ""){
      $from=$UserCache->{email};
   }
   msg(INFO,"forward: search in $fwdtarget id $fwdtargetid");
   if ($fwdtarget eq "base::user"){
      my $u=getModuleObject($self->Config,"base::user");
      $u->SetFilter(userid=>\$fwdtargetid);
      my ($rec,$msg)=$u->getOnlyFirst(qw(email));
      if (defined($rec)){
         push(@to,$rec->{email});
      }
   }
   if ($fwdtarget eq "base::grp"){
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
   my $wf=$self->{workflow};
   if (!defined($wf)){
      $wf=getModuleObject($self->Config,"base::workflow");
      $self->{workflow}=$wf;
   }
   my $subject=$self->Config->Param("SITENAME");
   $subject.=" " if ($subject ne "");
   $subject.=$self->T($param{mode});
   my ($wfrec,$msg)=$wf->getOnlyFirst({id=>\$wfheadid},qw(name));
   if (defined($wfrec)){
      $subject.=" " if ($subject ne "" && $wfrec->{name} ne "");
      $subject.=$wfrec->{name};
   }

   msg(INFO,"forward subject: %s",$subject);
   msg(INFO,"forward    wfid: %s",$wfheadid);
   msg(INFO,"forward    from: %s",$from);
   msg(INFO,"forward      to: %s",join(", ",@to));
   msg(INFO,"forward comment: %s",$comments);
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
   }
   my $baseurl;
   if ($ENV{SCRIPT_URI} ne ""){
      $baseurl=$ENV{SCRIPT_URI};
      $baseurl=~s/\/auth\/.*$//;
      my $url=$baseurl;
      $url.="/auth/base/workflow/ById/".$wfheadid;
      $comments.="\n\n\n".$self->T("Edit").":\n";
      $comments.=$url;
      $comments.="\n\n";
   }
   else{
      my $baseurl=$self->Config->Param("EventJobBaseUrl");
      $baseurl.="/" if (!($baseurl=~m/\/$/));
      my $url=$baseurl;
      $url.="auth/base/workflow/ById/".$wfheadid;
      $comments.="\n\n\n".$self->T("Edit").":\n";
      $comments.=$url;
      $comments.="\n\n";
   }
   my %adr=(emailfrom=>$from,
            emailto  =>\@to);

   if ($param{sendercc} && $from ne 'no_reply@w5base.net'){
      $adr{emailcc}=[$from];
   }
   if (defined($param{sendcc})){
      $param{sendcc}=[$param{sendcc}] if (ref($param{sendcc}) ne "ARRAY");
      $adr{emailcc}=[] if (!defined($adr{emailcc}));
      push(@{$adr{emailcc}},@{$param{sendcc}});
   }
   my $emailpostfix="";
   if ($baseurl ne ""){
      my $lang=$self->Lang();
      $lang="?HTTP_ACCEPT_LANGUAGE=$lang";
      my $imgtitle="current state of workflow";
      $emailpostfix="<img title=\"$imgtitle\" class=status border=0 ".
             "src=\"$baseurl/public/base/workflow/ShowState/$wfheadid$lang\">";
   }

   if (my $id=$wf->Store(undef,{
           class    =>'base::workflow::mailsend',
           step     =>'base::workflow::mailsend::dataload',
           name     =>$subject,%adr,
           emailhead=>$self->T("LABEL:".$param{mode}).":",
           emailpostfix=>$emailpostfix,
           emailtext=>$comments,
          })){
      my %d=(step=>'base::workflow::mailsend::waitforspool');
      my $r=$wf->Store($id,%d);
   }
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   if ($newrec->{name} eq "forwardto"){
      printf STDERR ("workflow action forward\n");
      my %add=Datafield2Hash($newrec->{additional});
      my $fwdtarget=$add{ForwardTarget}->[0];
      my $fwdtargetid=$add{ForwardTargetId}->[0];
      my $fwdname=$add{ForwardToName}->[0];
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
   return("header","default","actiondata","additional","source");
}




1;
