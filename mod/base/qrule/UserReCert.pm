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
use Digest::MD5 qw(md5_base64);
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

   my $latestOrgChange;
   if ($dataobj->Self() eq "base::grp"){
      printf STDERR ("UserReCert: base::grp Handling:\n");
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
   }
   else{
      printf STDERR ("UserReCert: CI-Handling: %s\n",$dataobj->Self());
      foreach my $lnkrec (@{$rec->{contacts}}){
         if ($lnkrec->{lastorgchangedt} ne ""){
            if (in_array($lnkrec->{roles},["write","read"])){
               if (!defined($latestOrgChange) ||
                    $latestOrgChange eq "" ||
                    $latestOrgChange lt $lnkrec->{lastorgchangedt}){
                  $latestOrgChange=$lnkrec->{lastorgchangedt};
               }
            }
         }
      }

   }
   my $doNotify=0;
   my $openReCertReq=0;
   my @certUids;
   if (exists($rec->{lrecertreqdt}) &&
       exists($rec->{lrecertdt})){
      @certUids=$dataobj->getReCertificationUserIDs($rec);
   }
   if ($rec->{lrecertreqdt} eq "" && $latestOrgChange ne "" &&
       ($rec->{lrecertdt} eq "" || $latestOrgChange gt $rec->{lrecertdt})){
      if ($#certUids!=-1){
         $forcedupd->{lrecertreqdt}=NowStamp("en");
         $doNotify++;
      }
   }

   printf STDERR ("fifi 01: $doNotify - $rec->{lrecertreqdt} \n");
   if ($doNotify || $rec->{lrecertreqdt} ne ""){ # we have now an open recert
      $doNotify++;
   }
   printf STDERR ("fifi 02: $doNotify\n");

   if ($doNotify){
      if ($rec->{lrecertreqnotify} ne ""){
         my $d=CalcDateDuration($rec->{lrecertreqnotify},NowStamp("en"));
         if ($d->{totalminutes}<5){
            msg(INFO,"last recert notify to short in the past - no new notify");
            $doNotify=0;
         }
      }
   }
   printf STDERR ("fifi 03: $doNotify\n");

   if ($doNotify){
      if ($#certUids==-1){
         $doNotify=0;
      }
   } 

   if ($doNotify){
      $forcedupd->{lrecertreqnotify}=NowStamp("en");
      printf STDERR ("fifi 000: Notify\n");
      printf STDERR ("fifi 000: Notify\n");
      printf STDERR ("fifi 000: Notify\n");
      printf STDERR ("fifi 000: Notify\n");
      printf STDERR ("fifi 000: Notify\n");
      my %notifyParam;

      my $informationHash;
      if ($dataobj->Self() eq "base::grp"){
         $informationHash=md5_base64("UserReCert: base::grp".$rec->{grpid});
         $notifyParam{emailto}=\@certUids;
      }
      else{
         $informationHash=md5_base64("UserReCert: ".
                                     $dataobj->Self().$rec->{id});
      }
      $notifyParam{infoHash}=$informationHash;
                                             


      $dataobj->NotifyWriteAuthorizedContacts($rec,{},
                                              \%notifyParam,{},sub{
         my ($subject,$ntext);
         my $ciname;
         if (exists($rec->{fullname})){
            $ciname=$rec->{fullname};
         }
         else{
            $ciname=$rec->{name};
         }
         my $subject=$self->T("ReCert request").": ".$ciname;
         my $NotifyTempl="UserReCertCiNotify";
         if ($dataobj->Self() eq "base::grp"){
            $NotifyTempl="UserReCertGrpNotify";
         }
         my $tmpl=$dataobj->getParsedTemplate("tmpl/".$NotifyTempl,{
            skinbase=>'base',
            static=>{
               NAME=>$rec->{name}
            }
         });

         return($subject,$tmpl);
      });

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
