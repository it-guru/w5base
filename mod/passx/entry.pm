package passx::entry;
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
use kernel::App::Web::Listedit;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);


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
                label         =>'W5BaseID',
                dataobjattr   =>'passxentry.entryid'),

      new kernel::Field::Select(
                name          =>'entrytype',
                default       =>'1',
                label         =>'account type',
                transprefix   =>'actype.',
                value         =>['1',
                                 '4',
                                 '2',
                                 '3',
                                 '10',
                                 '11'],
                dataobjattr   =>'passxentry.entrytype'),

      new kernel::Field::Link(
                name          =>'entrytypeid',
                label         =>'entrytypeid',
                dataobjattr   =>'passxentry.entrytype'),

      new kernel::Field::Link(
                name          =>'uniqueflag',
                label         =>'uniqueflag',
                dataobjattr   =>'passxentry.uniqueflag'),

      new kernel::Field::Text(
                name        =>'name',
                label       =>'Systemname',
                dataobjattr =>'passxentry.systemname'),

      new kernel::Field::Text(
                name        =>'account',
                label       =>'Account',
                dataobjattr =>'passxentry.username'),

      new kernel::Field::Link(
                name          =>'scriptkey',
                label         =>'ScriptKey',
                dataobjattr   =>'passxentry.scriptkey'),

      new kernel::Field::Text(
                name        =>'quickpath',
                label       =>'Quick-Path',
                dataobjattr =>'passxentry.quickpath'),

      new kernel::Field::Text(
                name        =>'comments',
                label       =>'Comments',
                dataobjattr =>'passxentry.comments'),


      new kernel::Field::SubList(
                name          =>'acls',
                label         =>'Accesscontrol',
                subeditmsk    =>'subedit.entry',
                depend        =>['entrytype'],
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $rec=$param{current};
                   if ($rec->{entrytype}>10){
                      return(0);
                   }
                   return(1);
                },
                group         =>'acl',
                allowcleanup  =>1,
                vjoininhash   =>[qw(acltarget acltargetid aclmode)],
                vjointo       =>'passx::acl',
                vjoinbase     =>[{'aclparentobj'=>\'passx::entry'}],
                vjoinon       =>['id'=>'refid'],
                vjoindisp     =>['acltargetname','aclmode']),

      new kernel::Field::Text(
                name          =>'srcsys',
                htmldetail    =>0,
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'passxentry.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                htmldetail    =>0,
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'passxentry.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                htmldetail    =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'passxentry.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'passxentry.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'passxentry.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'passxentry.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'passxentry.modifyuser'),

      new kernel::Field::Link(
                name          =>'ownerid',
                group         =>'source',
                label         =>'OwnerID',
                dataobjattr   =>'passxentry.modifyuser'),

      new kernel::Field::Link(
                name          =>'modifyuser',
                group         =>'source',
                label         =>'ModifyUserID',
                dataobjattr   =>'passxentry.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'passxentry.editor'),

      new kernel::Field::RealEditor( 
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'passxentry.realeditor'),

      new kernel::Field::ListWebLink( 
                name          =>'listweblink',
                webjs         =>'function o(id){'.
                                ' parent.parent.location.href="../mgr/Workspace?ModeSelectCurrentMode=pstore&id="+id;'.
                                '}',
                webtarget     =>'_self',
                weblink       =>\&DirectLink,
                webtitle      =>'access Password Store',
                label         =>'Link'),

      new kernel::Field::Link(
                name          =>'aclmode',
                selectable    =>0,
                dataobjattr   =>'passxacl.aclmode'),
                                    
      new kernel::Field::Link(
                name          =>'acltarget',
                selectable    =>0,
                dataobjattr   =>'passxacl.acltarget'),
                                    
      new kernel::Field::Link(
                name          =>'acltargetid',
                selectable    =>0,
                dataobjattr   =>'passxacl.acltargetid'),

   );
   $self->setDefaultView(qw(entrytype name account listweblink comments mdate));
   return($self);
}

sub DirectLink
{
   my $self=shift;
   my $current=shift;
   my $mgr=$self->getParent->getPersistentModuleObject("passx::mgr");
   my $userid=$self->getParent->getCurrentUserId();
   $mgr->SetFilter({userid=>\$userid,entryid=>\$current->{id}});
   my ($erec,$msg)=$mgr->getOnlyFirst(qw(id));
   if (!defined($erec)){
      return(undef);
   }
   
   return("JavaScript:o($current->{id})");
}

sub Initialize
{
   my $self=shift;

   $self->setWorktable("passxentry");
   return($self->SUPER::Initialize());
}



