package caiman::qrule::ParentOrgUnit;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Validates the parent child structur of org-units against CAIMAN.

=head3 IMPORTS

NONE

=cut
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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

   if ($rec->{cistatusid}==4){
      if ($rec->{srcsys} eq "CAIMAN"){
         my @qmsg;
         if ($rec->{srcid} eq "00000000-0000-0000-0000-000000000000"){
            push(@qmsg,"EC top Org-Entry detected");
            return(0,{qmsg=>\@qmsg});
         }
         if ($rec->{srcid} eq ""){
            push(@qmsg,"srcid is not defined");
            return(3,{qmsg=>\@qmsg,dataissue=>\@qmsg});
         }
         $errorlevel=0;
         my $ciam=getModuleObject($self->getParent->Config(),"caiman::orgarea");
         $ciam->SetFilter({torgoid=>\$rec->{srcid}});
         my ($ciamrec,$msg)=$ciam->getOnlyFirst(qw(ALL));

         my $nousers=0;
         if (!defined($ciamrec)){
            push(@qmsg,"orgunit id not found in CAIMAN");
            return(3,{qmsg=>\@qmsg,dataissue=>\@qmsg});
         }
         else{
            my $nosgroups=1;
            if (ref($ciamrec->{subunits}) eq "ARRAY" &&
                $#{$ciamrec->{subunits}}!=-1){
               $nosgroups=0;
            }
            if ($nosgroups){ # check users only, if there are no subgroups
               $nousers=1;   # to reduce querys on CAIMAN
               msg(INFO,"check users, because there are no subgroups");
               if (ref($ciamrec->{users}) eq "ARRAY" &&
                   $#{$ciamrec->{users}}!=-1){
                  $nousers=0;
               }
            }
            if (!($ciam->LastMsg())){
               if ($nosgroups && $nousers){  # empty CAIMAN Group: HR Rotz
                  # check current group, if users have a srcload within last
                  # 90 days. If it is, this group is "fresh" orphaned and
                  # the dataissue can be deferred
                  my $foundfreshuser=0;
                  foreach my $lnkrec (@{$rec->{users}}){
                     if ($lnkrec->{srcsys} eq "CAIMAN"){
                        my $d=CalcDateDuration($lnkrec->{srcload},
                                               NowStamp("en"));
                        if (defined($d) && $d->{totaldays}<90){
                           $foundfreshuser++;
                        }
                     }
                  }
                  if ($foundfreshuser){
                     push(@qmsg,
                          "orphaned orgunit group in CAIMAN but within 90d");
                     return(0,{qmsg=>\@qmsg});
                  }
                  else{
                     push(@qmsg,"orphaned orgunit group in CAIMAN");
                     return(3,{qmsg=>\@qmsg,dataissue=>\@qmsg});
                  }
               }
            }
            else{
               $ciam->LastMsg(""); # reset posible CAIMAN Errors
            }
         }

         if (defined($ciamrec)){
            my $grp=getModuleObject($self->getParent->Config(),"base::grp");


            $grp->SetFilter({grpid=>\$rec->{parentid}});
            my ($pgrp,$msg)=$grp->getOnlyFirst(qw(srcsys srcid));
            if ($pgrp->{srcsys} ne "CAIMAN"){
               return(0,{qmsg=>[
                  'parent group is not from CAIMAN - '.
                  'disabling parent sync']
               });
            }
            else{
               my $parentid=$ciamrec->{parentid};
               if ($parentid ne ""){
                  my $grp=getModuleObject($self->getParent->Config(),
                                          "base::grp");
                  $grp->SetFilter({srcid=>\$parentid,
                                   srcsys=>\'CAIMAN',
                                   grpid=>\$rec->{parentid}});
                  my ($prec,$msg)=$grp->getOnlyFirst(qw(ALL));
                  if (!defined($prec)){
                     push(@qmsg,"parent unit in CAIMAN doesn't matches");
                     $grp->ResetFilter();
                     $grp->SetFilter({srcid=>\$parentid,srcsys=>\'CAIMAN'});
                     my ($pgrprec,$msg)=$grp->getOnlyFirst(qw(ALL));
                     if (defined($pgrprec)){
                        push(@qmsg,"parent group as of CAIMAN is: ".
                                   $pgrprec->{fullname});
                     }
                     else{
                        push(@qmsg,"parent tOuCID in CAIMAN is: ",$parentid);
                     }
                     return(3,{qmsg=>\@qmsg,dataissue=>\@qmsg});
                  }
               }
            }

            ##################################################################
            # orphaned check
            my $nosgroups=1;
            foreach my $grec (@{$rec->{subunits}}){
               if ($grec->{srcsys} eq "CAIMAN"){
                  $nosgroups=0;
               }
            }
            if ($nosgroups && $nousers){  # empty CAIMAN Group: HR Rotz
               push(@qmsg,"orphaned orgunit group from CAIMAN");
               return(3,{qmsg=>\@qmsg,dataissue=>\@qmsg});
            }
            ##################################################################
         }
      }
   }
   return($errorlevel,undef);
}



1;
