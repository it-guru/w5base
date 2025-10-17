package AL_TCom::qrule::NORcheck;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checking if NOR-Nachweis und NOR-Vorgabe is valid and makes sense.

=head3 IMPORTS

NONE

=head3 HINTS

no english hints avalilable

[de:]

Diese QualityRule prüft die Existenz und das Alter von NOR-Vorgabe
und NOR-Nachweis. Da ein NOR-Nachweis für JEDE Anwendung empfohlen
wird und ein NOR-Nachweis nur nach vorheriger NOR-Vorgabe erstellt
werden kann, ist folgende Notifikation vorgesehen:

Anwendung ist älter als 3 Monate und Status is installiert/aktiv:
Mail an CBM (IT-SeM) mit CC an Application-Manager mit der
Empfehlung eine NOR-Vorgabe in Darwin zu erfassen.

verankerte NOR-Vorgabe existiert und ist älter als 4 Wochen mit:
Mail an SDM (IT-SeM) mit CC an Application-Manager mit
Empfehlung einen NOR-Nachweis zu erstellen.

NOR-Nachweis ist erstellt - ist aber älter als 12 Monate:
Mail an SDM (IT-SeM) mit CC an Application-Manager mit
Empfehlung einen neuen NOR-Nachweis zu erstellen.

=cut
#######################################################################
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
   return(["itil::appl"]);
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

   my $applid=$rec->{id};
   my $applmgrid=$rec->{applmgrid};
   my $delmgrid=$rec->{delmgrid};
   my $delmgr2id=$rec->{delmgr2id};
   my $semid=$rec->{semid};
   my $sem2id=$rec->{sem2id};

   #printf STDERR ("NOR-Check for Application ID = $applid\n");
   #printf STDERR ("applmgrid=$applmgrid\n");
   #printf STDERR ("delmgrid=$delmgrid\n");
   #printf STDERR ("delmgr2id=$delmgr2id\n");
   #printf STDERR ("semid=$semid\n");
   #printf STDERR ("sem2id=$sem2id\n");

   my $now=NowStamp("en");

   my $adv=getModuleObject($dataobj->Config,"itil::appladv");
   $adv->SetFilter({srcparentid=>\$applid,isactive=>'1'});
   my @advrec=$adv->getHashList(qw(id refreshinfo1 refreshinfo2 
                                   dstateid mdate urlofcurrentrec));
   #printf STDERR ("advrec=%s\n",Dumper(\@advrec));

   my $advage;
   if ($advrec[0]->{mdate} ne ""){
      my $d=CalcDateDuration($advrec[0]->{mdate},$now,"GMT");
      if (defined($d)){
         $advage=$d->{days};
      }
   }
   my $nor=getModuleObject($dataobj->Config,"itil::applnor");
   $nor->SetFilter({srcparentid=>\$applid,isactive=>'1'});
   my @norrec=$nor->getHashList(qw(id refreshinfo1 refreshinfo2 
                                   dstateid mdate urlofcurrentrec));
   #printf STDERR ("norrec=%s\n",Dumper(\@norrec));
   my $norage;
   if ($norrec[0]->{mdate} ne ""){
      my $d=CalcDateDuration($norrec[0]->{mdate},$now,"GMT");
      if (defined($d)){
         $norage=$d->{days};
      }
   }

   my $appage;
   if ($rec->{cdate} ne "" && $rec->{cistatusid}==4){
      my $d=CalcDateDuration($rec->{cdate},$now,"GMT");
      if (defined($d)){
         $appage=$d->{days};
      }
   }

   if (defined($appage) && $appage>30){
      if (!defined($advage) || $advage eq ""){
         if ($advrec[0]->{refreshinfo1} eq ""){
            $self->sendNotification($dataobj,$rec,
                                    $adv,"refreshinfo1",$advrec[0]);
            # Mail ADV erstellen
            #printf STDERR ("adv erstellen\n");
         }
      }
      else{
         if ((!defined($norage) || $norage eq "") && $advage>60){
            if ($norrec[0]->{refreshinfo1} eq ""){
               # ersten NOR Nachweis erstellen
               $self->sendNotification($dataobj,$rec,
                                       $nor,"refreshinfo1",$norrec[0]);
               #printf STDERR ("nor erstellen\n");
            }
         }
         if (defined($norage) && $norage>365){
            if ($norrec[0]->{refreshinfo2} eq ""){
               # NOR-Nachweis Refresh erstellen
               $self->sendNotification($dataobj,$rec,
                                       $nor,"refreshinfo2",$norrec[0]);
               #printf STDERR ("nor refresh erstellen\n");
            }
         }
      }
   }



   #printf STDERR ("now=$now\n");
   #printf STDERR ("advage=$advage\n");
   #printf STDERR ("norage=$norage\n");
   #printf STDERR ("appage=$appage\n");

   return(0,undef);
}

