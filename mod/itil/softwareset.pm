package itil::softwareset;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
                dataobjattr   =>'softwareset.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'softwareset.name'),

      new kernel::Field::Mandator(),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>'softwareset.mandator'),

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
                dataobjattr   =>'softwareset.cistatus'),

      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'softwareset.databoss'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                class         =>'mandator',
                vjoinbase     =>[{'parentobj'=>\'itil::softwareset'}],
                vjoininhash   =>['targetid','target','roles'],
                group         =>'contacts'),

      new kernel::Field::SubList(
                name          =>'software',
                label         =>'Software presets',
                group         =>'software',
                subeditmsk    =>'subedit.software',
                vjointo       =>'itil::lnksoftwaresoftwareset',
                vjoinon       =>['id'=>'softwaresetid'],
                vjoindisp     =>['fullname',"comparator",'versionexp'],
                vjoininhash   =>['fullname','softwareid','version','startwith',
                                 'releasekey','comparator']),

      new kernel::Field::SubList(
                name          =>'osrelease',
                label         =>'OS-Release presets',
                group         =>'osrelease',
                subeditmsk    =>'subedit.osrelease',
                vjointo       =>'itil::lnkosreleasesoftwareset',
                vjoinon       =>['id'=>'softwaresetid'],
                vjoindisp     =>['fullname',"comparator"],
                vjoininhash   =>['osreleaseid','comparator']),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                label         =>'Comments',
                dataobjattr   =>'softwareset.comments'),

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
                dataobjattr   =>'softwareset.additional'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'softwareset.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'softwareset.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                history       =>0,
                label         =>'Source-Load',
                dataobjattr   =>'softwareset.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'softwareset.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'softwareset.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'softwareset.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'softwareset.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'softwareset.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'softwareset.realeditor'),

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
   #             dataobjattr   =>'softwareset.lastqcheck'),
   #   new kernel::Field::QualityResponseArea()
   );
   $self->{use_distinct}=1;
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->setDefaultView(qw(linenumber name cistatus mandator mdate));
   $self->setWorktable("softwareset");
   return($self);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default software osrelease contacts misc control
             attachments source));
}


sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable left outer join lnkcontact ".
            "on lnkcontact.parentobj in ('itil::softwareset') ".
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

   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"fullname"));


   return(1);
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
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   $self->NotifyOnCIStatusChange($oldrec,$newrec);
   return($bak);
}

#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/softwareset.jpg?".$cgi->query_string());
#}



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

   my @databossedit=qw(default software osrelease contacts misc);
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
   }
   return(undef);
}



sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::softwareset");
}









1;
