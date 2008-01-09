package timetool::workgroup;
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
   $self->LoadSubObjs("timetool","subsys");

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                searchable    =>0,
                label         =>'W5BaseID',
                dataobjattr   =>'timeplanworkgroup.id'),
                                                  
      new kernel::Field::Mandator(),

      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'250px',
                label         =>'Name',
                dataobjattr   =>'timeplanworkgroup.name'),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>'timeplanworkgroup.mandator'),

      new kernel::Field::Select(
                name          =>'cistatus',
                selectwidth   =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'timeplanworkgroup.cistatus'),

      new kernel::Field::TextDrop(
                name          =>'adm',
                group         =>'admin',
                label         =>'Administrator',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['admid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'admid',
                dataobjattr   =>'timeplanworkgroup.adm'),

      new kernel::Field::TextDrop(
                name          =>'adm2',
                group         =>'admin',
                label         =>'Debuty Administrator',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['adm2id'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'adm2id',
                dataobjattr   =>'timeplanworkgroup.adm2'),

      new kernel::Field::Select(
                name          =>'mincomposition',
                selectwidth   =>'40%',
                label         =>'Min. Composition',
                default       =>'0',
                value         =>[qw(0 1 2 3 4 5 6 7 8 9 10)],
                dataobjattr   =>'timeplanworkgroup.mincomposition'),

      new kernel::Field::Boolean(
                name          =>'restrictive',
                label         =>'Restrictive controlled',
                dataobjattr   =>'timeplanworkgroup.restrictive'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                label         =>'Comments',
                dataobjattr   =>'timeplanworkgroup.comments'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Members',
                vjoinbase     =>[{'parentobj'=>\'timetool::workgroup'}],
                vjoininhash   =>['targetid','target'],
                vjoindisp     =>['targetname','comments'],
                group         =>'contacts'),

      new kernel::Field::ContactLnk(
                name          =>'contactids',
                uivisible     =>0,
                label         =>'ContactIDs',
                vjoinbase     =>[{'parentobj'=>\'timetool::workgroup'}],
                vjoininhash   =>['targetid','target'],
                vjoindisp     =>['targetid'],
                group         =>'contactids'),

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
                   return(1);
                },
                dataobjattr   =>'timeplanworkgroup.additional'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'timeplanworkgroup.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'timeplanworkgroup.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'timeplanworkgroup.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'timeplanworkgroup.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'timeplanworkgroup.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'timeplanworkgroup.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'timeplanworkgroup.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'timeplanworkgroup.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'timeplanworkgroup.realeditor'),

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

   );
   $self->{CI_Handling}={uniquename=>"name",
                         activator=>["admin","w5base.timetool.timeplan"],
                         uniquesize=>60};
   $self->{history}=[qw(insert modify delete)];
   $self->{use_distinct}=1;
   $self->setDefaultView(qw(name mandator tmode cistatus mdate));
   $self->setWorktable("timeplanworkgroup");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable";

   $from.=" left outer join lnkcontact ".
          "on lnkcontact.parentobj='timetool::workgroup' ".
          "and $worktable.id=lnkcontact.refid";

   return($from);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt) && 
       !$self->IsMemberOf([qw(admin w5base.timetool.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                                  ["REmployee","RMember"],"both");
      my @grpids=keys(%grps);
      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {mandatorid=>\@mandators},
                 {admid=>$userid},       {adm2id=>$userid},
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>"*roles=?write?=roles* *roles=?read?=roles*"},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>"*roles=?write?=roles* *roles=?read?=roles*"}
                ]);
   }
   return($self->SetFilter(@flt));
}


         

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   
   if ($name eq "" || $name=~m/[;,\&\\]/){
      $self->LastMsg(ERROR,
           sprintf($self->T("invalid name '%s' specified"),$name));
      return(0);
   }
   $newrec->{name}=$name;

   ########################################################################
   # standard security handling
   #
   ########################################################################
   if ($self->isDataInputFromUserFrontend()){
      my $userid=$self->getCurrentUserId();
      if (!defined($oldrec)){
         if (!defined($newrec->{admid}) ||
             $newrec->{admid}==0){
            $newrec->{admid}=$userid;
         }
      }
      if (defined($newrec->{admid}) &&
          $newrec->{admid}!=$userid &&
          !($self->IsMemberOf("admin")) &&
          $newrec->{admid}!=$oldrec->{admid}){
         $self->LastMsg(ERROR,"you are not authorized to set other persons ".
                              "as admin");
         return(0);
      }
   }
   ########################################################################

   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
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


sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;

   my $refobj=getModuleObject($self->Config,"itil::lnktimeplancustcontract");
   if (defined($refobj)){
      my $idname=$self->IdField->Name();
      my $id=$oldrec->{$idname};
      $refobj->SetFilter({'timeplan'=>\$id});
      $refobj->SetCurrentView(qw(ALL));
      $refobj->ForeachFilteredRecord(sub{
                         $refobj->ValidatedDeleteRecord($_);
                      });
   }
   if (!$self->HandleCIStatus($oldrec,undef,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
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

   my @databossedit=qw(default contacts misc admin);
   if (!defined($rec)){
      return(0) if (!$self->IsMemberOf("admin"));
      return("default");
   }
   else{
      if ($rec->{adm2id}==$userid){
         return(@databossedit);
      }
      if ($rec->{admid}==$userid){
         return(@databossedit);
      }
      if ($self->IsMemberOf("admin")){
         return(@databossedit);
      }
      return(0);
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
            if (grep(/^admin$/,@roles)){
               return(@databossedit);
            }
         }
      }
   }
   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default));
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/timetool/load/workgroup.jpg?".$cgi->query_string());
}


1;
