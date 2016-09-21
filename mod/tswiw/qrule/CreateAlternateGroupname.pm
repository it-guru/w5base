package tswiw::qrule::CreateAlternateGroupname;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Create a alternate groupname and store it in additional container.

=head3 IMPORTS

Description

=cut
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
   my $errorlevel=0;
   my @qmsg;

   my $forcedupd={};
   my %a=%{$rec->{additional}};
   my $add=$rec->{additional};
   my $alternateGroupnameHR=$add->{alternateGroupnameHR}->[0];
   my $alternateGroupname=$add->{alternateGroupname}->[0];
   if ($alternateGroupnameHR ne "" || $alternateGroupname ne ""){
      delete($add->{alternateGroupnameHR});
      delete($add->{alternateGroupname});
      $forcedupd->{additional}=\%a;
   }




#   my $tOuSD=$add->{tOuSD}->[0];
#   if ($rec->{srcsys} eq "WhoIsWho" && $rec->{srcid} ne ""){
#      $errorlevel=0;
#      my $wiw=getModuleObject($self->getParent->Config(),"tswiw::orgarea");
#      $wiw->SetFilter({touid=>\$rec->{srcid}});
#      my ($wiwrec,$msg)=$wiw->getOnlyFirst(qw(name shortname));
#      if (defined($wiwrec)){
#         if ($wiwrec->{shortname} ne $tOuSD){
#            $forcedupd->{additional}=\%a if (!exists($forcedupd->{additional}));
#            $forcedupd->{additional}->{tOuSD}=$wiwrec->{shortname};
#            $tOuSD=$wiwrec->{shortname};
#         }
#      }
#   }
#   else{
#      if ($rec->{additional}->{tOuSD}->[0] ne ""){
#         $forcedupd->{additional}=\%a if (!exists($forcedupd->{additional}));
#         $forcedupd->{additional}->{tOuSD}=undef;
#         $tOuSD=undef;
#      }
#   }
#   my $fullname=$rec->{fullname};
#   my $subteamgroup=""; 
#   my $country="INT";
#
#   if (defined($tOuSD)){
#      $country=substr($rec->{srcid},0,2);
#   }
#   else{
#      # find correct tOuSD and subteamgroup
#      my $o=$dataobj->Clone();
#      my $oprec=$rec;
#      while(defined($oprec) && $oprec->{parentid} ne ""){
#         $o->SetFilter({grpid=>$oprec->{parentid}});
#         ($oprec)=$o->getOnlyFirst(qw(fullname additional parentid));
#         if ($oprec->{additional}->{tOuSD}->[0] ne ""){
#            $tOuSD=$oprec->{additional}->{tOuSD}->[0];
#            $subteamgroup=$rec->{fullname};
#            my $qr=quotemeta($oprec->{fullname});
#            $subteamgroup=~s/^$qr//;
#            last;
#         }
#      }
#   }
#   
#
#
#   my $prefix;
#   my $n1;
#   my %trtab=(
#      'SDM.TC' =>'DTAG.TSI.S.DTAG',
#      'CS.TC'  =>'DTAG.TSI.Prod.CS.Telco',
#      'TI.CSO' =>'DTAG.TSI.TI.E-CSO',
#      'TI.TSO' =>'DTAG.TSI.TI.E-TSO',
#      'TI.MCS' =>'DTAG.TSI.TI.E-MCS',
#      'TI.GSO' =>'DTAG.TSI.TI.E-GSO',
#      'TI.ESO' =>'DTAG.TSI.TI.E-ESO',
#      'TI.TSI' =>'DTAG.TSI.TI.E-TSI',
#      'TI.ITS' =>'DTAG.TSI.TI.E-ITS',
#      'TI.ITG' =>'DTAG.TSI.TI.E-ITG',
#      'TI.ART' =>'DTAG.TSI.TI.E-ART',
#      'PSS'    =>'DTAG.TSI.Prod.GBOP.PSS',
#      'INT.CSS'=>'DTAG.TSI.INT.SK.CSS.CSS_Applicat'
#   );
#
#
#   {  # altname creation
#      if (defined($tOuSD)){  # ok - the unit is a org unit
#        # $altname=~s/^DTAG\.TSI\.S.*$/S/i;
#        # $altname=~s/^DTAG\.TSI\.Prod\.CS\.Telco.*$/CS.TC/i;
##         $altname=~s/^DTAG\.TSI\.Prod\.GBOP\.PSS.*$/PSS/i;
#
#
#         my $shortname;
#
#         foreach my $k (keys(%trtab)){
#            my $qtr=quotemeta($trtab{$k});
#            if (my ($sn)=$rec->{fullname}=~m/^$qtr(\.(.*)){0,1}$/i){
#               $prefix=$k;
#               $shortname=$sn;
#               last;
#            }
#         }
#         if (defined($prefix)){
#            $n1=uc($prefix.".".$country.".".$tOuSD.$subteamgroup);
#            $n1=~s/\s/_/g;
#
#            if (length($n1)>30){
#               $n1=undef;
#            }
#
#            if ($n1 ne $alternateGroupnameHR){
#               if (!exists($forcedupd->{additional})){
#                  $forcedupd->{additional}=\%a;
#               }
#               $forcedupd->{additional}->{alternateGroupnameHR}=$n1;
#            }
#         }
#         else{
#            if (!exists($forcedupd->{additional})){
#               $forcedupd->{additional}=\%a;
#            }
#            delete($forcedupd->{additional}->{alternateGroupnameHR});
#         }
#      }
#   }
#print STDERR Dumper($forcedupd);
#
#   my $spocgrp;
#   if (defined($prefix) && $trtab{$prefix} ne ""){ # SPOC suchen
#      my $grp=getModuleObject($self->getParent->Config,"base::grp");
#      my $name=$trtab{$prefix}.".AGroupAdmin";
#      $grp->SetFilter({fullname=>\$name});
#      ($spocgrp)=$grp->getOnlyFirst(qw(fullname grpid));
#   }
#   my $oldWf;
#   if ($rec->{grpid} ne ""){ # bestehenden Task suchen
#      my $wf=getModuleObject($self->getParent->Config,"base::workflow");
#      $wf->SetFilter({directlnktype=>\'base::grp',
#                       directlnkid=>\$rec->{grpid},
#                       directlnkmode=>\'AGroupAdmin',
#                       class=>\'base::workflow::task',
#                       stateid=>'<20'});
#      ($oldWf)=$wf->getOnlyFirst(qw(fullname grpid));
#   }
#   #printf STDERR ("fifi spocgrp=$spocgrp\n");
#   #printf STDERR ("fifi oldWf=$oldWf\n");
#
#   if ((!defined($spocgrp) || $n1 eq "") && defined($oldWf) ){
#      # mark existing task as 25-obsolete
#   }
#
#   if (defined($spocgrp) && $n1 ne ""){
#      my $acgrpo=getModuleObject($self->getParent->Config,"tsacinv::group");
#      $acgrpo->SetFilter({srcid=>\"W5B:$rec->{grpid}"});
#      my ($acgrp)=$acgrpo->getOnlyFirst(qw(code name));
#
#      if ($acgrpo->Ping()){
#         if (defined($acgrp)){
#            if ($acgrp->{name} ne $n1){
#               # Bitte gruppe umbenennen lassen
#            }
#            else{
#            }
#         }
#         else{
#            # Bitte gruppe neu anlegen lassen
#            # mit folgenden Mitgliedern
#         }
#      }
#   }
#
#   if (1){
#      if (!defined($oldWf)){
#         # neuen Task mit Text anlegen
#      }
#      else{
#         # bestehenden Task ändern
#      }
#   }

   if (keys(%$forcedupd)){
      delete($forcedupd->{additional}->{alternateGroupname});
      delete($forcedupd->{additional}->{alternateGroupnameAM});
      delete($forcedupd->{additional}->{alternateGroupnameSC});
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
