package tswiw::event::orgarea;
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

   $self->RegisterEvent("UserVerified",\&UpdateOrgareaStructure,timeout=>300);
   $self->RegisterEvent("WiWOrgareaRefresh",\&UpdateOrgareaStructure,
                         timeout=>14400);
   return(1);
}

sub UpdateOrgareaStructure
{
   my $self=shift;
   my $app=$self->getParent();
   $self->{SRCSYS}="WhoIsWho";
   my $account=shift;
   msg(DEBUG,"Verify orgarea structure of account '%s'",$account);

   return() if ($account eq "anonymous");

   my $user=getModuleObject($self->Config,"base::user");
   my $mainuser=getModuleObject($self->Config,"base::user");
   my $grp=getModuleObject($self->Config,"base::grp");
   my $grpuser=getModuleObject($self->Config,"base::lnkgrpuser");
   my $wiwusr=getModuleObject($self->Config,"tswiw::user");
   my $wiworg=getModuleObject($self->Config,"tswiw::orgarea");

   if (!defined($wiwusr) ||
       !defined($wiworg) ||
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
   }
   $mainuser->SetCurrentView(qw(email usertyp groups posix));
   my ($urec,$msg)=$mainuser->getFirst();
   if (!defined($urec)){
      msg(ERROR,"can't load any user accounts to verifiy");
      return({msg=>$msg,exitcode=>1});
   }
   msg(DEBUG,"ok, first record loaded");
   do{
      if (defined($urec) && $urec->{email} ne "" &&
          $urec->{email} ne 'null@null.com' &&
          $urec->{usertyp} eq "user"){
         my @curgrpid=();
         msg(DEBUG,"processing email addr '%s'",$urec->{email});
         if (defined($urec->{groups}) && ref($urec->{groups}) eq "ARRAY"){
            foreach my $grp (@{$urec->{groups}}){
               $grp->{roles}=[] if (!defined($grp->{roles}));
               if (grep(/^REmployee$/,@{$grp->{roles}})){
                  push(@curgrpid,$grp->{grpid});
               }
            }
         }
         msg(DEBUG,"validateing userid=$urec->{userid} request $account");
         #
         # load srcid's from base::grp
         #
         $grp->SetFilter({grpid=>\@curgrpid,srcsys=>\$self->{SRCSYS}});
         $grp->SetCurrentView(qw(grpid srcid srcsys srcload));
         my $curgrps=$grp->getHashIndexed(qw(grpid srcid));

         #
         # loading the "should" sitiuation from wiw
         #
         msg(DEBUG,"trying to load userinformations from wiw");
         $wiwusr->SetFilter([{email=>$urec->{email}},{email2=>$urec->{email}}]);
         $wiwusr->SetCurrentView(qw(ALL));
         my ($wiwrec,$msg)=$wiwusr->getFirst();
         if (!defined($wiwrec)){
            if (defined($msg)){
               msg(ERROR,"LDAP problem:%s",$msg);
            }
            msg(DEBUG,"User '%s' couldn't be found in LDAP",$urec->{email});
            goto NEXT;
         }
         my $wiwid=$wiwrec->{id};
         my $touid=$wiwrec->{touid};
         my $surname=$wiwrec->{surname};
         my $givenname=$wiwrec->{givenname};
         my $uidlist=$wiwrec->{uid};
         $uidlist=[$uidlist] if (ref($uidlist) ne "ARRAY");
         my @posix=grep(!/^[A-Z]{1,3}\d+$/,@{$uidlist});
         my $posix=$posix[0];

#printf STDERR ("fifi=wiwuser=posix=$posix=%s\n",Dumper($wiwrec));
         #
         # hinzufügen der Userrollen
         #
         if ($touid ne ""){
            $wiworg->SetFilter({touid=>\$touid});
            $wiworg->SetCurrentView(qw(touid name parentid parent shortname));
            my ($wiwrec,$msg)=$wiworg->getFirst();
            if (defined($wiwrec)){
               my $bk=$self->addGrpLinkToUser($grp,$wiworg,$grpuser,
                                              $wiwrec,$urec,
                                              ['REmployee','RMember']);
               return($bk) if (defined($bk));
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

         #
         # hinzufügen der Leiter rollen
         #
         if (!defined($wiwid) || $wiwid eq ""){
            msg(ERROR,"can't find wiwid of user '%s'",$urec->{email});
            goto NEXT;
         }
         $wiworg->SetFilter({mgrwiwid=>\$wiwid});
         foreach my $wiwrec ($wiworg->getHashList(
                              qw(touid name parentid parent shortname))){
            my $bk=$self->addGrpLinkToUser($grp,$wiworg,$grpuser,
                                           $wiwrec,$urec,
                                           ['RBoss']);
            return($bk) if (defined($bk));
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
      NEXT:
      ($urec,$msg)=$mainuser->getNext();
   }until(!defined($urec));
 
   CLEANUP:

   if (!defined($account) || $account eq ""){
      $grpuser->SetFilter(srcsys=>\$self->{SRCSYS},       # (8 Wochen)
                          srcload=>"<now-7d");           # übergang = 7 Tage
      $grpuser->SetCurrentView(qw(ALL));
      my ($rec,$msg)=$grpuser->getFirst();
      if (defined($rec)){
         do{
            if ($rec->{expiration} eq ""){
               my $exp="now+7d";
               $exp=$app->ExpandTimeExpression($exp,"en","GMT","GMT");
               $grpuser->ValidatedUpdateRecord($rec,{expiration=>$exp,
                                                     roles=>$rec->{roles}},
                 {userid=>\$rec->{userid},lnkgrpuserid=>\$rec->{lnkgrpuserid}});
            }
            ($rec,$msg)=$grpuser->getNext();
         }until(!defined($rec));
      }
      else{
         if (defined($msg)){
            msg(ERROR,"LDAP cleanup problem:%s",$msg);
         }
      }



      $grpuser->SetFilter(srcsys=>\$self->{SRCSYS},       # (8 Wochen)
                          srcload=>"<now-56d");           # übergang = 56 Tage
      $grpuser->SetCurrentView(qw(ALL));
      my ($rec,$msg)=$grpuser->getFirst();
      if (defined($rec)){
         do{
            $grpuser->ValidatedDeleteRecord($rec);
            ($rec,$msg)=$grpuser->getNext();
         }until(!defined($rec));
      }
      else{
         if (defined($msg)){
            msg(ERROR,"LDAP cleanup problem:%s",$msg);
         }
      }
   }



   return({msg=>'fine',exitcode=>0});
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
      if (defined($lnkrec)){
         my @newroles;
         foreach my $role (@{$roles}){
            if (defined($lnkrec->{roles})){
               if (!grep(/^$role$/,@{$lnkrec->{roles}})){
                  push(@newroles,$role);
               }
            }
         }
         my %newlnk=(roles=>[@newroles,@{$lnkrec->{roles}}],
                     expiration=>undef,
                     alertstate=>undef,
                     srcsys=>$self->{SRCSYS},
                     srcid=>"none",
                     srcload=>$nowstamp);
         my $back=$grpuser->ValidatedUpdateRecord($lnkrec,\%newlnk,
                            {lnkgrpuserid=>$lnkrec->{lnkgrpuserid}});
         #printf STDERR ("fifi insert=back=$back\n");
      }
      else{
         my %newlnk=(userid=>$urec->{userid},
                     roles=>$roles,
                     srcsys=>$self->{SRCSYS},
                     srcload=>$nowstamp,
                     expiration=>undef,
                     alertstate=>undef,
                     grpid=>$grpid2add);
         #printf STDERR ("fifi try to create lnk %s\n",Dumper(\%newlnk));
         my $back=$grpuser->ValidatedInsertRecord(\%newlnk);
         #printf STDERR ("fifi insert=back=$back\n");
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

   $grp->SetFilter({srcid=>\$wiwrec->{touid},srcsys=>\$self->{SRCSYS}});
   $grp->SetCurrentView(qw(grpid srcid srcsys srcload));
   my ($rec,$msg)=$grp->getFirst();
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

#   my $v1=getModuleObject($self->Config,"w5v1inv::orgarea");
   msg(DEBUG,"try to create touid=$wiwrec->{touid} in base::grp");
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
      #      $v1->SetFilter({fullname=>\"DTAG"});
      #      $v1->SetCurrentView(@view);
      #      my ($rec,$msg)=$v1->getFirst();
      #      if (defined($rec)){
      #         $newgrp{grpid}=$rec->{id};
      #      }
            my $back=$grp->ValidatedInsertRecord(\%newgrp);
            $parentoftsi=$back; 
         }
         else{
            $parentoftsi=$rec->{grpid};
         }
         my %newgrp=(name=>"TSI",parent=>'DTAG',cistatusid=>4);
      #   $v1->SetFilter({fullname=>\"DTAG.TSI"});
      #   $v1->SetCurrentView(@view);
      #   my ($rec,$msg)=$v1->getFirst();
      #   if (defined($rec)){
      #      $newgrp{grpid}=$rec->{id};
      #   }
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
#   my $w5v1id;
#   ################################################################
#   #
#   # W5V1 Interface
#   #
#   {
#      if (defined($v1)){
#         $v1->SetFilter({ldapid=>$wiwrec->{touid}});
#         $v1->SetCurrentView(qw(id name));
#         my ($rec,$msg)=$v1->getFirst();
#         if (defined($rec)){
#            $w5v1id=$rec->{id};
#            if ($rec->{name} ne ""){
#               $newname=$rec->{name};
#            }
#         }
#      }
#   }
   ################################################################
   $newname=~s/\s/_/g;    # rewriting for some shit names
   my %newgrp=(name=>$newname,
               srcsys=>$self->{SRCSYS},
               srcid=>$wiwrec->{touid},
               cistatusid=>4,
               srcload=>NowStamp(),
               comments=>"Description from WhoIsWho: ".$wiwrec->{name});
   $newgrp{name}=~s/&/_u_/g;
#   $newgrp{grpid}=$w5v1id if (defined($w5v1id));
   $newgrp{parentid}=$parentid if (defined($parentid));
   msg(DEBUG,"Write=%s",Dumper(\%newgrp));
   my $back=$grp->ValidatedInsertRecord(\%newgrp);
   msg(DEBUG,"ValidatedInsertRecord returned=$back");

   return($back);
}


1;
