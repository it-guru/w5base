package tsciam::qrule::RefreshOrgInfos;
#######################################################################
=pod

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
   my $errorlevel=undef;
   my @qmsg;

   my $forcedupd={};
   $errorlevel=0;
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
      ($ciamrec,$msg)=$o->getOnlyFirst(qw(name shortname sapid
                                          urlofcurrentrec));
      my $ext_refid1;
      if (defined($ciamrec)){
         if ($ciamrec->{name} ne $rec->{description}){
            $forcedupd->{description}=$ciamrec->{name};
         }
         $ext_refid1='SAP:'.$ciamrec->{sapid} if ($ciamrec->{sapid} ne "");
      }
      if ($rec->{ext_refid1} ne $ext_refid1){
         $forcedupd->{ext_refid1}=$ext_refid1;
      }
      {
         my @i;
         #######################################################
         push(@i,["CIAM tOuCID:",$ciamrec->{toucid}]);
         push(@i,["CIAM tOuSD: ",$ciamrec->{shortname}]);
         push(@i,["CIAM : ",$ciamrec->{urlofcurrentrec}]);
         #######################################################
         my $c=$rec->{comments};
         $c=~s/(^|\n).*?WhoIsWho.*?(\n|$)//gs;  # remove posible WhoIsWho Infos

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
         }
      }
   }
   elsif($rec->{fullname} eq "DTAG.TSI"){  # Migration von DTAG.TSI in CIAM
      $forcedupd->{srcsys}="CIAM";     
      $forcedupd->{srcid}="15131753";
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
