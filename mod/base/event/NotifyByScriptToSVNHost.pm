package base::event::NotifyByScriptToSVNHost;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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


   $self->RegisterEvent("NotifyByScriptToSVNHost",
                        "NotifyByScriptToSVNHost",timeout=>300);
   return(1);
}

sub NotifyByScriptToSVNHost
{
   my $self=shift;
   my %param=@_;

   my $mod=$param{mod};

   return({exitcode=>1,msg=>'no mod specified'}) if ($mod eq "");


   my $NotifyByScript=$self->Config->Param("NotifyByScript");
   $NotifyByScript=$NotifyByScript->{$mod} if (ref($NotifyByScript) eq "HASH");
   return({exitcode=>0,msg=>'no script specified'}) if ($NotifyByScript eq "");

   $|=1;

   $SIG{INT}='DEFAULT';
   $SIG{HUP}='DEFAULT';
   $SIG{CHLD}='DEFAULT';
   $SIG{ALRM}='DEFAULT';
   $SIG{USR1}='DEFAULT';
   $SIG{TERM}='DEFAULT';
   $SIG{PIPE}='DEFAULT';
   $SIG{WARN}='DEFAULT';
   $SIG{QUIT}='DEFAULT';

   my $pr=getModuleObject($self->Config,"base::projectroom");
   $pr->SetFilter({id=>\$param{id}});
   my @prlist=$pr->getHashList(qw(id name contacts));

   if ($#prlist!=-1){
      if (my $pid=open(CMD,"|$NotifyByScript")){
         my %grplist;
         foreach my $prrec (@prlist){
            my %acl;
            foreach my $c (@{$prrec->{contacts}}){
               if ($c->{target} eq "base::user"){
                  if (in_array($c->{roles},"SVNread")){
                     $acl{usrrd}->{$c->{targetid}}++;
                  }
                  if (in_array($c->{roles},"SVNwrite")){
                     $acl{usrwr}->{$c->{targetid}}++;
                  }
               }
               if ($c->{target} eq "base::grp"){
                  if (in_array($c->{roles},"SVNread")){
                     $acl{grprd}->{$c->{targetid}}++;
                     $grplist{$c->{targetid}}=[];
                  }
                  if (in_array($c->{roles},"SVNwrite")){
                     $acl{grpwr}->{$c->{targetid}}++;
                     $grplist{$c->{targetid}}=[];
                  }
               }
            }
            printf CMD ("BEGIN: projectroom $prrec->{id} $prrec->{name}\n");
            printf CMD ("[%s:/]\n",$prrec->{id});
            printf CMD ("%s\n",$self->aclToSVNRule(\%acl));
            printf CMD ("[%s:/]\n",$prrec->{name});
            printf CMD ("%s\n",$self->aclToSVNRule(\%acl));
            printf CMD ("END: projectroom\n");
         }
         printf CMD ("\nBEGIN: groups\n");
         if (keys(%grplist)){ 
            foreach my $grpid (keys(%grplist)){
               next if ($grpid==-2);
               next if ($grpid==-1);
               printf CMD ("GRP$grpid = %s\n",
                           join(", ",$self->getGroupMemberAccounts($grpid)));
            }
         }
         printf CMD ("END: groups\n\n");
         sleep(1);
         kill(15,$pid);
         close(CMD);
      }
      else{
         return({exitcode=>1,msg=>'fail to run '.$NotifyByScript});
      }
   }

   return({exitcode=>0,msg=>'ok'});
}

sub aclToSVNRule
{
   my $self=shift;
   my $acl=shift;

   my $d="";

   foreach my $k (keys(%$acl)){
      if ($k eq "grpwr"){
         foreach my $grpid (keys(%{$acl->{$k}})){
            if ($grpid==-1){
               $d.="* = wr\n";
            }
            elsif ($grpid==-2){
               $d.="anonymous = wr\n";
            }
            else{
               $d.="\@GRP$grpid = wr\n";
            }
         }
      }
      if ($k eq "grprd"){
         foreach my $grpid (keys(%{$acl->{$k}})){
            if ($grpid==-1){
               $d.="* = r\n";
            }
            elsif ($grpid==-2){
               $d.="anonymous = r\n";
            }
            else{
               $d.="\@GRP$grpid = r\n";
            }
         }
      }
      if ($k eq "usrwr"){
         foreach my $usrid (keys(%{$acl->{$k}})){
            foreach my $acc ($self->getAccountsByUserid($usrid)){
               $d.=$acc." = wr\n";
            }
         }
      }
      if ($k eq "usrrd"){
         foreach my $usrid (keys(%{$acl->{$k}})){
            foreach my $acc ($self->getAccountsByUserid($usrid)){
               $d.=$acc." = r\n";
            }
         }
      }
   }

   return($d);
}


sub getAccountsByUserid
{
   my $self=shift;
   my $userid=shift;

   my $user=$self->getPersistentModuleObject("base::useraccount");
   $user->SetFilter({userid=>\$userid});
   my @acc;
   foreach my $accrec ($user->getHashList("account")){
      push(@acc,$accrec->{account});
   }
   return(@acc);
}

sub getGroupMemberAccounts
{
   my $self=shift;
   my $grpid=shift;
   my $lgrp=$self->getPersistentModuleObject("base::lnkgrpuserrole");
   $lgrp->SetFilter({grpid=>\$grpid,cistatusid=>[4],grpcistatusid=>[4]});

   my @userids=();
   foreach my $lnkrec ($lgrp->getHashList(qw(userid))){
      push(@userids,$lnkrec->{userid});
   }
   my $ua=$self->getPersistentModuleObject("base::useraccount");
   $ua->SetFilter({userid=>\@userids});
   @userids=$ua->getVal("account");
   
   return(@userids);
}





1;
