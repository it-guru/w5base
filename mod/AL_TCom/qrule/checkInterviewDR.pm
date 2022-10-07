package AL_TCom::qrule::checkInterviewDR;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks and extend Interview-answers of DR-Test.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

Checks and extends Interviews-Answers on DR-Test topic.

[de:]

Prüft und erweitert die Interview-Antworten im Themenblock DR-Test.
Wenn die eingegebene Changenummer wie eine SM9 Changenummer aussieht,
dann wird das Datum des letzten DR Tests automatisch aus dem Change
entnommen und in die Antwort eingefügt.

Über die SLA Vorgaben wird errechnet, wie alt der letzte DR Test 
maximal sein darf. Ist dieser zu alt, wird ein DataIssue erzeugt.

Ist das DR Test Plandatum weiter in der Zukunft, als das durch die
SLA Vorgaben definierte Interval, so wird ein DataIssue erzeugt.

Liegt das DR Test Plandatum länger als 8 Wochen vor dem letzten
DR Test, so wird ein DataIssue erzeugt.

Liegt das DR Test Plandatum länger als das halbe Test-Intervall in
der Vergangenheit, so wird ein DataIssue erzeugt.

Wurde eine Anwendung neu aufgebaut (und hat somit noch keinen
"letzten DR Test", so sind die betreffenden Fragen alle auf
"relevant"="nein" zu setzen.

[en:]

Checks and extends Interviews-Answers on DR-Test topic. When 
the inserted change number looks like SM9 change number, the date of
last DR test will be automatically filled out from the entered change.

A DataIssue is created if max. age of the last DR test (calculated 
based on the SLA guidlines) is too old. 

A DataIssue is created if the date of the planned DR test is 
set further in the future as the interval defined in the SLA guidlines.

A DataIssue is created if the date of the planned DR test is 
set 8 weeks before the last DR test.

A DataIssue is created if the date of the planned DR test is 
older then the half test-interval.

In case of a new application (which doesnt have the "last DR 
test") set all question under "relevant" to "no".



=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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


   return(0) if ($rec->{cistatusid}!=3 && 
                 $rec->{cistatusid}!=4 &&
                 $rec->{cistatusid}!=5);

   my $wf=getModuleObject($self->getParent->Config,"base::workflow");
   my $ia=getModuleObject($self->getParent->Config,"base::interanswer");
   my $i=getModuleObject($self->getParent->Config,"base::interview");
   my $tag=getModuleObject($self->getParent->Config,"itil::tag_appl");
   my $iarec=$self->readCurrentAnswers($ia,$rec);

   $i->SetFilter({qtag=>'SOB*'});
   $i->SetCurrentView(qw(id qtag));
   $self->{intv}=$i->getHashIndexed("qtag");

   my $ChangeNeeded=0;
   my $ChangeNumber;
   my $interviewchanged=0;
   my $ChangeEndDate;

   if ($rec->{soslanumdrtestinterval} == 0 ||
       $rec->{soslanumdrtestinterval} == 12){
      return(undef,{qmsg=>'DR-Test checking deactivated or automated'});
   }
   if (exists($iarec->{qtag}->{SOB_003}) &&
       $iarec->{qtag}->{SOB_003}->{relevant} eq "1"){
      $ChangeNeeded++;
   }

   if (exists($iarec->{qtag}->{SOB_003}) &&
       $iarec->{qtag}->{SOB_003}->{relevant} eq "1" &&
       $iarec->{qtag}->{SOB_003}->{answer} ne ""){
      my $changenumber=$iarec->{qtag}->{SOB_003}->{answer};
      if ($changenumber=~/^C\d+$/){
         $ChangeNumber=$changenumber;
         $wf->SetFilter({srcid=>\$changenumber,srcsys=>'*change'});
         my ($wfrec,$msg)=$wf->getOnlyFirst(qw(eventend wffields.changeend 
                                               invoicedate));
         if (defined($wfrec)){
            my $qtag="SOB_004";
            my $day=$wfrec->{eventend};
            if ($wfrec->{changeend} ne ""){
               $ChangeEndDate=$wfrec->{changeend};
            }
            if ($day ne ""){
               my $d=CalcDateDuration($day,NowStamp("en"));
               #print STDERR "Delta workflowend ($day):".Dumper($d);
               if (defined($d)){
                  if ($d->{totaldays}>0){  # take workflow end, if it's in past
                     $day=~s/ .*$//; # cut of time
                     my ($y,$m,$d)=$day=~m/(\d+)-(\d+)-(\d+)/;
                     $day="$y-$m-$d";
                     if (!defined($iarec->{qtag}->{$qtag})){
                        # insert new
                        $tag->setTag($rec->{id},"DRTestNotify","");
                        $ia->ValidatedInsertRecord({
                            parentid=>$rec->{id},
                            parentobj=>'itil::appl',
                            interviewid=>$self->{intv}->{qtag}->{$qtag}->{id},
                            relevant=>1,
                            answer=>$day
                        });
                        $interviewchanged++;
                     }
                     else{
                        # update old
                        if ($iarec->{qtag}->{$qtag}->{relevant} ne "1" ||
                            $iarec->{qtag}->{$qtag}->{answer} ne $day){
                           $tag->setTag($rec->{id},"DRTestNotify","");
                           $ia->ValidatedUpdateRecord($iarec->{qtag}->{$qtag},
                              { relevant=>1, answer=>$day},
                              {id=>$iarec->{qtag}->{$qtag}->{id}});
                           $interviewchanged++;
                        }
                     }
                  }
                  else{
                     my $msg="temporary skip take of workflow end from change";
                     push(@qmsg,$msg);
                  }
               }
            }
         }
         else{
            if (exists($rec->{interviewst}->{qStat}->{activeQuestions}->
                       {qtag}->{SOB_003})){
               my $msg="not existing Disaster-Recovery change number";
               push(@qmsg,$msg);
               push(@dataissue,$msg);
            }
         }
      }
   }
   if (!exists(   # break, if answer on changenumber is not active
        $rec->{interviewst}->{qStat}->{activeQuestions}->{qtag}->{SOB_003})){
      return(undef);
   }
   if ($interviewchanged){
      $iarec=$self->readCurrentAnswers($ia,$rec);
   }

   my $planday="";
   if (defined($iarec->{qtag}->{SOB_005}) &&
       $iarec->{qtag}->{SOB_005}->{relevant} eq "1"){
      $planday=$iarec->{qtag}->{SOB_005}->{answer};
   }
   my $lastday="";
   if (defined($iarec->{qtag}->{SOB_004}) &&
       $iarec->{qtag}->{SOB_004}->{relevant} eq "1"){
      $lastday=$iarec->{qtag}->{SOB_004}->{answer};
   }
   $lastday=~s#/#.#g;
   $planday=~s#/#.#g;
   my $maxagedays=365;
   my $maxagedays=int(365/$rec->{soslanumdrtestinterval});
   if ($lastday ne "" && 
       ($lastday=~m/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) &&
       $rec->{soslanumdrtestinterval}>0){
      my $lday=$wf->ExpandTimeExpression($lastday,"en","GMT","GMT");
      if ($lday ne ""){
         my $duration=CalcDateDuration(NowStamp("en"),$lday);
         if (defined($duration)){
            if ($duration->{days}<($maxagedays*-1)){
               my $msg="age of Disaster-Recovery Test violates SLA definition";
               push(@qmsg,$msg);
               push(@dataissue,$msg);
               $errorlevel=3 if ($errorlevel<3);
            }
         }
      }
   }
   if ($planday eq "" && $rec->{cdate} ne ""){
      my $duration=CalcDateDuration($rec->{cdate},NowStamp("en"));
      if (defined($duration) && $duration->{totaldays}>($maxagedays*0.5)){
         my $msg="missing valid next DR-Test change planning";
         push(@qmsg,$msg);
         push(@dataissue,$msg);
         $errorlevel=3 if ($errorlevel<3);
      }
   }
   msg(INFO,"$rec->{name}: lastday: ".$lastday);
   msg(INFO,"$rec->{name}: planday: ".$planday);
   msg(INFO,"$rec->{name}: maxagedays: ".$maxagedays);
   if ($lastday ne "" &&
       ($lastday=~m/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/)){
      if ($planday ne "" &&
          ($planday=~m/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) ){
         my $lday=$wf->ExpandTimeExpression($lastday,"en","GMT","GMT");
         my $pday=$wf->ExpandTimeExpression($planday,"en","GMT","GMT");
         if ($lday ne "" && $pday ne ""){
            my $duration=CalcDateDuration($lday,$pday);
            if (defined($duration) && $duration->{days}<-56){
               my $msg="Disaster-Recovery Test plan date is bevor last test";
               push(@qmsg,$msg);
               push(@dataissue,$msg);
               $errorlevel=3 if ($errorlevel<3);
            }
         }
         if ($#qmsg==-1 && $pday ne ""){
            my $duration=CalcDateDuration(NowStamp("en"),$pday);
            if (defined($duration) && $duration->{days}<(($maxagedays/2)*-1)){
               my $msg="Disaster-Recovery Test plan date is in the past";
               push(@qmsg,$msg);
               push(@dataissue,$msg);
               $errorlevel=3 if ($errorlevel<3);
            }
         }
         if ($#qmsg==-1 && $lday ne ""){
            my $duration=CalcDateDuration(NowStamp("en"),$lday);
            if (defined($duration) && $duration->{days}>90){
               my $msg="Disaster-Recovery last test is to far in the future";
               push(@qmsg,$msg);
               push(@dataissue,$msg);
               $errorlevel=3 if ($errorlevel<3);
            }
         }
         if ($#qmsg==-1 && $pday ne ""){
            my $duration=CalcDateDuration(NowStamp("en"),$pday);
            if (defined($duration) && $duration->{days}>$maxagedays){
               my $msg=
                  "Disaster-Recovery Test plan date is to far in the future";
               push(@qmsg,$msg);
               push(@dataissue,$msg);
               $errorlevel=3 if ($errorlevel<3);
            }
         }
         if ($#qmsg==-1 && $pday ne "" && $lday ne ""){
            my $duration=CalcDateDuration($lday,$pday);
            if (defined($duration) && $duration->{days}>$maxagedays){
               my $msg=
                  "Disaster-Recovery Test plan date is to far in the future";
               push(@qmsg,$msg);
               push(@dataissue,$msg);
               $errorlevel=3 if ($errorlevel<3);
            }
         }

      }
      if ($lastday ne "" && $maxagedays>0){
         my $debuglog="";
         #printf STDERR ("ChangeEndDate=%s\n",$ChangeEndDate);
         my $ChangeEndDateOnly=$ChangeEndDate;
         $ChangeEndDateOnly=~s/ .*$//;
         if ($lastday eq ""){
            $lastday=NowStamp("en");
            $lastday=~s/\s.*$//;
         }
         $debuglog.="last date of DR-Tests: $lastday\n"; 
         $debuglog.="maximum days bettween DR-Tests: $maxagedays\n"; 
         my $deadline=$wf->ExpandTimeExpression(
                      $lastday."+${maxagedays}d",
                      "en","GMT","GMT");

         $deadline=~s/\s.*$//;
         if ($planday ne ""){
            $deadline=$planday;
            $debuglog.="deadline replaced by interview answer: $deadline\n"; 
         }
         else{
            $debuglog.="deadline for DR-Test: $deadline\n"; 
         }
         $deadline=~s/\s.*$//;

         my $plandeadline=$wf->ExpandTimeExpression(
                           $deadline."-42d",
                           "en","GMT","GMT");
         $debuglog.="plan of DR-Test deadline: $plandeadline\n"; 
         $debuglog.="last day from Change: $ChangeEndDate\n"; 
         
         my $d=CalcDateDuration(NowStamp("en"),$plandeadline);
         my $needToPlan=0;
         if (defined($d)){
            if ($d->{totaldays}<0){
               $needToPlan=1;
            }
         }
         else{
            msg(ERROR,"DR Test calc needToPlan failed: $plandeadline");
         }
         if ($needToPlan && $ChangeNumber eq ""){ # check if next plandate 
                                                  # within next 42 days
            msg(INFO,"needToPlanCheck: lastday: $lastday");
            msg(INFO,"needToPlanCheck: planday: $planday");
            if ($lastday eq $planday){
               my $msg="found change planning without ChangeNumber";
               push(@qmsg,$msg);
               $needToPlan=0;
            }
         }

         msg(INFO,"$rec->{name}: next DR-Test planing deadline: ".
                  $plandeadline);
         msg(INFO,"$rec->{name}: days to next DR-Test planing deadline: ".
                  "$d->{totaldays}");
         msg(INFO,"$rec->{name}: next DR-Test planning needed: $needToPlan");
         if ($needToPlan){
            my $d;
            if ($ChangeEndDate ne ""){
               #printf STDERR ("ChangeEndDate=%s\n",$ChangeEndDate);
               $d=CalcDateDuration($deadline." 00:00:00",$ChangeEndDate);
               #printf STDERR ("plandeadline->ChangeEndDate:%s\n",Dumper($d));
            }
            if (!defined($d) || ($d->{totaldays}>-42 && $d->{totaldays}<7)){
               # Zieldatum des Changes um den deadline Termin
               my $msg="missing valid next DR-Test change planning";
               push(@qmsg,$msg);
               push(@dataissue,$msg);
               $errorlevel=3 if ($errorlevel<3);
               {
                  msg(INFO,"set DR-TestChange missing");
                  my $marker=$tag->getTag($rec->{id},
                              {name=>"DRTestNotify",mdate=>'>now-90d'});
                  if ($marker eq ""){
                     msg(INFO,"set DRTestNotify tag");
                     msg(INFO,"DR Test planning needed for ".$rec->{name}.
                              " - deadline for test is $deadline");
                     my $notifyparam={emailbcc=>11634953080001};
                     my $notifycontrol={};
                     $dataobj->NotifyWriteAuthorizedContacts($rec,{},
                                     $notifyparam,$notifycontrol,sub{
                        my $self=shift;
                        my $notifyparam=shift;
                        my $notifycontrol=shift;
                        my $subject;
                        my $text;
                        $subject=$self->T("request to plan next DR Test for").
                                 " ".$rec->{name};
                        my $tmpl=$self->getParsedTemplate(
                           "tmpl/AL_TCom.qrule.checkInterviewDR.testplan",{
                              static=>{
                                 APPNAME=>$rec->{name}
                              }
                        });
                        $text=$tmpl;

                        $text.="\n\n";
                   
                        $text.=$self->T("Calculation base for this mail").":\n".
                               "---\n".
                               $debuglog;
                   
                   
                        return($subject,$text);
                     });
                     # mail verschicken
                     $tag->setTag($rec->{id},"DRTestNotify",NowStamp("en"));
                  }
                  # hier sollte die Notification versandt werden
               }
            }
         }
      }
   }


   my @result=$self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}


sub readCurrentAnswers
{
   my $self=shift;
   my $ia=shift;
   my $rec=shift;

   $ia->SetFilter({
       parentid=>\$rec->{id},
       parentobj=>\'itil::appl',
       qtag=>"SOB*"
   });
   $ia->SetCurrentView(qw(ALL));
   my $iarec=$ia->getHashIndexed("qtag");

   return($iarec);
}




1;
