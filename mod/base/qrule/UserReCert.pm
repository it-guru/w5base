package base::qrule::UserReCert;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Recertivication of user assigments to CI-Contacts.

=head3 IMPORTS

NONE

=head3 HINTS

[de:]

Rezertifizierung von Kontakten in CIs oder Gruppen die
mit der Zuweisung von Rechten (lesen oder schreiben) verbunden
sind.

[en:]

Recertification of contacts in CIs or groups that are
associated with the assignment of rights (read or write).

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

   return(undef,undef) if (!defined($cistatusid_FObj) || $rec->{cistatusid}>5);

   #########################################################################
   # initiate ReCert process only if the CI is 6 weeks old, at least
   #
   my $crefdate=$rec->{cdate};
   if (exists($rec->{instdate}) && $rec->{instdate} ne ""){
      $crefdate=$rec->{instdate};
   }
   if ($crefdate ne ""){
      my $crefd=CalcDateDuration($crefdate,NowStamp("en"));
      if (defined($crefd) && $crefd->{days}<(6*7)){ # 6 weeks 
         return(undef,{qmsg=>['The config item is in the transient phase']});
      }

   }
   #########################################################################


   my $lrecertreqdt_FObj=$dataobj->getField("lrecertreqdt",$rec);
   my $lrecertdt_FObj=$dataobj->getField("lrecertdt",$rec);
   my $lrecertuser_FObj=$dataobj->getField("lrecertuser",$rec);

   my $latestOrgChange;
   if ($dataobj->Self() eq "base::grp"){
      msg(INFO,sprintf("UserReCert: base::grp Handling:\n"));
      foreach my $lnkrec (@{$rec->{users}}){
         my $lnkmdate=$lnkrec->{mdate};
         my $lnkcdate=$lnkrec->{cdate};
         msg(INFO,"UserLnk: ".$lnkrec->{lnkgrpuserid}." lastorgchangedt='".
                  $lnkrec->{lastorgchangedt}."' cdate='".$lnkcdate."' mdate='".
                  $lnkmdate."'");
         if ($lnkrec->{lastorgchangedt} ne "" &&
             $lnkmdate ne "" && $lnkcdate ne ""){
            my $md=CalcDateDuration($lnkrec->{lastorgchangedt},$lnkmdate);
            my $cd=CalcDateDuration($lnkrec->{lastorgchangedt},$lnkcdate);
      #printf STDERR ("fifi lastorgchangedt: %s\n",$lnkrec->{lastorgchangedt});
      #printf STDERR ("fifi cdate: %s\n",$lnkcdate);
      #printf STDERR ("fifi mdate: %s\n",$lnkmdate);
      #printf STDERR ("fifi md   : %s\n",Dumper($md));
      #printf STDERR ("fifi cd   : %s\n",Dumper($cd));
            if (defined($cd) && $cd->{totalminutes}<0){ 
               if (in_array($lnkrec->{roles},[orgRoles()])){
                  if (!defined($latestOrgChange) ||
                       $latestOrgChange eq "" ||
                       $latestOrgChange lt $lnkrec->{lastorgchangedt}){
                     $latestOrgChange=$lnkrec->{lastorgchangedt};
                  }
               }
            }
            else{
               msg(INFO,"ignore grp relation created after lastorgchangedt on ".
                        "lnkrec id=$lnkrec->{lnkgrpuserid}");
            }
         }
      }
   }
   else{
      msg(INFO,sprintf("UserReCert: CI-Handling: %s\n",$dataobj->Self()));
      foreach my $lnkrec (@{$rec->{contacts}}){
         my $lnkmdate=$lnkrec->{mdate};
         my $lnkcdate=$lnkrec->{cdate};
         msg(INFO,"ContactLnk: ".$lnkrec->{id}." lastorgchangedt='".
                  $lnkrec->{lastorgchangedt}."' cdate='".$lnkcdate."' mdate='".
                  $lnkmdate."'");
         if ($lnkrec->{lastorgchangedt} ne "" &&
             $lnkmdate ne "" && $lnkcdate ne ""){
            my $md=CalcDateDuration($lnkrec->{lastorgchangedt},$lnkmdate);
            my $cd=CalcDateDuration($lnkrec->{lastorgchangedt},$lnkcdate);
      #printf STDERR ("fifi lastorgchangedt: %s\n",$lnkrec->{lastorgchangedt});
      #printf STDERR ("fifi cdate: %s\n",$lnkcdate);
      #printf STDERR ("fifi mdate: %s\n",$lnkmdate);
      #printf STDERR ("fifi md   : %s\n",Dumper($md));
      #printf STDERR ("fifi cd   : %s\n",Dumper($cd));
            if (defined($cd) && $cd->{totalminutes}<0){ 
               if (defined($md) && $md->{totalminutes}<0){ 
                  if (in_array($lnkrec->{roles},["write","read"])){
                     if (!defined($latestOrgChange) ||
                          $latestOrgChange eq "" ||
                          $latestOrgChange lt $lnkrec->{lastorgchangedt}){
                        $latestOrgChange=$lnkrec->{lastorgchangedt};
                     }
                  }
               }
               else{
                  msg(INFO,"ignore ci contact relation modified ".
                           "after lastorgchangedt on ".
                           "lnkrec id=$lnkrec->{id}");
               }
            }
            else{
               msg(INFO,"ignore ci contact relation created ".
                        "after lastorgchangedt on ".
                        "lnkrec id=$lnkrec->{id}");
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

   if ($forcedupd->{lrecertreqdt} ne "" || $rec->{lrecertreqdt} ne ""){
      push(@qmsg,"recertification is requested");
   }

   if ($doNotify || $rec->{lrecertreqdt} ne ""){ # we have now an open recert
      $doNotify++;
      push(@qmsg,"recertification notification handling is active")
   }
   msg(INFO,"2 debug: doNotify=$doNotify latestOrgChange=$latestOrgChange");

   if ($doNotify){
      if ($rec->{lrecertreqnotify} ne ""){
         my $d=CalcDateDuration($rec->{lrecertreqnotify},NowStamp("en"));
         if (!defined($d)){
            msg(ERROR,"error in CalcDateDuration on rec=".Dumper($rec));
         }
         else{
            msg(INFO,"2 debug: lrecertreqnotify=".$rec->{lrecertreqnotify});
            msg(INFO,"2 debug: lrecertreqnotify age=".$d->{totaldays});
            if ($d->{totaldays}<7){ # send a notify only once a week
               msg(INFO,"last recert notify to short in the past - ".
                        "no new notify");
               $doNotify=0;
            }
         }
      }
   }

   msg(INFO,"3 debug: doNotify=$doNotify latestOrgChange=$latestOrgChange");
   if ($doNotify){
      if ($#certUids==-1){
         $doNotify=0;
      }
   } 
   #$doNotify=1; # force notification
   msg(INFO,"4 debug: doNotify=$doNotify latestOrgChange=$latestOrgChange");

   if ($doNotify && $rec->{lrecertreqdt} ne ""){
      $forcedupd->{lrecertreqnotify}=NowStamp("en");
      my $AgeOfReCertProcess=0;
      my $d=CalcDateDuration($rec->{lrecertreqdt},NowStamp("en"));
      if (!defined($d)){
         msg(ERROR,"error in doNotify CalcDateDuration on rec=".Dumper($rec));
      }
      else{
         $AgeOfReCertProcess=$d->{totaldays};
      }
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
         if ($AgeOfReCertProcess>15){  # wait 14 days bevor sending a real mail
            push(@qmsg,"recertification notification send as email");
            my %notifyParam;
            $notifyParam{faqkey}='QualityRule '.$self->Self();
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
                  my $NotifyTempl="UserReCertGrpNotify";
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
               if ($AgeOfReCertProcess<56){
                  msg(INFO,"9 debug: send UserReCertCiNotify message");
                  $notifyParam{emailto}=[$rec->{databossid}];
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
                     my $tmpl=$dataobj->getParsedTemplate("tmpl/".$NotifyTempl,
                        {
                           skinbase=>'base',
                           static=>{
                              NAME=>$rec->{name}
                           }
                        });
                     return($subject,$tmpl);
                  });
               }
               else{
                  msg(INFO,"9 debug: send UserReCertCiNotifyWithCC message");
                  $dataobj->NotifyWriteAuthorizedContacts($rec,{},
                                                          \%notifyParam,{},
                                                          sub{
                     my ($subject,$ntext);
                     my $ciname;
                     if (exists($rec->{fullname})){
                        $ciname=$rec->{fullname};
                     }
                     else{
                        $ciname=$rec->{name};
                     }
                     my $subject=$self->T("ReCert request").": ".$ciname;
                     my $NotifyTempl="UserReCertCiNotifyWithCC";
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
