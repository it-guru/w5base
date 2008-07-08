package tsacinv::qrule::compareLocation;
#######################################################################
=pod

=head3 PURPOSE

This qulaity rule compares a W5Base physical system to an AssetCenter physical
system (Asset) and updates on demand nessasary fields.
Unattended Imports are only done, if the field "Allow automatic interface
updates" is set to "yes".

=head3 IMPORTS

none
=cut
# ToDo:
#From AssetCenter the fields Location.
#CurrentVersion and Description are imported. SeM and TSM are imported, if
#it was successfuly to import the relatied contacts.
#IP-Addresses can only be synced, if the field "Allow automatic interface
#updates" is set to "yes".
#If Mandator is set to "Extern" and "Allow automatic interface updates"
#is set to "yes", some aditional Imports are posible:
#
#- "W5Base Administrator" field is set to the supervisor of Assignmentgroup in AC
#
#- "AC CO-Number" is imported to comments field in W5Base
#
#- "AC Assignmentgroup" is imported to comments field in W5Base

#######################################################################

#  Functions:
#  * at cistatus "installed/active":
#    - check if systemid is valid in tsacinv::system
#    - check if assetid is valid in tsacinv::asset 
#
#######################################################################
#
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
   return(["itil::asset","OSY::asset","AL_TCom::asset"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   return(0,undef) if ($rec->{cistatusid}!=4);
   if ($rec->{name} ne ""){
      my $par=getModuleObject($self->getParent->Config(),"tsacinv::asset");
      my $acloc=getModuleObject($self->getParent->Config(),"tsacinv::location");
      my $baseloc=getModuleObject($self->getParent->Config(),"base::location");
      $par->SetFilter({assetid=>\$rec->{name}});
      my ($parrec,$msg)=$par->getOnlyFirst(qw(locationid));
      if (!defined($parrec)){
         push(@qmsg,'given assetid not found as active in AssetCenter');
         push(@dataissue,'given assetid not found as active in AssetCenter');
         $errorlevel=3 if ($errorlevel<3);
      }
      else{
          $acloc->SetFilter({locationid=>\$parrec->{'locationid'}});
          my ($locrec,$msg)=$acloc->getOnlyFirst(qw(ALL));

          my @loc=split("[-/]",$locrec->{'fullname'});
          # first check
          my $location=$loc[1].".".$loc[2].".".$loc[3]."*".$loc[4]."*";
          $baseloc->SetFilter({name=>$location});
          my ($baselocrec,$msg)=$baseloc->getOnlyFirst(qw(ALL));
          if (!defined($baselocrec)){
             # secound check
             $location=$loc[1]."*".$loc[2]."*".substr($loc[3],0,3)."*".
                       substr($loc[3],length($loc[3])-1,1)."*".$loc[4]."*";
             $baseloc->ResetFilter();
             $baseloc->SetFilter({name=>$location});
             ($baselocrec,$msg)=$baseloc->getOnlyFirst(qw(ALL));
          }
      #    push(@qmsg,'w5baselocation='.$baselocrec->{name}.' aclocation='.$location.' acorg='.
      #         $locrec->{fullname});
          $self->IfaceCompare($dataobj,
                              $rec,"location",
                              $baselocrec,"name",
                              $forcedupd,$wfrequest,
                              \@qmsg,\@dataissue,\$errorlevel,
                              mode=>'string');
      }
   }else{
      push(@qmsg,'no assetid specified');
      push(@dataissue,'no assetid specified');
      $errorlevel=3 if ($errorlevel<3);
   }

   if (keys(%$forcedupd)){
      #printf STDERR ("fifi request a forceupd=%s\n",Dumper($forcedupd));
      if ($dataobj->ValidatedUpdateRecord($rec,$forcedupd,{id=>\$rec->{id}})){
         push(@qmsg,"all desired fields has been updated: ".
                    join(", ",keys(%$forcedupd)));
      }
      else{
         push(@qmsg,$self->getParent->LastMsg());
         $errorlevel=3 if ($errorlevel<3);
      }
   }
   if (keys(%$wfrequest)){
      my $msg="different values stored in AssetCenter: ";
      push(@qmsg,$msg);
      push(@dataissue,$msg);
      $errorlevel=3 if ($errorlevel<3);
   }
   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}


1;
