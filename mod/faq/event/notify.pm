package faq::event::notify;
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

   $self->RegisterEvent("faqchanged","FaqNotify");
   return(1);
}

sub FaqNotify
{
   my $self=shift;
   my $id=shift;
   my $link;
   my $lang="en";

   if ($id=~m/;/){
      my @l=split(/;/,$id);
      $id=$l[0];
      $link=$l[1];
      $lang=$l[2];
   }

   return({exitcode=>1,msg=>'ERROR: no id'}) if (!($id=~m/^\d+$/));
   my $faq=getModuleObject($self->Config,"faq::article");
   $faq->SetFilter({faqid=>\$id});
   my ($faqrec,$msg)=$faq->getOnlyFirst(qw(ALL));
   return({exitcode=>1,msg=>'ERROR: no valid faqid'}) if (!defined($faqrec));

   my $wf=getModuleObject($self->Config,"base::workflow");
   my $subject="FAQ: ".$faqrec->{name};
   my $sitename=$self->Config->Param("SITENAME");
   if ($sitename ne ""){
      $subject=$sitename.": ".$subject;
   }
   $ENV{HTTP_FORCE_LANGUAGE}=$lang if ($lang ne "");
   my $emailprefix=[$self->getParent->T("changed").":",
                    $self->getParent->T("cathegorie").":"];
   my $emailtext=[$faqrec->{name},$faqrec->{categorie}];
   my %email;
   $self->getNotifyDestinations($faqrec,"faqchanged",\%email);
   $self->getNotifyDestinations($faqrec,"faqartchanged",\%email);

   if (keys(%email)){
      my @emailto=keys(%email);
      if (defined($link)){
         push(@$emailprefix,$self->getParent->T("FAQ Article").":");
         push(@$emailtext,$link." ");
      }
      my $label=$self->getParent->T("faq::article","faq::article");
      delete($ENV{HTTP_FORCE_LANGUAGE});
      return({exitcode=>'0'}) if ($#emailto==-1);
      #push(@$emailtext,join(", ",@emailto));
      my $fromemail='noreply@w5base.net';
     
     
      if ($faqrec->{ownerid}>0){
         my $user=getModuleObject($self->Config,"base::user");
         $user->SetFilter({userid=>\$faqrec->{ownerid}});
         my ($urec,$msg)=$user->getOnlyFirst(qw(email fullname));
         #$fromemail=$urec->{email} if (defined($urec) && $urec->{email} ne "");
         if (defined($urec) && $urec->{fullname} ne ""){
            $fromemail=$urec->{fullname};
            $fromemail=~s/["<>]//g;
            $fromemail="\"$fromemail\" <>";
         }
      }

      my @emailcategory=();
      push(@emailcategory,"faqchanged");
      if ($faqrec->{categorie} ne ""){
         push(@emailcategory,"FAQ-Category $faqrec->{categorie}");
      }
     
     
      if ($id=$wf->Store(undef,{class  =>'base::workflow::mailsend',
                                step   =>'base::workflow::mailsend::dataload',
                                name   =>$subject,
                                emailfrom    =>$fromemail,
                                emailbcc     =>\@emailto,
                                emailcategory=>\@emailcategory,
                                additional   =>{label=>$label},
                                emailprefix  =>$emailprefix,
                                emailtemplate=>"faq/faqmail",
                                emailtext    =>$emailtext})){
         my %d=(step=>'base::workflow::mailsend::waitforspool');
         my $r=$wf->Store($id,%d);
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
   my $cat=getModuleObject($self->Config,"faq::category");
   my $nextcat=$rec->{faqcat};
   if ($mode eq "faqartchanged"){
      $ia->LoadTargets($emailto,'faq::article',\$mode,$rec->{faqid});
   }
   else{
      while(1){
         last if (!defined($nextcat) || $nextcat==0);
         msg(INFO,"Check $nextcat");
         my $catrec;
         $cat->SetFilter({faqcatid=>\$nextcat});
         my ($catrec,$msg)=$cat->getOnlyFirst(qw(faqcatid name parentid));
         $ia->LoadTargets($emailto,'faq::category',\$mode,$catrec->{faqcatid});
         last if (!defined($catrec) ||
                  !defined($catrec->{parentid}) ||
                  $catrec->{parentid}<=0);
         $nextcat=$catrec->{parentid};
      }
   }
}



1;
