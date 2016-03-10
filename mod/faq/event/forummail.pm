package faq::event::forummail;
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
use kernel::Event;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;

   $self->RegisterEvent("forumnewtopicmail","ForumNewTopicMail");
   $self->RegisterEvent("forumaddentrymail","ForumAddEntryMail");
   return(1);
}

sub ForumNewTopicMail
{
  my $self=shift;
  return($self->sendForumMail("new",@_));
}

sub ForumAddEntryMail
{
  my $self=shift;
  return($self->sendForumMail("add",@_));
}

sub sendForumMail
{
   my $self=shift;
   my $mode=shift;
   my $id=shift;
   my ($link,$entryid);
   my $lang="en";

   if ($id=~m/;/){
      my @l=split(/;/,$id);
      $id=$l[0];
      $link=$l[1];
      $lang=$l[2];
      $entryid=$l[3];
   }

   return({exitcode=>1,msg=>'ERROR: no id'}) if (!($id=~m/^\d+$/));
   my $user=getModuleObject($self->Config,"base::user");
   my $faq=getModuleObject($self->Config,"faq::forumtopic");
   $faq->SetFilter({id=>\$id});
   my ($torec,$msg)=$faq->getOnlyFirst(qw(ALL));
   return({exitcode=>1,msg=>'ERROR: no valid topic id'}) if (!defined($torec));

   my $wf=getModuleObject($self->Config,"base::workflow");
   my $subject=$torec->{name};
   my $sitename=$self->Config->Param("SITENAME");
   $ENV{HTTP_FORCE_LANGUAGE}=$lang if ($lang ne "");
   my $emailprefix=[$self->getParent->T("Topic",'faq::forumtopic').":"];
   my $emailtext=[$torec->{name}];
   my %email=();
   $self->getNotifyDestinations($torec,$mode,\%email);
   my @emailto=keys(%email);
   if ($#emailto!=-1){
      if (defined($link)){
         push(@$emailprefix,$self->getParent->T("direct link").":");
         push(@$emailtext,$link." ");
      }
      if ($torec->{comments} ne "" && $mode ne "add"){
         push(@$emailprefix,$self->getParent->T("question/ info").":");
         push(@$emailtext,$torec->{comments});
      }
      if ($torec->{creator} ne "" && $mode ne "add"){
         $user->ResetFilter();
         $user->SetFilter({userid=>\$torec->{creator}});
         my ($urec,$msg)=$user->getOnlyFirst(qw(fullname));
         if (defined($urec)){
            push(@$emailprefix,$self->getParent->T("Creator","faq::forumtopic").":");
            push(@$emailtext,$urec->{fullname});
         }
      }
      if ($mode eq "add"){
         if ($entryid ne ""){
            my $faqe=getModuleObject($self->Config,"faq::forumentry");
            $faqe->SetFilter({id=>\$entryid});
            my ($enrec,$msg)=$faqe->getOnlyFirst(qw(ALL));
            if (defined($enrec)){
               push(@$emailprefix,$self->getParent->T("answer").":");
               push(@$emailtext,$enrec->{comments});
            }
            if ($enrec->{creator} ne ""){
               $user->ResetFilter();
               $user->SetFilter({userid=>\$enrec->{creator}});
               my ($urec,$msg)=$user->getOnlyFirst(qw(fullname));
               if (defined($urec)){
                  push(@$emailprefix,$self->getParent->T("Creator","faq::forumentry").":");
                  push(@$emailtext,$urec->{fullname});
               }
            }
         }
      }

      my $label="Forum";
      my $board=$torec->{forumboardname};
      if ($board ne ""){
         $label.=": <br>".$board;
      }
      my $UnsubscribeInfo=$self->getParent->T("UnsubscribeInfo");
      delete($ENV{HTTP_FORCE_LANGUAGE});
      return({exitcode=>'0'}) if ($#emailto==-1);
      #push(@$emailtext,join(", ",@emailto));
      my $fromemail='"'.$sitename.': Forum';
      if ($torec->{forumboardname} ne ""){
         my $boardname=$torec->{forumboardname};
         $boardname=~s/[^a-z0-9]/ /gi; 
         $fromemail.=": ".$boardname;
      }
      $fromemail.='" <noreply@w5base.net>';


     # if ($torec->{ownerid}>0){
     #    my $user=getModuleObject($self->Config,"base::user");
     #    $user->SetFilter({userid=>\$torec->{ownerid}});
     #    my ($urec,$msg)=$user->getOnlyFirst(qw(email));
     #    $fromemail=$urec->{email} if (defined($urec) && $urec->{email} ne "");
     # }
     
     my @e=@emailto;
     while(@e){
        my @eblk=splice(@e,0,999);   # block mail in 999 adresslist max
        my $nwfrec={
           class  =>'base::workflow::mailsend',
           step   =>'base::workflow::mailsend::dataload',
           name   =>$subject,
           emailfrom    =>$fromemail,
           emailbcc     =>\@eblk,
           additional   =>{label=>$label, UnsubscribeInfo=>$UnsubscribeInfo},
           emailprefix  =>$emailprefix,
           emailtemplate=>"faq/faqmail",
           emailtext    =>$emailtext
        };
        if ($id=$wf->Store(undef,$nwfrec)){
           my %d=(step=>'base::workflow::mailsend::waitforspool');
           my $r=$wf->Store($id,%d);
        }
     }
   }
   return({exitcode=>'0'});
}


sub getNotifyDestinations
{
   my $self=shift;
   my $rec=shift;
   my $mode=shift;
   my $emailto=shift;

   my $ia=getModuleObject($self->Config,"base::infoabo");
   if ($mode eq "new"){
      $ia->LoadTargets($emailto,'faq::forumboard',"foaddtopic",
                       $rec->{forumboard});
   }
   if ($mode eq "add"){
      $ia->LoadTargets($emailto,'faq::forumboard',"foboardansw",
                       $rec->{forumboard});
      $ia->LoadTargets($emailto,'faq::forumtopic',"foaddentry",
                       $rec->{id});
   }
}



1;
