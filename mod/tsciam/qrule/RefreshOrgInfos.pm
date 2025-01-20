package tsciam::qrule::RefreshOrgInfos;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Refreshes some Informations from CIAM.

=head3 IMPORTS

Description

=cut
#  W5Base Framework
#  Copyright (C) 2007  Hartmut Vogler (it@guru.de)
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
use tsciam::ext::orgareaImport;
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

   my $errorlevel=undef;
   my @qmsg;

   my $forcedupd={};
   $errorlevel=0;
   my $sisnumber;

   # per default the parent sisnumber is inherit
   if ($rec->{parentid} ne ""){
      my $po=$dataobj->Clone();
      $po->SetFilter({grpid=>\$rec->{parentid},cistatusid=>\'4'});
      my ($prec,$msg)=$po->getOnlyFirst(qw(name sisnumber));
      if (defined($prec)){
         $sisnumber=$prec->{sisnumber};
      }
   }

   if ($rec->{srcsys} eq "WhoIsWho" && $rec->{cistatusid} eq "4"){
      # do an orgstructure transfer from WhoIsWho to CIAM
      if ($rec->{ext_refid1} ne "" && 
          (my ($sapid)=$rec->{ext_refid1}=~m/^SAP:(\d+)$/)){
         # transfer is posible
         my $o=getModuleObject($self->getParent->Config(),"tsciam::orgarea");
         $o->SetFilter({sapid=>\$sapid});
         my @l=$o->getHashList(qw(toucid));
         if ($#l>0 && $rec->{srcid} ne ""){
            # try to add tOuSD to find a unique ciam tOuCID
            msg(INFO,"try to find unique ciam org by adding tOuSD");
            my $wiw=getModuleObject($self->getParent->Config(),
                                    "tswiw::orgarea");
            $wiw->SetFilter({touid=>\$rec->{srcid}});
            my ($wiwrec,$msg)=$wiw->getOnlyFirst(qw(shortname));
            if (defined($wiwrec) && $wiwrec->{shortname} ne ""){
               msg(INFO,"now search with tOuSD $wiwrec->{shortname}");
               $o->ResetFilter();
               $o->SetFilter({sapid=>\$sapid,shortname=>\$wiwrec->{shortname}});
               my @l2=$o->getHashList(qw(toucid));
               if ($#l2==0){
                  @l=@l2;
               }
            }
         }
         if ($#l==0){
            my $ciamrec=$l[0];
            $forcedupd->{srcsys}='CIAM';
            $forcedupd->{srcid}=$ciamrec->{toucid};
            $forcedupd->{ext_refid2}="WhoIsWho:$rec->{srcid}";
         }
         elsif($#l>0){
            msg(ERROR,"sapid '$sapid' not unique in CIAM");
         }
         else{
            msg(ERROR,"fail to find CIAM Org for $rec->{name} ".
                      "based on sapid '$sapid'");
         }
      }
   }
   elsif ($rec->{srcsys} eq "CIAM"){
      # CIAM Org-Structure Updates
      my ($ciamrec,$msg);
      my $o=getModuleObject($self->getParent->Config(),"tsciam::orgarea");
      $o->SetFilter({toucid=>\$rec->{srcid}});
      ($ciamrec,$msg)=$o->getOnlyFirst(qw(name shortname sapid toumgr
                                          urlofcurrentrec));
      my $ext_refid1;
      if (defined($ciamrec)){
         my $is_org=0;
         my $hasOrgRecord=0;    # Fuer INT Einheiten exisitert nicht immer
                                # ein tsciam::organisation Eintrag bzw. 
                                # ist einfach die toLD nicht die gleiche, wie
                                # die tOuLD - da muss dann der Leiter für die
                                # Berechnung herhalten.
         if ($ciamrec->{name} ne "" && $ciamrec->{shortname} ne ""){
            my $p=getModuleObject($self->getParent->Config(),
                  "tsciam::organisation");

            # Das wäre eigentlich der korrekte Filter ...
            #$p->SetFilter({
            #    abbreviation=>\$ciamrec->{shortname},
            #    name=>\$ciamrec->{name}
            #});
            # ... aber bei MSS Drehsten passt die Abkürzung in den OrgUnits
            # nicht zur Abkürzung in der Organisation
            $p->SetFilter({
                name=>\$ciamrec->{name}
            });

            my ($orgrec,$msg)=$p->getOnlyFirst(qw(ALL));
            if (defined($orgrec)){
               $hasOrgRecord=1;
               $is_org=1;
               my $refid2;
               if ($orgrec->{tocid} ne ""){
                  $refid2="toCID:".$orgrec->{tocid};
               }
               if ($orgrec->{sisnumber} ne ""){
                  $sisnumber=$orgrec->{sisnumber};
               }
               if ($rec->{ext_refid2} ne $refid2){
                  $forcedupd->{ext_refid2}=$refid2;
               }
            }
         }
         if (($ciamrec->{name}=~m/\sGmbH$/i) ||   # name of ciam record
             ($ciamrec->{name}=~m/\sAG$/)){       # indicates an organisation
            $is_org=1;
         }
         # Problem: Rentnerservice TD GmbH ist namentlich eine eigene
         #          Firma. Laut tsciam::organisation aber nicht. Sie befindet
         #          sich im Org-Baum unterhalb von DTIT - der Leiter hat
         #          aber eine Gesselschaftsnummer der "Deutsche Telekom AG"
         #          -> alles sehr verworren

         if (!$hasOrgRecord){
                   # Konzept funktioniert nicht, wenn der Leiter etwas 
                   # komisarisch leitet - also aus einer Firma kommt, bei der
                   # er nicht direkt arbeitet.
            if ($ciamrec->{toumgr} ne ""){
               my $p=getModuleObject($self->getParent->Config(),"tsciam::user");
               $p->SetFilter({tcid=>$ciamrec->{toumgr}});
               my ($mgrrec,$msg)=$p->getOnlyFirst(qw(ALL));
               if (defined($mgrrec)){
                  if ($mgrrec->{office_sisnumber} ne ""){
                     $sisnumber=$mgrrec->{office_sisnumber};

                     my $po=getModuleObject($self->getParent->Config(),
                           "tsciam::organisation");
                     $po->SetFilter({
                         sisnumber=>\$sisnumber
                     });
                     my ($orgrec,$msg)=$po->getOnlyFirst(qw(ALL));
                     if (defined($orgrec)){
                        my $refid2;
                        if ($orgrec->{tocid} ne ""){
                           $refid2="toCID:".$orgrec->{tocid};
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

         if ($ciamrec->{name} ne $rec->{description}){
            $forcedupd->{description}=$ciamrec->{name};
         }
         $ext_refid1='SAP:'.$ciamrec->{sapid} if ($ciamrec->{sapid} ne "");
      }
      if ($rec->{ext_refid1} ne $ext_refid1){
         $forcedupd->{ext_refid1}=$ext_refid1;
      }
      if (defined($ciamrec)){  # rename check
         my $rawoldtousd;
         my $oldtousd;
         my $curtousd;
         if (exists($rec->{additional}->{tOuSD}) &&
             ref($rec->{additional}->{tOuSD}) eq "ARRAY"){
            $rawoldtousd=$rec->{additional}->{tOuSD}->[0];
            $oldtousd=tsciam::ext::orgareaImport::preFixShortname(
                         $ciamrec->{toucid},$rawoldtousd);
         }
         $curtousd=tsciam::ext::orgareaImport::preFixShortname(
            $ciamrec->{toucid},
            $ciamrec->{shortname}
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
                        "based on CIAM new tOuSD '$curtousd'";
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
      if (defined($ciamrec)){
         my @i;
         #######################################################
         push(@i,["CIAM tOuCID:",$ciamrec->{toucid}]);
         push(@i,["CIAM tOuSD:",trim($ciamrec->{shortname})]);
         push(@i,["CIAM : ",$ciamrec->{urlofcurrentrec}]);
         #######################################################
         my $c=$rec->{comments};
         $c=~s/(^|\n).*?WhoIsWho.*?(\n|$)//gs;  # remove posible WhoIsWho Infos
         $c=~s/^(.+)CIAM tOuSD:.*$/$1/gm;

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
      if (defined($ciamrec)){
         my %newadditional=%{$rec->{additional}};
         my $changed=0;
         if (exists($newadditional{alternateGroupnameHR})){
            $changed++;
            delete($newadditional{alternateGroupnameHR});
         }
         if (!exists($newadditional{tOuSD}) ||
              ref($newadditional{tOuSD}) ne "ARRAY" ||
              $newadditional{tOuSD}->[0] ne $ciamrec->{shortname}){
            $changed++;
            $newadditional{tOuSD}=$ciamrec->{shortname};
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
   elsif($rec->{fullname} eq "DTAG.TSI"){  # Migration von DTAG.TSI in CIAM
      $forcedupd->{srcsys}="CIAM";     
      $forcedupd->{srcid}="15131753";
   }


   if ($rec->{srcsys} ne "CAIMAN"){
      if ($sisnumber ne $rec->{sisnumber}){
         $forcedupd->{sisnumber}=$sisnumber;
      }
   }

   if (keys(%$forcedupd)){
      if ($dataobj->ValidatedUpdateRecord($rec,$forcedupd,
                                          {grpid=>\$rec->{grpid}})){
         push(@qmsg,"all desired fields has been updated: ".
                    join(", ",keys(%$forcedupd)));
      }
      else{
         push(@qmsg,$self->getParent->LastMsg());
         $errorlevel=3 if ($errorlevel<3);
      }
   }
   return($errorlevel,{qmsg=>\@qmsg});
}



1;
