package tsacinv::qrule::compareAsset;
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
      $par->SetFilter({assetid=>\$rec->{name}});
      my ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      if (!defined($parrec)){
         push(@qmsg,'given assetid not found as active in AssetCenter');
         push(@dataissue,'given assetid not found as active in AssetCenter');
         $errorlevel=3 if ($errorlevel<3);
      }
      else{
          my $acroom=$parrec->{room};
          my $acloc=$parrec->{tsacinv_locationfullname};
          if ($acroom=~m/^\d{1,2}\.\d{3}$/){
             if (my ($geb)=$acloc=~m#^/[^/]+/([A-Z]{1})/#){
                $acroom=$geb.$acroom;
             }
          }
          $acroom="C1.300" if ($acroom eq "1.300"); 
#printf STDERR ("acroom=$acroom asset=%s\n",Dumper($parrec));
          $self->IfaceCompare($dataobj,
                              $rec,"room",
                              {room=>$acroom},"room",
                              $forcedupd,$wfrequest,
                              \@qmsg,\@dataissue,\$errorlevel,
                              mode=>'string');
         $self->IfaceCompare($dataobj,
                             $rec,"memory",
                             $parrec,"memory",
                             $forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             tolerance=>5,mode=>'integer');

         $self->IfaceCompare($dataobj,
                             $rec,"cpucount",
                             $parrec,"cpucount",
                             $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
                             mode=>'integer');
         $self->IfaceCompare($dataobj,
                             $rec,"corecount",
                             $parrec,"corecount",
                             $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
                             mode=>'integer');
      }

#      if ($rec->{mandator} eq "Extern" && $rec->{allowifupdate}){
#         # forced updates on External Data
#         my $admid;
#         my $acgroup=getModuleObject($self->getParent->Config,"tsacinv::group");
#         $acgroup->SetFilter({lgroupid=>\$parrec->{lassignmentid}});
#         my ($acgrouprec,$msg)=$acgroup->getOnlyFirst(qw(supervisorldapid));
#         if (defined($acgrouprec)){
#            if ($acgrouprec->{supervisorldapid} ne "" ||
#                $acgrouprec->{supervisoremail} ne ""){
#               my $importname=$acgrouprec->{supervisorldapid};
#               if ($importname eq ""){
#                  $importname=$acgrouprec->{supervisoremail};
#               }
#               my $tswiw=getModuleObject($self->getParent->Config,
#                                         "tswiw::user");
#               my $databossid=$tswiw->GetW5BaseUserID($importname);
#               if (defined($databossid)){
#                  $admid=$databossid;
#               }
#            }
#         }
#         if ($admid ne ""){
#            $self->IfaceCompare($dataobj,
#                                $rec,"admid",
#                                {admid=>$admid},"admid",
#                                $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
#                                mode=>'integer');
#         }
#         my $comments="";
#         if ($parrec->{assignmentgroup} ne ""){
#            $comments.="\n" if ($comments ne "");
#            $comments.="AssetCenter AssignmentGroup: ".
#                       $parrec->{assignmentgroup};
#         }
#         if ($parrec->{conumber} ne ""){
#            $comments.="\n" if ($comments ne "");
#            $comments.="AssetCenter CO-Number: ".
#                       $parrec->{conumber};
#         }
#         $self->IfaceCompare($dataobj,
#                             $rec,"comments",
#                             {comments=>$comments},"comments",
#                             $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
#                             mode=>'string');
#      }
   }
   else{
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
