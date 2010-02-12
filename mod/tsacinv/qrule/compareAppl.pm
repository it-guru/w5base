package tsacinv::qrule::compareAppl;
#######################################################################
=pod

=head3 PURPOSE

This qulaity rule compares a W5Base application to an AssetManager application
and updates on demand nessasary fields.
Unattended Imports are only done, if the field "Allow automatic interface
updates" is set to "yes".

=head3 IMPORTS

From AssetManager the fields CO-Number, ApplicationID, Application Number,
CurrentVersion, CHM Approvergroup, INM Assignmentgroup and Description 
are imported. SeM and TSM are imported, if
it was successfuly to import the relatied contacts.
#If Mandator is "Extern" and "Allow automatic interface updates" is set to "yes",
#there will be also the Name of the application, the databoss and the cistatus 
#imported from AssetManager.

=cut
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
   return(["itil::appl","AL_TCom::appl"]);
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
   if ($rec->{applid} ne ""){
      my $tswiw=getModuleObject($self->getParent->Config,"tswiw::user");
      my $par=getModuleObject($self->getParent->Config(),"tsacinv::appl");
      $par->SetFilter({applid=>\$rec->{applid}});
      my ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      return(undef,undef) if (!$par->Ping());
      if (!defined($parrec)){
         push(@qmsg,'given applicationid not found as active in AssetManager');
         $errorlevel=3 if ($errorlevel<3);
      }
      else{
         $self->IfaceCompare($dataobj,
                             $rec,"conumber",
                             $parrec,"conumber",
                             $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
                             mode=>'native');
         if ($parrec->{sememail} ne ""){
            my $semid=$tswiw->GetW5BaseUserID($parrec->{sememail});
            if (defined($semid)){
               $self->IfaceCompare($dataobj,
                                   $rec,"semid",
                                   {semid=>$semid},"semid",
                                   $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
                                   mode=>'native');
            }
         }
         if ($parrec->{tsmemail} ne ""){
            my $tsmid=$tswiw->GetW5BaseUserID($parrec->{tsmemail});
            if (defined($tsmid)){
               $self->IfaceCompare($dataobj,
                                   $rec,"tsmid",
                                   {tsmid=>$tsmid},"tsmid",
                                   $forcedupd,$wfrequest,
                                   \@qmsg,\@dataissue,\$errorlevel,
                                   mode=>'native');
            }
         }
         $self->IfaceCompare($dataobj,
                             $rec,"applnumber",
                             $parrec,"ref",
                             $forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'native');
         $self->IfaceCompare($dataobj,
                             $rec,"description",
                             $parrec,"description",
                             $forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'native');
         $self->IfaceCompare($dataobj,
                             $rec,"currentvers",
                             $parrec,"version",
                             $forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'native');
         if ($dataobj->Self eq "AL_TCom::appl"){  # only for AL DTAG
            $self->IfaceCompare($dataobj,
                                $rec,"acinmassingmentgroup",
                                $parrec,"iassignmentgroup",
                                $forcedupd,$wfrequest,
                                \@qmsg,\@dataissue,\$errorlevel,
                                mode=>'native',
                                AllowEmpty=>0);
            $self->IfaceCompare($dataobj,
                                $rec,"scapprgroup",
                                $parrec,"capprovergroup",
                                $forcedupd,$wfrequest,
                                \@qmsg,\@dataissue,\$errorlevel,
                                mode=>'native',
                                AllowEmpty=>0);
         }
      }
      #if ($rec->{allowifupdate}){
      #}

      if ($rec->{mandator} eq "Extern" && $rec->{allowifupdate}){
         # forced updates on External Data
         if (!defined($parrec)){
            $forcedupd->{cistatusid}=5;
         }
         else{
            my $databossid;
            my $acgroup=getModuleObject($self->getParent->Config,
                                        "tsacinv::group");
            $acgroup->SetFilter({lgroupid=>\$parrec->{lassignmentid}});
            my ($acgrouprec,$msg)=$acgroup->getOnlyFirst(qw(supervisorldapid));
            if (defined($acgrouprec)){
               if ($acgrouprec->{supervisorldapid} ne "" ||
                   $acgrouprec->{supervisoremail} ne ""){
                  my $importname=$acgrouprec->{supervisorldapid};
                  if ($importname eq ""){
                     $importname=$acgrouprec->{supervisoremail};
                  }
                  my $tswiw=getModuleObject($self->getParent->Config,
                                            "tswiw::user");
    #              my $newdatabossid=$tswiw->GetW5BaseUserID($importname);
    # noch nicht   if (defined($newdatabossid)){
    #                 $databossid=$newdatabossid;
    #              }
               }
            }
         }
      }
   }
   else{
      if ($rec->{mandator} ne "Extern"){
         push(@qmsg,'no applicationid specified');
         $errorlevel=3 if ($errorlevel<3);
      }
   }



   if (keys(%$forcedupd)>0){
      msg(INFO,sprintf("forceupd=%s\n",Dumper($forcedupd)));
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
#      printf STDERR ("fifi request a DataIssue Workflow=%s\n",Dumper($wfrequest));
   }

   # now process workflow request for traditional W5Deltas

   # todo

   #######################################################################

   if ($#qmsg!=-1 || $errorlevel>0){
      return($errorlevel,{qmsg=>\@qmsg});
   }

   return($errorlevel,undef);
}



1;
