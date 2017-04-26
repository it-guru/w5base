package faq::forumtopic;
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
use kernel::App::Web::Listedit;
use kernel::DataObj::DB;
use kernel::Field;
use faq::lib::forum;
use kernel::App::Web::VoteLink;

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB 
        kernel::App::Web::VoteLink);



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
                label         =>'Topic',
                searchable    =>1,
                htmlwidth     =>'450',
                dataobjattr   =>'forumtopic.name'),

      new kernel::Field::TextDrop(
                name          =>'forumboardname',
                label         =>'Boardname',
                vjointo       =>'faq::forumboard',
                vjoinon       =>['forumboard'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'forumboard',
                dataobjattr   =>'forumtopic.forumboard'),

      new kernel::Field::Select(
                name          =>'forcetopicicon',
                default       =>'0',
                htmleditwidth =>'60%',
                label         =>'force topic icon',
                transprefix   =>'icon.',
                value         =>['0',
                                 '1',
                                 '2'],
                dataobjattr   =>'forumtopic.topicicon'),

      new kernel::Field::DynWebIcon(
                name          =>'topicicon',
                htmlwidth     =>'5px',
                group         =>'stat',
                htmldetail    =>1,
                depend        =>['viewcount','isreaded'],
                label         =>'Topic Symbol',
                weblink       =>sub{
                                   my $self=shift;
                                   my $current=shift;
                                   my $mode=shift;
                                   
                                   my $ico="forum_topic";
                                   if ($current->{viewcount}>100){
                                      $ico="forum_hottopic";
                                   }
                                   if ($current->{isreaded}){
                                      $ico.="_readed";
                                   }
                                   if ($mode=~m/html/i){
                                      return("<img ".
                                             "src=\"../../faq/load/$ico.gif\">");
                                   }
                                   return("-");
                                },
                dataobjattr   =>'forumtopic.topicicon'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'forumtopic.comments'),

      new kernel::Field::Text(
                name          =>'viewcount',
                group         =>'stat',
                label         =>'Views',
                searchable    =>0,
                readonly      =>1,
                sqlorder      =>'none',
                dataobjattr   =>'forumtopic.viewcount'),
                                    
      new kernel::Field::Text(
                name          =>'entrycount',
                group         =>'stat',
                label         =>'Answers',
                searchable    =>0,
                readonly      =>1,
                sqlorder      =>'none',
                onRawValue    =>\&countEntries),
                                    
      new kernel::Field::Date(
                name          =>'lastentrymdate',
                group         =>'stat',
                label         =>'Last-Entry Date',
                searchable    =>0,
                readonly      =>1,
                sqlorder      =>'desc',
                dataobjattr   =>'max(forumentry.modifydate)'),
                                    
      new kernel::Field::Text(
                name          =>'lastentry',
                label         =>'Last-Entry ID',
                group         =>'stat',
                searchable    =>0,
                weblinkto     =>'faq::forumentry',
                weblinkon     =>['lastentry'=>'id'],
                readonly      =>1,
                sqlorder      =>'none',
                dataobjattr   =>'max(forumentry.id)'),
                                    
      new kernel::Field::Text(
                name          =>'creatorshort',
                group         =>'stat',
                label         =>'Creator surname',
                searchable    =>0,
                weblinkto     =>'base::user',
                weblinkon     =>['creator'=>'userid'],
                depend        =>['creator'],
                onRawValue    =>\&getShortCreator,
                readonly      =>1,
                sqlorder      =>'none'),
                                    
      new kernel::Field::Text(
                name          =>'lastworkershort',
                label         =>'Lastworker surname',
                group         =>'stat',
                searchable    =>0,
                depend        =>['lastentry'],
                onRawValue    =>\&faq::lib::forum::getShortLastworker,
                readonly      =>1,
                sqlorder      =>'none'),

      new kernel::Field::SubList(
                name          =>'answers',
                label         =>'Answers',
                group         =>'answers',
                allowcleanup  =>1,
                vjointo       =>'faq::forumentry',
                vjoinon       =>['id'=>'forumtopic'],
                vjoindisp     =>['cdate','owner']),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'Topic-No',
                sqlorder      =>'desc',
                size          =>'10',
                group         =>'source',
                dataobjattr   =>'forumtopic.id'),
                                    
      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'forumtopic.owner'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'forumtopic.modifyuser'),

      new kernel::Field::Link(
                name          =>'ownerid',
                group         =>'source',
                label         =>'OwnerID',
                dataobjattr   =>'forumtopic.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'forumtopic.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'forumtopic.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'forumtopic.srcload'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'forumtopic.editor'),
                                   
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'forumtopic.realeditor'),
                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                label         =>'Creation-Date',
                group         =>'source',
                dataobjattr   =>'forumtopic.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                label         =>'Modification-Date',
                sqlorder      =>'desc',
                group         =>'source',
                dataobjattr   =>'forumtopic.modifydate'),

      new kernel::Field::Link(
                name          =>'isreaded',
                label         =>'IsReaded',
                dataobjattr   =>'forumtopicread.createuser'),
                                   
      new kernel::Field::Fulltext(
                dataobjattr   =>'forumtopic.comments,forumtopic.name'),

   );
   $self->extendFieldDefinition();
   $self->setDefaultView(qw(mdate name entrycount editor topicicon));
   $self->{DetailY}=520;
   $self->setWorktable("forumtopic");
   return($self);
}

