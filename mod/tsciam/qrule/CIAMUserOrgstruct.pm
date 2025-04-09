package tsciam::qrule::CIAMUserOrgstruct;
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
   my $forcedupd={};
   my $wfrequest={};
   my @qmsg;
   my @dataissue;

   my $Config=$self->getParent->Config;
   $self->{SRCSYS}="CIAM";

   my $user=getModuleObject($Config,"base::user");
   my $mainuser=getModuleObject($Config,"base::user");
   my $grp=getModuleObject($Config,"base::grp");
   my $grpuser=getModuleObject($Config,"base::lnkgrpuser");
   my $ciamusr=getModuleObject($Config,"tsciam::user");
   my $ciamorg=getModuleObject($Config,"tsciam::orgarea");

   if (!defined($ciamusr) ||
       !defined($ciamorg) ||
       !defined($grpuser)||
       !defined($user)   ||
       !defined($mainuser)   ||
       !defined($grp)){
      msg(ERROR,"CIAMUserOrgstruct can't connect ".
                "nesassary information objects");
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
         #msg(INFO,"grpids='%s'",join(",",@curgrpid));
         if ($#curgrpid!=-1){
            $grp->SetFilter({grpid=>\@curgrpid,
                             srcsys=>'WhoIsWho',
                             cistatusid=>\'4'});
            my @l=$grp->getHashList(qw(grpid));
            if ($#l!=-1){
               return(1,{qmsg=>[
                  'not all organisational groups migrated to CIAM - '.
                  'disabling relation sync'
               ]});
            }
         }
         msg(INFO,"validateing userid=$urec->{userid} requested");

         #
         # loading the "should" sitiuation from ciam
         #
         msg(DEBUG,"trying to load userinformations from ciam");
         $ciamusr->SetFilter([
            {email=>$urec->{email},active=>\'true',primary=>\'true'},
            {email2=>$urec->{email},active=>\'true',primary=>\'true'},
            {email3=>$urec->{email},active=>\'true',primary=>\'true'},
            {email4=>$urec->{email},active=>\'true',primary=>\'true'}
         ]);
         my @l=$ciamusr->getHashList(qw(ALL));
         my @allciament=sort({
            $b->{twrid} <=> $a->{twrid}
         } @l);
        
         my $ciamrec;
         if ($#allciament!=-1){
            $ciamrec=shift(@allciament);
         }

         if (defined($ciamrec)){  # doublicate Workrelation check
            $ciamusr->ResetFilter();
            $ciamusr->SetFilter({tcid=>\$ciamrec->{tcid},active=>\'true'});
            my %o;
            foreach my $r ($ciamusr->getHashList(qw(toucid))){
               $o{$r->{toucid}}++;
            }
            foreach my $toucid (keys(%o)){
               my $v=$o{$toucid};
               if ($v>1){
                  my $msg="double workrelation to the same org unit in CIAM: ".
                          $toucid;
                  push(@qmsg,$msg);
                  $errorlevel=1 if ($errorlevel<1);
               }
            }
         }

         if (!defined($ciamrec)){
            if (($urec->{posix} ne "" || $urec->{dsid} ne "") && 
                $urec->{cistatusid}<6){
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
               if ($old && defined($rec) && $rec->{lastexternalseen} eq ""){
                 if (1){   # Expression !($urec->{email}=~m/\@telekom\.de$/i)){
                           # now with CIAM Interface not needed - because
                           # all Telekom contacts should be in CIAM
                    $ciamusr->Log(ERROR,"basedata",
                                 "E-Mail '%s' not found in LDAP (CIAM) ".
                                 "but with POSIX or DSID entry",
                                 $urec->{email});
                 }
                 else{
                    if (!defined($age) || $age>259200){ # half year
                       $ciamusr->Log(ERROR,"basedata",
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
         my $ciamid=$ciamrec->{tcid};
         my $toucid=$ciamrec->{toucid};
         my $surname=$ciamrec->{surname};
         my $givenname=$ciamrec->{givenname};
         my $uidlist=$ciamrec->{wiwid};
         $uidlist=[$uidlist] if (ref($uidlist) ne "ARRAY");
         my @posix=grep(!/^[A-Z]{1,3}\d+$/,@{$uidlist});
         my $posix=$posix[0];

         my $ciamstate=$ciamrec->{office_state};

         if ($ciamstate eq "DTAG User"){
            $ciamusr->Log(ERROR,"basedata",
                "Contact '%s'\nseems to be a WebEx/SCP only user. ".
                "Please check this and then clear the posix entry.".
                "\n-",$urec->{fullname}
            );
            return($errorlevel,undef);
         }
         if ($ciamstate eq "Rumpfdatensatz"){
            # Bisher (01/2016) keine Erklärung von den CIAM Leuten, was
            # ein "Rumpfdatensatz" ist - also wird die org-Relation erstmal
            # irgnoriert.
            return($errorlevel,undef);
         }
         $self->addWorkrelationShip($grp,$grpuser,$urec,$toucid,$ciamstate);


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


         ######################################################################
         #
         # hinzufügen der Leiter rollen
         #
         if (!defined($ciamid) || $ciamid eq ""){
            msg(ERROR,"can't find ciamid of user '%s'",$urec->{email});
            return($errorlevel,undef);
         }
         $ciamorg->SetFilter({toumgr=>\$ciamid,disabled=>\'false'});
         foreach my $ciamrec ($ciamorg->getHashList(
                              qw(toucid name parentid parent shortname))){
            if ($ciamrec->{toucid} ne ""){
               @bossgrpsrcid=grep(!/^$ciamrec->{toucid}$/,@bossgrpsrcid);
            }
            my $bk=$self->addGrpLinkToUser($grp,$ciamorg,$grpuser,
                                           $ciamrec,$urec,
                                           ['RBoss']);
            return($errorlevel,undef) if (defined($bk));
         }
         if ($#bossgrpsrcid!=-1){
            $ciamusr->Log(WARN,"backlog",
                         "removing RBoss from User '%s' on group toucid='%s'",
                         $urec->{email},join(",",@bossgrpsrcid)
            );
            my $lnkgrpuser=getModuleObject($Config,"base::lnkgrpuser");
            my $lnkgrpuserop=$lnkgrpuser->Clone();
            $grp->SetFilter({srcid=>\@bossgrpsrcid,
                             srcsys=>\$self->{SRCSYS}});
            foreach my $rgrprec ($grp->getHashList("grpid")){
               $lnkgrpuser->ResetFilter();
               $lnkgrpuser->SetFilter({userid=>\$urec->{userid},
                                           grpid=>\$rgrprec->{grpid},
                                           roles=>'RBoss'});
               foreach my $lnkrec ($lnkgrpuser->getHashList("ALL")){
                  my $needkill=0;
                  if (ref($lnkrec->{roles}) eq "ARRAY"){
                     my @r=grep(!/^RBoss$/,@{$lnkrec->{roles}});
                     if ($#r!=-1){
                        msg(INFO,"patching relation $rec->{lnkgrpuserid}");
                        $lnkgrpuserop->ValidatedUpdateRecord($lnkrec,
                           {lnkgrpuserid=>$lnkrec->{lnkgrpuserid},
                            roles=>\@r},
                           {lnkgrpuserid=>\$lnkrec->{lnkgrpuserid}});
                     }
                     else{
                        $needkill++;
                     }
                  }
                  else{
                     $needkill++;
                  }
                  if ($needkill){
                     msg(INFO,"killing relation $rec->{lnkgrpuserid}");
                     $lnkgrpuserop->ValidatedDeleteRecord($lnkrec);
                  }
               }
            }
         }
         ######################################################################


         ######################################################################
         #
         # hinzufügen alternativer Arbeitsverhältnisse
         #
         #msg(INFO,"---------------------------------------------------");
         #msg(INFO,"hinzufügen alternativer Arbeitsverhälnisse zu tCID=".
         #    $ciamrec->{tcid});
         $ciamusr->ResetFilter();

         $ciamusr->SetFilter(
            {tcid=>\$ciamrec->{tcid},active=>\'true',primary=>\'false'},
         );
         my @wrlist=$ciamusr->getHashList(qw(tcid twrid wiwid
                                             toucid office_state));
         my %grps;
         if ($#wrlist!=-1){
            %grps=$grp->getGroupsOf($urec->{userid},[qw(REmployee)],'up');
         }
         foreach my $wr (@wrlist){
             if (defined($ciamrec) &&
                 $ciamrec->{toucid} eq $wr->{toucid}){
                #
                # User hat prim. und sec. zur gleichen Org-Einheit. Seit
                # 11/2017 behandeln wir es nun so, dass das prim. 
                # Verhältnis vor geht.
                #$ciamusr->Log(ERROR,"basedata",
                #             "Contact '%s' has active primary AND secondary ".
                #             "CIAM workrelation to the same org ".
                #             "unit toucid='%s'",
                #             $urec->{fullname},$wr->{toucid});
                next;
             }
             my $ciamstate=$wr->{office_state};
             if (lc($ciamstate) eq lc("Employee")){
                $ciamstate="RFreelancer"; # Sekundäre Arbeitsverhältnisse
                                          # werden immer als Extern angesehen.
             }
             if (exists($grps{14516421600001})){ # Hautbereich der Azubis
                $ciamstate="Apprentice"; # Es existiert noch ein Arbeitsv.
                # im Azubi Bereich - das Sek. Arbeitsverhältnis muß also AZUBI
                # sein.
             }
             my $toucid=$wr->{toucid};
             next if ($toucid eq "1446227"); # Arbeitverhälntisse auf DTAG.NULL
             $self->addWorkrelationShip($grp,$grpuser,$urec,$toucid,$ciamstate);
         }
         #msg(INFO,"---------------------------------------------------");
         ######################################################################


      }
   }
   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}

sub addWorkrelationShip
{
   my $self=shift;
   my $grp=shift;
   my $grpuser=shift;
   my $urec=shift;
   my $toucid=shift;
   my $ciamstate=shift;

   my $ciamorg=getModuleObject($self->getParent->Config,"tsciam::orgarea");

   my $level1role="RFreelancer";
   if (lc($ciamstate) eq lc("Intern") ||
       lc($ciamstate) eq lc("Manager") ||
       lc($ciamstate) eq lc("Employee")){
      $level1role="REmployee";
   }
   if (lc($ciamstate) eq lc("Apprentice")){
      $level1role="RApprentice";
   }
   msg(INFO,"organizationalstatus=$ciamstate --- w5base role=$level1role");
   

   #
   # hinzufügen der Userrollen
   #
   if ($toucid ne ""){
      $ciamorg->SetFilter({toucid=>\$toucid});
      my ($ciamrec,$msg)=$ciamorg->getOnlyFirst(qw(toucid name parentid 
                                                 parent shortname));
      if (defined($ciamrec)){
         my $bl=getModuleObject($self->getParent->Config,"base::userblacklist");
         if (!$bl->checkLock('lockorgtransfer',[
                             {posix=>$urec->{posix}},
                             {email=>\$urec->{email}}])){
            my $bk=$self->addGrpLinkToUser($grp,$ciamorg,$grpuser,
                                           $ciamrec,$urec,
                                           [$level1role,'RMember']);
            msg(ERROR,"fail to add realtion to $toucid") if (defined($bk));
         }
      }
      else{
         if (defined($msg)){
            msg(ERROR,"LDAP problem - Orgsearch:%s",$msg);
         }
         msg(ERROR,"CIAM Orgarea '%s' not found for user '%s'",
             $toucid,$urec->{email});
      }
   }
   else{
      msg(DEBUG,"user '%s' has no orgarea",$urec->{email});
   }
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
   my $ciamorg=shift;  # communication object
   my $grpuser=shift; # communication object
   my $ciamrec=shift;    # ciam orgarea record
   my $urec=shift;      # aktueller User record
   my $roles=shift;     # array auf zuzuweisende rollen

   my $app=$self->getParent();
   my $nowstamp=$app->ExpandTimeExpression("now","en","GMT","GMT");
   my $grpid2add=$ciamorg->getGrpIdOf($ciamrec);
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
            my @orgRoles=grep(!/^RBoss.*$/,orgRoles()); # RBoss muss bleiben!
            # RBoss wird von einer anderen CIAM QualityRule behandelt und 
            # RBoss2 muss in Darwin vergeben werden können (z.B. für 
            # Reporting Rechte) - d.h. RBoss2 steht nicht unter CIAM Authorität
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
      msg(ERROR,"Can't create group tOuCID='$ciamrec->{toucid}' ".
                "for user '$urec->{email}'");
      msg(ERROR,$self->getParent->LastMsg());
   }
   return(undef);
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
     

      my %adr=(emailfrom=>'"CIAM to W5BaseDarwin" <no_reply@w5base.net>',
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
      my $label=$self->T("CIAM to W5Base/Darwin automatic ".
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
              emailcategory =>['CIAM',
                               'tsciam::qrule::CIAMUserOrgstruct',
                               'NewOrgRelation']
             })){
         my %d=(step=>'base::workflow::mailsend::waitforspool');
         my $r=$wf->Store($id,%d);
      }
      delete($ENV{HTTP_FORCE_LANGUAGE});
   }
}




1;
