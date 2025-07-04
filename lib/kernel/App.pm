package kernel::App;
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
use kernel::date;
use kernel::TemplateParsing;
use XML::Smart;
use IO::File;
use kernel::Universal;
@ISA    = qw(kernel::Universal kernel::TemplateParsing);

sub new
{
   my $type=shift;
   my $self={@_};
   $self=bless($self,$type);

   return($self);
}
######################################################################
sub DataObj
{
   $_[0]->{DataObj}={} if (!defined($_[0]->{DataObj}));
   return($_[0]->{DataObj}->{$_[1]}) if (defined($_[1]));
   return($_[0]->{DataObj});
}

sub BackendSessionName
{
   my $self=shift;
   $self->{BackendSessionName}=$_[0] if ($_[0] ne "");
   return($self->{BackendSessionName});
}




sub Module
{
   my $self=shift;
   return($self->{OrigModule}) if (exists($self->{OrigModule}));
   my $s=$self->Self();
   my ($module,$app)=$s=~m/^(.*?)::(.*)$/;
   return($module);
}

sub App
{
   my $self=shift;
   my $s=$self->Self();
   my ($module,$app)=$s=~m/^(.*?)::(.*)$/;
   $app=~s/::/./g;
   return($app);
}

sub Config
{
   my ($self)=@_;

   return($self->{'Config'});
}


#
# Call to ensure, not too many edit operation occured at
# one second
#
sub setTimePerEditStamp
{
   my $self=shift;

   $self->{TimePerEditCount}=0      if (!exists($self->{TimePerEditCount}));
   if ($self->{TimePerEditStamp} ne time()){
      $self->{TimePerEditCount}=0;
      $self->{TimePerEditStamp}=time();
   }
   else{
      $self->{TimePerEditCount}++;
   }
   if ($self->{TimePerEditCount}>7){
      sleep(1);
      $self->{TimePerEditCount}=0;
   }
}



sub getPersistentModuleObject
{
   my $self=shift;
   my $label=shift;
   my $module=shift;

   $module=$label if (!defined($module) || $module eq "");
   if (!defined($self->{$label})){
      my $m=$self->ModuleObject($module);
      $self->{$label}=$m
   }
   if (defined($self->{$label})){
      if ($self->{$label}->can("ResetFilter")){
         $self->{$label}->ResetFilter();
      }
   }
   return($self->{$label});
}

sub ModuleObject
{
   my $self=shift;
   my $name=shift;
   my $config=$self->Config;
   my $o=getModuleObject($config,$name);
   if (defined($o)){
      $o->setParent($self);
   }
   return($o);
}

#
# Collect all current valid object names for "getModuleObject" (with
# no submodules or workflow objects)
#
sub globalObjectList
{
   my $self=shift;
   my $instdir=$self->Config->Param("INSTDIR");
   my $pat="$instdir/mod/*/*.pm";
   my @objlist=map({
      my $qi=quotemeta($instdir);
      $_=~s/^$instdir//;
      $_=~s/\/mod\///; $_=~s/\.pm$//;
      $_=~s/\//::/g;
      $_;
   } grep({
     -s $_;
   } glob($pat)));
   return(@objlist);
}


sub W5ServerCall
{
   my $self=shift;
   my $method=shift;
   my @param=@_;

   if (!defined($self->Cache->{W5Server})){
      msg(ERROR,"no W5Server connection for call '%s'",$method);
      return(undef);
   }
   my $bk=$self->Cache->{W5Server}->Call($method,@param);
   return($bk);
}

sub W5ServerCallGetUniqueIdCached
{
   my $self=shift;

#
#  ToDo - Cached UniqeIDs generieren
#

#   my $res=$self->W5ServerCall("rpcGetUniqueId");
#   return($res) if (!defined($res));
#   my $retry=15;
#   while(!defined($res=$self->W5ServerCall("rpcGetUniqueId"))){
#      sleep(1);
#      last if ($retry--<=0);
#      msg(WARN,"W5Server problem for user $ENV{REMOTE_USER} ($retry)");
#   }
#   if (defined($res) && $res->{exitcode}==0){
#      $id=$res->{id};
#   }
#
#   my $bk=$self->Cache->{W5Server}->Call($method,@param);

}

sub getCurrentAclModes      # extracts the current acl 
{                           # (contrib to kernel::App::Web::AclControl)
   my $self=shift;
   my $useraccount=shift;
   my $acllist=shift;
   my $roles=shift;
   my $direction=shift;
   return(undef) if (ref($acllist) ne "ARRAY");
   
   my $userid;
   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$useraccount})){
      $UserCache=$UserCache->{$useraccount}->{rec};
   }
   if (defined($UserCache->{tz})){
      $userid=$UserCache->{userid};
   }
   $direction="both" if (!defined($direction));
   my %grps=$self->getGroupsOf($useraccount,$roles,$direction);
   my %u=();
   foreach my $rec (@{$acllist}){
      if (defined($rec->{acltarget})){
         if ($rec->{acltarget} eq "base::user" &&
             $rec->{acltargetid} eq $userid){
            $u{$rec->{aclmode}}=1;
         } 
         if ($rec->{acltarget} eq "base::grp" &&
             grep(/^$rec->{acltargetid}$/,keys(%grps))){
            $u{$rec->{aclmode}}=1;
         } 
      } 
      if (defined($rec->{target})){  # to be compatible to contact object
         my $match=0;
         if ($rec->{target} eq "base::user" &&
             $rec->{targetid} eq $userid){
            $match=1;
         } 
         if ($rec->{target} eq "base::grp" &&
             grep(/^$rec->{targetid}$/,keys(%grps))){
            $match=1;
         } 
         if ($match && ref($rec->{roles}) eq "ARRAY"){
            foreach my $role (@{$rec->{roles}}){
               $u{$role}=1;
            }
         }
      } 
   }
   return(keys(%u));
}

