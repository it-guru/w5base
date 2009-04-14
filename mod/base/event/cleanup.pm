package base::event::cleanup;
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


   $self->RegisterEvent("AutoFinishWorkflows","AutoFinishWorkflows");
   $self->RegisterEvent("CleanupLnkGrpUser","LnkGrpUser");
   return(1);
}



sub AutoFinishWorkflows  
{
   my $self=shift;
   my $class=shift;
   if ($class=~m/^\s*$/ || $class=~m/^\*+$/){
      msg(ERROR,"no class defined in AutoFinishWorkflows");
      return({exitcode=>1,msg=>'commandline error'});
   }
   if ($class=~m/[,; ]/ && !($class=~m/\*/)){
      my @class=split(/[,; ]+/,$class);
      $class=\@class;
   }
   my $CleanupWorkflow=shift;
   my $wf=getModuleObject($self->Config,"base::workflow");
   my $wfop=$wf->Clone();
   if ($CleanupWorkflow eq ""){
      $CleanupWorkflow=$self->Config->Param("AutoFinishWorkflow");
   }
   $CleanupWorkflow="<now-84d" if ($CleanupWorkflow eq "");


   foreach my $stateid (qw(16 17 10)){
      $wf->SetFilter({stateid=>\$stateid,
                      class=>$class,
                      mdate=>$CleanupWorkflow."+28d"});
      $wf->SetCurrentView(qw(id closedate stateid class));
      $wf->SetCurrentOrder(qw(NONE));
      $wf->Limit(100);
      my $c=0;
      
      my ($rec,$msg)=$wf->getFirst(unbuffered=>1);
      if (defined($rec)){
         do{
            msg(INFO,"process $rec->{id} class=$rec->{class}");
            if (1){
               if ($wfop->Action->StoreRecord($rec->{id},"wfautofinish",
                   {translation=>'base::workflowaction'},"",undef)){
                  my $closedate=$rec->{closedate};
                  $closedate=NowStamp("en") if ($closedate eq "");
                  #printf STDERR ("info: fifi autoclose wfid=$rec->{id}\n");
                
                  $wfop->UpdateRecord({stateid=>21,closedate=>$closedate},
                                      {id=>\$rec->{id}});
                  $wfop->StoreUpdateDelta({id=>$rec->{id},
                                         stateid=>$rec->{stateid}},
                                        {id=>$rec->{id},
                                         stateid=>21});
               }
            }
            ($rec,$msg)=$wf->getNext();
         } until(!defined($rec));
      }
   }


}

sub LnkGrpUser
{
   my $self=shift;

   my $lnk=getModuleObject($self->Config,"base::lnkgrpuser");
   my $nowstamp=NowStamp("en");
   $lnk->SetFilter({expiration=>"<\"$nowstamp\""});
   my $oldcontext=$W5V2::OperationContext;
   $W5V2::OperationContext="Kernel";

   foreach my $lrec ($lnk->getHashList(qw(ALL))){
      my $dur=CalcDateDuration($lrec->{expiration},$nowstamp);
      my $days=$dur->{totalseconds}/86400;
      if ($days>56){           # das muss irgenwann mal rein
         # sofort löschen
      }
      elsif($days>30){
         if ($lrec->{alertstate} ne "red"){
            $lnk->ValidatedUpdateRecord($lrec,{alertstate=>'red',
                                               editor=>$lrec->{editor},
                                               roles=>$lrec->{roles},
                                               realeditor=>$lrec->{realeditor},
                                               mdate=>$lrec->{mdate}},
                                       {lnkgrpuserid=>\$lrec->{lnkgrpuserid}});
         }
         # red setzen
      }
      elsif($days>14){
         if ($lrec->{alertstate} ne "orange"){
            if ($lnk->ValidatedUpdateRecord($lrec,
                                            {alertstate=>'orange',
                                             editor=>$lrec->{editor},
                                             roles=>$lrec->{roles},
                                             realeditor=>$lrec->{realeditor},
                                             mdate=>$lrec->{mdate}},
                                       {lnkgrpuserid=>\$lrec->{lnkgrpuserid}})){
               $self->NotifyUser($lrec);
            }
         }
         # orange setzen und mail verschicken
      } 
      else{
         # yellow setzen und mail verschicken
         if ($lrec->{alertstate} ne "yellow"){
            if ($lnk->ValidatedUpdateRecord($lrec,
                      {alertstate=>'yellow',
                       editor=>$lrec->{editor},
                       realeditor=>$lrec->{realeditor},
                       roles=>$lrec->{roles},
                       mdate=>$lrec->{mdate}},
                      {lnkgrpuserid=>\$lrec->{lnkgrpuserid}})){
               $self->NotifyAdmin($lrec);
            }
         }
      }
      
     # msg(INFO,Dumper($lrec));
     # msg(INFO,Dumper($dur));
   }
   $W5V2::OperationContext=$oldcontext;

#   my $wf=getModuleObject($self->Config,"base::workflow");
#   if (my $id=$wf->Store(undef,{
#          class    =>'base::workflow::mailsend',
#          step     =>'base::workflow::mailsend::dataload',
#          name     =>'eine Mail vom Testevent1 mit äöüß',
#          emailtext=>'Hallo Welt'
#         })){
#      my $r=$wf->Store($id,step=>'base::workflow::mailsend::waitforspool');
#      return({msg=>'versandt'});
#   }
   return({msg=>'shit'});
}


