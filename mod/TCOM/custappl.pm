package TCOM::custappl;
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
use kernel::Field;
use kernel::DataObj::DB;
use kernel::App::Web::Listedit;
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{UseSqlReplace}=1;

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                searchable    =>0,
                label         =>'W5BaseID',
                altdataobjattr=>'appl.id',
                dataobjattr   =>'TCOM_appl.id'),

      new kernel::Field::Text(
                name          =>'name',
                readonly      =>1,
                htmlwidth     =>'200px',
                label         =>'TS Applicationname',
                altdataobjattr=>'appl.name',
                dataobjattr   =>'TCOM_appl.origname'),

      new kernel::Field::TextDrop(
                name          =>'customer',
                label         =>'Customer',
                readonly      =>1,
                vjointo       =>'base::grp',
                vjoinon       =>['customerid'=>
                                 'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Select(  
                name          =>'cistatus',
                readonly      =>1,
                selectwidth   =>'40%',
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',   # function is needed to 
                label         =>'CI-StatusID',  # show undefined state
                dataobjattr   =>'if (appl.cistatus is null,0,appl.cistatus)'),

      new kernel::Field::Link(       
                name          =>'customerid',
                altdataobjattr=>'appl.customer',
                dataobjattr   =>'TCOM_appl.customer'),

      new kernel::Field::TextDrop(
                name          =>'wbv',
                group         =>'tcomcontact',
                label         =>'WBV Wirkbetriebsverantwortlicher',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['wbvid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(      
                name          =>'wbvid',
                group         =>'tcomcontact',
                dataobjattr   =>'TCOM_appl.wbv'),

      new kernel::Field::TextDrop(
                name          =>'ev',
                group         =>'tcomcontact',
                label         =>'EV Einführungsverantwortlicher',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['evid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(      
                name          =>'evid',
                group         =>'tcomcontact',
                dataobjattr   =>'TCOM_appl.ev'),

      new kernel::Field::TextDrop(
                name          =>'itv',
                group         =>'tcomcontact',
                label         =>'ITV IT-Verantwortlicher',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['itvid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(      
                name          =>'itvid',
                group         =>'tcomcontact',
                dataobjattr   =>'TCOM_appl.itv'),

      new kernel::Field::TextDrop(
                name          =>'inm',
                group         =>'tcomcontact',
                label         =>'INM Intergrationsmanager',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['inmid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(      
                name          =>'inmid',
                group         =>'tcomcontact',
                dataobjattr   =>'TCOM_appl.inm'),

      new kernel::Field::TextDrop(
                name          =>'ippl',
                group         =>'tcomcontact',
                label         =>'IPPL IP Projektleiter',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['ipplid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(      
                name          =>'ipplid',
                group         =>'tcomcontact',
                dataobjattr   =>'TCOM_appl.ippl'),

      new kernel::Field::Interface(      
                name          =>'semid',
                group         =>'tscontact',
                dataobjattr   =>'appl.sem'),

      new kernel::Field::Interface(
                name          =>'sememail',
                group         =>'tscontact',
                vjointo       =>'base::user',
                vjoinon       =>['semid'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'sem',
                group         =>'tscontact',
                label         =>'Service Manager',
                translation   =>'itil::appl',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['semid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Interface(
                name          =>'tsmid',
                group         =>'tscontact',
                dataobjattr   =>'appl.tsm'),

      new kernel::Field::Interface(
                name          =>'tsmemail',
                group         =>'tscontact',
                vjointo       =>'base::user',
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'tsm',
                group         =>'tscontact',
                translation   =>'itil::appl',
                label         =>'Technical Solution Manager',
                vjointo       =>'base::user',
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Text(
                name          =>'businessteambossid',
                group         =>'tscontact',
                label         =>'Business Team Boss ID',
                onRawValue    =>\&getTeamBossID,
                readonly      =>1,
                uivisible     =>0, 
                depend        =>['businessteamid']),

      new kernel::Field::Text( 
                name          =>'businessteamboss',
                group         =>'tscontact',
                label         =>'Business Team Boss',
                onRawValue    =>\&getTeamBoss, 
                htmldetail    =>1,
                readonly      =>1,             
                depend        =>['businessteambossid']),

      new kernel::Field::Text( 
                name          =>'businessteambossemail',
                group         =>'tscontact',
                label         =>'Business Team Boss EMail',
                onRawValue    =>\&getTeamBossEMail, 
                htmldetail    =>0,
                readonly      =>1,             
                depend        =>['businessteambossid']),

      new kernel::Field::Link(
                name          =>'businessteamid',
                dataobjattr   =>'appl.businessteam'),

      new kernel::Field::Text(
                name          =>'custname',
                htmlwidth     =>'200px',
                label         =>'TCOM Applicationname',
                dataobjattr   =>'TCOM_appl.name'),

      new kernel::Field::SubList(
                name          =>'custcontracts',
                label         =>'Customer Contracts',
                group         =>'custcontracts',
                nodetaillink  =>1,
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkapplcustcontract',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['custcontract','custcontractid'],
                vjoinbase     =>[{custcontractcistatusid=>'<=4'}],
                vjoininhash   =>['custcontractid','custcontractcistatusid',
                                 'custcontract','custcontractname']),

   );

   $self->setDefaultView(qw(name custname cistatus));
   $self->setWorktable("TCOM_appl");
   return($self);
}


sub getTeamBossID
{
   my $self=shift;
   my $current=shift;
   my $teamfieldname=$self->{depend}->[0];
   my $teamfield=$self->getParent->getField($teamfieldname);
   my $teamid=$teamfield->RawValue($current);
   my @teambossid=();
   if ($teamid ne ""){
      my $lnk=getModuleObject($self->getParent->Config,
                              "base::lnkgrpuser");
      $lnk->SetFilter({grpid=>\$teamid,
                       nativroles=>'RBoss'});
      foreach my $rec ($lnk->getHashList("userid")){
         if ($rec->{userid} ne ""){
            push(@teambossid,$rec->{userid});
         }
      }
   }
   return(\@teambossid);
}

sub getTeamBoss
{
   my $self=shift;
   my $current=shift;
   my $teambossfieldname=$self->{depend}->[0];
   my $teambossfield=$self->getParent->getField($teambossfieldname);
   my $teambossid=$teambossfield->RawValue($current);
   my @teamboss;
   if ($teambossid ne "" && ref($teambossid) eq "ARRAY" && $#{$teambossid}>-1){
      my $user=getModuleObject($self->getParent->Config,"base::user");
      $user->SetFilter({userid=>$teambossid});
      foreach my $rec ($user->getHashList("fullname")){
         if ($rec->{fullname} ne ""){
            push(@teamboss,$rec->{fullname});
         }
      }
   }
   return(\@teamboss);
}


sub getTeamBossEMail
{
   my $self=shift;
   my $current=shift;
   my $teambossfieldname=$self->{depend}->[0];
   my $teambossfield=$self->getParent->getField($teambossfieldname);
   my $teambossid=$teambossfield->RawValue($current);
   my @teamboss;
   if ($teambossid ne "" && ref($teambossid) eq "ARRAY" && $#{$teambossid}>-1){
      my $user=getModuleObject($self->getParent->Config,"base::user");
      $user->SetFilter({userid=>$teambossid});
      foreach my $rec ($user->getHashList("email")){
         if ($rec->{email} ne ""){
            push(@teamboss,$rec->{email});
         }
      }
   }
   return(\@teamboss);
}



sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   my $userid=$self->getCurrentUserId();
   my %grp=$self->getGroupsOf($ENV{REMOTE_USER},"RMember","both");
   my @grpids=keys(%grp);
   @grpids=(qw(NONE)) if ($#grpids==-1);
   $self->SetNamedFilter("Customer",{customerid=>\@grpids});

   return($self->SetFilter(@flt));
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   $newrec->{tsiname}=effVal($oldrec,$newrec,"tsiname");
   $newrec->{customerid}=effVal($oldrec,$newrec,"customerid");

   return(1);
}


sub getSqlFrom
{
   my $self=shift;
   my @from=("appl left outer join TCOM_appl on appl.id=TCOM_appl.id ",
             "TCOM_appl left outer join appl on TCOM_appl.id=appl.id ");

   return(@from);
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
   return("tcomcontact");
}  

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default tcomcontact tscontact custcontracts));
}

sub HandleInfoAboSubscribe
{
   my $self=shift;
   my $id=Query->Param("CurrentIdToEdit");
   my $ia=$self->getPersistentModuleObject("base::infoabo");
   if ($id ne ""){
      $self->ResetFilter();
      $self->SetFilter({id=>\$id});
      my ($rec,$msg)=$self->getOnlyFirst(qw(name));
      print($ia->WinHandleInfoAboSubscribe({},
                      $self->SelfAsParentObject(),$id,$rec->{name},
                      "base::staticinfoabo",undef,undef));
   }
   else{
      print($self->noAccess());
   }
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::appl");
}
















1;
