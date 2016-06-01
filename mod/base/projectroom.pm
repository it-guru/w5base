package base::projectroom;
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
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'projectroom.id'),
                                                  
      new kernel::Field::Mandator(),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>'projectroom.mandator'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Projectroom short-name',
                dataobjattr   =>'projectroom.name'),

      new kernel::Field::Text(
                name          =>'projectname',
                label         =>'Project fullname',
                dataobjattr   =>'projectroom.fullname'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'projectroom.cistatus'),

      new kernel::Field::Contact(
                name          =>'databoss',
                label         =>'Databoss',
                vjoinon       =>'databossid'),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'projectroom.databoss'),

      new kernel::Field::Contact(
                name          =>'projectboss',
                vjoinon       =>'projectbossid',
                AllowEmpty    =>1,
                group         =>'commercial',
                label         =>'Project boss'),

      new kernel::Field::Link(
                name          =>'projectbossid',
                group         =>'commercial',
                dataobjattr   =>'projectroom.projectboss'),

      new kernel::Field::Contact(
                name          =>'projectboss2',
                vjoinon       =>'projectboss2id',
                AllowEmpty    =>1,
                group         =>'commercial',
                label         =>'deputy Project boss'),

      new kernel::Field::Link(
                name          =>'projectboss2id',
                group         =>'commercial',
                dataobjattr   =>'projectroom.projectboss2'),

      new kernel::Field::Date(
                name          =>'durationstart',
                label         =>'Projectroom start',
                dataobjattr   =>'projectroom.durationstart'),

      new kernel::Field::Date(
                name          =>'durationend',
                label         =>'Projectroom end',
                dataobjattr   =>'projectroom.durationend'),

      new kernel::Field::Text(
                name          =>'conumber',
                htmlwidth     =>'100px',
                group         =>'commercial',
                label         =>'Costcenter',
                weblinkto     =>'itil::costcenter',
                weblinkon     =>['conumber'=>'name'],
                dataobjattr   =>'projectroom.conumber'),

      new kernel::Field::Boolean(
                name          =>'iscommercial',
                group         =>'projectclass',
                htmlhalfwidth =>1,
                label         =>'commercial project',
                dataobjattr   =>'projectroom.is_commercial'),

      new kernel::Field::Boolean(
                name          =>'isallowlnkact',
                group         =>'projectclass',
                htmlhalfwidth =>1,
                label         =>'allow link of actions',
                dataobjattr   =>'projectroom.is_allowlnkact'),

      new kernel::Field::Boolean(
                name          =>'isrestirctiv',
                group         =>'projectclass',
                label         =>'restrictive task management',
                dataobjattr   =>'projectroom.is_isrestirctiv'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                vjointo       =>'base::lnkprojectroomcontact',
                class         =>'mandator',
                vjoinbase     =>[{'parentobj'=>\'base::projectroom'}],
                vjoininhash   =>['targetid','target','roles'],
                group         =>'contacts'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                label         =>'Comments',
                dataobjattr   =>'projectroom.comments'),

      new kernel::Field::FileList(
                name          =>'attachments',
                parentobj     =>'base::projectroom',
                label         =>'Attachments',
                group         =>'attachments'),


      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $rec=$param{current};
                   if (!defined($rec->{$self->Name()})){
                      return(0);
                   }
                   return(0);
                   return(1);
                },
                dataobjattr   =>'projectroom.additional'),

      new kernel::Field::SubList(
                name          =>'relations',
                label         =>'Relations',
                group         =>'relations',
                htmldetail    =>0,
                allowcleanup  =>1,
                readonly      =>1,
                vjointo       =>'base::lnkprojectroom',
                vjoinon       =>['id'=>'projectroomid'],
                vjoindisp     =>['parentobj','refid',
                                 'parentobjname','comments']),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Project description',
                dataobjattr   =>'projectroom.description'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'projectroom.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'projectroom.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                history       =>0,
                label         =>'Source-Load',
                dataobjattr   =>'projectroom.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'projectroom.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'projectroom.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'projectroom.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'projectroom.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'projectroom.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'projectroom.realeditor'),
   
      new kernel::Field::Link(
                name          =>'sectarget',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.target'),

      new kernel::Field::Link(
                name          =>'sectargetid',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.targetid'),

      new kernel::Field::Link(
                name          =>'secroles',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.croles'),

      new kernel::Field::QualityText(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'projectroom.lastqcheck'),
   );
   $self->{workflowlink}={ workflowkey=>[id=>'affectedprojectid']
                         };
   $self->{workflowlink}->{workflowstart}=\&calcWorkflowStart;
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->setDefaultView(qw(linenumber name projectname 
                            cistatus mandator mdate));
   $self->setWorktable("projectroom");
   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}





sub calcWorkflowStart
{
   my $self=shift;
   my $id=shift;
   my $r={};

   my %env=('frontendnew'=>'1');
   my $wf=getModuleObject($self->Config,"base::workflow");
   my @l=$wf->getSelectableModules(%env);

  # if (grep(/^base::workflow::task\$$/,@l)){
      $r->{'base::workflow::task'}={
                                      id=>sub{
                                         my $self=shift;
                                         my $rec=shift;
                                         my $q=shift;
                                         $q->{'Formated_tasktyp'}=
                                           "projectroom:".$rec->{id};
                                      }
                                    };
  # }
   return($r);
}




sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default projectclass commercial misc 
             control attachments contacts));
}


sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable left outer join lnkcontact ".
            "on lnkcontact.parentobj in ('base::projectroom') ".
            "and $worktable.id=lnkcontact.refid";

   return($from);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;
   
   if (!$self->IsMemberOf("admin")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"direct");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
          [$self->orgRoles()],"both");
      my @grpids=keys(%grps);
      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {mandatorid=>\@mandators},
                 {databossid=>$userid},
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"}
                ]);
   }
   return($self->SetFilter(@flt));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));

   $name=~s/\s+/_/g;
   if (length($name)<3 || haveSpecialChar($name) ||
       ($name=~m/^\d+$/) || # only numbers as application name is not ok!
       ($name=~m/\@/)){     # @ is in some cases invalid
      $self->LastMsg(ERROR,
           sprintf($self->T("invalid project name '%s' specified"),$name));
      return(0);
   }


   if (exists($newrec->{name}) && $newrec->{name} ne $name){
      $newrec->{name}=$name;
   }

   my $vname="durationstart";
   if (effChanged($oldrec,$newrec,$vname)){
      my $d=effVal($oldrec,$newrec,$vname);
      my $off=CalcDateDuration(NowStamp("en"),$d);
      if ($off->{totaldays}<-180){
         $self->LastMsg(ERROR,"projectroom start too far in the past");
         return(0)
      }
      if ($off->{totaldays}>14){
         $self->LastMsg(ERROR,"projectroom start too far in the future");
         return(0)
      }
   }

   my $vname="durationend";
   my $cistatusid=effVal($oldrec,$newrec,"cistatusid");
   if ($cistatusid>2 && $cistatusid<6){
      if (effVal($oldrec,$newrec,$vname) eq ""){
         $self->LastMsg(ERROR,"no projectroom end specified");
         return(0)
      }
   }
   if (effChanged($oldrec,$newrec,$vname)){
      my $d=effVal($oldrec,$newrec,$vname);
      my $off=CalcDateDuration(NowStamp("en"),$d);
      if ($off->{totaldays}<-14){ # max. 14 days in the past
         $self->LastMsg(ERROR,"projectroom end too far in the past");
         return(0)
      }
      if ($off->{totaldays}>730){  # max. 2 years in the future
         $self->LastMsg(ERROR,"projectroom end too far in the future");
         return(0)
      }
   }


   ########################################################################
   # standard security handling
   #
   if ($self->isDataInputFromUserFrontend()){
      my $userid=$self->getCurrentUserId();
      if (!defined($oldrec)){
         if (!defined($newrec->{databossid}) ||
             $newrec->{databossid}==0){
            if ($self->IsMemberOf("admin")){
               $self->LastMsg(ERROR,"no valid databoss defined");
               return(0);
            }
            else{
               my $userid=$self->getCurrentUserId();
               $newrec->{databossid}=$userid;
            }
         }
      }
      if (!$self->IsMemberOf("admin")){
         if (defined($newrec->{databossid}) &&
             $newrec->{databossid}!=$userid &&
             $newrec->{databossid}!=$oldrec->{databossid}){
            $self->LastMsg(ERROR,"you are not authorized to set other persons ".
                                 "as databoss");
            return(0);
         }
      }
   }
   if (exists($newrec->{conumber})){
      my $conumber=trim(effVal($oldrec,$newrec,"conumber"));
      if ($conumber ne ""){
         $conumber=~s/^0+//g;
         if (!($conumber=~m/^\d{5,13}$/)){
            my $fo=$self->getField("conumber");
            my $msg=sprintf($self->T("value of '%s' is not correct ".
                                     "numeric"),$fo->Label());
            $self->LastMsg(ERROR,$msg);
            return(0);
         }
         $newrec->{conumber}=$conumber;
      }
   }
   ########################################################################


   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"name"));
   return(1);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/project.jpg?".$cgi->query_string());
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   my @grps=qw(header default contacts projectclass history
               misc control attachments source);
   if ($rec->{iscommercial}){
      push(@grps,"commercial");
   }
   return(@grps);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   my @databossedit=qw(default contacts projectclass commercial
                       misc control attachments);
   if (!defined($rec)){
      return("default");
   }
   else{
      if ($rec->{databossid}==$userid){
         return(@databossedit);
      }
      if ($self->IsMemberOf("admin")){
         return(@databossedit);
      }
      if (defined($rec->{contacts}) && ref($rec->{contacts}) eq "ARRAY"){
         my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                                     ["RMember"],"both");
         my @grpids=keys(%grps);
         foreach my $contact (@{$rec->{contacts}}){
            if ($contact->{target} eq "base::user" &&
                $contact->{targetid} ne $userid){
               next;
            }
            if ($contact->{target} eq "base::grp"){
               my $grpid=$contact->{targetid};
               next if (!grep(/^$grpid$/,@grpids));
            }
            my @roles=($contact->{roles});
            @roles=@{$contact->{roles}} if (ref($contact->{roles}) eq "ARRAY");
            return(@databossedit) if (grep(/^write$/,@roles));
         }
      }
   }
   return;
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("base::projectroom");
}






1;