sub countEntries
{
   my $self=shift;
   my $current=shift;
   my $e=$self->getParent->getPersistentModuleObject("faq::forumentry");
   $e->ResetFilter();
   $e->SetFilter({forumtopic=>\$current->{id}});
   return($e->CountRecords());
}


sub SecureSetFilter
{
   my $self=shift;

   my $bo0=$self->getPersistentModuleObject("faq::forumboard");
   $bo0->SecureSetFilter();
   my @boids=map({$_->{id}} $bo0->getHashList(qw(id)));
   return($self->SUPER::SetFilter([{forumboard=>\@boids}],@_));
}


sub getShortCreator
{
   my $self=shift;
   my $current=shift;
   my $creator=$current->{creator};

   my $maxlen=10;
   my $user=$self->getParent->getPersistentModuleObject("base::user");
   $user->SetFilter({userid=>\$creator});
   my ($urec,$msg)=$user->getOnlyFirst(qw(email surname));
   my $d=$urec->{surname};
   $d=$urec->{email} if ($d eq "");
   $d=substr($d,0,$maxlen-3)."..." if (length($d)>$maxlen);
   return($d);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $name=effVal($oldrec,$newrec,"name");
   $newrec->{name}=trim($name);
   if ($newrec->{name} eq ""){
      $self->LastMsg(ERROR,"no valid forumtopic shortdescription");
      return(0);
   }

   my $comments=effVal($oldrec,$newrec,"comments");
   if ($comments eq ""){
      $self->LastMsg(ERROR,"no valid comments");
      return(0);
   }
   else{
      $newrec->{comments}=trim($comments);
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
   my $userid=$self->getCurrentUserId();
   $userid=0 if (!defined($userid));

   $from.=" left outer join forumentry ".
          "on forumtopic.id=forumentry.forumtopic ".
          "left outer join forumtopicread ".
          "on forumtopic.id=forumtopicread.forumtopic ".
          " and forumtopicread.createuser='$userid' ".
          " and forumtopicread.createdate>=forumtopic.modifydate";
   $from=$self->extendSqlFrom($from,"forumtopic.id");
   return($from);
}

sub getSqlGroup
{  
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   return("forumtopic.id");
}


sub getSqlOrder
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my @order=$self->initSqlOrder;
   my @view=$self->getFieldObjsByView([$self->getCurrentView()]);


   my @o=$self->GetCurrentOrder();
   if ($#o==0 && $o[0] eq "cdate"){
      return("if (forumentry.modifydate is null,forumtopic.createdate,".
             "forumentry.modifydate) desc");
   }
   return($self->SUPER::getSqlOrder());
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


   my $bo=$self->getPersistentModuleObject("faq::forumboard");
   $bo->SetFilter({id=>\$rec->{forumboard}});
   my ($borec,$msg)=$bo->getOnlyFirst(qw(ALL));
   if (defined($borec)){
      my @acl=$bo->getCurrentAclModes($ENV{REMOTE_USER},$borec->{acls});
      if ($self->IsMemberOf("admin") ||
          grep(/^moderate$/,@acl)){
         return("default");
      }
   }
   return(undef);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/faq/load/topic.jpg?".$cgi->query_string());
}

sub getDetailBlockPriority
{
   my $self=shift;

   return("header","default","answers","stat","source");
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $id=effVal($oldrec,$newrec,"id");
   my $idobj=$self->IdField();
   my $idname=$idobj->Name();
   my $userid=$self->getCurrentUserId();

   if (!defined($oldrec) && $id ne "" && $userid ne ""){   # call only if new rec
      my $url=$ENV{SCRIPT_URI};
      $url=~s#/auth/.*$##g;
      $url=~s#/public/.*$##g;
      my $openurl=$url;
      $url.="/auth/base/menu/msel/faq/forum";
      $openurl.="/auth/faq/forum/Topic/$id";
      $url.="?OpenURL=$openurl";
      #$url.="ById/$id";
      my $lang=$self->Lang();
      {  # add infoabo for creator
         my $ia=getModuleObject($self->Config,"base::infoabo");
         $ia->ValidatedInsertRecord({parentobj=>'faq::forumtopic',
                                     active=>'1',
                                     mode=>'foaddentry',
                                     refid=>$id,
                                     userid=>$userid});
      }
      my %p=(eventname=>'forumnewtopicmail',
             spooltag=>'forummail-'.$id,
             redefine=>'1',
             retryinterval=>600,
             firstcalldelay=>300,
             xfirstcalldelay=>3,
             eventparam=>$id.";".$url.";".$lang,
             userid=>11634953080001);
      my $res;
      if ($self->isDataInputFromUserFrontend()){
         if (defined($res=$self->W5ServerCall("rpcCallSpooledEvent",%p)) &&
             $res->{exitcode}==0){
            msg(INFO,"ForumMail Event sent OK");
         }
         else{
            msg(ERROR,"ForumMail Event sent failed");
         }
      }
   }

   return($self->SUPER::FinishWrite($oldrec,$newrec));
}









1;
