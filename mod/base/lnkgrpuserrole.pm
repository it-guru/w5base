package base::lnkgrpuserrole;
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
use Data::Dumper;
use kernel;
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   
   $self->AddFields(
      new kernel::Field::Id(
                name          =>'roleid',
                label         =>'RoleId',
                size          =>'10',
                dataobjattr   =>'lnkgrpuserrole.lnkgrpuserroleid'),

      new kernel::Field::Contact(
                name          =>'userfullname',
                label         =>'UserFullname',
                readonly      =>1,
                vjoinon       =>'userid',
                dataobjattr   =>'contact.fullname'),

      new kernel::Field::Link(
                name          =>'userid',
                label         =>'UserID',
                readonly      =>1,
                dataobjattr   =>'contact.userid'),

      new kernel::Field::Select(
                name          =>'usercistatus',
                readonly      =>'1',
                label         =>'Contact CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'User CI-StatusID',
                readonly      =>1,
                dataobjattr   =>'contact.cistatus'),

      new kernel::Field::Text(
                name          =>'grpfullname',
                label         =>'GrpFullname',
                weblinkto     =>'base::grp',
                weblinkon     =>['grpid'=>'grpid'],
                readonly      =>1,
                dataobjattr   =>'grp.fullname'),

      new kernel::Field::Link(
                name          =>'grpid',
                dataobjattr   =>'grp.grpid'),

      new kernel::Field::Select(
                name          =>'grpcistatus',
                readonly      =>'1',
                label         =>'Group CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'grpcistatusid',
                dataobjattr   =>'grp.cistatus'),

      new kernel::Field::Link(
                name          =>'email',
                dataobjattr   =>'contact.email'),

      new kernel::Field::Text(
                name          =>'lnkgrpuserid',
                label         =>'LinkId',
                weblinkto     =>'base::lnkgrpuser',
                weblinkon     =>['lnkgrpuserid'=>'lnkgrpuserid'],
                dataobjattr   =>'lnkgrpuserrole.lnkgrpuserid'),

      new kernel::Field::Select(
                name          =>'role',
                label         =>'Role',
                value         =>['RMember',
                                 'RBoss','RBoss2',             # orgrole
                                 'REmployee',                  # orgrole
                                 'RApprentice','RFreelancer',  # orgrole
                                 'RBackoffice',                # orgrole
                                 'RQManager',                  
                                 'RReportReceive',
                                 'RTechReportRcv',
                                 'RAuditor',
                                 'RMonitor',
                                 'RControlling',
                                 'RTimeManager',
                                 'RINManager',                 # ITIL role
                                 'RINManager2',                # ITIL role
                                 'RINOperator',                # ITIL role
                                 'RCHManager',                 # ITIL role
                                 'RCHManager2',                # ITIL role
                                 'RCHOperator',                # ITIL role
                                 'RCFManager',                 # ITIL role
                                 'RCFManager2',                # ITIL role
                                 'RCFOperator',                # ITIL role
                                 'RPRManager',                 # ITIL role
                                 'RPRManager2',                # ITIL role
                                 'RPROperator',                # ITIL role
                                 'RODManager',                 # ITIL role
                                 'RODManager2',                # ITIL role
                                 'RODOperator',                # ITIL role
                                 'RCAManager',                 # ITIL role
                                 'RCAManager2',                # ITIL role
                                 'RCAOperator',                # ITIL role
                                 'RLIManager',                 # ITIL role
                                 'RLIManager2',                # ITIL role
                                 'RLIOperator',                # ITIL role
                                 'RSKPManager',                # ITIL role
                                 'RSKPManager2',               # ITIL role
                                 'RSKManager',                 # ITIL role
                                 'RSKCoord',                   # ITIL role
                                 'BCManager',        # BusinessCapability Mgr
                                 'PCManager',        # ProcessChain Mgr
                                 'BPManager',        # BusinessProcess Mgr
                                 'RITDemandMgr',               # IT role
                                 'RAdmin',                     # W5Base role
                                 'RDataAdmin',                 # W5Base role
                                 'RContactAdmin',              # W5Base role
                                 'W5BaseSupport',              # W5Base role 
                                ],
                dataobjattr   =>'lnkgrpuserrole.nativrole'),

      new kernel::Field::Text(
                name          =>'nativrole',
                label         =>'native role',
                htmldetail    =>0,
                dataobjattr   =>'lnkgrpuserrole.nativrole'),

      new kernel::Field::Date(
                name          =>'expiration',
                label         =>'Expiration-Date',
                dataobjattr   =>'lnkgrpuser.expiration'),

      new kernel::Field::CDate(
                name          =>'cdate',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkgrpuserrole.createdate'),
                                  
      new kernel::Field::Editor(
                name          =>'editor',
                label         =>'Editor Account',
                dataobjattr   =>'lnkgrpuserrole.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkgrpuserrole.realeditor'),

   );
   $self->setDefaultView(qw(roleid userfullname grpfullname role editor cdate));
   $self->setWorktable("lnkgrpuserrole");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   return("$worktable left outer join lnkgrpuser ".
          "on $worktable.lnkgrpuserid=lnkgrpuser.lnkgrpuserid ".
          "left outer join contact ".
          "on lnkgrpuser.userid=contact.userid ".
          "left outer join grp ".
          "on lnkgrpuser.grpid=grp.grpid ");
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if ((!defined($oldrec) && !defined($newrec->{lnkgrpuserid})) ||
       (defined($newrec->{lnkgrpuserid}) && $newrec->{lnkgrpuserid}==0)){
      $self->LastMsg(ERROR,"invalid lnkid specified");
      return(undef);
   }
   if ((!defined($oldrec) && !defined($newrec->{role})) ||
       (defined($newrec->{role}) && $newrec->{role} eq "")){
      $self->LastMsg(ERROR,"invalid role specified");
      return(undef);
   }
   return(1);
}


sub initSearchQuery
{
   my $self=shift;

   if (!defined(Query->Param("search_usercistatus"))){
     Query->Param("search_usercistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
   if (!defined(Query->Param("search_grpcistatus"))){
     Query->Param("search_grpcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}






sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   $self->InvalidateUserCache();
   return($bak);
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);
   $self->InvalidateUserCache();
   return($bak);
}
   


1;
