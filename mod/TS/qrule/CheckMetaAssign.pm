package TS::qrule::CheckMetaAssign;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks all referenced Meta-Assignmentgroups in current object
against her state.


=head3 IMPORTS

=head3 HINTS
In fields Assignmentgroups (Change-Approver or Incident-Assignmentgroup)
are only those groups allowed, which are in AssetManager or
ServiceManager set as active.
Incident-Assignmentgroups must be set as active in 
AssetManager AND ServiceManager!

[de:]

In den Feldern Assignmentgroups (Change-Approver oder Incident-Assignmentgroup)
sind nur Gruppen erlaubt, die auch wirklich in AssetManager oder 
Servicemanager aktiv sind.

Incident-Assignmentgroups müssen sowohl in AssetManager als auch in
ServiceManager aktiv sein.

=cut

#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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
   return([".*::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   my $errorlevel=0;
   my $forcedupd={};
   my $wfrequest={};
   my @qmsg;
   my @dataissue;

   if (exists($rec->{cistatusid}) && $rec->{cistatusid} eq "4"){
      my @fld=$dataobj->getFieldObjsByView([qw(ALL)]);
      my $tsgrpmgmtgrp;
      foreach my $fld (@fld){
         if (exists($fld->{vjointo}) &&
             defined($fld->{vjointo}) &&
             $fld->{vjointo} eq "tsgrpmgmt::grp"){
            my $grpid=$rec->{$fld->{vjoinon}->[0]};
            if ($grpid ne ""){ # es wurde bereits eine Gruppe eingetr.
               if (!defined($tsgrpmgmtgrp)){
                  $tsgrpmgmtgrp=getModuleObject($dataobj->Config,$fld->{vjointo});
               }
               $tsgrpmgmtgrp->ResetFilter();
               $tsgrpmgmtgrp->SetFilter({id=>\$grpid});
               my @l=$tsgrpmgmtgrp->getHashList(qw(id cistatusid fullname));
               foreach my $grprec (@l){
                  if ($grprec->{cistatusid} ne "4"){
                     my $msg="use of deleted assignmentgroup: ";
                     $msg.=$grprec->{fullname};
                     push(@qmsg,$msg);
                     push(@dataissue,$msg);
                     $errorlevel=3 if ($errorlevel<3);
                  }
               }
            }
         }
      }
      if (keys(%$forcedupd)){
         if ($dataobj->ValidatedUpdateRecord($rec,$forcedupd,
                     {userid=>\$rec->{userid}})){
            push(@qmsg,"all desired fields has been updated: ".
                       join(", ",keys(%$forcedupd)));
         }
         else{
            push(@qmsg,$self->getParent->LastMsg());
            $errorlevel=3 if ($errorlevel<3);
         }
      }
      
      if (keys(%$wfrequest)){
         my $msg="different values stored in CIAM: ";
         push(@qmsg,$msg);
         push(@dataissue,$msg);
         $errorlevel=3 if ($errorlevel<3);
      }
      return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
   }
   return($errorlevel,undef);
}



1;
