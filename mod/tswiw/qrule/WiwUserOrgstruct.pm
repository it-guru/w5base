package tswiw::qrule::WiwUserOrgstruct;
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
use kernel::QRule;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return(["base::user"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $errorlevel=0;


   if ($rec->{dsid} ne ""){ # Das haben nur in CIAM gefundene Datensätze
      return($errorlevel,undef);
   }

   my $Config=$self->getParent->Config;
   $self->{SRCSYS}="WhoIsWho";

   my $user=getModuleObject($Config,"base::user");
   my $mainuser=getModuleObject($Config,"base::user");
   my $grp=getModuleObject($Config,"base::grp");
   my $grpuser=getModuleObject($Config,"base::lnkgrpuser");
   my $wiwusr=getModuleObject($Config,"tswiw::user");
   my $wiworg=getModuleObject($Config,"tswiw::orgarea");

   if (!defined($wiwusr) ||
       !defined($wiworg) ||
       !defined($grpuser)||
       !defined($user)   ||
       !defined($mainuser)   ||
       !defined($grp)){
      msg(ERROR,"WiwUserOrgstruct can't connect nesassary information objects");
      return($errorlevel,undef);
   }


   $mainuser->ResetFilter();
   $mainuser->SetFilter({userid=>\$rec->{userid}});
   my ($urec)=$mainuser->getOnlyFirst(qw(email surname givenname usertyp 
                                         groups posix cistatusid lastlogon
                                         fullname));
   if (defined($urec)){ # found correct urec record for user
      if (defined($urec) && $urec->{email} ne "" &&
          $urec->{email} ne 'null@null.com' &&
          (!($urec->{surname}=~m/_duplicate_/i)) &&
          $urec->{usertyp} eq "user"){     # it seems to be a correct email
         msg(INFO,"processing email addr '%s'",$urec->{email});
         my @curgrpid=$self->extractCurrentGrpIds($urec);
         msg(INFO,"grpids='%s'",join(",",@curgrpid));
         msg(INFO,"validateing userid=$urec->{userid} requested");

         #
         # loading the "should" sitiuation from wiw
         #
         msg(DEBUG,"trying to load userinformations from wiw");
         $wiwusr->SetFilter([{email=>$urec->{email}},
                             {email2=>$urec->{email}},
                             {email3=>$urec->{email}}]);
         my ($wiwrec,$msg)=$wiwusr->getOnlyFirst(qw(ALL));
         if (!defined($wiwrec)){
            if (defined($msg)){
               msg(ERROR,"LDAP problem:%s",$msg);
            }
            if ($urec->{posix} ne "" && $urec->{cistatusid}<6){
               my $old=0;
               my $age;
               if ($urec->{lastlogon} eq ""){
                  $old=1;
               }
               else{
                  my $d=CalcDateDuration($urec->{lastlogon},NowStamp("en"));
                  if (defined($d)){
                     $age=$d->{totalminutes};
                  }
                  if (!defined($d) || $age>80640){ # 8 weeks
                      $old=1;
                  }
               }
               if ($old){
                  if (!($urec->{email}=~m/\@telekom\.de$/i)){
                     $wiwusr->Log(ERROR,"basedata",
                                  "E-Mail '%s' not found in LDAP (WhoIsWho) ".
                                  "but with POSIX entry",$urec->{email});
                  }
                  else{
                     if (!defined($age) || $age>259200){ # half year
                        $wiwusr->Log(ERROR,"basedata",
                            "Contact '%s'\nseems to be a telekom ".
                            "contact, which have\nleave the organisation.".
                            "\nPlease check the existence. If he not\n".
                            "leave the organisation, clear the posix entry.".
                            "\n-",
                            $urec->{fullname});
                     }
                  }
               }
            }
            return($errorlevel,undef);
         }


         my $wiwid=$wiwrec->{id};
         my $touid=$wiwrec->{touid};
         my $surname=$wiwrec->{surname};
         my $givenname=$wiwrec->{givenname};
         my $uidlist=$wiwrec->{uid};
         $uidlist=[$uidlist] if (ref($uidlist) ne "ARRAY");
         my @posix=grep(!/^[A-Z]{1,3}\d+$/,@{$uidlist});
         my $posix=$posix[0];

         my $wrs=$wiwrec->{office_wrs};
         my $wiwstate=$wiwrec->{office_state};

         if ($wiwstate eq "DTAG User"){
            $wiwusr->Log(ERROR,"basedata",
                "Contact '%s'\nseems to be a WebEx/SCP only user. ".
                "Please check this and then clear the posix entry.".
                "\n-",
                $urec->{fullname});
            return($errorlevel,undef);
         }

         my $level1role="RFreelancer";
         if ($wiwstate eq "Intern" ||
             $wiwstate eq "Manager" ||
             $wiwstate eq "Employee"){
            $level1role="REmployee";
         }
         if ($wrs eq "Auszubildender"){
            $level1role="RApprentice";
         }
         msg(INFO,"organizationalstatus=$wiwstate --- w5base role=$level1role");
         

         #
         # hinzufügen der Userrollen
         #
         if ($touid ne ""){
            $wiworg->SetFilter({touid=>\$touid});
            my ($wiwrec,$msg)=$wiworg->getOnlyFirst(qw(touid name parentid 
                                                       parent shortname));
            if (defined($wiwrec)){
               my $bl=getModuleObject($dataobj->Config,"base::userblacklist");
               if (!$bl->checkLock('lockorgtransfer',[
                                   {posix=>$urec->{posix}},
                                   {email=>\$urec->{email}}])){
                  my $bk=$self->addGrpLinkToUser($grp,$wiworg,$grpuser,
                                                 $wiwrec,$urec,
                                                 [$level1role,'RMember']);
                  return($errorlevel,undef) if (defined($bk));
               }
            }
            else{
               if (defined($msg)){
                  msg(ERROR,"LDAP problem - Orgsearch:%s",$msg);
               }
               msg(ERROR,"WIW Orgarea '%s' not found for user '%s'",
                   $touid,$urec->{email});
            }
         }
         else{
            msg(DEBUG,"user '%s' has no orgarea",$urec->{email});
         }



         my @curbossgroups=$self->extractCurrentGrpIds($urec,["RBoss"]);
         #
         # load current boss srcids from groups
         #
         $grp->SetFilter({grpid=>\@curbossgroups,srcsys=>\$self->{SRCSYS}});
         $grp->SetCurrentView(qw(grpid srcid srcsys srcload));
         my $curbossgrps=$grp->getHashIndexed(qw(grpid srcid));
         my @bossgrpsrcid=();
         if (ref($curbossgrps->{srcid}) eq "HASH"){
            @bossgrpsrcid=keys(%{$curbossgrps->{srcid}});
         }


         #
         # hinzufügen der Leiter rollen
         #
         if (!defined($wiwid) || $wiwid eq ""){
            msg(ERROR,"can't find wiwid of user '%s'",$urec->{email});
            return($errorlevel,undef);
         }
         $wiworg->SetFilter({mgrwiwid=>\$wiwid});
         foreach my $wiwrec ($wiworg->getHashList(
                              qw(touid name parentid parent shortname))){
            if ($wiwrec->{touid}=~m/^\S+$/){
               @bossgrpsrcid=grep(!/^$wiwrec->{touid}$/,@bossgrpsrcid);
            }
            my $bk=$self->addGrpLinkToUser($grp,$wiworg,$grpuser,
                                           $wiwrec,$urec,
                                           ['RBoss']);
            return($errorlevel,undef) if (defined($bk));
         }
         if ($#bossgrpsrcid!=-1){
            $wiwusr->Log(WARN,"basedata",
                         "removing RBoss from User '%s' on group touid='%s'",
                         $urec->{email},join(",",@bossgrpsrcid));
            my $lnkgrpuserrole=getModuleObject($Config,"base::lnkgrpuserrole");
            my $lnkgrpuserroleop=$lnkgrpuserrole->Clone();
            $grp->SetFilter({srcid=>\@bossgrpsrcid,
                             srcsys=>\$self->{SRCSYS}});
            foreach my $rgrprec ($grp->getHashList("grpid")){
               $lnkgrpuserrole->ResetFilter();
               $lnkgrpuserrole->SetFilter({userid=>\$urec->{userid},
                                           grpid=>\$rgrprec->{grpid},
                                           nativrole=>\'RBoss'});
               foreach my $lnkrec ($lnkgrpuserrole->getHashList("ALL")){
                  $lnkgrpuserroleop->ValidatedDeleteRecord($lnkrec);
               }
            }
         }


         if ($posix ne "" && defined($urec->{userid})){
            my %upd=(posix=>$posix,
                     surname=>$surname,
                     givenname=>$givenname);
            msg(DEBUG,"Refreshing posix id '$posix' of user '%s'",
                $urec->{email});
            my $back=$user->ValidatedUpdateRecord($urec,\%upd,
                                 {userid=>\$urec->{userid}});
         }
         else{
            msg(DEBUG,"no posix update posix='$posix' ".
                      "userid='$urec->{userid}'");
         }
      }
   }
   return($errorlevel,undef);
}

sub extractCurrentGrpIds
{
   my $self=shift;
   my $urec=shift;
   my $chkroles=shift;

   $chkroles=[orgRoles()] if (!defined($chkroles));

   my @curgrpid=();
   msg(DEBUG,"processing email addr '%s'",$urec->{email});
   if (defined($urec->{groups}) && ref($urec->{groups}) eq "ARRAY"){
      foreach my $grp (@{$urec->{groups}}){
         $grp->{roles}=[] if (!defined($grp->{roles}));
         if (in_array($grp->{roles},$chkroles)){
            push(@curgrpid,$grp->{grpid});
         }
      }
   }
   return(@curgrpid);
}


sub addGrpLinkToUser
{
   my $self=shift;
   my $grp=shift;     # communication object
   my $wiworg=shift;  # communication object
   my $grpuser=shift; # communication object
   my $wiwrec=shift;    # wiw orgarea record
   my $urec=shift;      # aktueller User record
   my $roles=shift;     # array auf zuzuweisende rollen

   my $app=$self->getParent();
   my $nowstamp=$app->ExpandTimeExpression("now","en","GMT","GMT");
   my $grpid2add=$self->getGrpIdOf($grp,$wiworg,$wiwrec);
   if (defined($grpid2add)){
      $grpuser->SetFilter({userid=>\$urec->{userid},
                           grpid=>\$grpid2add});
      $grpuser->SetCurrentView(qw(grpid userid lnkgrpuserid roles 
                                  srcsys srcid srcload));
      my ($lnkrec,$msg)=$grpuser->getFirst();
      my $oldrolestring="";
      my $newrolestring="";
      if (defined($lnkrec)){
         my %newroles;
         my @oldroles;
         my @origroles;
         if (defined($lnkrec->{roles})){
            @origroles=@{$lnkrec->{roles}};
         }
         if (!in_array($roles,"RBoss")){
            my @orgRoles=grep(!/^RBoss$/,orgRoles()); # RBoss muss bleiben!
            $oldrolestring=join(",",sort(@{$lnkrec->{roles}}));
            foreach my $r (@{$lnkrec->{roles}}){
               push(@oldroles,$r) if (!in_array(\@orgRoles,$r));
            }
         }
         else{
            @oldroles=@{$lnkrec->{roles}};
         }
         foreach my $r (@$roles,@oldroles){
            $newroles{$r}++;
         }
         $newrolestring=join(",",sort(keys(%newroles)));
         my %newlnk=(roles=>[keys(%newroles)],
                     expiration=>undef,
                     alertstate=>undef,
                     srcsys=>$self->{SRCSYS},
                     srcid=>"none",
                     srcload=>$nowstamp);
         my $bk=$grpuser->ValidatedUpdateRecord($lnkrec,\%newlnk,
                            {lnkgrpuserid=>$lnkrec->{lnkgrpuserid}});
         if (!in_array(\@origroles,$roles->[0])){
            $self->NotifyNewTeamRelation($lnkrec->{lnkgrpuserid},
                                         $urec->{userid},$grpid2add,"Rchange",
                                         $roles);
         }
      }
      else{
         $newrolestring=join(",",sort(@$roles));
         my %newlnk=(userid=>$urec->{userid},
                     roles=>$roles,
                     srcsys=>$self->{SRCSYS},
                     srcload=>$nowstamp,
                     expiration=>undef,
                     alertstate=>undef,
                     grpid=>$grpid2add);
         #printf STDERR ("fifi try to create lnk %s\n",Dumper(\%newlnk));
         my $bk=$grpuser->ValidatedInsertRecord(\%newlnk);
         if ($bk){
            $self->NotifyNewTeamRelation($bk,$urec->{userid},$grpid2add,"Rnew",
                                         $roles)
         }
      }
   }
   else{
      msg(ERROR,"Can't create group for user '$urec->{email}'");
      msg(ERROR,$self->getParent->LastMsg());
   }
   return(undef);
}


sub getGrpIdOf
{
   my $self=shift;
   my $grp=shift;
   my $wiworg=shift;
   my $wiwrec=shift;

   msg(DEBUG,"try to find touid=$wiwrec->{touid} in base::grp");

   {  # prevent new create of groups, which already transfer to CIAM
      $grp->ResetFilter();
      $grp->SetFilter({ext_refid2=>'WhoIsWho:'.$wiwrec->{touid}});
      my ($rec,$msg)=$grp->getOnlyFirst();
      if (defined($rec)){
         return($rec->{grpid});
      }
   }

   $grp->ResetFilter();
   $grp->SetFilter({srcid=>\$wiwrec->{touid},srcsys=>\$self->{SRCSYS}});
   $grp->SetCurrentView(qw(grpid srcid srcsys srcload));
   my ($rec,$msg)=$grp->getOnlyFirst();
   if (defined($rec)){
      return($rec->{grpid});
   }
   return($self->createGrp($grp,$wiworg,$wiwrec));

}


sub createGrp
{
   my $self=shift;
   my $grp=shift;
   my $wiworg=shift;
   my $wiwrec=shift;

   msg(INFO,"try to create touid=$wiwrec->{touid} in base::grp");
   my $parentid;
   if (defined($wiwrec->{parentid})){
      $wiworg->SetFilter({touid=>[$wiwrec->{parentid}]});
      $wiworg->SetCurrentView(qw(touid name parentid parent shortname));
      my ($wiwrec,$msg)=$wiworg->getFirst();
      $parentid=$self->getGrpIdOf($grp,$wiworg,$wiwrec);
      if (!defined($parentid)){
         msg(ERROR,"problem in createGrp '$grp' from WiW ".
                   "tOuID $wiwrec->{touid}");
         return(undef);
      }
   }
   elsif ($wiwrec->{parentid} eq "DE039607"){  # T-Deutschland
      my @view=qw(id name);
      $grp->SetFilter({fullname=>\"DTAG.TDG"});
      $grp->SetCurrentView(@view);
      my ($rec,$msg)=$grp->getFirst();
      if (!defined($rec)){
         $grp->SetFilter({fullname=>\"DTAG"});
         $grp->SetCurrentView(@view);
         my ($rec,$msg)=$grp->getFirst();
         my $parentoftsi;
         if (!defined($rec)){
            my %newgrp=(name=>"DTAG",cistatusid=>4);
            my $back=$grp->ValidatedInsertRecord(\%newgrp);
            $parentoftsi=$back; 
         }
         else{
            $parentoftsi=$rec->{grpid};
         }
         my %newgrp=(name=>"TDG",parent=>'DTAG',cistatusid=>4);
         $parentid=$grp->ValidatedInsertRecord(\%newgrp);
      }
      else{
         $parentid=$rec->{grpid}; 
      }
   }
   else{
      # wenn keine parentid im WIW, dann mit DTAG.TSI "verbinden"
      my @view=qw(id name);
      $grp->SetFilter({fullname=>\"DTAG.TSI"});
      $grp->SetCurrentView(@view);
      my ($rec,$msg)=$grp->getFirst();
      if (!defined($rec)){
         $grp->SetFilter({fullname=>\"DTAG"});
         $grp->SetCurrentView(@view);
         my ($rec,$msg)=$grp->getFirst();
         my $parentoftsi;
         if (!defined($rec)){
            my %newgrp=(name=>"DTAG",cistatusid=>4);
            my $back=$grp->ValidatedInsertRecord(\%newgrp);
            $parentoftsi=$back; 
         }
         else{
            $parentoftsi=$rec->{grpid};
         }
         my %newgrp=(name=>"TSI",parent=>'DTAG',cistatusid=>4);
         $parentid=$grp->ValidatedInsertRecord(\%newgrp);
      }
      else{
         $parentid=$rec->{grpid}; 
      }
   }


   my $newname=$wiwrec->{shortname};
   if ($newname eq ""){
      msg(ERROR,"no shortname for id '$wiwrec->{touid}' found");
      return(undef);
   }
   ################################################################
   $newname=~s/[^A-Z\.0-9,-]/_/gi;    # rewriting for some shit names
   my %newgrp=(name=>$newname,
               srcsys=>$self->{SRCSYS},
               srcid=>$wiwrec->{touid},
               cistatusid=>4,
               srcload=>NowStamp(),
               comments=>"Description from WhoIsWho: ".$wiwrec->{name});
   $newgrp{name}=~s/&/_u_/g;
   $newgrp{parentid}=$parentid if (defined($parentid));
   my $back=$grp->ValidatedInsertRecord(\%newgrp);
   msg(DEBUG,"ValidatedInsertRecord returned=$back");

   return($back);
}

sub NotifyNewTeamRelation
{
   my $self=shift;
   my $relid=shift;
   my $userid=shift;
   my $grpid=shift;
   my $op=shift;
   my $roles=shift;
   my $Config=$self->getParent->Config();
   my $TargetPureName;
   msg(INFO,"NotifyNewTeamRelation: userid=$userid grpid=$grpid op=$op");

   my $user=getModuleObject($Config,"base::user");
   $user->SetFilter({userid=>\$userid,cistatusid=>"<6"});
   my ($urec)=$user->getOnlyFirst(qw(email lastlang purename banalprotect));

   my $grp=getModuleObject($Config,"base::grp");
   $grp->SetFilter({grpid=>\$grpid,cistatusid=>"<6"});
   my ($grec)=$grp->getOnlyFirst(qw(fullname));
   msg(INFO,"--------------");

   if (defined($urec) && defined($grec)){
      $TargetPureName=" ($urec->{purename})";
      if ($urec->{lastlang} ne ""){
         $ENV{HTTP_FORCE_LANGUAGE}=$urec->{lastlang};
      }
      else{
         $ENV{HTTP_FORCE_LANGUAGE}="de";
      }
      my @emailcc=();
      my @emailbcc=();
      my $wf=getModuleObject($Config,"base::workflow");
   
      my $grpuser=getModuleObject($Config,"base::lnkgrpuser");
      $grpuser->SetFilter({grpid=>\$grpid});
      foreach my $lnkrec ($grpuser->getHashList(qw(userid roles))){
         if (ref($lnkrec->{roles}) eq "ARRAY"){
            if (grep(/^(RBoss|RBoss2)$/,@{$lnkrec->{roles}})){
               $user->SetFilter({userid=>\$lnkrec->{userid}});
               my ($urec)=$user->getOnlyFirst(qw(email banalprotect));
               if (!$urec->{banalprotect}){
                  push(@emailcc,$urec->{email}) if ($urec->{email} ne "");
               }
               else{ # hier fügt Mann nun die Support Adresse einfügen
                  $user->ResetFilter();
                  $user->SetFilter({cistatusid=>\'4',isw5support=>\'1'});
                  foreach my $sup ($user->getHashList(qw(email))){
                     push(@emailcc,$sup->{email}) if ($sup->{email} ne "");
                  }
               }
            }
         }
      }
      # Admins hinzufügen  
      my $grpuser=getModuleObject($Config,"base::lnkgrpuser");
      $grpuser->SetFilter({grpid=>\'1'});   
      foreach my $lnkrec ($grpuser->getHashList(qw(userid roles))){
         if (ref($lnkrec->{roles}) eq "ARRAY"){
            if (grep(/^(RMember)$/,@{$lnkrec->{roles}})){
               $user->SetFilter({userid=>\$lnkrec->{userid}});
               my ($urec)=$user->getOnlyFirst(qw(email banalprotect));
               if (!$urec->{banalprotect}){
                  push(@emailbcc,$urec->{email}) if ($urec->{email} ne "");
               }
               else{ # hier fügt Mann nun die Support Adresse einfügen
                  $user->ResetFilter();
                  $user->SetFilter({cistatusid=>\'4',isw5support=>\'1'});
                  foreach my $sup ($user->getHashList(qw(email))){
                     push(@emailbcc,$sup->{email}) if ($sup->{email} ne "");
                  }
               }
            }
         }
      }
     

      my %adr=(emailfrom=>'"WhoIsWho to W5BaseDarwin" <no_reply@w5base.net>',
               emailcc=>\@emailcc,
               emailbcc=>\@emailbcc);
      if (!$urec->{banalprotect}){
         $adr{emailto}=$urec->{email};
      }
      else{ # hier könnte man die Support Adresse einfügen
         $user->ResetFilter();
         $user->SetFilter({cistatusid=>\'4',isw5support=>\'1'});
         $adr{emailto}=[];
         foreach my $sup ($user->getHashList(qw(email))){
            push(@{$adr{emailto}},$sup->{email}) if ($sup->{email} ne "");
         }
      }

      my $subject;
      my $mailtext;

      my $sitename=$Config->Param("SiteName");
      $sitename="W5Base" if ($sitename eq "");

    
      if ($op eq "Rnew"){
         $subject="$sitename: ".
                  $self->T("new org relation to")." ".$grec->{fullname}; 
         $mailtext=sprintf($self->T("MAILTEXT.NEW"),$TargetPureName,
                                                    $grec->{fullname});
      }
      else{
         $subject="$sitename: ".
                  $self->T("role update to")." ".$grec->{fullname}; 
         $mailtext=sprintf($self->T("MAILTEXT.UPDATE"),$TargetPureName,
                                                       $grec->{fullname});
      }
      my $baseurl=$Config->Param("EventJobBaseUrl");
      $baseurl.="/" if (!($baseurl=~m/\/$/));
      my $url=$baseurl;
      $url.="auth/base/lnkgrpuser/ById/".$relid;

      $mailtext.="\n\n   <b>Org-Unit:</b>\n".
                 "   ".$grec->{fullname};
      $mailtext.="\n\n   <b>".$self->T("added roles").":</b>\n";
      foreach my $r (@$roles){
         $mailtext.="   ".$self->T($r,"base::lnkgrpuserrole")."\n";
      }
     
      $mailtext.="\n\nDirectLink:\n".$url;
      my $label=$self->T("WhoIsWho to W5Base/Darwin automatic ".
                         "organisation relation administration:");
      my $supportnote=$user->getParsedTemplate(
                        "tmpl/mailsend.supportnote",{
                           static=>{
                           }
                        });
      if ($supportnote ne ""){
         $mailtext.=$supportnote;
      }
     
      if (my $id=$wf->Store(undef,{
              class    =>'base::workflow::mailsend',
              step     =>'base::workflow::mailsend::dataload',
              directlnktype =>'base::user',
              directlnkid   =>$userid,
              directlnkmode =>"mail.$op",
              name     =>$subject,
              %adr,
              emailhead=>$label,
              emailtext=>$mailtext,
              emailcategory =>['WIW',
                               'tswiw::qrule::WiwUserOrgstruct',
                               'NewOrgRelation']
             })){
         my %d=(step=>'base::workflow::mailsend::waitforspool');
         my $r=$wf->Store($id,%d);
      }
      delete($ENV{HTTP_FORCE_LANGUAGE});
   }
}




1;
