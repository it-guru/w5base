package caiman::qrule::RefreshOrgInfos;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Refreshes some Informations from CAIMAN.

=head3 IMPORTS

Description

=cut
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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
use caiman::ext::orgareaImport;
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
   return(["base::grp"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};


   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   my $sisnumber;

   my $par=getModuleObject($self->getParent->Config(),"caiman::orgarea");
   return(undef,undef) if ($par->isSuspended());
   if (!$par->Ping()){
      msg(INFO,"Ping failed to $par");
      return(undef,undef);
   }

   # per default the parent sisnumber is inherit
   if ($rec->{parentid} ne ""){
      my $po=$dataobj->Clone();
      $po->SetFilter({grpid=>\$rec->{parentid},cistatusid=>\'4'});
      my ($prec,$msg)=$po->getOnlyFirst(qw(name sisnumber));
      if (defined($prec)){
         $sisnumber=$prec->{sisnumber};
      }
   }

   if ($rec->{srcsys} eq "CIAM" && $rec->{cistatusid} eq "4"){
      # do an orgstructure transfer from WhoIsWho to CAIMAN
      if ($rec->{ext_refid1} ne "" && 
          (my ($sapid)=$rec->{ext_refid1}=~m/^SAP:(\d+)$/)){
         # transfer is posible
         my $o=getModuleObject($self->getParent->Config(),"caiman::orgarea");
         $o->SetFilter({sapid=>"*$sapid"});
         my @l=$o->getHashList(qw(torgoid sapid));
         if ($#l>0 && $rec->{srcid} ne ""){
            # try to add tOuSD to find a unique caiman tOuCID
            msg(INFO,"try to find unique caiman org by adding tOuSD/toumgr");
            my $ciam=getModuleObject($self->getParent->Config(),
                                    "tsciam::orgarea");
            $ciam->SetFilter({toucid=>\$rec->{srcid}});
            my ($ciamrec,$msg)=$ciam->getOnlyFirst(qw(shortname toumgr));
            if (defined($ciamrec) && $ciamrec->{toumgr} ne ""){
               $o->ResetFilter();
               $o->SetFilter({sapid=>"*$sapid",
                              toumgr=>\$ciamrec->{toumgr}});
               my @l2=$o->getHashList(qw(torgoid sapid));
               if ($#l2==0){
                  msg(INFO,"found unique caiman rec by add toumgr");
                  @l=@l2;
               }
            }
            if ($#l!=0 && defined($ciamrec) && $ciamrec->{shortname} ne ""){
               $o->ResetFilter();
               $o->SetFilter({sapid=>"*$sapid",
                              shortname=>\$ciamrec->{shortname}});
               my @l2=$o->getHashList(qw(torgoid sapid));
               if ($#l2==0){
                  msg(INFO,"found unique caiman rec by add shortname");
                  @l=@l2;
               }
            }
         }
         if ($#l==0){
            my $caimanrec=$l[0];
            $forcedupd->{srcsys}='CAIMAN';
            $forcedupd->{srcid}=$caimanrec->{torgoid};
            $forcedupd->{ext_refid2}="CIAM:$rec->{srcid}";
         }
         elsif($#l>0){
            msg(ERROR,"sapid '*$sapid' not unique in CAIMAN");
         }
         else{
            msg(ERROR,"fail to find CAIMAN Org for $rec->{fullname} ".
                      "based on sapid '*$sapid'");
         }
      }
   }
   elsif ($rec->{srcsys} eq "CAIMAN"){
      # CAIMAN Org-Structure Updates
      my ($caimanrec,$msg);
      my $o=getModuleObject($self->getParent->Config(),"caiman::orgarea");
      $o->SetFilter({torgoid=>\$rec->{srcid}});
      ($caimanrec,$msg)=$o->getOnlyFirst(qw(name shortname sapid toumgr
                                          urlofcurrentrec));
      my $ext_refid1;
      if (defined($caimanrec)){
         my $is_org=0;
         my $hasOrgRecord=0;    # Fuer INT Einheiten exisitert nicht immer
                                # ein caiman::organisation Eintrag bzw. 
                                # ist einfach die toLD nicht die gleiche, wie
                                # die tOuLD - da muss dann der Leiter für die
                                # Berechnung herhalten.
         if ($caimanrec->{name} ne "" && $caimanrec->{shortname} ne ""){
            my $p=getModuleObject($self->getParent->Config(),
                  "caiman::organisation");

            # Das wäre eigentlich der korrekte Filter ...
            #$p->SetFilter({
            #    abbreviation=>\$caimanrec->{shortname},
            #    name=>\$caimanrec->{name}
            #});
            # ... aber bei MSS Drehsten passt die Abkürzung in den OrgUnits
            # nicht zur Abkürzung in der Organisation
            $p->SetFilter({
                name=>\$caimanrec->{name}
            });

            my ($orgrec,$msg)=$p->getOnlyFirst(qw(ALL));
            if (defined($orgrec)){
               $hasOrgRecord=1;
               $is_org=1;
               my $refid2;
               if ($orgrec->{torgoid} ne ""){
                  $refid2="tOrgOID:".$orgrec->{torgoid};
               }
               if ($rec->{sisnumber} ne $orgrec->{sisnumber}){
                  $forcedupd->{sisnumber}=$orgrec->{sisnumber};
               }
               if ($rec->{ext_refid2} ne $refid2){
                  $forcedupd->{ext_refid2}=$refid2;
               }
            }
         }
         if (($caimanrec->{name}=~m/\sGmbH$/i) ||   # name of caiman record
             ($caimanrec->{name}=~m/\sAG$/)){       # indicates an organisation
            $is_org=1;
         }
         # Problem: Rentnerservice TD GmbH ist namentlich eine eigene
         #          Firma. Laut caiman::organisation aber nicht. Sie befindet
         #          sich im Org-Baum unterhalb von DTIT - der Leiter hat
         #          aber eine Gesselschaftsnummer der "Deutsche Telekom AG"
         #          -> alles sehr verworren

         if (!$hasOrgRecord){
                   # Konzept funktioniert nicht, wenn der Leiter etwas 
                   # komisarisch leitet - also aus einer Firma kommt, bei der
                   # er nicht direkt arbeitet.
            if ($caimanrec->{toumgr} ne ""){
               my $p=getModuleObject($self->getParent->Config(),"caiman::user");
               $p->SetFilter({tcid=>$caimanrec->{toumgr}});
               my ($mgrrec,$msg)=$p->getOnlyFirst(qw(ALL));
               if (defined($mgrrec)){
                  if ($mgrrec->{office_sisnumber} ne ""){
                     $sisnumber=$mgrrec->{office_sisnumber};

                     my $po=getModuleObject($self->getParent->Config(),
                           "caiman::organisation");
                     $po->SetFilter({
                         sisnumber=>\$sisnumber
                     });
                     my ($orgrec,$msg)=$po->getOnlyFirst(qw(ALL));
                     if (defined($orgrec)){
                        my $refid2;
                        if ($orgrec->{tocid} ne ""){
                           $refid2="tOrgOID:".$orgrec->{torgoid};
                        }
                        if ($rec->{ext_refid2} ne $refid2){
                           $forcedupd->{ext_refid2}=$refid2;
                        }
                     }
                  }
               }
            }
         }

         if ($is_org){
            if (!$rec->{is_org}){
               $forcedupd->{is_org}=1;
            }
            if ($rec->{is_orggroup}){
               $forcedupd->{is_orggroup}=0;
            }
         }
         else{
            if ($rec->{is_org}){
               $forcedupd->{is_org}=0;
            }
            if (!$rec->{is_orggroup}){
               $forcedupd->{is_orggroup}=1;
            }
         }

         if ($caimanrec->{name} ne $rec->{description}){
            $forcedupd->{description}=$caimanrec->{name};
         }
         $ext_refid1='SAP:'.$caimanrec->{sapid} if ($caimanrec->{sapid} ne "");
      }
      if ($rec->{ext_refid1} ne $ext_refid1){
         $forcedupd->{ext_refid1}=$ext_refid1;
      }
      if (defined($caimanrec)){  # rename check
         my $rawoldtousd;
         my $oldtousd;
         my $curtousd;
         if (exists($rec->{additional}->{tOuSD}) &&
             ref($rec->{additional}->{tOuSD}) eq "ARRAY"){
            $rawoldtousd=$rec->{additional}->{tOuSD}->[0];
  #          $oldtousd=caiman::ext::orgareaImport::preFixShortname(
  #                       $caimanrec->{toucid},$rawoldtousd);
         }
         $curtousd=caiman::ext::orgareaImport::preFixShortname(
            $caimanrec->{torgoid},
            $caimanrec->{shortname}
         );
         my $curfinename=$curtousd;
         my $localrenamed=0;
         if (defined($oldtousd) && 
             $rec->{name} ne $oldtousd &&
             $rec->{name} ne "tOuSD" &&   # invalid local name
             $rec->{name} ne ""){         # invalid local name
            $localrenamed=1;
         }
         #printf STDERR ("DEBUG: localname=$rec->{name}\n");
         #printf STDERR ("DEBUG: localrenamed=$localrenamed\n");
         #printf STDERR ("DEBUG: curtousd=$curtousd\n");
         #printf STDERR ("DEBUG: oldtousd=$oldtousd\n");

         if (!$localrenamed && $curtousd ne $rec->{name}){
            my $oldname=$rec->{fullname};
            my $basemsg="Try rename of Org '$oldname' needed - ".
                        "based on CAIMAN new tOuSD '$curtousd'";
            $dataobj->Log(WARN,"basedata",$basemsg);

            ##################################################################
            # the new name for current group can be already be in use on 
            # the same org-level, so we need to rename the already existing
            # in an oldxx to get free space for the new name.
            $dataobj->ResetFilter();
            $dataobj->SetFilter({
               parentid=>\$rec->{parentid},
               name=>\$curtousd,
               grpid=>"!".$rec->{grpid}
            });
            my ($chkrec,$msg)=$dataobj->getOnlyFirst(qw(ALL));
            if (defined($chkrec)){ # rename will not work, because new exists
               my $basemsg="New name='$curtousd' already in use by ".
                           "$chkrec->{fullname} (grpid:$chkrec->{grpid})";
               $dataobj->Log(WARN,"basedata",$basemsg);
               FINDFREE: for(my $c=1;$c<99;$c++){  # try find free oldname
                  my $oldname=$chkrec->{name};
                  if (length($oldname)>14){
                     $oldname=substr($oldname,0,14);
                  }
                  $oldname.=sprintf("-old%02d",$c);
                  $dataobj->ResetFilter();
                  $dataobj->SetFilter({
                     parentid=>\$rec->{parentid},
                     name=>\$oldname
                  });
                  my ($chk2rec,$msg)=$dataobj->getOnlyFirst(qw(grpid));
                  if (!defined($chk2rec)){ # OK Name ist frei
                     if ($dataobj->ValidatedUpdateRecord($chkrec,{
                           name=>$oldname},{grpid=>\$chkrec->{grpid}})){
                        my $basemsg="Rename '$chkrec->{fullname}' to ".
                                    "name='$oldname' done - now ".
                                    "new $curtousd is useable";
                        $dataobj->Log(WARN,"basedata",$basemsg);
                        last FINDFREE;
                     }
                  }
               }
            }
            ##################################################################
            if ($dataobj->ValidatedUpdateRecord($rec,{name=>$curtousd},
                                                {grpid=>\$rec->{grpid}})){
               push(@qmsg,"all desired fields has been updated: name");
               my $basemsg="Rename of Org '$oldname' to name='$curtousd' ".
                           "done\n--";
               $dataobj->Log(WARN,"basedata",$basemsg);
            }
            else{
               push(@qmsg,$basemsg);
               push(@qmsg,$self->getParent->LastMsg());
               $errorlevel=3 if ($errorlevel<3);
               return($errorlevel,{qmsg=>\@qmsg,dataissue=>\@qmsg});
            }
         }
      }
      if (defined($caimanrec)){
         my @i;
         #######################################################
         push(@i,["CAIMAN tOrgOID:",$caimanrec->{torgoid}]);
         push(@i,["CAIMAN tOuSD:",trim($caimanrec->{shortname})]);
         push(@i,["CAIMAN : ",$caimanrec->{urlofcurrentrec}]);
         #######################################################
         my $c=$rec->{comments};
         $c=~s/(^|\n).*?WhoIsWho.*?(\n|$)//gs;  # remove posible WhoIsWho Infos
         $c=~s/(^|\n).*?CIAM.*?(\n|$)//gs;  # remove posible WhoIsWho Infos
         $c=~s/^(.+)CAIMAN tOuSD:.*$/$1/gm;

         foreach my $irec (@i){ 
            my $infopref=$irec->[0];
            my $infoline=join(" ",$irec->[0],$irec->[1]);
            my $qinfoline=quotemeta($infoline);
            if (!($c=~m/(^|\n)$qinfoline(\n|$)/s)){
               if (($c=~m/$infopref/)){
                  $c=~s/(^|\n)$infopref.*?(\n|$)//gs;
               }
               if ($c ne "" && !($c=~m/\n$/s)){
                  $c.="\n";
               }
               $c.=$infoline;
            }
         }
         #######################################################
         if (trim($c) ne trim($rec->{comments})){
            $forcedupd->{comments}=$c;
            $checksession->{EssentialsChangedCnt}++;
         }
      }
      if (defined($caimanrec)){
         my %newadditional=%{$rec->{additional}};
         my $changed=0;
         if (exists($newadditional{alternateGroupnameHR})){
            $changed++;
            delete($newadditional{alternateGroupnameHR});
         }
         if (!exists($newadditional{tOuSD}) ||
              ref($newadditional{tOuSD}) ne "ARRAY" ||
              $newadditional{tOuSD}->[0] ne $caimanrec->{shortname}){
            $changed++;
            $newadditional{tOuSD}=$caimanrec->{shortname};
            if (!defined($newadditional{tOuSD})){
               $newadditional{tOuSD}="";
            }
         }
         if ($changed){
            $forcedupd->{additional}=\%newadditional;
         }
      }

      #printf STDERR ("store last known tOuSD\n");
      #printf STDERR ("d=%s\n",Dumper($rec));
   }

   my @result=$self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);


  # if ($sisnumber ne $rec->{sisnumber}){
  #    $forcedupd->{sisnumber}=$sisnumber;
  # }
#
#   if (keys(%$forcedupd)){
#      if ($dataobj->ValidatedUpdateRecord($rec,$forcedupd,
#                                          {grpid=>\$rec->{grpid}})){
#         push(@qmsg,"all desired fields has been updated: ".
#                    join(", ",keys(%$forcedupd)));
#      }
#      else{
#         push(@qmsg,$self->getParent->LastMsg());
#         $errorlevel=3 if ($errorlevel<3);
#      }
#   }
#   return($errorlevel,{qmsg=>\@qmsg});
}



1;
