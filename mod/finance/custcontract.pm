package finance::custcontract;
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
   $param{MainSearchFieldLines}=4;

   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'custcontract.id'),
                                                  
      new kernel::Field::Mandator(),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>'custcontract.mandator'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Contract Number',
                dataobjattr   =>'custcontract.name'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Contract Name',
                dataobjattr   =>'custcontract.fullname'),

      new kernel::Field::Text(
                name          =>'conumber',
                htmlwidth     =>'100px',
                label         =>'CO-Number',
                weblinkto     =>'itil::costcenter',
                weblinkon     =>['conumber'=>'name'],
                dataobjattr   =>'custcontract.conumber'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'custcontract.cistatus'),

      new kernel::Field::TextDrop(
                name          =>'customer',
                SoftValidate  =>1,
                label         =>'Customer',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['customerid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'customerid',
                dataobjattr   =>'custcontract.customer'),


      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'custcontract.databoss'),


      new kernel::Field::Contact(
                name          =>'contructcoord',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                label         =>'Contruct Coordinator',
                vjoinon       =>'contructcoordid'),

      new kernel::Field::Link(
                name          =>'contructcoordid',
                dataobjattr   =>'custcontract.contractcoord'),



      new kernel::Field::Date(
                name          =>'durationstart',
                label         =>'Duration Start',
                dataobjattr   =>'custcontract.durationstart'),

      new kernel::Field::Date(
                name          =>'durationend',
                label         =>'Duration End',
                dataobjattr   =>'custcontract.durationend'),

      new kernel::Field::Select(
                name          =>'autoexpansion',
                label         =>'Auto Expansion',
                transprefix   =>'autoexpansion.',
                htmleditwidth =>'150px',
                value         =>[qw(0 1 2 3 6 12 18 24 36)],
                dataobjattr   =>'custcontract.autoexpansion'),

      new kernel::Field::Select(
                name          =>'cancelperiod',
                label         =>'Cancel Period',
                transprefix   =>'cancelperiod.',
                htmleditwidth =>'150px',
                value         =>[qw(0 1 2 3 6 12 18 24 36)],
                dataobjattr   =>'custcontract.cancelperiod'),


      new kernel::Field::TextDrop(
                name          =>'responseteam',
                group         =>'sem',
                htmlwidth     =>'300px',
                label         =>'CBM Team',
                vjointo       =>'base::grp',
                vjoinon       =>['responseteamid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'responseteamid',
                group         =>'sem',
                dataobjattr   =>'custcontract.responseteam'),

      new kernel::Field::TextDrop(
                name          =>'sem',
                group         =>'sem',
                label         =>'Customer Business Manager',
                vjointo       =>'base::user',
                vjoinon       =>['semid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'semid',
                group         =>'sem',
                dataobjattr   =>'custcontract.sem'),

      new kernel::Field::TextDrop(
                name          =>'sem2',
                group         =>'sem',
                label         =>'Debuty Customer Business Manager',
                vjointo       =>'base::user',
                vjoinon       =>['sem2id'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'sem2id',
                group         =>'sem',
                dataobjattr   =>'custcontract.sem2'),

      new kernel::Field::Import( $self,
                vjointo       =>'itil::costcenter',
                vjoinon       =>['conumber'=>'name'],
                dontrename    =>1,
                group         =>'delmgmt',
                fields        =>[qw(delmgr   delmgr2
                                    delmgrid delmgr2id
                                    delmgrteam
                                    delmgrteamid)]),

      new kernel::Field::SubList(
                name          =>'modules',
                label         =>'active modules',
                group         =>'modules',
                ignViewValid  =>1,
                allowcleanup  =>1,
                vjointo       =>'finance::custcontractmod',
                vjoinon       =>['id'=>'contractid'],
                vjoininhash   =>['rawname'],
                vjoindisp     =>['name']),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                class         =>'mandator',
                vjoinbase     =>[{'parentobj'=>\'finance::custcontract'}],
                vjoininhash   =>['targetid','target','roles'],
                group         =>'contacts'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                label         =>'Comments',
                dataobjattr   =>'custcontract.comments'),

      new kernel::Field::FileList(
                name          =>'attachments',
                parentobj     =>'finance::custcontract',
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
                dataobjattr   =>'custcontract.additional'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'custcontract.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'custcontract.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                history       =>0,
                label         =>'Source-Load',
                dataobjattr   =>'custcontract.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'custcontract.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'custcontract.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'custcontract.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'custcontract.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'custcontract.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'custcontract.realeditor'),
   
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
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'custcontract.lastqcheck'),
   );
   $self->{use_distinct}=1;
   $self->{history}=[qw(modify delete)];
   $self->{workflowlink}={ workflowkey=>[id=>'affectedcontractid']
                         };
   $self->setDefaultView(qw(linenumber name cistatus mandator mdate fullname));
   $self->setWorktable("custcontract");
   return($self);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default sem delmgmt modules 
             contacts control misc attachments));
}


sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable left outer join lnkcontact ".
            "on lnkcontact.parentobj in ('finance::custcontract') ".
            "and $worktable.id=lnkcontact.refid";

   return($from);
}

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}






sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;
   
   if (!$self->IsMemberOf("admin")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                              [orgRoles(),qw(RMember RCFManager RCFManager2
                               RAuditor RMonitor)],"both");
      my @grpids=keys(%grps);
      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {mandatorid=>\@mandators},
                 {semid=>$userid},
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"},
                 {sem2id=>$userid}
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
   if (($name=~m/[\s,äöüß]/i) || ($name=~m/^\s*$/)){
      $self->LastMsg(ERROR,"invalid contract number '%s' specified",$name);
      return(0);
   }
   if (exists($newrec->{name}) && $newrec->{name} ne $name){
      $newrec->{name}=$name;
   }
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
   if (exists($newrec->{conumber}) && $newrec->{conumber} ne ""){
      if (!$self->finance::costcenter::ValidateCONumber("conumber",
          $oldrec,$newrec)){
         $self->LastMsg(ERROR,
             $self->T("invalid number format '\%s' specified",
                      "finance::costcenter"),$newrec->{conumber});
         return(0);
      }
   }

   my $durationstart=trim(effVal($oldrec,$newrec,"durationstart"));
   if ((!defined($oldrec) || exists($newrec->{durationstart})) &&
       $durationstart eq ""){
      $self->LastMsg(ERROR,"no duration start defined");
      return(0);
   }
   ########################################################################

#   if ($self->isDataInputFromUserFrontend()){
#      if (!$self->isWriteOnApplValid($applid,"systems")){
#         $self->LastMsg(ERROR,"no access");
#         return(undef);
#      }
#   }


   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"name"));
   return(1);
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

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/contract.jpg?".$cgi->query_string());
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

   my @databossedit=qw(default contacts sem misc control modules attachments);
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
      push(@chkgroups,$rec->{responseteamid}) if ($rec->{responseteamid} ne "");
      if ($#chkgroups!=-1){
         if ($self->IsMemberOf(\@chkgroups,["RControlling",
                                            "RCFManager","RCFManager2",
                                            "RDataAdmin"],"down")){
            return(@databossedit);
         }
      }
   }
   return(undef);
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("finance::custcontract");
}






1;
