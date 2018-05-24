package faq::forumboard;
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
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Boardname',
                htmlwidth     =>'100',
                searchable    =>1,
                htmlwidth     =>'450',
                dataobjattr   =>'forumboard.name'),

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
                dataobjattr   =>'forumboard.cistatus'),

      new kernel::Field::Text(
                name          =>'boardgroup',
                label         =>'Boardgroup',
                searchable    =>1,
                htmlwidth     =>'150',
                dataobjattr   =>'forumboard.boardgroup'),
                                    
#      new kernel::Field::Select(
#                name          =>'categorie',
#                htmleditwidth =>'50%',
#                allowempty    =>1,
#                label         =>'Categorie',
#                vjointo       =>'faq::category',
#                vjoinon       =>['faqcatid'=>'faqcatid'],
#                vjoindisp     =>'fullname'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                searchable    =>0,
                htmlwidth     =>'100',
                dataobjattr   =>'forumboard.comments'),

      new kernel::Field::SubList(
                name          =>'acls',
                label         =>'Accesscontrol',
                subeditmsk    =>'subedit.forumboard',
                group         =>'acl',
                htmlwidth     =>'500px',
                allowcleanup  =>1,
                forwardSearch =>1,
                vjoininhash   =>[qw(acltarget acltargetid aclmode)],
                vjointo       =>'faq::forumboardacl',
                vjoinbase     =>[{'aclparentobj'=>\'faq::forumboard'}],
                vjoinon       =>['id'=>'refid'],
                vjoindisp     =>['acltargetname','aclmode']),

      new kernel::Field::Link(
                name          =>'faqcatid',
                dataobjattr   =>'forumboard.faqcat'),
                                    
      new kernel::Field::Id(
                name          =>'id',
                label         =>'Board-Id',
                sqlorder      =>'desc',
                size          =>'10',
                group         =>'source',
                dataobjattr   =>'forumboard.id'),

      new kernel::Field::Link(
                name          =>'aclmode',
                selectable    =>0,
                dataobjattr   =>'forumboardacl.aclmode'),
                                    
      new kernel::Field::Link(
                name          =>'acltarget',
                selectable    =>0,
                dataobjattr   =>'forumboardacl.acltarget'),
                                    
      new kernel::Field::Link(
                name          =>'acltargetid',
                selectable    =>0,
                dataobjattr   =>'forumboardacl.acltargetid'),

      new kernel::Field::Htmlarea(
                name          =>'boardheader',
                searchable    =>0,
                group         =>'boardheader',
                label         =>'board header',
                dataobjattr   =>'forumboard.boardheader'),

      new kernel::Field::FileList(
                name          =>'attachments',
                label         =>'Attachments',
                parentobj     =>'faq::forumboard',
                group         =>'attachments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'forumboard.owner'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'forumboard.modifyuser'),

      new kernel::Field::Link(
                name          =>'ownerid',
                group         =>'source',
                label         =>'OwnerID',
                dataobjattr   =>'forumboard.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'forumboard.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'forumboard.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'forumboard.srcload'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'forumboard.editor'),
                                   
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'forumboard.realeditor'),
                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                label         =>'Creation-Date',
                group         =>'source',
                dataobjattr   =>'forumboard.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                label         =>'Modification-Date',
                sqlorder      =>'desc',
                group         =>'source',
                dataobjattr   =>'forumboard.modifydate'),
                                   
   );
   $self->setDefaultView(qw(name boardgroup));
   $self->{DetailY}=520;
   $self->setWorktable("forumboard");
   return($self);
}



sub isAnonymousAccessValid
{
    my $self=shift;
    return(1);
}




sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),"setSubscribe","BoardHeader");
}

sub BoardHeader
{
   my $self=shift;
   my $id=Query->Param("id");

   my $bo=$self->getPersistentModuleObject("faq::forumboard");
   $bo->SecureSetFilter({id=>\$id});
   my ($borec,$msg)=$bo->getOnlyFirst(qw(boardheader));

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css',
                                   'Output.HtmlDetail.css'],
                           body=>1,form=>1);
   if (defined($borec)){
      print($borec->{boardheader});
   }
   print $self->HtmlBottom(body=>1,form=>1);
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (!defined($oldrec) || defined($newrec->{name})){
      $newrec->{name}=trim($newrec->{name});
      if ($newrec->{name} eq ""){
         $self->LastMsg(ERROR,"no valid forumboard shortdescription");
         return(0);
      }
   }
   if (exists($newrec->{boardheader})){
      $newrec->{boardheader}=~s/<script/<div style="visible:hidden" script/gi;
      $newrec->{boardheader}=~s/<\script>/<\/div>/gi;
   }

   return(1);
}

sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable";

   $from.=" left outer join forumtopic ".
          "on forumboard.id=forumtopic.forumboard ".
          " left outer join forumentry ".
          "on forumtopic.id=forumentry.forumtopic ".
          "left outer join forumboardacl on ".
          "forumboard.id=forumboardacl.refid and ".
          "forumboardacl.aclparentobj='faq::forumboard'"; 

   return($from);
}

sub SecureSetFilter
{
   my $self=shift;
   if (!$self->IsMemberOf("admin")){
      return($self->AddSecureSetFilter(@_));
   }
   return($self->SUPER::SecureSetFilter(@_));
}

sub AddSecureSetFilter
{
   my $self=shift;

   my $userid=$self->getCurrentUserId();
   my %groups=$self->getGroupsOf($ENV{REMOTE_USER},'RMember','up');
   return($self->SUPER::SecureSetFilter([
                   {aclmode=>['write','read','answer','moderate'],
                    acltarget=>\'base::user',
                    acltargetid=>[$userid]},
                   {aclmode=>['write','read','answer','moderate'],
                    acltarget=>\'base::grp',
                    acltargetid=>[keys(%groups)]},
                   {acltargetid=>[undef]},
                                        ],@_));
}


sub getSqlGroup
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   return("forumboard.id");
}

sub getDetailBlockPriority
{
   my $self=shift;

   return("header","default","stat","acl","boardheader","attachments","source");
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","header") if (!defined($rec));

   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $moderator=0;

   if ($self->IsMemberOf("admin")){
      return("default","acl","boardheader","attachments");
   }

   my @acl=$self->getCurrentAclModes($ENV{REMOTE_USER},$rec->{acls});
   if (grep(/^moderate$/,@acl)){
      $moderator=1;
   }
   if ($moderator){
      return("acl","boardheader","attachments");
   }

   return(undef);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/faq/load/board.jpg?".$cgi->query_string());
}


sub setSubscribe
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(title=>"",body=>1);
   if ($ENV{REMOTE_USER} ne "anonymous"){
      my ($op,$refid,$mode,$active)=split(/\//,Query->Param("FUNC"));
      if ($refid=~m/^\d+$/ && $mode ne "" && 
          ($active eq "1" || $active eq "0")){
         my $userid=$self->getCurrentUserId();
         my $ia=getModuleObject($self->Config,"base::infoabo");
         $ia->ValidatedInsertOrUpdateRecord(
                        {refid=>$refid,parentobj=>"faq::forumboard",
                         userid=>$userid,mode=>$mode,active=>$active},
                        {refid=>\$refid,parentobj=>\"faq::forumboard",
                         userid=>$userid,mode=>\$mode});
      }
   }
   print $self->HtmlBottom(body=>1);
}



1;
