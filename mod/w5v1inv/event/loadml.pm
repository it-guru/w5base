package w5v1inv::event::loadml;
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


   $self->RegisterEvent("loadml","LoadMailingList");
   return(1);
}


sub LoadMailingList
{
   my $self=shift;
   my $file=shift;
   my $listid=shift;

   if (!open(F,"<$file")){
      msg(ERROR,"can't open file '$file'");
      return({exitcode=>'1'});
   }
   my $user=getModuleObject($self->Config,"base::user");
   my $ia=getModuleObject($self->Config,"base::infoabo");
   my $to=getModuleObject($self->Config,"faq::forumboard");
   $to->SetFilter({id=>\$listid});
   my ($torec,$msg)=$to->getOnlyFirst(qw(all));
   if (!defined($torec)){
      msg(ERROR,"listid '$listid' not found");
      return({exitcode=>'1'});
   }
   msg(DEBUG,"LoadMailingList from $file into list $listid");
   my $count=0;
   my $fail=0;
   while(defined(my $email=<F>)){
      $email=~s/\s*//g;
      $email=lc($email);
      if ($email ne ""){
         $count++;
         msg(DEBUG,"process '$email'");
         $email=~s/\@.*$/\@/;
         $user->ResetFilter();
         $user->SetFilter({email=>"$email*"});
         my ($urec,$msg)=$user->getOnlyFirst(qw(id email fullname));
         if (defined($urec)){
            my $userid=$urec->{userid};
            my $boardid=$torec->{id};
            msg(DEBUG,"found user '$urec->{fullname}'");
            msg(DEBUG," => userid=$userid bo=$boardid");
            foreach my $mode (qw(foaddtopic foboardansw)){
               my $rec={userid=>$userid,
                        mode=>$mode,
                        refid=>$boardid,
                        active=>1,
                        srcsys=>'Majordomo',
                        parentobj=>'faq::forumboard'};
               $ia->ValidatedInsertOrUpdateRecord($rec,
                                   {userid=>\$rec->{userid},
                                    refid=>\$rec->{refid},
                                    parentobj=>\$rec->{parentobj},
                                    mode=>\$rec->{mode}});
            }
         }
         else{
            $fail++;
         }
      }
   }


   close(F);
   msg(DEBUG,"count=$count fail=$fail");
   return({exitcode=>'0'});
}





1;
