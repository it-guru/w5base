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

Checks Interviews-Answers on DR-Test topic. 

A valid CR number from SM9 is to be filled into the answer field  last (/next) Disaster-Recovery test (Change-Number) . In this case the date of last DR test will be automatically taken from the entered change and it will be copied to the answer field last Disaster-Recovery Test (WorkflowEnd). The existing content will be herewith replaced.

If no valid CR number from SM9 exists, this field must be left empty.
Possible comments can be inserted into the dedicated comment field available by clicking on corresponding icon (bubble).

A DataIssue is created if age of the last DR test (calculated based on the SLA guidelines) is too old.

A DataIssue is created if the date of the planned DR test is set further in the future as the interval defined in the SLA guidelines.

A DataIssue is created if the date of the planned DR test is set 8 weeks before the last DR test.

A DataIssue is created if the date of the planned DR test is older then the half test-interval.

In case of a new application which doesnt have any entry under "last DR test" and there is no planned date next Disaster-Recovery test set and the age of application reaches the half of the test interval (based on SLA), a DataIssue is created.


Further information you can find on Disaster Recovery FAQ site at intranet:

https://yam-united.telekom.com/pages/problem-management-telekom-it/apps/wiki/dr-faq/list/view/435cc4fa-558c-4354-9d43-2cd19482000b


The interview procedure here is not interactive, in case of any questions please contact our FMB:

mailto:DR_Disaster_Recovery_Test@telekom.de


[de:]

Prüft die Interview-Antworten im Themenblock DR-Test. 

Im Antwortfeld letzter (bzw. nächster) Disaster-Recovery Test (Change-Nummer) ist eine gültige CR Nummer aus SM9 einzutragen. In diesem Fall wird das Datum des letzten DR Tests automatisch aus dem Change entnommen und in das Antwortfeld letzter Disaster-Recovery Test (WorkflowEnd) eingefügt. Bereits eingetragene Inhalte werden dadurch überschrieben. 

Wenn keine gültige CR Nummer aus SM9 vorhanden ist, ist das Feld leer zu lassen. Kommentare können ggf. in dediziertes Kommentarfeld eingetragen werden.

Über die SLA Vorgaben wird errechnet, wie alt der letzte DR Test maximal sein darf. Ist dieser zu alt, wird ein DataIssue erzeugt.

Ist das DR Test Plandatum weiter in der Zukunft, als das durch die SLA Vorgaben definierte Intervall, so wird ein DataIssue erzeugt.

Liegt das DR Test Plandatum länger als 8 Wochen vor dem letzten DR Test, so wird ein DataIssue erzeugt.

Liegt das DR Test Plandatum länger als das halbe Test-Intervall in der Vergangenheit, so wird ein DataIssue erzeugt.

Wurde eine Anwendung neu aufgebaut und hat noch keinen "letzten DR Test" und ist kein Plantermin vorhanden wenn das Alter der Anwendung das halbe Test-Intervall (vom SLA Vorgaben) erreicht, so wird ein DataIssue erzeugt.


Weiterführende Informationen finden Sie auch auf unserer FAQ Seite im Intranet:

https://yam-united.telekom.com/pages/problem-management-telekom-it/apps/wiki/dr-faq/list/view/435cc4fa-558c-4354-9d43-2cd19482000b


Das Interviewverfahren ist nicht interaktiv, bei Fragen wenden Sie sich bitte an unsere FMB:

