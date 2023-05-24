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
   $self->RegisterEvent("CleanupAPIKeys","cleanAPIKeys");
   $self->RegisterEvent("CleanupWebFS","CleanupWebFS");
   $self->RegisterEvent("CleanupInterview","CleanupInterview");
   $self->RegisterEvent("CleanupLnkContact","CleanupLnkContact");
   $self->RegisterEvent("CleanupLnkContactExp","CleanupLnkContactExp");
   $self->RegisterEvent("CleanupLnkMandatorContact","LnkMandatorContact");

   $self->RegisterEvent("CleanupSampleMultiEvent1","CleanupSampleMultiEvent1");
   $self->RegisterEvent("Cleanup","CleanupSampleMultiEvent1");

   $self->RegisterEvent("CleanupSampleMultiEvent2","CleanupSampleMultiEvent2");
   $self->RegisterEvent("Cleanup","CleanupSampleMultiEvent2");
   return(1);
}


sub CleanupSampleMultiEvent1
{
   my $self=shift;
   msg(INFO,"CleanupMultiEvent1:1");

   return({exitcode=>0});
}

sub CleanupSampleMultiEvent2
{
   my $self=shift;
   msg(INFO,"CleanupMultiEvent2:2");

   return({exitcode=>0});
}


sub CleanupInterview
{
   my $self=shift;

   my $obj=getModuleObject($self->Config,"base::interview");
   return($obj->CleanupInterview());
}


sub cleanAPIKeys
{
   my $self=shift;

   my $obj=getModuleObject($self->Config,"base::useraccount");
   return($obj->CleanupUnunsedAPIKeys());
}


sub LnkMandatorContact
{
   my $self=shift;
   my %param=@_;
   $param{flt}={parentobj=>'base::mandator'};

   return($self->CleanupLnkContact(%param));
}





sub CleanupLnkContactExp
{
   my $self=shift;
   my %param=@_;

   my $obj=getModuleObject($self->Config,"base::lnkcontact");
   my $objop=$obj->Clone();


   $obj->SetFilter({expiration=>"<now-14d"});
   $obj->SetCurrentView(qw(ALL));
   
   my ($rec,$msg)=$obj->getFirst(unbuffered=>1);
   my $c=0;
   my %o;
   my $deletecount=0;
   if (defined($rec)){
      do{
         my $needdelete=1;
         msg(INFO,"process $rec->{parentobj} ($rec->{refid})");
         if ($needdelete){
            $W5V2::HistoryComments="base::event::CleanupLnkContactExp\n".
                                   "by expiration $rec->{expiration}\n";
            $objop->ValidatedDeleteRecord($rec);
            $W5V2::HistoryComments=undef;
            $deletecount++;
         }
         #if ($deletecount){
         #   return({exitcode=>0,deletecount=>$deletecount});
         #}
         ($rec,$msg)=$obj->getNext();
      } until(!defined($rec));
   }
   return({exitcode=>0,deletecount=>$deletecount});
}


sub CleanupLnkContact
{
   my $self=shift;
   my %param=@_;

   my $obj=getModuleObject($self->Config,"base::lnkcontact");
   my $objop=$obj->Clone();
   $obj->SetCurrentView(qw(ALL));
   
   if (exists($param{flt})) {
      $obj->SetFilter($param{flt});
   }

   my ($rec,$msg)=$obj->getFirst(unbuffered=>1);
   my $c=0;
   my %o;
   my $deletecount=0;
   if (defined($rec)){
      do{
         my $needdelete=0;
         msg(INFO,"process $rec->{parentobj} ($rec->{refid})");
         if (!exists($o{$rec->{parentobj}})){
            $o{$rec->{parentobj}}=
               getModuleObject($self->Config,$rec->{parentobj}); 
         }
         if (!exists($o{$rec->{parentobj}}) || !defined($o{$rec->{parentobj}})){
            $needdelete++;
         }
         if (!$needdelete){
            my $idobj=$o{$rec->{parentobj}}->IdField(); 
            if (!defined($idobj)){
               die("fail to detect idobj in $rec->{parentobj}");
            }
            my $idname=$idobj->Name();
            $o{$rec->{parentobj}}->ResetFilter();
            $o{$rec->{parentobj}}->SetFilter({$idname=>\$rec->{refid}});
            my ($refrec)=$o{$rec->{parentobj}}->getOnlyFirst($idname);
            if (!defined($refrec)){
               $needdelete++;
            }
         }

         if ($needdelete){
            $objop->ValidatedDeleteRecord($rec);
            $deletecount++;
         }
         ($rec,$msg)=$obj->getNext();
      } until(!defined($rec));
   }
   return({exitcode=>0,deletecount=>$deletecount});
}



