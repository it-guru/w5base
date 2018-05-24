package faq::forumentry;
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

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                searchable    =>1,
                htmlwidth     =>'450',
                dataobjattr   =>'forumentry.comments'),

      new kernel::Field::TextDrop(
                name          =>'forumtopicname',
                group         =>'topic',
                label         =>'Topic',
                vjointo       =>'faq::forumtopic',
                vjoinon       =>['forumtopic'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'forumtopic',
                dataobjattr   =>'forumentry.forumtopic'),
                                    
      new kernel::Field::Id(
                name          =>'id',
                label         =>'Entry-No',
                sqlorder      =>'desc',
                size          =>'10',
                group         =>'source',
                dataobjattr   =>'forumentry.id'),
                                    
      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'forumentry.owner'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'forumentry.modifyuser'),

      new kernel::Field::Link(
                name          =>'ownerid',
                group         =>'source',
                label         =>'OwnerID',
                dataobjattr   =>'forumentry.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'forumentry.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'forumentry.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'forumentry.srcload'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'forumentry.editor'),
                                   
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'forumentry.realeditor'),
                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                label         =>'Creation-Date',
                group         =>'source',
                dataobjattr   =>'forumentry.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                label         =>'Modification-Date',
                sqlorder      =>'desc',
                group         =>'source',
                dataobjattr   =>'forumentry.modifydate'),

      new kernel::Field::Fulltext(
                dataobjattr   =>'forumentry.comments'),
   );
   $self->setDefaultView(qw(mdate editor comments));
   $self->{DetailY}=520;
   $self->setWorktable("forumentry");
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   return(1);
}



sub isAnonymousAccessValid
{
    my $self=shift;
    return(1);
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
   return("default","topic") if ($self->IsMemberOf("admin"));

   return(undef);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/faq/load/entry.jpg?".$cgi->query_string());
}

sub getDetailBlockPriority
{
   my $self=shift;

   return("header","topic","default","source");
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $id=effVal($oldrec,$newrec,"id");
   my $toid=effVal($oldrec,$newrec,"forumtopic");
   my $userid=$self->getCurrentUserId();

   if (!defined($oldrec)){   # call only if new rec
      my $url=$ENV{SCRIPT_URI};
      $url=~s#/auth/.*$##g;
      $url=~s#/public/.*$##g;
      my $openurl=$url;
      $url.="/auth/base/menu/msel/faq/forum";
      $openurl.="/auth/faq/forum/Topic/$toid";
      $url.="?OpenURL=$openurl";
      my $lang=$self->Lang();

      {  # add infoabo for creator
         my $ia=getModuleObject($self->Config,"base::infoabo");
         $ia->ValidatedInsertOrUpdateRecord(
                                {parentobj=>'faq::forumtopic',
                                 active=>'1',
                                 mode=>'foaddentry',
                                 refid=>$toid,
                                 userid=>$userid},
                                {parentobj=>\'faq::forumtopic',
                                 mode=>\'foaddentry',
                                 refid=>\$toid,
                                 userid=>\$userid});
      }

    
      my %p=(eventname=>'forumaddentrymail',
             spooltag=>'forumaddmail-'.$id,
             redefine=>'1',
             retryinterval=>600,
             xfirstcalldelay=>3,
             firstcalldelay=>300,
             eventparam=>$toid.";".$url.";".$lang.";".$id,
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