mailto:DR_Disaster_Recovery_Test@telekom.de


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

   return(undef) if ($rec->{opmode} ne "prod");

   my $wf=getModuleObject($self->getParent->Config,"base::workflow");
   my $ia=getModuleObject($self->getParent->Config,"base::interanswer");
   my $i=getModuleObject($self->getParent->Config,"base::interview");
   my $tag=getModuleObject($self->getParent->Config,"itil::tag_appl");
   my $iarec=$self->readCurrentAnswers($ia,$rec);


   my $drRiskAcceptance=0;
   my @nameexpr;

   my $ne=qr/^Exception_DR_Retirement_$rec->{ictono}_.+_(\d{8})\.pdf$/;
   push(@nameexpr,$ne);

   my $ne=qr/^Ausnahme_DR_Retirement_$rec->{ictono}_.+_(\d{8})\.pdf$/;
   push(@nameexpr,$ne);

   if (exists($rec->{attachments}) &&
       ref($rec->{attachments}) eq "ARRAY"){
      foreach my $a (@{$rec->{attachments}}){
         foreach my $ne (@nameexpr){
            if (my ($date)=$a->{name}=~m/$ne/){
               my ($y,$m,$d)=$date=~m/^([0-9]{4})([0-9]{2})([0-9]{2})$/;
               my $qval;
               my $dur;
               my $age;
               my $errors;
               {
                  open local(*STDERR), '>', \$errors;
                  eval('$qval=$ia->ExpandTimeExpression('.
                       '"$y-$m-$d 00:00:00","en");');
                  if ($qval ne ""){
                     $dur=CalcDateDuration($qval,$a->{cdate});
                  }
                  if (defined($dur)){
                     $age=CalcDateDuration($a->{cdate},NowStamp("en"));
                  }
               }
               if (defined($dur) && 
                   $dur->{totaldays}>-15 &&
                   $dur->{totaldays}<15 &&
                   defined($age) &&
                   $age->{totaldays}<180){
                  $drRiskAcceptance++;
               }
            }
         }
      }
   }






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
               if (!$drRiskAcceptance){
                  push(@dataissue,$msg);
               }
            }
         }
      }
   }
   #if (!exists(   # break, if answer on changenumber is not active
   #     $rec->{interviewst}->{qStat}->{activeQuestions}->{qtag}->{SOB_003})){
   #   return(undef);
   #}
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
               if (!$drRiskAcceptance){
                  push(@dataissue,$msg);
                  $errorlevel=3 if ($errorlevel<3);
               }
            }
         }
      }
   }
   if ($lastday eq "" && $rec->{cdate} ne ""){
      my $duration=CalcDateDuration($rec->{cdate},NowStamp("en"));
      if (defined($duration) && $duration->{totaldays}>($maxagedays)){
         my $msg="missing last DR-Test date";
         push(@qmsg,$msg);
         if (!$drRiskAcceptance){
            push(@dataissue,$msg);
            $errorlevel=3 if ($errorlevel<3);
         }
      }
   }
   if ($planday eq "" && $rec->{cdate} ne ""){
      my $duration=CalcDateDuration($rec->{cdate},NowStamp("en"));
      if (defined($duration) && $duration->{totaldays}>($maxagedays*0.5)){
         my $msg="missing valid next DR-Test change planning";
         push(@qmsg,$msg);
         if (!$drRiskAcceptance){
            push(@dataissue,$msg);
            $errorlevel=3 if ($errorlevel<3);
         }
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
               if (!$drRiskAcceptance){
                  push(@dataissue,$msg);
                  $errorlevel=3 if ($errorlevel<3);
               }
            }
         }
         if ($#qmsg==-1 && $pday ne ""){
            my $duration=CalcDateDuration(NowStamp("en"),$pday);
            if (defined($duration) && $duration->{days}<(($maxagedays/2)*-1)){
               my $msg="Disaster-Recovery Test plan date is in the past";
               push(@qmsg,$msg);
               if (!$drRiskAcceptance){
                  push(@dataissue,$msg);
                  $errorlevel=3 if ($errorlevel<3);
               }
            }
         }
         if ($#qmsg==-1 && $lday ne ""){
            my $duration=CalcDateDuration(NowStamp("en"),$lday);
            if (defined($duration) && $duration->{days}>90){
               my $msg="Disaster-Recovery last test is to far in the future";
               push(@qmsg,$msg);
               if (!$drRiskAcceptance){
                  push(@dataissue,$msg);
                  $errorlevel=3 if ($errorlevel<3);
               }
            }
         }
         if ($#qmsg==-1 && $pday ne ""){
            my $duration=CalcDateDuration(NowStamp("en"),$pday);
            if (defined($duration) && $duration->{days}>$maxagedays){
               my $msg=
                  "Disaster-Recovery Test plan date is to far in the future";
               push(@qmsg,$msg);
               if (!$drRiskAcceptance){
                  push(@dataissue,$msg);
                  $errorlevel=3 if ($errorlevel<3);
               }
            }
         }
         if ($#qmsg==-1 && $pday ne "" && $lday ne ""){
            my $duration=CalcDateDuration($lday,$pday);
            if (defined($duration) && $duration->{days}>$maxagedays){
               my $msg=
                  "Disaster-Recovery Test plan date is to far in the future";
               push(@qmsg,$msg);
               if (!$drRiskAcceptance){
                  push(@dataissue,$msg);
                  $errorlevel=3 if ($errorlevel<3);
               }
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
            if (!defined($d) || ($d->{totaldays}<-42 && $d->{totaldays}>7)){
               # Zieldatum des Changes nicht um den deadline Termin
               my $msg="missing valid next DR-Test change planning";
               push(@qmsg,$msg);
               if (!$drRiskAcceptance){
                  push(@dataissue,$msg);
                  $errorlevel=3 if ($errorlevel<3);
               }
               {
                  msg(INFO,"set DR-TestChange missing");
                  my $marker=$tag->getTag($rec->{id},
                              {name=>"DRTestNotify",mdate=>'>now-90d'});
                  if ($marker eq ""){
                     msg(INFO,"set DRTestNotify tag");
                     msg(INFO,"DR Test planning needed for ".$rec->{name}.
                              " - deadline for test is $deadline");
                     my $notifyparam={emailbcc=>11634953080001,
                                      emailcategory=>'DRTestPlanningNeeded'};
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
