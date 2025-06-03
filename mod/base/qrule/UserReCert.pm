package base::qrule::UserReCert;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Recertivication of user assigments to CI-Contacts.

=head3 IMPORTS

NONE

=cut
#######################################################################
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
   return([".*"]);
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

   my $cistatusid_FObj=$dataobj->getField("cistatusid",$rec);

   return(0,undef) if (!defined($cistatusid_FObj) || $rec->{cistatusid}>5);

   my $lrecertreqdt_FObj=$dataobj->getField("lrecertreqdt",$rec);
   my $lrecertdt_FObj=$dataobj->getField("lrecertdt",$rec);
   my $lrecertuser_FObj=$dataobj->getField("lrecertuser",$rec);

   if ($dataobj->Self() eq "base::grp"){
      printf STDERR ("UserReCert: base::grp Handling:\n");
      my $latestOrgChange;
      foreach my $lnkrec (@{$rec->{users}}){
         if ($lnkrec->{lastorgchangedt} ne ""){
            if (in_array($lnkrec->{roles},[orgRoles()])){
               if (!defined($latestOrgChange) ||
                    $latestOrgChange eq "" ||
                    $latestOrgChange lt $lnkrec->{lastorgchangedt}){
                  $latestOrgChange=$lnkrec->{lastorgchangedt};
               }
            }
         }
      }
      my $doNotify=0;
      if (!defined($rec->{lrecertreqdt}) || $rec->{lrecertreqdt} eq "" ||
          $rec->{lrecertreqdt} lt $latestOrgChange){
         $forcedupd->{lrecertreqdt}=$latestOrgChange;
         $doNotify++;
      }
      if ($rec->{lrecertreqdt} ne "" &&
          $rec->{lrecertreqdt} gt $latestOrgChange){
         printf STDERR ("\n\nreset recert date=$latestOrgChange!!!\n\n-\n");
         $forcedupd->{lrecertreqdt}=$latestOrgChange;
      }

      # ignore lrecertreqnotify if it is to old
      if (defined($rec->{lrecertreqnotify}) && 
          $rec->{lrecertreqnotify} ne ""){
         my $d=CalcDateDuration($rec->{lrecertreqnotify},NowStamp("en"));
         if ($d->{totalminutes}>2){
            $rec->{lrecertreqnotify}=undef;
         }
      }

      #printf STDERR ("fifi forcedupd->{lrecertreqdt}: %s\n",$forcedupd->{lrecertreqdt});
      #printf STDERR ("fifi rec->{lrecertreqdt}: %s\n",$rec->{lrecertreqdt});
      #printf STDERR ("fifi rec->{lrecertdt}: %s\n",$rec->{lrecertdt});

      if (!defined($rec->{lrecertreqnotify}) || 
          $rec->{lrecertreqnotify} eq "" &&
          ($forcedupd->{lrecertreqdt} ne "" ||
           $rec->{lrecertreqdt} gt $rec->{lrecertdt})){ 
         my @orgadm=$dataobj->getMembersOf($rec->{grpid},["RAdmin"],"up");
         printf STDERR ("NOTIFY01: --- !!! reCertNotify -----\n");
         printf STDERR ("orgadmin=%s\n",Dumper(\@orgadm));

         printf STDERR ("\n\nnotify request recert ".
                        "date=$latestOrgChange!!!\n\n-\n");
         printf STDERR ("NOTIFY02: --- !!! reCertNotify -----\n");
         $forcedupd->{lrecertreqnotify}=NowStamp("en");
      }
   }
   else{
      printf STDERR ("UserReCert: CI Handling:\n");
      printf STDERR ("contacts=%s\n",Dumper($rec->{contacts}));

   }

   if (keys(%$forcedupd)){ # du the forcedupd silent
      $forcedupd->{mdate}=$rec->{mdate};
      my $idfield=$dataobj->IdField();
      my $idname=$idfield->Name();
      if ($dataobj->ValidatedUpdateRecord($rec,$forcedupd,
                                          {$idname=>\$rec->{$idname}})){
         msg(INFO,"upd ok");
         $forcedupd={};
      }
      else{
         push(@qmsg,$self->getParent->LastMsg());
         $errorlevel=3 if ($errorlevel<3);
      }
   }







#   if ($urlswi>0 && $#{$rec->{applurl}}==-1){
#      $errorlevel=3;
#      my $msg="missing communication urls in application documentation";
#      push(@dataissue,$msg);
#      push(@qmsg,$msg);
#   }

   my @result=$self->HandleQRuleResults(undef,
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}




1;
