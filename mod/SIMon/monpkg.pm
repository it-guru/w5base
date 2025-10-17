package SIMon::monpkg;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
   $param{MainSearchFieldLines}=3;

   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'simonpkg.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'simonpkg.name'),

      new kernel::Field::Mandator(),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>'simonpkg.mandator'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                default       =>'4',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'cistatusid',
                default       =>'2',
                label         =>'CI-StateID',
                dataobjattr   =>'simonpkg.cistatus'),


      #new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'simonpkg.databoss'),

      new kernel::Field::Select(
                name          =>'restrictarget',
                label         =>'target state',
                transprefix   =>'TARGET.',
                htmleditwidth =>'200px',
                translation   =>'SIMon::lnkmonpkgrec',
                value         =>[qw(MAND RECO MONI)],
                dataobjattr   =>'simonpkg.restrictarget'),

      new kernel::Field::TextDrop(
                name          =>'managergrp',
                htmlwidth     =>'300px',
                label         =>'exception approver group',
                vjointo       =>'base::grp',
                AllowEmpty    =>1,
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['managergrpid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'managergrpid',
                dataobjattr   =>'simonpkg.managergrpid'),

      new kernel::Field::Textarea(
                name          =>'restriction',
                label         =>'logical system restriction',
                dataobjattr   =>'simonpkg.restriction'),

      new kernel::Field::SubList(
                name          =>'software',
                label         =>'Software',
                group         =>'software',
                subeditmsk    =>'subedit.software',
                vjointo       =>'SIMon::lnkmonpkgsoftware',
                vjoinon       =>['id'=>'monpkgid'],
                vjoindisp     =>['software']),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                class         =>'mandator',
                vjoinbase     =>[{'parentobj'=>\'SIMon::monpkg'}],
                vjoininhash   =>['targetid','target','roles'],
                group         =>'contacts'),

      new kernel::Field::Textarea(
                name          =>'notifycomments',
                group         =>'misc',
                label         =>'notify comments',
                dataobjattr   =>'simonpkg.comments'),

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
                dataobjattr   =>'simonpkg.additional'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'simonpkg.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'simonpkg.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                history       =>0,
                label         =>'Source-Load',
                dataobjattr   =>'simonpkg.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'simonpkg.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'simonpkg.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'simonpkg.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'simonpkg.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'simonpkg.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'simonpkg.realeditor'),

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


   #   new kernel::Field::IssueState(),
   #   new kernel::Field::QualityText(),
   #   new kernel::Field::QualityState(),
   #   new kernel::Field::QualityOk(),
   #   new kernel::Field::QualityLastDate(
   #             dataobjattr   =>'simonpkg.lastqcheck'),
   #   new kernel::Field::QualityResponseArea()
   );
   $self->{use_distinct}=1;
   $self->{history}={
      update=>[
         'local'
      ]
   };

   $self->{CI_Handling}={uniquename=>"name",
                         activator=>["admin","w5base.SIMon.monpkg"],
                         uniquesize=>255};

   $self->setDefaultView(qw(name cistatus restrictarget mdate));
   $self->setWorktable("simonpkg");
   return($self);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default software contacts misc source));
}


sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable left outer join lnkcontact ".
            "on lnkcontact.parentobj in ('SIMon::monpkg') ".
            "and $worktable.id=lnkcontact.refid";

   return($from);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   ########################################################################
   # standard security handling
   #
   if ($self->isDataInputFromUserFrontend()){
      my $userid=$self->getCurrentUserId();
      if (!defined($oldrec)){
         if (!defined($newrec->{databossid}) ||
             $newrec->{databossid}==0){
            $newrec->{databossid}=$userid;
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
   ########################################################################
   my $name=effVal($oldrec,$newrec,"name");

   if (effVal($oldrec,$newrec,"cistatusid")>5){
      $name=~s/\[[0-9]+\]$//;
   }
   if (!($name=~m/[a-z0-9_-]/i)){
      $self->LastMsg(ERROR,"invalid installation package name");
      return(0);
   }

   my $rest=effVal($oldrec,$newrec,"restriction");
   if ($rest ne ""){
      my $p=new Text::ParseWhere();
      if (!defined($p->compileExpression($rest))){
         if ($p->errString()){
            $self->LastMsg(ERROR,$p->errString());
         }
         else{
            $self->LastMsg(ERROR,"invalid restriction expression");
         }
         return(undef);
      }
   }



   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"name"));


   return(1);
}


sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $wrgroups=shift;

   my $userid=$self->getCurrentUserId();
   if (defined($oldrec) && $oldrec->{userid}==$userid){
      delete($newrec->{cistatusid});
   }
   else{
      if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
         return(0);
      }
   }
   return($self->SUPER::SecureValidate($oldrec,$newrec,$wrgroups));
}




sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf("admin") && 
       $W5V2::OperationContext ne "W5Replicate"){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
          [orgRoles(),qw(RCFManager RCFManager2 RAuditor RMonitor)],"both");
      my @grpids=keys(%grps);
      my $userid=$self->getCurrentUserId();
      push(@flt,[
         {mandatorid=>\@mandators},
         {databossid=>$userid},
         {creator=>$userid},
         {sectargetid=>\$userid,sectarget=>\'base::user',
          secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                    "*roles=?read?=roles*"},
         {sectargetid=>\@grpids,sectarget=>\'base::grp',
          secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                    "*roles=?read?=roles*"},
      ]);
   }
   return($self->SetFilter(@flt));
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }

   return(1);
}




sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/SIMon/load/monpkg.jpg?".$cgi->query_string());
}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   return("header","default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   my @databossedit=qw(default software contacts misc);
   if (!defined($rec)){
      return(@databossedit);
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
      my @chkgroups;
      push(@chkgroups,$rec->{mandatorid}) if ($rec->{mandatorid} ne "");
      if ($#chkgroups!=-1){
         if ($self->IsMemberOf(\@chkgroups,["RDataAdmin"],"down")){
            return(@databossedit);
         }
      }
      if ($rec->{managergrpid} ne "" &&
          $self->IsMemberOf($rec->{managergrpid})){
         return("misc")
      }
   }
   return(undef);
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("SIMon::monpkg");
}









1;