sub sendNotification
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $docobj=shift;
   my $field=shift;
   my $docrec=shift;

   my (@to,@cc,@bcc);

   if (!ref($docrec)){
      msg(ERROR,"missing appldocrec");
      return(undef);
   }
   my $tmpl=$self->Self;
   $tmpl=~s/::/./g;
   my $skinbase=$self->Self;
   $skinbase=~s/::.*//g;
   my $notifycontrol={useTemplate=>"tmpl/$tmpl",
                      useSkinBase=>$skinbase};
   my $subject;


   if ($docobj->Self() eq "itil::appladv"){
      push(@to,$rec->{semid})  if ($rec->{semid}  ne "");
      push(@cc,$rec->{sem2id}) if ($rec->{sem2id} ne "");
      $notifycontrol->{useTemplate}.=".appladv";
   }
   if ($docobj->Self() eq "itil::applnor"){
      push(@to,$rec->{delmgrid})  if ($rec->{delmgrid}  ne "");
      push(@cc,$rec->{delmgr2id}) if ($rec->{delmgr2id} ne "");
      $notifycontrol->{useTemplate}.=".applnor";
   }
   if ($#to==-1){
      push(@to,$rec->{applmgrid}) if ($rec->{applmgrid} ne "");
   }
   if ($#to==-1){
      push(@cc,$rec->{databossid}) if ($rec->{databossid} ne "");
   }
   if ($rec->{applmgrid} ne ""){
      if (!in_array(\@to,$rec->{applmgrid})){
         push(@cc,$rec->{applmgrid});
      }
   }

   if ($#to!=-1){
      my $touserid=$to[0];
      my $user=getModuleObject($dataobj->Config,"base::user");
      $user->SetFilter({userid=>\$touserid});
      my ($userlang)=$user->getVal("talklang");

      my $outdate="";
      if ($docobj->Self() eq "itil::appladv"){
         $subject=$dataobj->T("Necessity to creation of NOR-Target");
         if ($field eq "refreshinfo2"){
            $outdate=sprintf($dataobj->T(
                             "The current NOR-Target %s is out of date."),
                             $docrec->{urlofcurrentrec});
         }
      }
      if ($docobj->Self() eq "itil::applnor"){
         $subject=$dataobj->T("Necessity to creation of NOR-Verification");
         if ($field eq "refreshinfo2"){
            $outdate=sprintf($dataobj->T(
                             "The current NOR-Verification %s is out of date."),
                             $docrec->{urlofcurrentrec});
         }
      }
      $outdate="\n".$outdate."\n" if ($outdate ne "");
      my $text=$dataobj->getParsedTemplate(
         $notifycontrol->{useTemplate},
         {
            skinbase=>$notifycontrol->{useSkinBase},
            static=>{
               NAME=>$rec->{name},
               OUTDATE=>$outdate,
               LANG=>$userlang,
            }
         }
      );

      if (defined($subject)){
         my %notifyparam=(
            emailfrom=>"\"Darwin-NOR Monitor\" <noreply\@darwin.telekom.de>",
            emailto=>\@to,
            emailcc=>\@cc,
            emailbcc=>\@bcc,
         );

         my $wfact=getModuleObject($dataobj->Config,"base::workflowaction");
         $wfact->Notify("INFO",$subject,$text,%notifyparam);
         $docobj->UpdateRecord({mdate=>$docrec->{mdate},
                                $field=>NowStamp("en")},
                               {id=>$docrec->{id}});
      }
   }
   
}

1;
