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
      msg(INFO,sprintf("UserReCert: base::grp Handling:\n"));
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
      msg(INFO,sprintf("UserReCert: CI-Handling: %s\n",$dataobj->Self()));
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
   msg(INFO,"1 debug: doNotify=$doNotify latestOrgChange=$latestOrgChange");

   if ($doNotify || $rec->{lrecertreqdt} ne ""){ # we have now an open recert
      $doNotify++;
   }
   msg(INFO,"2 debug: doNotify=$doNotify latestOrgChange=$latestOrgChange");

   if ($doNotify){
      if ($rec->{lrecertreqnotify} ne ""){
         my $d=CalcDateDuration($rec->{lrecertreqnotify},NowStamp("en"));
         if ($d->{totaldays}<2){
            msg(INFO,"last recert notify to short in the past - no new notify");
            $doNotify=0;
         }
      }
   }

   msg(INFO,"3 debug: doNotify=$doNotify latestOrgChange=$latestOrgChange");
   if ($doNotify){
      if ($#certUids==-1){
         $doNotify=0;
      }
   } 
   msg(INFO,"4 debug: doNotify=$doNotify latestOrgChange=$latestOrgChange");

   if ($doNotify && $rec->{lrecertreqdt} ne ""){
      $forcedupd->{lrecertreqnotify}=NowStamp("en");
      my $d=CalcDateDuration($rec->{lrecertreqdt},NowStamp("en"));
      msg(INFO,sprintf ("age of lrecertreqdt = %s\n",Dumper($d)));
      if ($dataobj->Self() ne "base::grp" && # no auto deactivation for base:grp
          $d->{totaldays}>112){  # set CI to cistatusid=6 after 4 months
         my $name;
         my $id;
         if ($dataobj->Self() eq "base::grp"){
            $id=$rec->{grpid};
            $name=$rec->{fullname};
         }
         else{
            $id=$rec->{id};
            $name=$rec->{name};
         }
         msg(INFO,"setting CI $name($id) to cistatusid=6 - disposed of wasted");
         $forcedupd->{cistatusid}="6";
         $forcedupd->{lrecertreqdt}=undef;
         $forcedupd->{lrecertreqnotify}=undef;
      }
      else{
         if ($d->{totaldays}>15){  # wait 14 days bevor sending a real mail
            my %notifyParam;
            if ($dataobj->Self() eq "base::grp"){
               $notifyParam{emailto}=\@certUids;
            }
            if ($dataobj->Self() eq "base::grp"){
               $dataobj->NotifyLangContacts($rec,{},
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
            else{
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
         }
         else{
            msg(INFO,"preserve real Notification Mail - ".
                     "because request is jung");
         }
      }

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