sub CleanupWebFS
{
   my $self=shift;
   my %param=@_;

   if ($param{'path'} eq ""){
      return({exitcode=>1,msg=>'no cleanup path specified'});
   }
   $param{'path'}=~s/^webfs:\///i;
   $param{'path'}=~s/^\///i;

   if ($param{'cdate'} eq ""){
      return({exitcode=>1,msg=>'no cleanup cdate specified'});
   }
   my $j=getModuleObject($self->Config,"base::joblog");
   my $webfs=getModuleObject($self->Config,"base::filemgmt");
   my $webfsop=$webfs->Clone();
   $webfs->SetFilter({fullname=>$param{'path'},
                      cdate=>$param{'cdate'},
                      parentobj=>\'base::filemgmt',
                      entrytyp=>\'file'});
   $webfs->SetCurrentView(qw(ALL));
   my ($rec,$msg)=$webfs->getFirst(unbuffered=>1);
   my $c=0;
   if (defined($rec)){
      do{
         msg(INFO,"process $rec->{fullname}");
         if ($param{force} ne "1"){
            msg(ERROR,"'$rec->{fullname}' ($rec->{cdate}) ".
                      "delete needed but no force set");
         }
         else{
            if ($webfsop->ValidatedDeleteRecord($rec)){
               $j->ValidatedInsertRecord({event=>'CleanupWebFS '.
                                         join(" ",map({"'".$_."'"} %param)),
                                          pid=>$$,
                                          exitcode=>0,
                                          method=>"unlink('$rec->{fullname}')",
                                          exitmsg=>"'$rec->{fullname}' deleted",
                                          exitstate=>'OK'});
               $c++;
            }
         }
         ($rec,$msg)=$webfs->getNext();
      } until(!defined($rec));
   }
   return({exitcode=>0,msg=>"$c files deleted"});
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


   my $c=0;
   foreach my $stateid (qw(16 17 10)){
      $wf->SetFilter({stateid=>\$stateid,
                      class=>$class,
                      mdate=>$CleanupWorkflow});
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
                  $c++;
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
   return({exitcode=>0,msg=>"$c workflows finished"});

}

sub LnkGrpUser
{
   my $self=shift;

   my $lnk=getModuleObject($self->Config,"base::lnkgrpuser");
   my $lnkop=$lnk->Clone();
   my $nowstamp=NowStamp("en");

   if (1){
      $lnk->ResetFilter();
      $lnk->SetFilter([
         { usercistatusid=>\undef },
         { grpcistatusid=>\undef  }
      ]);

      foreach my $lrec ($lnk->getHashList(qw(ALL))){ #hard del relation records,
         $lnkop->ValidatedDeleteRecord($lrec);       #if contactrec or grprec
      }                                              #does not exists (anymore)
   }
   if (1){
      $lnk->ResetFilter();
      $lnk->SetFilter({ 
         grpcistatusid=>">5",
         grpmdate=>"<now-7d",
         expiration=>\undef
     });
     
      foreach my $lrec ($lnk->getHashList(qw(ALL))){ 
         if ($lrec->{usercistatusid}<6){   # contact existiert noch
            my $exp=$lnkop->ExpandTimeExpression("now+30d");
            $lnkop->ValidatedUpdateRecord($lrec,{
               expiration=>$exp
            },{lnkgrpuserid=>\$lrec->{lnkgrpuserid}});
         }
         else{
            $lnkop->ValidatedDeleteRecord($lrec);
         }
      }                                             
   }                                             

   if (1){
      $lnk->ResetFilter();
      $lnk->SetFilter({ 
         usercistatusid=>">5",
         usermdate=>"<now-7d",
         expiration=>\undef
      });
     
      foreach my $lrec ($lnk->getHashList(qw(ALL))){ 
         if ($lrec->{grpcistatusid}<6){   # contact existiert noch
            my $exp=$lnkop->ExpandTimeExpression("now+30d");
            $lnkop->ValidatedUpdateRecord($lrec,{
               expiration=>$exp
            },{lnkgrpuserid=>\$lrec->{lnkgrpuserid}});
         }
         else{
            $lnkop->ValidatedDeleteRecord($lrec);
         }
      }                                             
   }                                             




   if (1){
      $lnk->ResetFilter();
      $lnk->SetFilter({expiration=>"<\"$nowstamp+28d\""});
      my $oldcontext=$W5V2::OperationContext;
      $W5V2::OperationContext="Kernel";
     
      foreach my $lrec ($lnk->getHashList(qw(ALL))){
         my $dur=CalcDateDuration($lrec->{expiration},$nowstamp);
         my $days=$dur->{totalseconds}/86400;
         if ($days>28){     
            # sofort löschen
            $lnkop->ValidatedDeleteRecord($lrec);
         }
         elsif($days>0){
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
         elsif($days>-21){
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
   }

   return({exitcode=>0,msg=>'OK'});
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
      foreach my $urec ($user->getHashList(qw(fullname lastlang 
                                              banalprotect
                                              email))){
         push(@res,{fullname=>$urec->{fullname},
                    lastlang=>$urec->{lastlang},
                    banalprotect=>$urec->{banalprotect},
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
            next if ($arec->{banalprotect});
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
            my $fakeFrom=$urec->{fullname};
            $fakeFrom=~s/"//g;
            $fakeFrom="\"$fakeFrom\" <>";
            $notiy{emailfrom}=$fakeFrom;
            $notiy{emailto}=$arec->{email};
            $notiy{emailcategory}='GroupRelationExpiredAdminInfo';
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

   if ($lrec->{usertyp} eq "user" ||
       $lrec->{usertyp} eq "service"){   # the relation effects on an real user
      my %admins;
      foreach my $arec ($self->getAdmins()){
         next if ($arec->{banalprotect});
         $admins{$arec->{email}}++;
      }
      if ($lrec->{email} ne "" && ref($lrec->{roles}) eq "ARRAY"){
         my $lnkgrp=getModuleObject($self->Config,"base::lnkgrpuser");
         my $user=getModuleObject($self->Config,"base::user");
         my $grp=getModuleObject($self->Config,"base::grp");
         my $grpid=$lrec->{grpid};
         my $userid=$lrec->{userid};
         my $group=$lrec->{group};
         $user->SetFilter({userid=>\$userid});
         my ($urec,$msg)=$user->getOnlyFirst(qw(fullname lastlang email
                                                cistatusid banalprotect));
         $grp->SetFilter({grpid=>\$grpid});
         my ($grec,$msg)=$grp->getOnlyFirst(qw(fullname cistatusid ));
         if (defined($urec) && $urec->{cistatusid}==4 && $lrec->{roles} ne "" &&
             defined($grec)){
            if ($urec->{lastlang} ne ""){
               $ENV{HTTP_FORCE_LANGUAGE}=$urec->{lastlang};
            }
            my $templatename="tmpl/event.cleanup.relation.user";
            if ($grec->{cistatusid}==6){  # relation to deleted group
               $templatename="tmpl/event.cleanup.dead.relation.user";
            }

            my $tmpl=$lnkgrp->getParsedTemplate($templatename,{current=>$lrec});
            my $baseurl=$self->Config->Param("EventJobBaseUrl");
            my $directlink=$baseurl."/auth/base/lnkgrpuser/Detail?".
                           "search_lnkgrpuserid=$lrec->{lnkgrpuserid}";
            my $groupinfo=$baseurl."/auth/base/menu/msel/sysadm/userenv".
                          "?OpenURL=%23groups";
            my %notiy;
            if (!$urec->{banalprotect}){
               $notiy{emailto}=$urec->{email};
            }
            else{ # hier könnte man die Support Adresse einfügen
               $notiy{emailto}=[];
               $user->ResetFilter();
               $user->SetFilter({cistatusid=>\'4',isw5support=>\'1'});
               foreach my $sup ($user->getHashList(qw(email))){
                  if ($sup->{email} ne ""){
                     push(@{$notiy{emailto}},$sup->{email});
                  }
               }
            }
            $notiy{emailcc}=[keys(%admins)];
            $notiy{emailcategory}='GroupRelationExpiredUserInfo';
            $notiy{name}=$self->T("relation nearly expired").": ".$group;
            if ($grec->{cistatusid}==6){
               $notiy{name}=$self->T("relation expired").": ".$group;
            }
            my $sitename=$self->Config->Param("SITENAME");
            if ($sitename ne ""){
               $notiy{name}=$sitename.": ".$notiy{name};
            }
            $tmpl.="\n<br>".$self->T("List your current group relations").
                   ":<br>".$groupinfo;
            $tmpl.="\n<br>DirectLink:<br>".$directlink;
           

            my $supportnote=$user->getParsedTemplate(
                              "tmpl/mailsend.supportnote",{
                                 static=>{
                                 }
                              });
            if ($supportnote ne ""){
               $tmpl.="\n<br>\n";
               $tmpl.=$supportnote;
            }



            $notiy{emailtext}=$tmpl;
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
