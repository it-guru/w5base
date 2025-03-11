package base::event::base;
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
use Sys::Hostname;
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

   $self->RegisterEvent("HelloW5Server",\&HelloW5Server,timeout=>10);
   $self->RegisterEvent("UserVerified",\&UserVerified,timeout=>300);
   $self->RegisterEvent("TableVersionCheck",\&TableVersionCheck,timeout=>300);
   return(1);
}

sub TableVersionCheck
{
   my $self=shift;

   my $ob=getModuleObject($self->Config,"base::menu");

   $ob->TableVersionCheck();



   return({msg=>'OK',exitcode=>0});
}


sub HelloW5Server
{
   my $self=shift;

   my $hostname=hostname();

   return({exitmsg=>"W5Server\@$hostname",exitcode=>0});
}


sub UserVerified
{
   my $self=shift;
   my $account=shift;

   my $app=$self->getParent();
   msg(DEBUG,"Verify orgarea structure of account '%s'",$account);

   return() if ($account eq "anonymous");

   my $user=getModuleObject($self->Config,"base::user");
   my $mainuser=getModuleObject($self->Config,"base::user");
   my $grp=getModuleObject($self->Config,"base::grp");
   my $grpuser=getModuleObject($self->Config,"base::lnkgrpuser");
   my $ciamusr=getModuleObject($self->Config,"tsciam::user");
   my $ciamorg=getModuleObject($self->Config,"tsciam::orgarea");

   if (!defined($ciamusr) ||
       !defined($ciamorg) ||
       !defined($grpuser)||
       !defined($user)   ||
       !defined($mainuser)   ||
       !defined($grp)){
      msg(ERROR,"can't connect nesassary information objects");
      return({msg=>'shit'});
   }
   #goto CLEANUP;
   $mainuser->ResetFilter();
   if ($account ne ""){
      $mainuser->SetFilter({accounts=>$account});
      my ($urec,$msg)=$mainuser->getOnlyFirst(qw(userid lastqcheck qcok));
      if (defined($urec)){
         my $since;
         if ($urec->{lastqcheck} ne ""){
            my $now=NowStamp("en");
            my $d=CalcDateDuration($urec->{lastqcheck},$now);
            $since=$d->{totalminutes};
         }
         if (!defined($since) || $since>5){
            if ($urec->{qcok}){
               msg(INFO,"Quality check of useraccount '$account' OK");
            }
            else{
               if ($self->LastMsg()>0){
                  my @l=$self->LastMsg();
                  if (grep(/error/i,@l)){
                     msg(ERROR,"Quality check of ".
                               "useraccount '$account' failed");
                  }
               }
               return({msg=>"qc fail '$account'",exitcode=>1});
            }
         }
         else{
            msg(INFO,"Quality for useraccount '$account' already run in ".
                     "the last 5m");
            return({msg=>"fast recall '$account'",exitcode=>0});
         }
      }
      else{
         msg(ERROR,"useraccount '$account' not found or not bound to contact");
         return({msg=>"invalid account '$account'",exitcode=>1});
      }
   }
   return({msg=>'fine',exitcode=>0});
}

1;