sub FrontendSetFilter
{
   my $self=shift;
   my $userid=$self->getCurrentUserId();
   my %groups=$self->getGroupsOf($ENV{REMOTE_USER},'RMember','both');
   return($self->SUPER::SecureSetFilter([{modifyuser=>\$userid},
                                         {aclmode=>['write','read'],
                                          acltarget=>\'base::user',
                                          acltargetid=>[$userid],
                                          entrytypeid=>'<=10'},
                                         {aclmode=>['write','read'],
                                          acltarget=>\'base::grp',
                                          acltargetid=>[keys(%groups)],
                                          entrytypeid=>'<=10'},
                                         ],@_));
   return($self->SUPER::SecureSetFilter(@_));
}

sub SecureSetFilter
{
   my $self=shift;
   my $userid=$self->getCurrentUserId();

   return($self->SUPER::SecureSetFilter([{modifyuser=>\$userid},
                                         {entrytypeid=>'<=10'},
                                         ],@_));

}



sub getSqlFrom
{
   my $self=shift;
   my $from="passxentry left outer join passxacl ".
            "on passxentry.entryid=passxacl.refid and ".
            "passxacl.aclparentobj='passx::entry'";
   return($from);
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (defined($newrec->{name})){
      $newrec->{scriptkey}=undef;
   }
   $newrec->{userid}=$self->getCurrentUserId();
   my $entrytype=effVal($oldrec,$newrec,"entrytype");
   if ($entrytype<10){
      my $name=lc(trim(effVal($oldrec,$newrec,"name")));
      if ($name eq "" || !($name=~m/^[a-z0-9_\.:]+$/)){
         $self->LastMsg(ERROR,
              sprintf($self->T("invalid systemname '%s' specified"),$name));
         return(0);
      }
      $newrec->{name}=$name;
   }
   else{
      my $name=trim(effVal($oldrec,$newrec,"name"));
      if ($name eq "" || $name=~m/[\s;]/){
         $self->LastMsg(ERROR,
              sprintf($self->T("invalid systemname '%s' specified"),$name));
         return(0);
      }
      $newrec->{name}=$name;
   }
   my $quickpath=trim(effVal($oldrec,$newrec,"quickpath"));
   $newrec->{quickpath}=$quickpath if (exists($newrec->{quickpath}));
   #if ($entrytype==1){
   #   my $sys=$self->getPersistentModuleObject("itil::system");
   #   my $ok=0;
   #   if (defined($sys)){
   #      my $searchname=$newrec->{name};
   #      $searchname=~s/[\*\?]//g;
   #      $sys->SetFilter({name=>$searchname});
   #      my ($rec,$msg)=$sys->getOnlyFirst(qw(name));
   #      if (defined($rec)){
   #         $ok=1;
   #         $newrec->{name}=$rec->{name};
   #      }
   #   }
   #   if (!$ok){
   #      $self->LastMsg(ERROR,"systemname not found in inventar");
   #      return(0);
   #   }
   #}
   if ($entrytype==4){
      my $appl=$self->getPersistentModuleObject("itil::appl");
      my $ok=0;
      if (defined($appl)){
         my $searchname=$newrec->{name};
         $searchname=~s/[\*\?]//g;
         $appl->SetFilter({name=>$searchname});
         my ($rec,$msg)=$appl->getOnlyFirst(qw(name));
         if (defined($rec)){
            $ok=1;
            $newrec->{name}=$rec->{name};
         }
      }
      if (!$ok){
         $self->LastMsg(ERROR,"application not found in inventar");
         return(0);
      }
   }

   my $account=trim(effVal($oldrec,$newrec,"account"));
   if ($account eq "" || !($account=~m/^[a-z0-9_\.\-]+$/)){
      $self->LastMsg(ERROR,
           sprintf($self->T("invalid account '%s' specified"),
                   $account));
      return(0);
   }
   $newrec->{account}=$account;
   if ($entrytype<10){
      $newrec->{uniqueflag}=$entrytype;
   }
   else{
      $newrec->{uniqueflag}=$self->getCurrentUserId();
   }


   return(1);
}



sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my @fieldgroup=("default");
   return(@fieldgroup) if (!defined($rec));

   push(@fieldgroup,"acl");
   my $userid=$self->getCurrentUserId();

   return(@fieldgroup) if ($userid==$rec->{modifyuser});

   my @acl=$self->getCurrentAclModes($ENV{REMOTE_USER},$rec->{acls});
   return(@fieldgroup) if ($rec->{owner}==$userid ||
                           $self->IsMemberOf("admin") ||
                           grep(/^write$/,@acl));
   return(undef);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

1;
