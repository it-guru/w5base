package crm::businessprocess;
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
use crm::lib::Listedit;
@ISA=qw(crm::lib::Listedit);

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
                dataobjattr   =>'businessprocess.id'),

      new kernel::Field::Mandator(),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>'businessprocess.mandator'),

     new kernel::Field::TextDrop(
                name          =>'customer',
                label         =>'Customer',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['customerid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'customerid',
                dataobjattr   =>'businessprocess.customer'),
   
      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'250px',
                label         =>'Shortname',
                dataobjattr   =>'businessprocess.name'),

      new kernel::Field::Text(
                name          =>'fullname',
                htmlwidth     =>'250px',
                label         =>'Name',
                dataobjattr   =>'businessprocess.fullname'),

      new kernel::Field::Text(
                name          =>'selektor',
                htmlwidth     =>'250px',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'Selektor',
                dataobjattr   =>'concat(businessprocess.name,"@",'.
                                'customer.fullname)'),

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
                dataobjattr   =>'businessprocess.cistatus'),

      new kernel::Field::TextDrop(
                name          =>'databoss',
                group         =>'procdesc',
                label         =>'Databoss',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['databossid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'businessprocess.databoss'),

      new kernel::Field::Select(
                name          =>'importance',
                group         =>'procdesc',
                transprefix   =>'im.',
                htmleditwidth =>'30%',
                label         =>'Importance',
                default       =>'3',
                value         =>[1,2,3,4,5],
                dataobjattr   =>'businessprocess.importance'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description',
                group         =>'procdesc',
                dataobjattr   =>'businessprocess.comments'),

      new kernel::Field::SubList(
                name          =>'acls',
                label         =>'Accesscontrol',
                subeditmsk    =>'subedit.businessprocess',
                group         =>'acl',
                allowcleanup  =>1,
                vjoininhash   =>[qw(acltarget acltargetid aclmode)],
                vjointo       =>'crm::businessprocessacl',
                vjoinbase     =>[{'aclparentobj'=>\'crm::businessprocess'}],
                vjoinon       =>['id'=>'refid'],
                vjoindisp     =>['acltargetname','aclmode']),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                group         =>'misc',
                dataobjattr   =>'businessprocess.comments'),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   return(0);
                },
                dataobjattr   =>'businessprocess.additional'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'businessprocess.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'businessprocess.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'businessprocess.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'businessprocess.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'businessprocess.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'businessprocess.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'businessprocess.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'businessprocess.editor'),

      new kernel::Field::RealEditor( 
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'businessprocess.realeditor'),

      new kernel::Field::Link(
                name          =>'sectarget',
                noselect      =>'1',
                dataobjattr   =>'businessprocessacl.acltarget'),

      new kernel::Field::Link(
                name          =>'sectargetid',
                noselect      =>'1',
                dataobjattr   =>'businessprocessacl.acltargetid'),

      new kernel::Field::Link(
                name          =>'secroles',
                noselect      =>'1',
                dataobjattr   =>'businessprocessacl.aclmode'),

   );
   $self->setDefaultView(qw(linenumber name cistatus importance cdate));
   $self->setWorktable("businessprocess");
   $self->{use_distinct}=1;
   $self->{CI_Handling}={uniquename=>"name",
                         activator=>["admin","w5base.crm.businessprocess"],
                         uniquesize=>40};
   return($self);
}


sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $wrgroups=shift;

   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return($self->SUPER::SecureValidate($oldrec,$newrec,$wrgroups));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ((!defined($oldrec) || defined($newrec->{name})) &&
       $newrec->{name}=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid name specified");
      return(0);
   }
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }

   ########################################################################
   # standard security handling
   #
   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      my $userid=$self->getCurrentUserId();
      if (!defined($oldrec)){
         if (!defined($newrec->{databossid}) ||
             $newrec->{databossid}==0){
            my $userid=$self->getCurrentUserId();
            $newrec->{databossid}=$userid;
         }
      }
      if (defined($newrec->{databossid}) &&
          $newrec->{databossid}!=$userid &&
          $newrec->{databossid}!=$oldrec->{databossid}){
         $self->LastMsg(ERROR,"you are not authorized to set other persons ".
                              "as databoss");
         return(0);
      }
   }
   ########################################################################
   my $customerid=effVal($oldrec,$newrec,"customerid");
   if ($customerid==0){
      $self->LastMsg(ERROR,"invalid or no customer specified");
      return(0);
   }
   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"name"));

   return(1);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt) &&
       !$self->IsMemberOf([qw(admin w5base.crm.businessprocess.read 
                              w5base.crm.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
             [qw(REmployee RApprentice RFreelancer RBoss)],"both");
      my @grpids=keys(%grps);
      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {mandatorid=>\@mandators},
                 {databossid=>$userid},
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>['write','read']},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>['write','read']}
                ]);
   }
   return($self->SetFilter(@flt));
}

sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $selfasparent=$self->SelfAsParentObject();
   my $from="$worktable left outer join businessprocessacl ".
            "on businessprocessacl.aclparentobj='$selfasparent' ".
            "and $worktable.id=businessprocessacl.refid ".
            "left outer join grp as customer on ".
            "customer.grpid=businessprocess.customer";

   return($from);
}  






sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my $userid=$self->getCurrentUserId();
   return("default","procdesc","misc","acl") if (!defined($rec) ||
                         ($rec->{cistatusid}<3 && $rec->{creator}==$userid) ||
                         $self->IsMemberOf($self->{CI_Handling}->{activator}));
   return("procdesc","misc","acl") if (defined($rec) &&
                         ($rec->{databossid}==$userid) ||
                         $self->IsMemberOf($self->{CI_Handling}->{activator}));
   return(undef);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default procdesc acl misc source));
}

sub SelfAsParentObject
{
   my $self=shift;
   return("crm::businessprocess");
}


1;