sub getAdmins
{
   my $self=shift;

   my $lnkgrp=getModuleObject($self->Config,"base::lnkgrpuser");
   my $user=getModuleObject($self->Config,"base::user");
   my @userid;
   $lnkgrp->SetFilter({group=>\"admin"});
   foreach my $lnk ($lnkgrp->getHashList(qw(userid))){
      push(@userid,$lnk->{userid});
   }
   my @res;
   if ($#userid!=-1){
      $user->SetFilter({userid=>\@userid,cistatusid=>\'4',
                        usertyp=>\'user'});
      foreach my $urec ($user->getHashList(qw(fullname lastlang email))){
         push(@res,{fullname=>$urec->{fullname},
                    lastlang=>$urec->{lastlang},
                    email=>$urec->{email}});
      }
   }
   return(@res);
}

sub NotifyAdmin
{
   my $self=shift;
   my $lrec=shift;

   if (ref($lrec->{roles}) eq "ARRAY"){
      my $lnkgrp=getModuleObject($self->Config,"base::lnkgrpuser");
      my $user=getModuleObject($self->Config,"base::user");
      my $userid=$lrec->{userid};
      my $group=$lrec->{group};
      $user->SetFilter({userid=>\$userid});
      my ($urec,$msg)=$user->getOnlyFirst(qw(fullname cistatusid email));
      if (defined($urec) && $urec->{cistatusid}==4){
         foreach my $arec ($self->getAdmins()){
            if ($arec->{lastlang} ne ""){
               $ENV{HTTP_FORCE_LANGUAGE}=$arec->{lastlang};
            }
            my $tmpl=$lnkgrp->getParsedTemplate(
                     "tmpl/event.cleanup.relation.admin",
                     {current=>$lrec});
            my $baseurl=$self->Config->Param("EventJobBaseUrl");
            my $directlink=$baseurl."/auth/base/lnkgrpuser/Detail?".
                           "search_lnkgrpuserid=$lrec->{lnkgrpuserid}";
            my %notiy;
            $notiy{emailfrom}=$urec->{email};
            $notiy{emailto}=$arec->{email};
            $notiy{name}=$self->T("admin info: relation expired").": ".$group;
            my $sitename=$self->Config->Param("SITENAME");
            if ($sitename ne ""){
               $notiy{name}=$sitename.": ".$notiy{name};
            }
            $notiy{emailtext}=$tmpl."\nDirectLink:\n".$directlink;
            $notiy{class}='base::workflow::mailsend';
            $notiy{step}='base::workflow::mailsend::dataload';
            
            my $wf=getModuleObject($self->Config,"base::workflow");
            if (my $id=$wf->Store(undef,\%notiy)){
               my %d=(step=>'base::workflow::mailsend::waitforspool');
               my $r=$wf->Store($id,%d);
            }
            delete($ENV{HTTP_FORCE_LANGUAGE});
         }
      }
   }
}


sub NotifyUser
{
   my $self=shift;
   my $lrec=shift;

   if ($lrec->{usertyp} eq "user"){   # the relation effects on an real user
      my %admins;
      foreach my $arec ($self->getAdmins()){
         $admins{$arec->{email}}++;
      }
      if ($lrec->{email} ne "" && ref($lrec->{roles}) eq "ARRAY"){
         my $lnkgrp=getModuleObject($self->Config,"base::lnkgrpuser");
         my $user=getModuleObject($self->Config,"base::user");
         my $userid=$lrec->{userid};
         my $group=$lrec->{group};
         $user->SetFilter({userid=>\$userid});
         my ($urec,$msg)=$user->getOnlyFirst(qw(fullname lastlang email
                                                cistatusid));
         if (defined($urec) && $urec->{cistatusid}==4){
            if ($urec->{lastlang} ne ""){
               $ENV{HTTP_FORCE_LANGUAGE}=$urec->{lastlang};
            }
            my $tmpl=$lnkgrp->getParsedTemplate(
                     "tmpl/event.cleanup.relation.user",
                     {current=>$lrec});
            my $baseurl=$self->Config->Param("EventJobBaseUrl");
            my $directlink=$baseurl."/auth/base/lnkgrpuser/Detail?".
                           "search_lnkgrpuserid=$lrec->{lnkgrpuserid}";
            my %notiy;
            $notiy{emailto}=$urec->{email};
            $notiy{emailcc}=[keys(%admins)];
            $notiy{name}=$self->T("relation expired").": ".$group;
            my $sitename=$self->Config->Param("SITENAME");
            if ($sitename ne ""){
               $notiy{name}=$sitename.": ".$notiy{name};
            }
            $notiy{emailtext}=$tmpl."\nDirectLink:\n".$directlink;
            $notiy{class}='base::workflow::mailsend';
            $notiy{step}='base::workflow::mailsend::dataload';
            
            my $wf=getModuleObject($self->Config,"base::workflow");
            if (my $id=$wf->Store(undef,\%notiy)){
               my %d=(step=>'base::workflow::mailsend::waitforspool');
               my $r=$wf->Store($id,%d);
            }
            delete($ENV{HTTP_FORCE_LANGUAGE});
         }
         #printf STDERR ("lrec=%s\n",Dumper($lrec));
      }
   }
}




1;
