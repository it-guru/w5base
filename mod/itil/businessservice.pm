package itil::businessservice;
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
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{Worktable}="businessservice";
   my ($worktable,$workdb)=$self->getWorktable();

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>"$worktable.id"),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                sqlorder      =>'desc',
                readonly      =>1,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};

                   return(1) if (defined($current));
                   return(0);
                },
                label         =>'Business-Service Fullname',
                dataobjattr   =>"concat(appl.name,':',".
                                "if ($worktable.name is null,'[ENTIRE]',".
                                "$worktable.name))"),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                sqlorder      =>'desc',
                label         =>'Name',
                dataobjattr   =>"$worktable.name"),

      new kernel::Field::Link(
                name          =>'parentid',
                selectfix     =>1,
                label         =>'ParentID',
                dataobjattr   =>"appl.id"),
                                                  
      new kernel::Field::Link(
                name          =>'applid',
                selectfix     =>1,
                label         =>'ApplicationID',
                dataobjattr   =>"$worktable.appl"),

      new kernel::Field::Text(
                name          =>'application',
                htmldetail    =>0,
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if (defined($current));
                   return(0);
                },
                uploadable    =>0,
                label         =>'Application',
                weblinkto     =>'itil::appl',
                weblinkon     =>['parentid'=>'id'],
                dataobjattr   =>'appl.name'),

      new kernel::Field::TextDrop(
                name          =>'srcapplication',
                searchable    =>0,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};

                   return(0) if (defined($current));
                   return(1);
                },
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if (defined($current));
                   return(0);
                },
                uploadable    =>0,
                label         =>'provided by application',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'applcistatus',
                htmldetail    =>0,
                group         =>'applinfo',
                label         =>'Application CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['applcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'applcistatusid',
                label         =>'ApplCiStatusID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::Contact(
                name          =>'funcmgr',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                label         =>'functional manager',
                vjoinon       =>'funcmgrid'),

                                                  
      new kernel::Field::Link(
                name          =>'funcmgrid',
                label         =>'functional mgr id',
                dataobjattr   =>"$worktable.funcmgr"),
                                                  
      new kernel::Field::Mandator( 
                readonly      =>1,
                group         =>'applinfo'),

      new kernel::Field::Interface(
                name          =>'mandatorid',
                group         =>'applinfo',
                readonly      =>1,
                dataobjattr   =>'appl.mandator'),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'appl.databoss'),

      new kernel::Field::Link(
                name          =>'businessteamid',
                dataobjattr   =>'appl.businessteam'),

      new kernel::Field::Link(
                name          =>'responseteamid',
                dataobjattr   =>'appl.responseteam'),

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
   $self->setDefaultView(qw(fullname application));
   return($self);
}




sub preProcessReadedRecord
{
   my $self=shift;
   my $rec=shift;

   if (!defined($rec->{id}) && $rec->{parentid} ne ""){
      my $o=$self->Clone();
      my ($id)=$o->ValidatedInsertRecord({applid=>$rec->{parentid}});
      $rec->{id}=$id;
   }
   return(undef);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_applcistatus"))){
     Query->Param("search_applcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="";

   $from.="appl left outer join businessservice ".
          "on appl.id=businessservice.appl left outer join lnkcontact ".
          "on lnkcontact.parentobj='itil::appl' ".
          "and appl.id=lnkcontact.refid ";

   return($from);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (effVal($oldrec,$newrec,"name") eq "[ENTIRE]" ||
       effVal($oldrec,$newrec,"name") eq ""){
      $newrec->{name}=undef;
   }
   if (defined($newrec->{name}) && $newrec->{name} eq ""){
      $self->LastMsg(ERROR,"invalid service name specified");
      return(0);
   }
   my $applid=effVal($oldrec,$newrec,"applid");

   if ($applid eq "" || !$self->isParentWriteable($applid)){
      $self->LastMsg(ERROR,"no write access to specified application");
      return(0);
   }

   return(1);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my @l;

   return("default") if (!defined($rec));
   if ($self->isParentWriteable($rec->{applid})){
      push(@l,"default");
   }
   return(@l);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/bussinessservice.jpg?".$cgi->query_string());
}




sub isParentWriteable
{
   my $self=shift;
   my $applid=shift;

   my $p=$self->getPersistentModuleObject($self->Config,"itil::appl");
   my $idname=$p->IdField->Name();
   my %flt=($idname=>\$applid);
   $p->SetFilter(\%flt);
   my @l=$p->getHashList(qw(ALL));
   if ($#l!=0){
      $self->LastMsg(ERROR,"invalid application reference");
      return(0);
   }
   my @write=$p->isWriteValid($l[0]);
   if (!grep(/^ALL$/,@write) && !grep(/^default$/,@write)){
      return(0);
   }
   return(1);
}

sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (
      #!$self->isDirectFilter(@flt) && 
       !$self->IsMemberOf([qw(admin w5base.itil.appl.read w5base.itil.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                          [orgRoles(),qw(RMember RCFManager RCFManager2 
                                         RAuditor RMonitor)],"both");
      my @grpids=keys(%grps);

      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {mandatorid=>\@mandators},
                 {databossid=>\$userid},
                 {businessteamid=>\@grpids},
                 {responseteamid=>\@grpids},
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





1;
