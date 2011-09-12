package AL_TCom::workflow::change;
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
use itil::workflow::change;
use AL_TCom::lib::workflow;
@ISA=qw(itil::workflow::change AL_TCom::lib::workflow);

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
   $self->AddGroup("tcomcod");
   return($self->SUPER::Init(@_));
}

sub isOptionalFieldVisible
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   my $name=$param{field}->Name();

   return(1) if ($name eq "relations");
   return($self->SUPER::isOptionalFieldVisible($mode,%param));
}

sub getStepByShortname
{
   my $self=shift;
   my $name=shift;
   my $WfRec=shift;
   return("AL_TCom::workflow::change::".$name) if ($name eq "askpublishmode");

   return($self->SUPER::getStepByShortname($name,$WfRec));
}


sub addSRCLinkToFacility
{
   my $self=shift;
   my $d=shift;
   my $current=shift;

   if ($d ne ""){
      if (defined($current->{srcsys}) &&
          $current->{srcsys} ne ""){
         return("tssc::chm",['srcid'=>'changenumber']);
      }
   }
   return($self->SUPER::addSRCLinkToFacility($d,$current));

}






sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my @l=();
   
   return($self->SUPER::getDynamicFields(%param),
          $self->InitFields(
           new kernel::Field::Select(    name       =>'tcomcodrelevant',
                                         label      =>'Relevant',
                                         htmleditwidth=>'20%',
                                         value      =>['',qw(yes no)],
                                         group      =>'tcomcod',
                                         container  =>'headref'),

           #
           # Das Feld tcomcodchangetype kann demnaechst entfallen 
           # (Stand:02/2009)
           #
           new kernel::Field::Select(    name       =>'tcomcodchangetype',
                                         label      =>'Type',
                                         uivisible  =>0,
                                         value      =>[
                                         qw(customer
                                            noncustomer)],
                                         group      =>'tcomcod',
                                         container  =>'headref'),

           new kernel::Field::Select(    name       =>'tcomcodcause',
                                         label      =>'Activity',
                                         translation=>'AL_TCom::lib::workflow',
                                         default    =>'undef',
                                         value      =>
                             [AL_TCom::lib::workflow::tcomcodcause()],
                                         group      =>'tcomcod',
                                         container  =>'headref'),

           new kernel::Field::Select(    name        =>'tcomcodchmrisk',
                                         readonly    =>1,
                                         label       =>'Risk',
                                         htmleditwidth=>'20%',
                                         value       =>["low","medium",
                                                        "high","very high"],
                                         group       =>'tcomcod',
                                         container   =>'headref'),

           new kernel::Field::Textarea(  name        =>'tcomcodcomments',
                                         label       =>'Comments',
                                         group       =>'tcomcod',
                                         container   =>'headref'),

           new kernel::Field::Text(      name        =>'tcomexternalid',
                                         label       =>'ExternalID',
                                         group       =>'tcomcod',
                                         container   =>'headref'),

           new kernel::Field::Number(    name        =>'tcomworktime',
                                         unit        =>'min',
                                         label       =>'Worktime',
                                         onUnformat =>
                                      \&AL_TCom::lib::workflow::minUnformat,
                                         detailadd  =>
                                      \&AL_TCom::lib::workflow::tcomworktimeadd,
                                         group       =>'tcomcod',
                                         container   =>'headref'),
                                                   
           new kernel::Field::Number(    name        =>'truecustomerprio',
                                         label       =>'true customer prio',
                                         htmldetail  =>0,
                                         group       =>'affected',
                                         container   =>'headref'),

   ));
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated
   if (!$self->isRecordMandatorReadable($rec) &&
       !$self->isPostReflector($rec)){
      return("header","default","itilchange","affected","relations",
             "source","state");
   }
   return($self->SUPER::isViewValid($rec));
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated
   my @edit;

   return() if (!defined($rec));
   return() if ($rec->{stateid}==21);
   return() if (!($rec->{step}=~m/::postreflection$/));
   if ($self->isPostReflector($rec)){
      push(@edit,"tcomcod","affected");
   }

   return(@edit);  # ALL means all groups - else return list of fieldgroups
}


sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),"tcomcod","affected","relations");
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
          emailsignatur=>'ChangeNotification: GCU Telco');
   $self->linkMail($WfRec->{id},$id);
   if (my $r=$wf->Store($id,%d)){
      return(1);
   }
   return(0);
}



sub getNotifyDestinations
{
   my $self=shift;
   my $mode=shift;    # "direct" | "all"
   my $WfRec=shift;
   my $emailto=shift;
   my $emailcc=shift;
   my $ifappl=shift;

   if ($mode ne "ALTCOMmode"){
      return($self->SUPER::getNotifyDestinations($mode,
                                                 $WfRec,$emailto,$emailcc));
   }
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
   my $aa=getModuleObject($self->Config,"itil::lnkapplappl");
   my $aaflt=[{fromapplid=>$applid},
              {toapplid=>$applid}];
   $aa->SetFilter($aaflt);
   foreach my $aarec ($aa->getHashList(qw(fromapplid toapplid contype
                                        toapplcistatus))){
      next if ($aarec->{contype}==4 ||
               $aarec->{contype}==5 ||
               $aarec->{contype}==3 );   # uncritical  communications
      if (grep(/^$aarec->{fromapplid}$/,@$applid)){  # von mir eingetragen
         next if ($aarec->{toapplcistatus}>4);       # not active filter
         push(@ifid,$aarec->{toapplid});
      }
      else{                                          # von anderen eingetragen
         push(@ifid,$aarec->{fromapplid});
      }
   }

   my @fl=qw(tsmid tsm2id);
   if ($#ifid!=-1){
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
#printf STDERR ("fifi to=%s req=%s\n",Dumper($emailto),Dumper(\@tobyfunc));
#printf STDERR ("fifi cc=%s req=%s\n",Dumper($emailcc),Dumper(\@ccbyfunc));

   return(undef);
}



#######################################################################
package AL_TCom::workflow::change::askpublishmode;
use vars qw(@ISA);
use kernel;
@ISA=qw(itil::workflow::change::askpublishmode);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $info=Query->Param("PublishInfoMsg");
   if (!defined($info)){
      Query->Param("PublishInfoMsg"=>$self->getParent->T("MSG001"));
   }
   return($self->SUPER::generateWorkspace($WfRec));
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my %buttons=$self->SUPER::getPosibleButtons($WfRec);
   $buttons{"PublishTComMode"}=$self->T('AL-TCom Change notification');
   delete($buttons{BreakWorkflow});
   delete($buttons{NextStep});
   return(%buttons);
}

sub Process
{  
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "PublishTComMode"){
      Query->Param("PublishMode"=>"ALTCOMmode");
      if (defined($WfRec)){
         my @WorkflowStep=Query->Param("WorkflowStep");
         push(@WorkflowStep,$self->getParent->getStepByShortname(
                                            "publishpreview",$WfRec));
         Query->Param("WorkflowStep"=>\@WorkflowStep);
      }
   }
   return($self->SUPER::Process($action,$WfRec));
}  
   











1;
