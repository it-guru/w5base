package tswiw::qrule::CreateAlternateGroupname;
#######################################################################
=pod

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
   my $tOuSD=$add->{tOuSD}->[0];
   if ($rec->{srcsys} eq "WhoIsWho" && $rec->{srcid} ne ""){
      $errorlevel=0;
      my $wiw=getModuleObject($self->getParent->Config(),"tswiw::orgarea");
      $wiw->SetFilter({touid=>\$rec->{srcid}});
      my ($wiwrec,$msg)=$wiw->getOnlyFirst(qw(name shortname));
      if (defined($wiwrec)){
         if ($wiwrec->{shortname} ne $tOuSD){
            $forcedupd->{additional}=\%a if (!exists($forcedupd->{additional}));
            $forcedupd->{additional}->{tOuSD}=$wiwrec->{shortname};
            $tOuSD=$wiwrec->{shortname};
         }
      }
   }
   else{
      if ($rec->{additional}->{tOuSD}->[0] ne ""){
         $forcedupd->{additional}=\%a if (!exists($forcedupd->{additional}));
         $forcedupd->{additional}->{tOuSD}=undef;
         $tOuSD=undef;
      }
   }
   my $fullname=$rec->{fullname};
   my $subteamgroup=""; 
   my $country="INT";

   if (defined($tOuSD)){
      $country=substr($rec->{srcid},0,2);
   }
   else{
      # find correct tOuSD and subteamgroup
      my $o=$dataobj->Clone();
      my $oprec=$rec;
      while(defined($oprec) && $oprec->{parentid} ne ""){
         $o->SetFilter({grpid=>$oprec->{parentid}});
         ($oprec)=$o->getOnlyFirst(qw(fullname additional parentid));
         if ($oprec->{additional}->{tOuSD}->[0] ne ""){
            $tOuSD=$oprec->{additional}->{tOuSD}->[0];
            $subteamgroup=$rec->{fullname};
            my $qr=quotemeta($oprec->{fullname});
            $subteamgroup=~s/^$qr//;
            last;
         }
      }
   }
   


   {  # altname creation
      if (defined($tOuSD)){  # ok - the unit is a org unit
        # $altname=~s/^DTAG\.TSI\.S.*$/S/i;
        # $altname=~s/^DTAG\.TSI\.Prod\.CS\.Telco.*$/CS.TC/i;
#         $altname=~s/^DTAG\.TSI\.Prod\.GBOP\.PSS.*$/PSS/i;

         my %trtab=(
            'SDM.TC' =>'^DTAG\.TSI\.S\.DTAG\.(.*)$',
            'CS.TC'  =>'^DTAG\.TSI\.Prod\.CS\.Telco\.(.*)$',
            'PSS'    =>'^DTAG\.TSI\.Prod\.GBOP\.PSS\.(.*)$',
            'INT.CSS'=>'^DTAG\.TSI\.INT\.SK\.CSS\.CSS_Applicat\.(.*)$'
         );

         my $prefix;
         my $shortname;

         foreach my $k (keys(%trtab)){
            if (my ($sn)=$rec->{fullname}=~m/$trtab{$k}/i){
               $prefix=$k;
               $shortname=$sn;
               last;
            }
         }
         if (defined($prefix)){
            my $n1=uc($prefix.".".$country.".".$tOuSD.$subteamgroup);
            $n1=~s/\s/_/g;
            my $n2=uc($prefix.".".$country.".".$shortname);
            $n2=~s/\s/_/g;

            if (length($n1)>30){
               $n1=undef;
            }
            if (length($n2)>30){
               $n2=undef;
            }

            if ($n1 ne $alternateGroupnameHR){
               if (!exists($forcedupd->{additional})){
                  $forcedupd->{additional}=\%a;
               }
               $forcedupd->{additional}->{alternateGroupnameHR}=$n1;
            }
            if ($n2 ne $alternateGroupname){
               if (!exists($forcedupd->{additional})){
                  $forcedupd->{additional}=\%a;
               }
               $forcedupd->{additional}->{alternateGroupname}=$n2;
            }
         }
         else{
            if (!exists($forcedupd->{additional})){
               $forcedupd->{additional}=\%a;
            }
            delete($forcedupd->{additional}->{alternateGroupnameHR});
            delete($forcedupd->{additional}->{alternateGroupname});
         }
      }
   }
   if (keys(%$forcedupd)){
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