sub ReadMimeTypes
{
   my $self=shift;
   my $mime=$self->Config->Param("MIMETYPES");

   if (!exists($self->{MimeType})){
      $self->{MimeType}={'msi'=>"Windows Installer Package"};
      if (open(F,"<$mime")){
         while(my $l=<F>){
            $l=~s/\s$//;
            next if ($l=~m/^\s*#.*$/);
            if (my ($t,$e)=$l=~m/^\s*(\S+)\s+(.+)$/){
               my @elist=split(/\s+/,$e);
               foreach my $e (@elist){
                  $self->{MimeType}->{$e}=$t;
               }
            }
         }
         close(F);
      }
      else{
         msg(ERROR,"can't open '$mime'");
      }
   }
}



sub getMandatorsOf
{
   my $self=shift;
   my $AccountOrUserID=shift;
   my @roles=@_;
   @roles=@{$roles[0]} if (ref($roles[0]) eq "ARRAY");
   my $userid;
   my $UserCache=$self->Cache->{User}->{Cache};
   if ($AccountOrUserID=~m/^\d+$/){
      if (!defined($UserCache->{$AccountOrUserID})){
         $self->_LoadUserInUserCache($AccountOrUserID);
      }
   }
   if (defined($UserCache->{$AccountOrUserID})){
      $UserCache=$UserCache->{$AccountOrUserID}->{rec};
   }
   if (defined($UserCache->{userid})){
      $userid=$UserCache->{userid};
   }
   my %groups;
   my %ugroups=$self->getGroupsOf($AccountOrUserID,[orgRoles()],
                               'both');
   my %cgroups=$self->getGroupsOf($AccountOrUserID,[qw(RCFManager RCFManager2)],
                               'both');
   my %dgroups=$self->getGroupsOf($AccountOrUserID,[qw(RCFManager RCFManager2)],
                                  'direct');
   map({
      if ($ugroups{$_}->{grpcistatusid}==4){
         $groups{$_}++;
      }
   } keys(%ugroups));
   map({$groups{$_}++} keys(%cgroups));
   my @grps=keys(%groups);
   my %m=();
  # my %m=map({($_=>1);}@grps);
   my $MandatorCache=$self->Cache->{Mandator}->{Cache};
   if (!defined($MandatorCache)){
      $self->ValidateMandatorCache(0);  # load Cache, if call is 
                                        # from Event (not in Web-Context)
      $MandatorCache=$self->Cache->{Mandator}->{Cache};
   }
   my $isadmin=$self->IsMemberOf("admin");
   CHK: foreach my $mid (keys(%{$MandatorCache->{id}})){
      my $mc=$MandatorCache->{id}->{$mid};
      my $grpid=$mc->{grpid};
      if (in_array(\@roles,"read")){  
         if ($mc->{cistatusid} ne "4"){
            next CHK if (!$isadmin &&            # Admins and direct Config-Mgr
                     !exists($dgroups{$grpid})); # of Mandators can read alle
         }                                       # mandators - no matter what st
      }
      if (in_array(\@roles,"write")){  # write only on active mandators allowed
         next CHK if ($mc->{cistatusid} ne "4" &&
                      $mc->{cistatusid} ne "3");
         if ($mc->{cistatusid} eq "3"){
            next CHK if (!$isadmin &&            # Admins and direct Config-Mgr
                     !exists($dgroups{$grpid})); # of Mandators can work on
         }                                       # "available" mandators
      }
      $m{$grpid}=1 if (grep(/^$grpid$/,@grps));
      if ($isadmin && !($#roles==0 && $roles[0] eq "direct")){
         $m{$grpid}=1;
         next CHK;
      }
      if (defined($mc->{contacts}) && ref($mc->{contacts}) eq "ARRAY"){
         foreach my $contact (@{$mc->{contacts}}){
            if ($contact->{target} eq "base::user"){
               next if ($contact->{targetid}!=$userid);
               my $mr=$contact->{roles};
               $mr=[$mr] if (ref($mr) ne "ARRAY");
               foreach my $chk (@roles){
                  if (grep(/^$chk$/,@{$mr})){
                     $m{$grpid}=1;
                     next CHK;
                  }
               }
            }
            if ($contact->{target} eq "base::grp"){
               my $g=$contact->{targetid};
               next if (!grep(/^$g$/,@grps));
               my $mr=$contact->{roles};
               $mr=[$mr] if (ref($mr) ne "ARRAY");
               foreach my $chk (@roles){
                  if (grep(/^$chk$/,@{$mr})){
                     $m{$grpid}=1;
                     next CHK;
                  }
               }
            }
         }
      }
   }
   if ($#roles==0 && $roles[0] eq "direct"){
      # order by distance
      return(sort({$ugroups{$a}->{distance} <=> $ugroups{$b}->{distance}} keys(%m)));
   }
   return(sort(keys(%m)));
}

sub isMandatorReadable
{
   my $self=shift;
   my $mandatorid=shift;
   return(0) if ($mandatorid==0);
   my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
   if (!in_array(\@mandators,[$mandatorid])){
      return(0);
   }
   return(1);
}


sub OpenByIdWindow
{
   my $self=shift;
   my $dataobj=shift;
   my $id=shift;
   my $innerText=shift;
   my $auth=shift;
   my $method="ById";

   if (!defined($auth)){
      $auth="auth";
   }

   my $baseurl=$self->Config->Param("EventJobBaseUrl");

   my $dest=$baseurl;

   $dest.="/" if (!($dest=~m/\/$/));

   if ($dataobj eq "base::workflow"){
      $method="ById";
   }
   $dataobj=~s/::/\//g;
   $dest.=$auth."/".$dataobj."/".$method."/".$id;

   my $onclick="";

   my $detailx=$self->DetailX();
   my $detaily=$self->DetailY();
   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   my $winsize="normal";
   if (defined($UserCache->{winsize}) && $UserCache->{winsize} ne ""){
      $winsize=$UserCache->{winsize};
   }
   my $winname="_blank";
   if (defined($UserCache->{winhandling}) &&
       $UserCache->{winhandling} eq "winonlyone"){
      $winname="W5BaseDataWindow";
   }
   if (defined($UserCache->{winhandling})
       && $UserCache->{winhandling} eq "winminimal"){
      $winname="W5B_".$self->Self."_".$id;
      $winname=~s/[^a-z0-9]/_/gi;
   }
   if ($dest ne ""){
      $onclick="custopenwin(\"$dest\",\"$winsize\",".
                   "$detailx,$detaily,\"$winname\");return(false);";
   }
   my $a="<a onclick='$onclick' href=\"$dest\">";




   return($a.$innerText."</a>");
}


sub getReCertificationUserIDs
{
   my $self=shift;
   my $rec=shift;

   if (exists($rec->{databossid}) && $rec->{databossid} ne ""){
      return($rec->{databossid});
   }

   return();

}



sub getMembersOf
{
   my $self=shift;
   my $group=shift;
   my $roles=shift;
   my $direction=shift;  # posible = up down both (firstup)
   $direction="down" if (!defined($direction));
   $group=[$group]      if (ref($group) ne "ARRAY");
   $roles=["RMember"]   if (!defined($roles));
   my %allgrp;
   my %userids;

   my $LoadGroups_direction=$direction;
   $LoadGroups_direction="up" if ($direction eq "firstup");
   foreach my $directgrp (@$group){
      $self->LoadGroups(\%allgrp,$LoadGroups_direction,$directgrp);
   }
   my $rolelink=$self->getPersistentModuleObject("getMembersOf",
                                                "base::lnkgrpuserrole");
   my @grpids=keys(%allgrp);
   $rolelink->SetFilter({grpid=>\@grpids,role=>$roles,
                         expiration=>">now OR [LEER]",    #to handle expiration
                         cistatusid=>[3,4]});
   if ($direction eq "firstup"){
      my @uids;
      $rolelink->SetCurrentView(qw(userid grpid));
      my $d=$rolelink->getHashIndexed(qw(grpid));
      foreach my $grprec (sort({
                            $a->{distance} <=> $b->{distance}
                         } values(%allgrp))){
         if (exists($d->{grpid}->{$grprec->{grpid}})){
            my $l=$d->{grpid}->{$grprec->{grpid}};
            $l=[$l] if (ref($l) ne "ARRAY");
            foreach my $lnkrec (@$l){
               push(@uids,$lnkrec->{userid});
            }
            last;
         }
      }
      return(@uids);
   }
   map({$userids{$_->{userid}}++;} $rolelink->getHashList(qw(userid)));

   return(keys(%userids));
}


sub LoadGroups
{
   my $self=shift;
   my $allgrp=shift;
   my $direction=shift;
   my $distance=0;
   if (ref($_[0]) eq "SCALAR"){
      $distance=${shift()};
   }
   my @grpids=@_;
   my $GroupCache=$self->Cache->{Group}->{Cache};
   if (!defined($GroupCache)){
      $self->ValidateGroupCache();
      $GroupCache=$self->Cache->{Group}->{Cache};
   }
   my @up;
   my @down;

   foreach my $grp (@grpids){
      next if (!defined($grp));
      if (!defined($allgrp->{$grp}) || 
          ($allgrp->{$grp}->{direction} eq "up" || # if a group has been loaded
           $direction eq "both")){ # in up mode and a additional "both" mode
         my $fullname=$GroupCache->{grpid}->{$grp}->{fullname};
         my $grpcistatusid=$GroupCache->{grpid}->{$grp}->{cistatusid};
         if (!exists($allgrp->{$grp}) ||      # distance 0 records have 
             $allgrp->{$grp}->{distance}!=0){ # priority !
            $allgrp->{$grp}={         # is requested - a force load is needed!
                  fullname=>$fullname,
                  grpid=>$grp,
                  grpcistatusid=>$grpcistatusid,
                  distance=>$distance,
                  is_org=>$GroupCache->{grpid}->{$grp}->{is_org},
                  is_projectgrp=>$GroupCache->{grpid}->{$grp}->{is_projectgrp},
                  direction=>$direction
            };
         }
         if ($direction eq "down" || $direction eq "both"){
            if (ref($GroupCache->{grpid}->{$grp}->{subid}) eq "ARRAY"){
               push(@down,@{$GroupCache->{grpid}->{$grp}->{subid}});
            }
         }
         if ($direction eq "up" || $direction eq "both"){
            push(@up,$GroupCache->{grpid}->{$grp}->{parentid});
         }
      }
   }
   my $nextdistance=$distance+1;
   $self->LoadGroups($allgrp,"down",\$nextdistance,@down) if ($#down!=-1);
   $nextdistance=$distance+1;
   $self->LoadGroups($allgrp,"up",\$nextdistance,@up) if ($#up!=-1);
}

sub _LoadUserInUserCache
{
   my $self=shift;
   my $AccountOrUserID=shift;
   my $res=shift;              # result of rpcCacheQuery in Web Context

   return(0) if ($AccountOrUserID eq "");
   return(0) if ($AccountOrUserID eq "anonymous");
   return(0) if ($W5V2::OperationContext eq "W5Server");

   my $o=$self->Cache->{User}->{DataObj};
   if (!defined($o)){     # DataObj also filled in App/Web.pm !
      $o=$self->ModuleObject("base::user");
      $self->Cache->{User}={DataObj=>$o,Cache=>{}};
   }
   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($o)){
      if ($o->Ping()){
         if ($AccountOrUserID=~m/^\d+$/){
            $o->SetFilter({userid=>\$AccountOrUserID});
         }
         else{
            $o->SetFilter({'accounts'=>[$AccountOrUserID]});
         }
         my ($rec,$msg)=$o->getOnlyFirst(qw(surname 
                               fullname country gtcack
                               userid givenname posix groups tz lang
                               cistatusid secstate ipacl pagelimit
                               dialermode dialerurl dialeripref
                               email usersubst usertyp winsize winhandling
                               dateofvsnfd
                               userquerybreakcount));
         if (defined($rec)){
            if ($rec->{ipacl} ne ""){
               $rec->{ipacl}=[split(/[;,]\s*/,$rec->{ipacl})];
            }
            $UserCache->{$AccountOrUserID}->{rec}=$rec;
            if (defined($res)){   # only in Web-Context the state is stored
               $UserCache->{$AccountOrUserID}->{state}=$res->{state};
            }
            $UserCache->{$AccountOrUserID}->{atime}=time();
            if ($AccountOrUserID ne $rec->{userid}){
               $UserCache->{$rec->{userid}}=$UserCache->{$ENV{REMOTE_USER}};
            }
            return(1);
         }
         if (!defined($rec)){
            if (!$o->Ping()){
               msg(ERROR,"_LoadUserInUserCache: ".
                         "nativ problem while access base::user");
               Stacktrace();
            }
         }
      }
      else{
         msg(ERROR,"_LoadUserInUserCache: ".
                   "fail to ping base::user");
         Stacktrace();
      }
   }
   else{
      msg(ERROR,"_LoadUserInUserCache: ".
                "nativ problem while create base::user o=$o");
      Stacktrace();
   }
   return(0);
}


sub isSuspended
{
    my $self=shift;
    my $dataobj=shift;
    my $field=shift;
    if ($dataobj=~m/^base::/){
       return(0); # base:: objects can not be suspended
    }

    if (!defined($dataobj)){
       $dataobj=$self->Self();
    }
    my $t=time();

    if (!defined($self->Cache->{Blacklist}) ||
        $self->Cache->{Blacklist}->{t}<$t-300){
       my $o=$self->getPersistentModuleObject("base::blacklist");
       $o->BackendSessionName("BlackListHandling");
       $o->SetFilter({
          status=>\'1',
          limitstart=>[undef,"<now"],
          expiration=>[undef,">now"]
       });
       $o->SetCurrentView(qw(objtype field));
       my $bl=$o->getHashIndexed("objtype");
       $bl=ObjectRecordCodeResolver($bl);
       $self->Cache->{Blacklist}={
          t=>$t,
          tab=>$bl
       }; 
       if (ref($self->Cache->{Blacklist}->{tab}) ne "HASH"){
          $self->Cache->{Blacklist}->{tab}={objtype=>{}};
       }
    }
    if ((!defined($field) || $field eq "")){
       if (ref($self->Cache->{Blacklist}) eq "HASH"){
          if (exists($self->Cache->{Blacklist}->{tab}->{objtype}->{$dataobj})){
             my $r=$self->Cache->{Blacklist}->{tab}->{objtype}->{$dataobj};
             if (ref($r) eq "HASH" && $r->{field} eq ""){
                return(1);
             }
          }
       }
    }
    return(0);
}


sub getInitiatorGroupsOf
{
   my $self=shift;
   my $AccountOrUserID=shift;

   my %groups=$self->getGroupsOf($AccountOrUserID,
                  [orgRoles(),"RBackoffice"],'direct');
   my $now=NowStamp("en");
   my %age;
   foreach my $grpid (keys(%groups)){
      my $cdate=$groups{$grpid}->{'cdate'};
      my $a=99999999999999;
      if ($cdate ne ""){
         if (my $duration=CalcDateDuration($cdate,$now,"GMT")){ 
            $a=$duration->{totalseconds};
            
         }
      }
      $age{$grpid}=$a;
   }
   my @grplist;
   foreach my $grpid (sort({
                              my $t=$groups{$b}->{is_projectgrp} <=> 
                                    $groups{$a}->{is_projectgrp};
                              if ($t==0){
                                 $age{$a} <=> $age{$b};
                              }
                              $t;
                           } keys(%groups))){
      next if ($groups{$grpid}->{grpcistatusid}>5);
      push(@grplist,$grpid);
      push(@grplist,$groups{$grpid}->{fullname});
   }
   if ($#grplist==-1){ # if no active groups found - allow inactive too
      foreach my $grpid (sort({
                           $age{$a} <=> $age{$b}
                         } keys(%groups))){
         push(@grplist,$grpid);
         push(@grplist,$groups{$grpid}->{fullname});
      }
   }
   return(@grplist) if (wantarray());
   return($grplist[1]);
}


sub getGroupsByRoles
{
   my $self=shift;
   my $grpid=shift;
   my $roles=shift;
   my $maxdistance=shift;

   my $distance=0;
   my %res;

   $roles=[$roles] if (ref($roles) ne 'ARRAY');
   @$roles=grep(!/^\s*$/,@$roles);

   my $grp=$self->getPersistentModuleObject('base::grp');
   my $userrole=$self->getPersistentModuleObject('base::lnkgrpuserrole');
   $userrole->SetCurrentView(qw(nativrole cdate
                                grpid grpfullname
                                userid userfullname));

   while (defined($grpid) && $grpid ne '' &&
          !(defined($maxdistance) && $distance>$maxdistance)) {
      $userrole->ResetFilter();
      $userrole->SetFilter({cistatusid=>\4,
                            grpcistatusid=>\4,
                            grpid=>\$grpid,
                            nativrole=>$roles});
      my $lnk=$userrole->getHashIndexed(qw(nativrole));

      $grp->ResetFilter();
      $grp->SetFilter({grpid=>\$grpid});
      my ($curgrp,$msg)=$grp->getOnlyFirst(qw(parentid description));

      if (defined($lnk->{nativrole})) {
         my %roles;
         foreach my $role (keys(%{$lnk->{nativrole}})) {
            if (ref($lnk->{nativrole}->{$role}) ne 'ARRAY') {
               $lnk->{nativrole}->{$role}=[$lnk->{nativrole}->{$role}];
            }

            my @sorted=sort {$b->{cdate} cmp $a->{cdate}}
                             @{$lnk->{nativrole}->{$role}};
            $roles{$role}=\@sorted;
         }
         $res{$grpid}->{roles}=\%roles;
         $res{$grpid}->{distance}=$distance;
         $res{$grpid}->{description}=$curgrp->{description};
      }

      $grpid=$curgrp->{parentid};
      $distance++;
   }

   return(%res);
}


sub getGroupsOf
{
   my $self=shift;
   my $AccountOrUserID=shift;
   my $roles=shift;      # internel names of roles         (undef=RMember)
   my $direction=shift;  # up | down | both | direct       (undef=direct)

   $roles=["RMember"]   if (!defined($roles));
   $roles=[$roles]      if (ref($roles) ne "ARRAY");
   $direction="direct"  if (!defined($direction));

   my @directgroups=();
   my %allgrp=();

   my $UserCache=$self->Cache->{User}->{Cache};
   if (!defined($UserCache->{$AccountOrUserID})){
      $self->_LoadUserInUserCache($AccountOrUserID);
   }
   $UserCache=$self->Cache->{User}->{Cache}; # address of UserCache can be
                                             # changed by _LoadUserInUserCache
   my %directgroupage;
   if (defined($UserCache->{$AccountOrUserID})){
      $UserCache=$UserCache->{$AccountOrUserID}->{rec};
      if (defined($UserCache->{groups}) && 
          ref($UserCache->{groups}) eq "ARRAY"){
         foreach my $role (@{$roles}){
            push(@directgroups,map({
                                    $directgroupage{$_->{grpid}}=$_->{cdate};
                                    $_->{grpid};
                                   } 
                                   grep({
                                          if (!defined($_->{roles})){
                                             $_->{roles}=[];
                                          }
                                          grep(/^$role$/,@{$_->{roles}});
                                        } 
                                        @{$UserCache->{groups}})));
         }
      }
   }
   foreach my $directgrp (@directgroups){
      $self->LoadGroups(\%allgrp,$direction,$directgrp);
   }
   #
   # Handle virtuell groups "anonymous" and "valid_user"
   #
   if (grep(/^RMember$/,@{$roles})){
      if ($ENV{REMOTE_USER} ne "anonymous" &&
          $ENV{REMOTE_USER} ne ""){
         $allgrp{-1}={name=>'valid_user',
                      fullname=>'valid_user',
                      grpid=>-1,
                      distance=>0,
                      roles=>['RMember']
                     };
      }
      else{
         $allgrp{-2}={name=>'anonymous',
                      fullname=>'anonymous',
                      grpid=>-2,
                      distance=>0,
                      roles=>['RMember']
                     };
      }
      my $ma=$self->Config->Param("MASTERADMIN");
      if ($ma ne "" && $ENV{REMOTE_USER} eq $ma){
         $allgrp{1}={name=>'admin',
                     fullname=>'admin',
                     grpid=>1,
                     distance=>0,
                     roles=>['RMember']
                    };
      }
   }
   if ($direction eq "direct"){  # store age of relation for later use
      foreach my $directgrpid (keys(%directgroupage)){
         $allgrp{$directgrpid}->{cdate}=$directgroupage{$directgrpid};
      }
   }

   return(%allgrp);
}


sub ValidateGroupCache
{
   my $self=shift;
   my $multistate=shift;


   if (defined($self->Cache->{Group}->{state})){
      my $res={state=>$multistate};
      if (!defined($res->{state})){
         $res=$self->W5ServerCall("rpcCacheQuery","Group");
      }
      if (!defined($res)){
         msg(INFO,"W5ServerCall failed - cache for cwGroup cleared");
         delete($self->Cache->{Group});
      }
      elsif ($self->Cache->{Group}->{state} ne $res->{state}){
         my $age="undef";
         if (($self->Cache->{Group}->{state}=~m/^[0-9]+$/) &&
             ($res->{state}=~m/^[0-9]+$/)){
            $age=$res->{state}-$self->Cache->{Group}->{state};
         }
         msg(INFO,"cache for Group is invalid - ".
                  "cleared state='%s' rpcstate='%s' age=$age",
                  $self->Cache->{Group}->{state},
                  $res->{state});
         delete($self->Cache->{Group});
      }
      if (defined($self->Cache->{Group})){
         $self->Cache->{Group}->{atime}=time();
      }
   }
   if (!defined($self->Cache->{Group}->{Cache})){
      my $grp=$self->ModuleObject("base::grp");
      $grp->SetFilter({grpid=>'>-999999999'}); # prefend slow query entry
      $grp->SetCurrentView(qw(grpid fullname parentid 
                              subid cistatusid
                              is_org is_projectgrp));
      $grp->SetCurrentOrder("NONE");
      $self->Cache->{Group}->{Cache}=$grp->getHashIndexed(qw(grpid fullname));
      foreach my $grp (values(%{$self->Cache->{Group}->{Cache}->{grpid}})){
         if (!defined($grp->{subid})){
            $grp->{subid}=[];
         }
         if (defined($grp->{parentid})){
            my $p=$self->Cache->{Group}->{Cache}->{grpid}->{$grp->{parentid}};
            if (!defined($p->{subid})){
               $p->{subid}=[$grp->{grpid}];
            }
            else{
               push(@{$p->{subid}},$grp->{grpid});
            }
         }
      }
      my $res=$self->W5ServerCall("rpcCacheQuery","Group");
      if (defined($res)){
         $self->Cache->{Group}->{state}=$res->{state};
      }
   }
   return(1);
}


sub getTemplate
{
   my $self=shift;
   my $name=shift;
   my $skinbase=shift;
   my $addskin=shift;
   my $mask;
   my $maskfound=0;
   my $filename;

   my %opt;
   if ($addskin ne ""){
      $opt{addskin}=$addskin;
   }
   if (!($name=~m/\.js$/) || ($name=~m/tmpl\/.*\.js$/)){
      if (!defined($skinbase)){
         $skinbase=$self->SkinBase();
         my $skinfilename=$skinbase."/".$name;
         $filename=$self->getSkinFile($skinfilename,%opt);
         if (!defined($filename)){
            my $sp;
            if ($self->can("SelfAsParentObject")){
               $sp=$self->SelfAsParentObject();
            }
            if ($sp ne $self->Self()){
               my ($altskinbase)=$sp=~m/^([^:]+)::/;
               my $skinfilename=$altskinbase."/".$name;
               my $f=$self->getSkinFile($skinfilename,%opt);
               if (defined($f)){
                  $filename=$f;
               }
            }
         }
      }
      else{
         $name=$skinbase."/".$name;
         $filename=$self->getSkinFile($name,%opt);
      }
   }
   else{
      my $instdir=$self->Config->Param("INSTDIR");
      $filename=$instdir."/lib/javascript/".$name;
   }

   if ( -r $filename ){
      if (open(F,"<$filename")){
         $maskfound=1;
         $mask=join('',<F>);
         close(F);
      }
   }
   if (!$maskfound){
      return(undef);
   }
   return($mask);
}

sub getParsedTemplate
{
   my $self=shift;
   my $name=shift;
   my $opt=shift;
   my $skinbase=$opt->{skinbase};
   my $mask=$self->getTemplate($name,$skinbase);
   if (defined($mask)){
      $self->ParseTemplateVars(\$mask,$opt);
   }
   else{
      $mask="<center><table bgcolor=red cellspacing=5 cellpadding=5>".
            "<tr><td><font face=\"Arial,Helvetica\">".
            "Template File '$name' not found<br>".
            "SKINDIR='".$self->getSkinDir()."'<br>".
            "SKIN='".join(": ",$self->getSkin())."'<br>".
            "</font></td></tr>".
            "</table></center>";
   }
   return($mask);
}

sub getDataObj
{
   my $self=shift;
   my $package=shift;
   my %modparam=();
   my $o;

   $modparam{'Config'}=$self->Config();
   eval("use $package;\$o=new $package(\%modparam);");
   if ($@ ne ""){
      msg(ERROR,"getDataObj: can't create '$package'");
      print STDERR $@;
      return(undef); 
   }
   $o->setParent($self);
   return($o);
}

sub getInstalledDataObjNames
{
   my $self=shift;
   my @names;

   my $instdir=$self->Config->Param("INSTDIR");
   @names=(glob($instdir."/mod/*/*.pm"),glob($instdir."/mod/*/workflow/*.pm"));
   map({$_=~s/^.*\/mod\///;
        $_=~s/\.pm$//;
        $_=~s/\//::/g;
        $_;} @names);

}

sub LoadTranslation
{
   my $self=shift;
   my $caller=shift;
   my $nodefaulttranslation=shift;
   my @calltag;
   my $tr={};

   if ($caller=~m/^kernel::/){
      if ($nodefaulttranslation){
         @calltag=("base/lang/$caller");
      }
      else{
         @calltag=("base/lang/translation","base/lang/$caller");
      }
   }
   else{
      my ($mod)=$caller=~m/^(\S+?)::/;
      if ($nodefaulttranslation){
         @calltag=("$mod/lang/$caller");
      }
      else{
         @calltag=("base/lang/translation","$mod/lang/translation",
                   "$mod/lang/$caller");
      }
   }
   foreach my $calltag (@calltag){
      $calltag=~s/::/./g;
      my $filename=$self->getSkinFile($calltag);
      if (defined($filename) && -r $filename){
         my $transcode="";
         if (open(F,"<$filename")){
            $transcode=join("",<F>);
            close(F);
         }
         my $trcode={};
         eval("\$trcode={$transcode};");
         msg(ERROR,"can't load transtable $filename\n%s",$@) if ($@ ne "");
         foreach my $key (keys(%{$trcode})){
            next if (ref($trcode->{$key}) ne "HASH");
            foreach my $lang (LangTable()){
               if (defined($trcode->{$key}->{$lang})){
                  $tr->{$lang}->{$key}=$trcode->{$key}->{$lang};
               }
            }
         }
      }
   }
   return($tr);
}


sub getSkinDir
{
   my $self=shift;

   my $skindir=$self->Config->Param('SKINDIR');
   if ($skindir eq ""){
      $skindir=$self->Config->Param("INSTDIR")."/skin";
   }
   return($skindir);
}


sub getSkin
{
   my $self=shift;
   my $lang=$self->Lang();

   my @skin=split(/:/,$self->Config->Param('SKIN'));
   $skin[0]="default"                  if ($skin[0] eq "");
   # Check if W5SKIN is set
   return("default") if (!defined(Query));
   my $userskin=Query->Cookie("W5SKIN");
   if ($userskin ne ""){
      if (in_array(\@skin,$userskin)){
         @skin=($userskin);
      }
   }
   push(@skin,"default")               if (!grep(/^default$/,@skin));
   @skin=map({($_.".".$lang,$_)} @skin);
   return(@skin);
}

sub LowLevelLang
{
   my $self=shift;

   my @languages=LangTable();
   if (defined($ENV{HTTP_ACCEPT_LANGUAGE})){
      my %l;
      my $defq=1.0;
      my $lang;
      map({my ($q)=$_=~m/q=([\d\.]+)/;
                 if (!defined($q)){
                    $q=$defq;
                    $defq=$defq-0.1;
                 }
                 $_=~s/[;]{0,1}q=[\d\.]+[;]{0,1}//;
                 $l{$q}=$_;
                } split(/,/,$ENV{HTTP_ACCEPT_LANGUAGE}));
      foreach my $q (sort({$b<=>$a} keys(%l))){
         if (grep(/^$l{$q}$/,@languages)){
            $lang=$l{$q};
            last;
         }
         my $chk=$l{$q};
         $chk=~s/-.*$//;
         if (grep(/^$chk$/,@languages)){
            $lang=$chk;
            last;
         }
      }
      return($languages[0]) if (!defined($lang));
      return($lang);
   }
   my $envlang=lc($ENV{LANG});
   $envlang=~s/_.*$//;
   if (grep(/^$envlang$/,@languages)){
      return($envlang);
   }
   return("en") if ($ENV{LANG} eq "C");
   return(undef);
}

sub UserTimezone
{
   my $self=shift;

   my $utimezone="GMT";
   my $UserCache=$self->Cache->{User}->{Cache};
   if ($ENV{REMOTE_USER} ne ""){
      if (defined($UserCache->{$ENV{REMOTE_USER}})){
         $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
      }
      if (defined($UserCache->{tz})){
         $utimezone=$UserCache->{tz};
      }
   }
   return($utimezone);
}

sub Log
{
   my $self=shift;
   my $mode=shift;
   my $facility=lc(shift);
   return(undef) if ($facility eq "" || length($facility)>20);
   $facility=~s/\.//g;
   if ($W5V2::OperationContext eq "W5Server"){
      $facility="w5server_".$facility;
   }
   elsif ($W5V2::OperationContext eq "W5Replicate"){
      $facility="w5replicate_".$facility;
   }
   my $Cache=$self->Cache;
   if (!exists($Cache->{LogCache})){
      $Cache->{LogCache}={}; 
   }
   my $LogCache=$Cache->{LogCache};
   if (!exists($LogCache->{$facility})){
      $LogCache->{$facility}={};
      my @logfac=split(/\s*[,;]\s*/,lc($self->Config->Param("Logging")));
      if (grep(/^\+{0,1}$facility$/,@logfac)){
         my $target=$self->Config->Param("LogTarget");
         if ($target=~m/^\//){ # file logging
            $target=~s/\%f/$facility/g;
            my $oldumask=umask(0000);
            my $fh=new IO::File();
            if (! -f $target){
               msg(INFO,"try to create logfile '$target' at PID $$");
               if ($fh->open(">$target")){
                  $fh->autoflush();
                  $LogCache->{$facility}->{file}=$target; 
                  $LogCache->{$facility}->{fh}=$fh; 
                  $fh->close();
               }
            }
            else{
               if ($self->Config->Param("W5BaseOperationMode") eq "dev"){
                  msg(INFO,"reopen logfile '$target' at PID $$");
               }
               if ($fh->open(">>$target")){
                  $fh->autoflush();
                  $LogCache->{$facility}->{file}=$target; 
                  $LogCache->{$facility}->{fh}=$fh; 
               }
            }
            if (! defined($LogCache->{$facility}->{fh})){
               msg(WARN,"fail to open logfile '$target' - $!");
            }
            umask($oldumask);
         }
         elsif ($target eq "SYSLOG"){
            eval('use Sys::Syslog qw(:DEFAULT setlogsock);');
            if ($@ eq ""){
               $LogCache->{$facility}->{syslog}=1; 
            }
         }
      }
      else{
         if (!grep(/^-{0,1}$facility$/,@logfac) &&
             !grep(/^$facility$/,@logfac)){
            $LogCache->{$facility}->{usemsg}=1; 
         }
      }
   }
   if (defined($LogCache->{$facility})){
      if ((defined($LogCache->{$facility}) &&
          exists($LogCache->{$facility}->{syslog}))){
         eval('
            openlog("w5base.".$facility,"ndelay,pid", "local0");
            syslog("info",@_);
            closelog();

         ');
      }
      if ((defined($LogCache->{$facility}) &&
          exists($LogCache->{$facility}->{usemsg})) || $W5V2::Debug){
         msg($mode,@_);
      }
      if (defined($LogCache->{$facility}->{fh})){
         if (! -f $LogCache->{$facility}->{file}){
            close($LogCache->{$facility}->{fh});
            delete($LogCache->{$facility});
            msg(INFO,"logs close for facility '$facility'");
         }
         else{
            my $fout=*{$LogCache->{$facility}->{fh}};
            my $fout=$LogCache->{$facility}->{fh};
            my $txt=shift;
            if ($txt=~m/\%/ && $#_!=-1){
               $txt=sprintf($txt,@_);
            }
            $!=undef;
            my $logd;
            foreach my $l (split(/[\r\n]+/,$txt)){
               if ($l ne "" && $l ne "-"){
                  $logd.=sprintf("%s [%d] %-6s %s\n",NowStamp(),$$,$mode,$l);
               }
               else{
                  $logd.="\n";
               }
            }
            $logd=~s/[^[:ascii:]]+/?/g;
            print $fout ($logd); # print atomic to make it better readable
            return(1);           # in the log for the admins
         }
      }
   }
   return(undef);
}


sub Lang
{
   my $self=shift;

   if (defined($ENV{HTTP_FORCE_LANGUAGE}) && 
       $ENV{HTTP_FORCE_LANGUAGE} ne ""){
      return($ENV{HTTP_FORCE_LANGUAGE});
   }
   my @languages=LangTable();
   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   
   if (defined($UserCache->{lang}) && grep(/^$UserCache->{lang}$/,@languages)){
      return($UserCache->{lang});
   }
   if (my $lowlang=$self->LowLevelLang()){
      return($lowlang);
   }
   if ($self->Config->Param("W5BaseOperationMode") eq "dev"){
      msg(INFO,"Warn: Lang(LANG)=%s not implemented! - ".
                     "using en caller=%s",join(",",caller(1)));
   }
   return("en");
}

sub LastMsg
{
   my $self=shift;
   my $type=shift;
   my $format=shift;
   my @p=@_;
   my $gc=globalContext();
   my $caller=caller();

   $gc->{LastMsg}=[] if (!exists($gc->{LastMsg}));
   $gc->{LastErrorMsgCount}=0 if (!exists($gc->{LastErrorMsgCount}));
   if (defined($type)){
      if ($type eq ""){
         $gc->{LastMsg}=[];
         $gc->{LastErrorMsgCount}=0;
      }
      else{
         msg(INFO,"LastMsg '%s' caller=$caller",$format);
         if ($type eq ERROR){
            $gc->{LastErrorMsgCount}++;
         }
         push(@{$gc->{LastMsg}},msg($type,$self->T($format,$caller),@p));
      }
   }
   else{
      if (wantarray()){
         return(@{$gc->{LastMsg}});
      }
   }
   return($#{$gc->{LastMsg}}+1);
}



sub LastErrorMsgCount     # Error message count, which are not silent
{
   my $self=shift;
   my $gc=globalContext();
   $gc->{LastErrorMsgCount}=0 if (!exists($gc->{LastErrorMsgCount}));
   return($gc->{LastErrorMsgCount});
}



sub SilentLastMsg
{
   my $self=shift;
   my $type=shift;
   my $format=shift;
   my @p=@_;
   my $gc=globalContext();
   my $caller=caller();

   $gc->{LastMsg}=[] if (!exists($gc->{LastMsg}));
   if (defined($type)){
      if ($type eq ""){
         $gc->{LastMsg}=[];
         $gc->{LastErrorMsgCount}=0;
      }
      else{
         push(@{$gc->{LastMsg}},
              sprintf($type.": ".$self->T($format,$caller)),@p);
      }
   }
   else{
      if (wantarray()){
         return(@{$gc->{LastMsg}});
      }
   }
   return($#{$gc->{LastMsg}}+1);
}



sub getSkinFile
{
   my $self=shift;
   my $conftag=shift;
   my %param=@_;
   my $baseskindir=$self->getSkinDir();
   my @skin;
 
   $conftag=~s/\.\./\./g;              # security hack
   $conftag=~s/^\///g;                 # security hack

   my @filename=();
   if (defined($param{skin})){
      @skin=($param{skin});
   }
   else{
      @skin=$self->getSkin();
   }
   if (defined($param{addskin})){
      unshift(@skin,$param{addskin});
   }
   my @skindir=($baseskindir);
   if ($#{$W5V2::INSTPATH}!=-1){
      push(@skindir,map({$_."/skin"} @{$W5V2::INSTPATH}));
   }
   my $modpath=$self->Config->Param("MODPATH");
   if ($modpath ne ""){
      foreach my $path (split(/:/,$modpath)){
         $path.="/skin";
         my $qpath=quotemeta($path);
         unshift(@skindir,$path) if (!grep(/^$qpath$/,@skindir));
      }
   }

   foreach my $skindir (@skindir){
      foreach my $skin (@skin){
         my $chkname=$skindir."/".$skin."/".$conftag;
         if ($conftag=~m/\*/){
            my @flist=glob($chkname);
            return(@flist) if ($#flist>=0);
         }
         else{
            if (-f $chkname){
               return($chkname);
            }
         }
      }
   }
   return();
}

sub T
{
   my $self=shift;
   my $txt=shift;
   my @module=@_;
   my $lang=$self->Lang();
   my @trtab;
   if ($#module==-1){
      $trtab[0]=(caller())[0];
   }
   else{
      @trtab=@module;
   }
   #printf STDERR ("TRANSLATE: $txt with %s lang=$lang\n",join(",",@trtab));
   foreach my $trtab (@trtab){
      if ($trtab ne ""){
         if (!defined($W5V2::Translation->{tab}->{$trtab})){
            #msg(INFO,"load translation table for '$trtab'");
            if (exists($W5V2::Translation->{self})){
               $W5V2::Translation->{tab}->{$trtab}=
                         $W5V2::Translation->{self}->LoadTranslation($trtab,0);
            }
            else{
               $W5V2::Translation->{tab}->{$trtab}=
                         $self->LoadTranslation($trtab,0);
            }
         }
         if (exists($W5V2::Translation->{tab}->{$trtab}->{$lang}) &&
             exists($W5V2::Translation->{tab}->{$trtab}->{$lang}->{$txt})){
            return($W5V2::Translation->{tab}->{$trtab}->{$lang}->{$txt});
         }
      }
   }
   return($txt);
}

sub ExpandTRangeExpression
{
   my $self=shift;
   my $val=shift;
   my $srctimezone=shift;
   my $dsttimezone=shift;
   my $filename=shift;
   my $opt=shift;
   my $f=undef;

   $dsttimezone="GMT" if (!defined($dsttimezone));
   if (!defined($srctimezone)){
      $srctimezone=$self->UserTimezone();
   }
   $opt={} if (!defined($opt));

   my $res=undef;

   if ($val=~m/^".*"$/){
      $val=~s/^"//;
      $val=~s/"$//;
   }
   if ($val=~m/^currentmonth$/gi){
      my ($Y,$M,$D,$h,$m,$s)=Today_and_Now($srctimezone); 
      my $max=Days_in_Month($Y,$M);
      $val="$Y-$M-01 00:00:00/$Y-$M-$max 23:59:59";
      $f=sprintf("%04d/%02d",$Y,$M);
      #printf STDERR ("fifi02 val='$val'\n");
   }
   elsif ($val=~m/^nextmonth$/gi){
      my ($Y,$M,$D,$h,$m,$s)=Today_and_Now($srctimezone); 
      ($Y,$M,$D)=Add_Delta_YM($srctimezone,$Y,$M,$D,0,1);
      my $max=Days_in_Month($Y,$M);
      $val="$Y-$M-01 00:00:00/$Y-$M-$max 23:59:59";
      $f=sprintf("%04d/%02d",$Y,$M);
   }
   elsif ($val=~m/^currentyear$/gi){
      my ($Y,$M,$D,$h,$m,$s)=Today_and_Now($srctimezone); 
      $val="$Y-01-01 00:00:00/$Y-12-31 23:59:59";
      $f=sprintf("%04d",$Y);
   }
   elsif ($val=~m/^lastyear$/gi){
      my ($Y,$M,$D,$h,$m,$s)=Today_and_Now($srctimezone); 
      $Y--;
      $val="$Y-01-01 00:00:00/$Y-12-31 23:59:59";
      $f=sprintf("%04d",$Y);
   }

   if (my ($Y1,$M1,$D1,$h1,$m1,$s1,$Y2,$M2,$D2,$h2,$m2,$s2)=
          $val=~m/^(\d{1,2})\.(\d{1,2})\.(\d{4})\s
                   (\d{1,2}):(\d{1,2}):(\d{1,2})-
                   (\d{1,2})\.(\d{1,2})\.(\d{4})\s
                   (\d{1,2}):(\d{1,2}):(\d{1,2})$/xgi){
      $val=sprintf("%04d-%02d-%02d %02d:%02d:%02d/".
                   "%04d-%02d-%02d %02d:%02d:%02d",
                   $D1,$M1,$Y1,$h1,$m1,$s1,
                   $D2,$M2,$Y2,$h2,$m2,$s2);
   }
   if (my ($Y1,$M1,$D1,$Y2,$M2,$D2)=
          $val=~m/^(\d{1,2})\.(\d{1,2})\.(\d{4})-
                   (\d{1,2})\.(\d{1,2})\.(\d{4})$/xgi){
      my ($h1,$m1,$s1,$h2,$m2,$s2)=(0,0,0,23,59,59);
      $val=sprintf("%04d-%02d-%02d %02d:%02d:%02d/".
                   "%04d-%02d-%02d %02d:%02d:%02d",
                   $D1,$M1,$Y1,$h1,$m1,$s1,
                   $D2,$M2,$Y2,$h2,$m2,$s2);
   }
   if (my ($Y1,$M1,$D1,$h1,$m1,$s1,$Y2,$M2,$D2,$h2,$m2,$s2)=
          $val=~m/^(\d{4})-(\d{1,2})-(\d{1,2})\s
                   (\d{1,2}):(\d{1,2}):(\d{1,2})\/
                   (\d{4})-(\d{1,2})-(\d{1,2})\s
                   (\d{1,2}):(\d{1,2}):(\d{1,2})$/xgi){
      my ($time1,$time2);
      my $fromalign=0;
      my $toalign=0;
      if ($opt->{align} eq "day"){
         if (!($h1==0  && $m1==0  && $s1==0 &&
               $h2==23 && $m2==59 && $s2==59)){
            $h1=0;$m1=0;$s1=0;     # auto align
            $h2=23;$m2=59;$s2=59;
            $fromalign=(24*60*60)*-1;
            $toalign=(24*60*60);
         } 
      }
      eval('$time1=Mktime($srctimezone,$Y1,$M1,$D1,$h1,$m1,$s1);');
      eval('$time2=Mktime($srctimezone,$Y2,$M2,$D2,$h2,$m2,$s2);');
      if ($time1>$time2){
         return(undef);
      }
      $time1+=$fromalign;
      $time2+=$toalign;
      ($Y1,$M1,$D1,$h1,$m1,$s1)=Localtime($dsttimezone,$time1);
      ($Y2,$M2,$D2,$h2,$m2,$s2)=Localtime($dsttimezone,$time2);
      $res=[sprintf("%04d-%02d-%02dT%02d:%02d:%02d",
                    $Y1,$M1,$D1,$h1,$m1,$s1),
            sprintf("%04d-%02d-%02dT%02d:%02d:%02d",
                    $Y2,$M2,$D2,$h2,$m2,$s2)];
      #printf STDERR ("fifi res= '%s' - '%s'\n",$res->[0],$res->[1]);
   }
   if (my ($Y1,$M1,$D1,$h1,$m1,$s1,$Y2,$M2,$D2,$h2,$m2,$s2)=
          $val=~m/^(\d{4})-(\d{1,2})-(\d{1,2})T
                   (\d{1,2}):(\d{1,2}):(\d{1,2})P
                   (\d{4})-(\d{1,2})-(\d{1,2})T
                   (\d{1,2}):(\d{1,2}):(\d{1,2})$/xgi){
      my ($time1,$time2);
      if ($opt->{align} eq "day"){
         if (!($h1==0  && $m1==0  && $s1==0 &&
               $h2==23 && $m2==59 && $s2==59)){
            return(undef);
         } 
      }
      eval('$time1=Mktime("GMT",$Y1,$M1,$D1,$h1,$m1,$s1);');
      eval('$time2=Mktime("GMT",$Y2,$M2,$D2,$h2,$m2,$s2);');
      if ($time1>$time2){
         return(undef);
      }
      ($Y1,$M1,$D1,$h1,$m1,$s1)=Localtime($dsttimezone,$time1);
      ($Y2,$M2,$D2,$h2,$m2,$s2)=Localtime($dsttimezone,$time2);
      $res=[sprintf("%04d-%02d-%02dT%02d:%02d:%02d",
                    $Y1,$M1,$D1,$h1,$m1,$s1),
            sprintf("%04d-%02d-%02dT%02d:%02d:%02d",
                    $Y2,$M2,$D2,$h2,$m2,$s2)];
      #printf STDERR ("fifi res= '%s' - '%s'\n",$res->[0],$res->[1]);
   }

   $$filename=$f if (ref($filename) eq "SCALAR");
   return($res);
}


sub PreParseTimeExpression
{
   my $self=shift;
   my $val=shift;
   my $tz=shift;
   my $filename=shift;
   my $f=undef;

   ####################################################################
   # pre parser
   if ($val=~m/^currentmonth$/gi){
      my ($Y,$M,$D,$h,$m,$s)=Today_and_Now($tz); 
      my $max=Days_in_Month($Y,$M);
      $val="\">=$Y-$M-01 00:00:00\" AND \"<=$Y-$M-$max 23:59:59\"";
      $f=sprintf("%04d/%02d",$Y,$M);
   }
   elsif ($val=~m/^lastmonth$/gi){
      my ($Y,$M,$D,$h,$m,$s)=Today_and_Now($tz); 
      ($Y,$M,$D)=Add_Delta_YM($tz,$Y,$M,$D,0,-1);
      my $max=Days_in_Month($Y,$M);
      $val="\">=$Y-$M-01 00:00:00\" AND \"<=$Y-$M-$max 23:59:59\"";
      $f=sprintf("%04d-%02d",$Y,$M);
   }
   elsif ($val=~m/^lastweek$/gi){
      $val=">=now-7d AND <=now";
      $f=sprintf("lastweek");
   }
   elsif ($val=~m/^last2weeks$/gi){
      $val=">=now-14d AND <=now";
      $f=sprintf("last2weeks");
   }
   elsif ($val=~m/^nextmonth$/gi){
      my ($Y,$M,$D,$h,$m,$s)=Today_and_Now($tz); 
      ($Y,$M,$D)=Add_Delta_YM($tz,$Y,$M,$D,0,1);
      my $max=Days_in_Month($Y,$M);
      $val="\">=$Y-$M-01 00:00:00\" AND \"<=$Y-$M-$max 23:59:59\"";
      $f=sprintf("%04d/%02d",$Y,$M);
   }
   elsif ($val=~m/^currentyear$/gi){
      my ($Y,$M,$D,$h,$m,$s)=Today_and_Now($tz); 
      $val="\">=$Y-01-01 00:00:00\" AND \"<=$Y-12-31 23:59:59\"";
      $f=sprintf("%04d",$Y);
   }
   elsif ($val=~m/^lastyear$/gi){
      my ($Y,$M,$D,$h,$m,$s)=Today_and_Now($tz); 
      $Y--;
      $val="\">=$Y-01-01 00:00:00\" AND \"<=$Y-01-12 23:59:59\"";
      $f=sprintf("%04d",$Y);
   }
   elsif ($val=~m/^currentmonth and lastmonth$/gi ||
          $val=~m/^lastmonth and currentmonth$/gi){
      my ($Y,$M,$D,$h,$m,$s)=Today_and_Now($tz); 
      my ($Y0,$M0,$D0)=Add_Delta_YM($tz,$Y,$M,$D,0,-1);
      my ($Y1,$M1,$D1)=($Y,$M,$D);
      my $max=Days_in_Month($Y1,$M1);
      $val="\">=$Y0-$M0-01 00:00:00\" AND \"<=$Y1-$M1-$max 23:59:59\"";
      $f=sprintf("%04d/%02d-%02d",$Y,$M,$M1);
   }
   elsif (my ($d)=$val=~m/^last\s+(\d+) months$/gi){
      my ($Y,$M,$D,$h,$m,$s)=Today_and_Now($tz); 
      my ($Y0,$M0,$D0)=Add_Delta_YM($tz,$Y,$M,$D,0,-1*$d);
      my ($Y1,$M1,$D1)=($Y,$M,$D);
      my $max=Days_in_Month($Y1,$M1);
      $val="\">=$Y0-$M0-01 00:00:00\" AND \"<=$Y1-$M1-$max 23:59:59\"";
      $f=sprintf("%04d/%02d-%02d",$Y,$M0,$M1);
   }
   elsif (my ($M,$Y)=$val=~m/^\((\d+)\/(\d+)\)$/gi){
      my $max;
      eval('$max=Days_in_Month($Y,$M);');
      if ($@ eq ""){
         $val="\">=$Y-$M-01 00:00:00\" AND \"<=$Y-$M-$max 23:59:59\"";
         $f=sprintf("%04d/%02d",$Y,$M);
      }
   }
   elsif (my ($q,$Y)=$val=~m/^\(q([1234])\/(\d+)\)$/gi){
      my ($m1,$m2)=(10,12);
      if ($q==1){
         $m1=1;$m2=3;
      }
      elsif($q==2){
         $m1=4;$m2=6;
      }
      elsif($q==3){
         $m1=7;$m2=9;
      }
      my $max;
      eval('$max=Days_in_Month($Y,$m2);');
      if ($@ eq ""){
         $val="\">=$Y-$m1-01 00:00:00\" AND \"<=$Y-$m2-$max 23:59:59\"";
         $f=sprintf("%04d/Q%d",$Y,$q);
      }
   }
   elsif (my ($h,$Y)=$val=~m/^\(h([12])\/(\d+)\)$/gi){
      my ($m1,$m2)=(7,12);
      if ($h==1){
         $m1=1;$m2=6;
      }
      my $max;
      eval('$max=Days_in_Month($Y,$m2);');
      if ($@ eq ""){
         $val="\">=$Y-$m1-01 00:00:00\" AND \"<=$Y-$m2-$max 23:59:59\"";
         $f=sprintf("%04d/H%d",$Y,$h);
      }
   }
   elsif (my ($Y,$M)=$val=~m/^\((\d{4})(\d{2})\)$/gi){
      my $max;
      eval('$max=Days_in_Month($Y,$M);');
      if ($@ eq ""){
         $val="\">=$Y-$M-01 00:00:00\" AND \"<=$Y-$M-$max 23:59:59\"";
         $f=sprintf("%04d/%02d",$Y,$M);
      }
   }
   elsif (my ($y1,$m1,$d1,$y2,$m2,$d2)=
          $val=~m/^\((\d{4})-(\d{2})-(\d{2}):(\d{4})-(\d{2})-(\d{2})\)$/gi){
      #my ($syear,$smon,$sday);
      #eval('($syear,$smon,$sday)=Monday_of_Week($W,$Y);');
      if ($@ eq ""){
         $val="\">=$y1-$m1-$d1 00:00:00\" AND ".
              "\"<=$y2-$m2-$d2 23:59:59\"";
         #$f=sprintf("%04d/CW%02d",$Y,$W);
      }
   }
   elsif (my ($Y,$W)=$val=~m/^\((\d+)[CK]W(\d+)\)$/gi){
      my ($syear,$smon,$sday);
      eval('($syear,$smon,$sday)=Monday_of_Week($W,$Y);');
      if ($@ eq ""){
         $val="\">=$syear-$smon-$sday 00:00:00\" AND ".
              "\"<=$syear-$smon-$sday 23:59:59+7d\"";
         $f=sprintf("%04d/CW%02d",$Y,$W);
      }
   }
   elsif (my ($Y,$W)=$val=~m/^\((\d+)Q(\d+)\)$/gi){   # Quartal def is todo!
   #   my ($syear,$smon,$sday);   
   #   eval('($syear,$smon,$sday)=Monday_of_Week($W,$Y);');
   #   if ($@ eq ""){
   #      $val="\">=$syear-$smon-$sday 00:00:00\" AND ".
   #           "\"<=$syear-$smon-$sday 23:59:59+7d\"";
   #      $f=sprintf("%04d/CW%02d",$Y,$W);
   #   }
   }
   elsif (my ($Y)=$val=~m/^\((\d{4,4})\)$/gi){
      my $max;
      eval('$max=Days_in_Month($Y,12);');
      if ($@ eq ""){
         $val="\">=$Y-01-01 00:00:00\" AND \"<=$Y-12-$max 23:59:59\"";
         $f=sprintf("%04d/01-12",$Y);
      }
   }
   $$filename=$f if (ref($filename) eq "SCALAR");

   return($val);
}


sub ExpandTimeExpression
{
   my $self=shift;
   my $val=shift;
   my $format=shift;    # undef=stamp|de|en|DateTime
   my $srctimezone=shift;
   my $dsttimezone=shift;
   my %param=@_;
   my $result="";
   my ($Y,$M,$D,$h,$m,$s);
   my $found=0;
   my $fail=1;
   my $time;
   my $orgval=trim($val);
   if ($param{defhour} eq ""){
      $param{defhour}=0;
   }
   if ($param{defmin} eq ""){
      $param{defmin}=0;
   }
   if ($param{defsec} eq ""){
      $param{defsec}=0;
   }
   $dsttimezone="GMT" if (!defined($dsttimezone));
   $format="en" if (!defined($format));
   if (!defined($srctimezone)){
      $srctimezone=$self->UserTimezone();
   }
   ####################################################################
   my $monthbase=$self->T("monthbase");
   my $todaylabel=$self->T("today");
   my $nowlabel=$self->T("now");

   #msg(INFO,"ExpandTimeExpression for '$val'");
   if ($val=~m/^$nowlabel/gi){
      $val=~s/^$nowlabel//;
      ($Y,$M,$D,$h,$m,$s)=Today_and_Now($dsttimezone); 
      $found=1;
      $fail=0;
   }
   elsif ($val=~m/^$todaylabel/gi){
      $val=~s/^$todaylabel//;
      ($Y,$M,$D,undef,undef,undef)=Today_and_Now($srctimezone); 
      $h=$param{defhour};
      $m=$param{defmin};
      $s=$param{defsec};
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif ($val=~m/^now/gi){
      $val=~s/^now//;
      ($Y,$M,$D,$h,$m,$s)=Today_and_Now($dsttimezone); 
      $found=1;
      $fail=0;
   }
   elsif ($val=~m/^today/gi){
      $val=~s/^today//;
      ($Y,$M,$D,undef,undef,undef)=Today_and_Now($srctimezone); 
      $h=$param{defhour};
      $m=$param{defmin};
      $s=$param{defsec};
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif ($val=~m/^monthbase/gi){
      $val=~s/^monthbase//;
      ($Y,$M,undef,undef,undef,undef)=Today_and_Now($srctimezone); 
      $h=$param{defhour};
      $m=$param{defmin};
      $s=$param{defsec};
      $D=1;
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($Y,$M,$D,$h,$m,$s)=$val=~
          m/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})Z/){
      $val=~s/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})Z//;
      eval('$time=Mktime("GMT",$Y,$M,$D,$h,$m,$s);'); # SRC is allays GMT
      if ($@ ne ""){                                  # in LDAP Timestamps
         $self->LastMsg(ERROR,"ilegal search expression '%s'",
                                         $orgval);
         return(undef);
      }
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($Y,$M,$D,$h,$m,$s)=$val=~
          m/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/){
      $val=~s/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})//;
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      if ($@ ne ""){
         $self->LastMsg(ERROR,"ilegal search expression '%s'",
                                         $orgval);
         return(undef);
      }
      
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($M,$Y)=$val=~/^(\d+)\/(\d+)/){
      $val=~s/^(\d+)\/(\d+)//;
      $Y+=2000 if ($Y<50);
      $Y+=1900 if ($Y>=50 && $Y<=99);
      $Y=1971 if ($Y<1971);
      $Y=2037 if (!is_POSIXmktime_Clean() && $Y>2037);
      $Y=2999 if (is_POSIXmktime_Clean()  && $Y>2999);
      eval('$time=Mktime($srctimezone,$Y,$M,1,0,0,0);');
      if ($@ ne ""){
         $self->LastMsg(ERROR,"ilegal month expression '%s'",
                                         $orgval);
         return(undef);
      }
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($Y,$M,$D,$h,$m,$s)=$val=~
          m/^(\d+)-(\d+)-(\d+)\s+(\d+):(\d+):(\d+)/){
      $val=~s/^(\d+)-(\d+)-(\d+)\s+(\d+):(\d+):(\d+)//;
      if (my ($srctz)=$val=~m/ ([A-Z]+)/){
         $val=~s/ ([A-Z])+//;
         $srctimezone=$srctz;
      }
      $Y+=2000 if ($Y<50);
      $Y+=1900 if ($Y>=50 && $Y<=99);
      $Y=1971 if ($Y<1971);
      $Y=2037 if (!is_POSIXmktime_Clean() && $Y>2037);
      $Y=2999 if (is_POSIXmktime_Clean()  && $Y>2999);
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      if ($@ ne ""){
         $self->LastMsg(ERROR,"ilegal expression '%s'",
                                         $orgval);
         return(undef);
      }
      
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($Y,$M,$D,$h,$m,$s)=$val=~
          m/^(\d{4})-(\d+)-(\d+)T(\d+):(\d+):(\d+)(\.\d*){0,1}Z/){
      $val=~s/^(\d{4})-(\d+)-(\d+)T(\d+):(\d+):(\d+)(\.\d*){0,1}Z//;
      $srctimezone="GMT";
      $Y=1971 if ($Y<1971);
      $Y=2037 if (!is_POSIXmktime_Clean() && $Y>2037);
      $Y=2999 if (is_POSIXmktime_Clean()  && $Y>2999);
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      if ($@ ne ""){
         $self->LastMsg(ERROR,"ilegal expression '%s'",
                                         $orgval);
         return(undef);
      }
      
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($Y,$M,$D,$h,$m,$s)=$val=~
          m/^(\d{4})-(\d+)-(\d+)T(\d+):(\d+):(\d+)/){
      $val=~s/^(\d{4})-(\d+)-(\d+)T(\d+):(\d+):(\d+)//;
      $srctimezone="GMT";
      $Y=1971 if ($Y<1971);
      $Y=2037 if (!is_POSIXmktime_Clean() && $Y>2037);
      $Y=2999 if (is_POSIXmktime_Clean()  && $Y>2999);
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      if ($@ ne ""){
         $self->LastMsg(ERROR,"ilegal expression '%s'",
                                         $orgval);
         return(undef);
      }
      
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($D,$M,$Y,$h,$m,$s)=$val=~
          m/^(\d+)\.(\d+)\.(\d+)\s+(\d+):(\d+):(\d+)/){
      $val=~s/^(\d+)\.(\d+)\.(\d+)\s+(\d+):(\d+):(\d+)//;
      $Y+=2000 if ($Y<50);
      $Y+=1900 if ($Y>=50 && $Y<=99);
      $Y=1971 if ($Y<1971);
      $Y=2037 if (!is_POSIXmktime_Clean() && $Y>2037);
      $Y=2999 if (is_POSIXmktime_Clean()  && $Y>2999);
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      if ($@ ne ""){
         $self->LastMsg(ERROR,"ilegal expression '%s'",
                                         $orgval);
         return(undef);
      }
      
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($D,$M,$Y,$h,$m)=$val=~
          m/^(\d+)\.(\d+)\.(\d+)\s+(\d+):(\d+)/){
      $val=~s/^(\d+)\.(\d+)\.(\d+)\s+(\d+):(\d+)//;
      $s=0;
      $Y+=2000 if ($Y<50);
      $Y+=1900 if ($Y>=50 && $Y<=99);
      $Y=1971 if ($Y<1971);
      $Y=2037 if (!is_POSIXmktime_Clean() && $Y>2037);
      $Y=2999 if (is_POSIXmktime_Clean()  && $Y>2999);
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      if ($@ ne ""){
         $self->LastMsg(ERROR,"ilegal expression '%s'",
                                         $orgval);
         return(undef);
      }
      ($Y,$M,$D,$h,$m)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($D,$M,$Y)=$val=~m/^(\d+)\.(\d+)\.(\d+)/){
      $val=~s/^(\d+)\.(\d+)\.(\d+)//;
      $h=$param{defhour};
      $m=$param{defmin};
      $s=$param{defsec};
      $Y+=2000 if ($Y<50);
      $Y+=1900 if ($Y>=50 && $Y<=99);
      $Y=1971 if ($Y<1971);
      $Y=2037 if (!is_POSIXmktime_Clean() && $Y>2037);
      $Y=2999 if (is_POSIXmktime_Clean()  && $Y>2999);
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      if ($@ ne ""){
         msg(ERROR,$@);
         $self->LastMsg(ERROR,"ilegal time expression '%s' $Y-$M-$D $h:$m:$s",
                                         $orgval);
         return(undef);
      }
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($D,$M)=$val=~m/^(\d+)\.(\d+)\./){
      $val=~s/^(\d+)\.(\d+)\.//;
      $h=$param{defhour};
      $m=$param{defmin};
      $s=$param{defsec};
      ($Y)=Today_and_Now($dsttimezone); 
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      if ($@ ne ""){
         msg(ERROR,$@);
         $self->LastMsg(ERROR,"ilegal time expression '%s' $Y-$M-$D $h:$m:$s",
                                         $orgval);
         return(undef);
      }
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($Y,$M,$D)=$val=~m/^(\d+)-(\d+)-(\d+)/){
      $val=~s/^(\d+)-(\d+)-(\d+)//;
      $h=$param{defhour};
      $m=$param{defmin};
      $s=$param{defsec};
      $Y+=2000 if ($Y<50);
      $Y+=1900 if ($Y>=50 && $Y<=99);
      $Y=1971 if ($Y<1971);
      $Y=2037 if (!is_POSIXmktime_Clean() && $Y>2037);
      $Y=2999 if (is_POSIXmktime_Clean()  && $Y>2999);
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      if ($@ ne ""){
         msg(ERROR,$@);
         $self->LastMsg(ERROR,"ilegal time expression '%s' $Y-$M-$D $h:$m:$s",
                                         $orgval);
         return(undef);
      }
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($h,$m,$s)=$val=~m/^(\d+):(\d+):(\d+)/){
      $val=~s/^(\d+):(\d+):(\d+)//;
      ($Y,$M,$D,undef,undef,undef)=Today_and_Now($srctimezone);
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      return(undef) if ($@ ne "");
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($h,$m)=$val=~m/^(\d+):(\d+)/){
      $val=~s/^(\d+):(\d+)//;
      ($Y,$M,$D,undef,undef,$s)=Today_and_Now($srctimezone);
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      return(undef) if ($@ ne "");
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }


   while($found && !$fail){
      my $n;
      $found=0;
      if (($n)=$val=~m/^([\+-]\d+)h/){
         $val=~s/^([\+-]\d+)h//;
         ($Y,$M,$D,$h,$m,$s)=Add_Delta_YMDHMS($dsttimezone,
                                              $Y,$M,$D,$h,$m,$s,0,0,0,$n,0,0);
         $found=1;
      }
      elsif (($n)=$val=~m/^([\+-]\d+)M/){
         $val=~s/^([\+-]\d+)M//;
         ($Y,$M,$D)=Add_Delta_YM($dsttimezone,$Y,$M,$D,0,$n);
         $found=1;
      }
      elsif (($n)=$val=~m/^([\+-]\d+)Y/){
         $val=~s/^([\+-]\d+)Y//;
         ($Y,$M,$D)=Add_Delta_YM($dsttimezone,$Y,$M,$D,$n,0);
         $found=1;
      }
      elsif (($n)=$val=~m/^([\+-]\d+)m/){   # for months
         $val=~s/^([\+-]\d+)m//;
         ($Y,$M,$D,$h,$m,$s)=Add_Delta_YMDHMS($dsttimezone,
                                              $Y,$M,$D,$h,$m,$s,0,0,0,0,$n,0);
         $found=1;
      }
      elsif (($n)=$val=~m/^([\+-]\d+)w/){    # for weeks
         $val=~s/^([\+-]\d+)w//;
         ($Y,$M,$D,$h,$m,$s)=Add_Delta_YMDHMS($dsttimezone,
                                              $Y,$M,$D,$h,$m,$s,0,0,7*$n,0,0,0);
         $found=1;
      }
      elsif (($n)=$val=~m/^([\+-]\d+)d/){    # for days
         $val=~s/^([\+-]\d+)d//;
         ($Y,$M,$D,$h,$m,$s)=Add_Delta_YMDHMS($dsttimezone,
                                              $Y,$M,$D,$h,$m,$s,0,0,$n,0,0,0);
         $found=1;
      }
      elsif (($n)=$val=~m/^([\+-]\d+)s/){
         $val=~s/^([\+-]\d+)s//;
         ($Y,$M,$D,$h,$m,$s)=Add_Delta_YMDHMS($dsttimezone,
                                              $Y,$M,$D,$h,$m,$s,0,0,0,0,0,$n);
         $found=1;
      }
      elsif ($val=~m/^\s*$/){
         $val=~s/^\s*$//;
         $found=1;
         last;
      }
      else{
         $fail=1;
      }
   }
   if ($fail || $val ne "" || $found==0){
      if ($orgval ne ""){
         $self->LastMsg(ERROR,"can't interpret time expression '%s'",
                                            $orgval);
      }
      return(undef);
   }
   if (wantarray()){
      return($Y,$M,$D,$h,$m,$s);
   }
   return(Date_to_String($format,$Y,$M,$D,$h,$m,$s,$dsttimezone));
}


sub LoadSubObjs
{
   my $self=shift;
   my $extender=shift;
   my $hashkey=shift;
   $hashkey="SubDataObj" if (!defined($hashkey));
   if (!defined($self->{$hashkey})){
      my $instdir=$self->Config->Param("INSTDIR");
      my @path=($instdir);
      my @pat;
      my $modpath=$self->Config->Param("MODPATH");
      if ($modpath ne ""){
         foreach my $path (split(/:/,$modpath)){
            my $qpath=quotemeta($path);
            unshift(@path,$path) if (!grep(/^$qpath$/,@path));
         }
      }
      my @sublist;
      my @disabled;

      foreach my $path (@path,@{$W5V2::INSTPATH}){
         my $pat="$path/mod/*/$extender/*.pm";
         if ($extender=~m/\//){
            $pat="$path/mod/*/$extender.pm";
         }
         unshift(@sublist,glob($pat)); 
         unshift(@disabled,glob($pat.".DISABLED")); 
      }
      @sublist=map({ $_=~s/^\/.*\/mod\///; 
                     $_;
                   } @sublist);

      @disabled=map({
                    $_=~s/^\/.*\/mod\///; 
                    $_=~s/\.DISABLED//; 
                    $_."/" if (!($_=~m/\.pm$/));
                    $_;
                   } @disabled);

      foreach my $dis (@disabled){
         @sublist=grep(!/^$dis/,@sublist);
      }
    
      @sublist=map({$_=~s/\.pm$//;
                    $_=~s/\//::/g;
                    $_;
                   } @sublist);
      my $p;
      $p=$self->getParent->Self if (defined($self->getParent()));
      foreach my $modname (@sublist){
         my $o=$self->ModuleObject($modname);
         if (defined($o)){
            if (!$o->can("setParent")){
               msg(ERROR,"cant call setParent on $o");
            }
            $o->setParent($self);
            $self->{$hashkey}->{$modname}=$o;
            if ($o->can("Init")){
               if (!$o->Init()){
                  delete($self->{$hashkey}->{$modname});
                  $self->{"Inactiv".$hashkey}->{$modname}=$modname;
               }
            }
         }
         else{
            msg(ERROR,"can't load $hashkey '%s' in '%s'",$modname,$self);
            printf STDERR ("%s\n",$@);
         }
      }
      my $inactiv="";
      my $activ="";
      if (keys(%{$self->{$hashkey}})){
         $activ=sprintf(" activ=%s",join(", ",keys(%{$self->{$hashkey}}))); 
      }
      if (keys(%{$self->{"Inactiv".$hashkey}})){
         $activ=sprintf(" inactiv=%s",
                        join(", ",keys(%{$self->{"Inactiv".$hashkey}}))); 
      }
      if ($activ ne "" || $inactiv ne ""){
         #msg(INFO,"LoadSubObjs($self - $hashkey): $activ$inactiv");
      }
   }
   return(keys(%{$self->{$hashkey}}));
}


sub LoadSubObjsOnDemand
{
   my $self=shift;
   my $extender=shift;
   my $hashkey=shift;
   $hashkey="SubDataObj" if (!defined($hashkey));
   if (!defined($self->{$hashkey})){
      my $instdir=$self->Config->Param("INSTDIR");
      my @path=($instdir);
      my @pat;
      my $modpath=$self->Config->Param("MODPATH");
      if ($modpath ne ""){
         foreach my $path (split(/:/,$modpath)){
            my $qpath=quotemeta($path);
            unshift(@path,$path) if (!grep(/^$qpath$/,@path));
         }
      }
      my @sublist;
      my @disabled;

      foreach my $path (@path){
         my $pat="$path/mod/*/$extender/*.pm";
         if ($extender=~m/\//){
            $pat="$path/mod/*/$extender.pm";
         }
         unshift(@sublist,glob($pat)); 
         unshift(@disabled,glob($pat.".DISABLED")); 
      }

      @sublist=map({my $qi=quotemeta($instdir);
                    $_=~s/^$qi//;
                    $_=~s/\/mod\///; 
                    $_;
                   } @sublist);

      @disabled=map({my $qi=quotemeta($instdir);
                    $_=~s/^$qi//;
                    $_=~s/\/mod\///; 
                    $_=~s/\.DISABLED//; 
                    $_."/" if (!($_=~m/\.pm$/));
                    $_;
                   } @disabled);

      foreach my $dis (@disabled){
         @sublist=grep(!/^$dis/,@sublist);
      }
    
      @sublist=map({$_=~s/\.pm$//;
                    $_=~s/\//::/g;
                    $_;
                   } @sublist);
      my $p;
      $p=$self->getParent->Self if (defined($self->getParent()));
      foreach my $modname (@sublist){
          my $o;
          tie($o,'SubModulHandler',$modname,$self);
          $self->{$hashkey}->{$modname}=$o;
      }
   }
   return(keys(%{$self->{$hashkey}}));
}




package SubModulHandler;
require Tie::Scalar;
use strict;
use vars qw(@ISA);

@ISA = qw(Tie::Scalar);

sub TIESCALAR
{
   my $type=shift;
   my $name=shift;
   my $parent=shift;
   my $self=bless({parent=>$parent,name=>$name},$type);
   return($self);
}



sub FETCH
{
   my $self=shift;
   if (!exists($self->{obj})){
      $self->{obj}=$self->{parent}->ModuleObject($self->{name});
      return(undef) if (!defined($self->{obj}));
      if (defined($self->{obj})){
         if ($self->{obj}->can("setParent")){
            $self->{obj}->setParent($self->{parent});
         }
         if ($self->{obj}->can("Init")){
            if (!$self->{obj}->Init()){
               $self->{obj}=undef;
            }
         }
      }
   }
   return($self->{obj});
}










######################################################################
1;
