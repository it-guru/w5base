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


   return(0) if ( $rec->{cistatusid}!=4 );

   return(undef) if ($rec->{opmode} ne "prod");

   my $wf=getModuleObject($self->getParent->Config,"base::workflow");
   my $ia=getModuleObject($self->getParent->Config,"base::interanswer");
   my $i=getModuleObject($self->getParent->Config,"base::interview");
   my $tag=getModuleObject($self->getParent->Config,"itil::tag_appl");
   my $iarec=$self->readCurrentAnswers($ia,$rec);


   #######################################################################
   #
   # Ausnahme Behandlung (pdf in den Anlagen)
   #
   #

   my $drRiskAcceptance=0;
   my @nameexpr;
   my $ne=qr/^Exception_DR_Retirement_$rec->{ictono}_.+_(\d{8})\.pdf$/;
   push(@nameexpr,$ne);

   my $ne=qr/^Exception_DR_Migration_$rec->{ictono}_.+_(\d{8})\.pdf$/;
   push(@nameexpr,$ne);

   my $ne=qr/^Ausnahme_DR_Retirement_$rec->{ictono}_.+_(\d{8})\.pdf$/;
   push(@nameexpr,$ne);

   my $ne=qr/^Ausnahme_DR_Migration_$rec->{ictono}_.+_(\d{8})\.pdf$/;
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
   #######################################################################
   #
   # soslanumdrtestinterval - Automatisierte Tests ausklammern
   #
   #
   if ($rec->{soslanumdrtestinterval} == 0 ||
       $rec->{soslanumdrtestinterval} == 12){
      return(undef,{qmsg=>'DR-Test checking deactivated or automated'});
   }


   #######################################################################
   #
   # Aktuelle Interview-Antworten laden 
   #
   #
   $i->SetFilter({qtag=>'SOB*'});
   $i->SetCurrentView(qw(id qtag));
   $self->{intv}=$i->getHashIndexed("qtag");


   #######################################################################
   #
   # Changenummber verarbeiten
   #
   my $ChangeNeeded=0;
   my $ChangeNumber;
   my $interviewchanged=0;
   my $ChangeEndDate;

#   if (exists($iarec->{qtag}->{SOB_003}) &&
#       $iarec->{qtag}->{SOB_003}->{relevant} eq "1"){
#      $ChangeNeeded++;
#   }
#   if (exists($iarec->{qtag}->{SOB_003}) &&
#       $iarec->{qtag}->{SOB_003}->{relevant} eq "1" &&
#       $iarec->{qtag}->{SOB_003}->{answer} ne ""){
#      my $changenumber=$iarec->{qtag}->{SOB_003}->{answer};
#      if ($changenumber=~/^C\d+$/){
#         $ChangeNumber=$changenumber;
#         $wf->SetFilter({srcid=>\$changenumber,srcsys=>'*change'});
#         my ($wfrec,$msg)=$wf->getOnlyFirst(qw(eventend wffields.changeend 
#                                               invoicedate));
#         if (defined($wfrec)){
#            my $qtag="SOB_004";
#            my $day=$wfrec->{eventend};
#            if ($wfrec->{changeend} ne ""){
#               $ChangeEndDate=$wfrec->{changeend};
#            }
#            if ($day ne ""){
#               my $d=CalcDateDuration($day,NowStamp("en"));
#               #print STDERR "Delta workflowend ($day):".Dumper($d);
#               if (defined($d)){
#                  if ($d->{totaldays}>0){  # take workflow end, if it's in past
#                     $day=~s/ .*$//; # cut of time
#                     my ($y,$m,$d)=$day=~m/(\d+)-(\d+)-(\d+)/;
#                     $day="$y-$m-$d";
#                     if (!defined($iarec->{qtag}->{$qtag})){
#                        # insert new
#                        $tag->setTag($rec->{id},"DRTestNotify","");
#                        $ia->ValidatedInsertRecord({
#                            parentid=>$rec->{id},
#                            parentobj=>'itil::appl',
#                            interviewid=>$self->{intv}->{qtag}->{$qtag}->{id},
#                            relevant=>1,
#                            answer=>$day
#                        });
#                        $interviewchanged++;
#                     }
#                     else{
#                        # update old
#                        if ($iarec->{qtag}->{$qtag}->{relevant} ne "1" ||
#                            $iarec->{qtag}->{$qtag}->{answer} ne $day){
#                           $tag->setTag($rec->{id},"DRTestNotify","");
#                           $ia->ValidatedUpdateRecord($iarec->{qtag}->{$qtag},
#                              { relevant=>1, answer=>$day},
#                              {id=>$iarec->{qtag}->{$qtag}->{id}});
#                           $interviewchanged++;
#                        }
#                     }
#                  }
#                  else{
#                     my $msg="temporary skip take of workflow end from change";
#                     push(@qmsg,$msg);
#                  }
#               }
#            }
#         }
#         else{
#            if (exists($rec->{interviewst}->{qStat}->{activeQuestions}->
#                       {qtag}->{SOB_003})){
#               my $msg="not existing Disaster-Recovery change number";
#               push(@qmsg,$msg);
#               if (!$drRiskAcceptance){
#                  push(@dataissue,$msg);
#               }
#            }
#         }
#      }
#   }
   #######################################################################
   #
   # Interview Antworten neu laden, falls diese durch das
   # o.g. Changenummern Verfahren verändert wurde.
   #
   if ($interviewchanged){
      $iarec=$self->readCurrentAnswers($ia,$rec);
   }


   #######################################################################
   #
   # Zeitpunkt des letzten Tests - und des geplanten nächsten
   # Test ermitteln. Zusätzlich die max. Anzahl von Tagen zwischen Tests
   # über soslanumdrtestinterval berechnen.
   #
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

   my $appdaysage=99999;
   if ($rec->{cdate} ne ""){
      my $duration=CalcDateDuration($rec->{cdate},NowStamp("en"));
      if (defined($duration)){
         $appdaysage=int($duration->{totaldays});
      }
   }
   my $maxagedays=365;
   my $maxagedays=int(365/$rec->{soslanumdrtestinterval});

   msg(INFO,"$rec->{name}: lastday: ".$lastday);
   msg(INFO,"$rec->{name}: planday: ".$planday);
   msg(INFO,"$rec->{name}: maxagedays: ".$maxagedays);
   msg(INFO,"$rec->{name}: appdaysage: ".$appdaysage);

   #######################################################################


   #######################################################################
   #
   # Prüfen des Anwendungsalters
   #
   #if ($appdaysage<$maxagedays*0.5){
   #   msg(INFO,"$rec->{name}: application to ".
   #                          "new appdaysage<maxagedays*0.5");
   #   return(0);
   #}
   #######################################################################

   #######################################################################
   #
   # Prüfen des des Datums des letzten DR Tests
   #
   if ($lastday ne "" && ($lastday=~m/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/)){
      if ($rec->{soslanumdrtestinterval}>0){
         my $lday=$wf->ExpandTimeExpression($lastday,"en","GMT","GMT");
         if ($lday ne ""){
            my $duration=CalcDateDuration(NowStamp("en"),$lday);
            if (defined($duration)){
               if ($duration->{days}<($maxagedays*-1)){
                  my $msg=
                      "age of Disaster-Recovery Test violates SLA definition";
                  push(@qmsg,$msg);
                  if (!$drRiskAcceptance){
                     push(@dataissue,$msg);
                     $errorlevel=3 if ($errorlevel<3);
                  }
               }
            }
         }
      }
   }
   else{
      my $duration=CalcDateDuration($rec->{cdate},NowStamp("en"));
      my $msg="missing last DR-Test date";
      push(@qmsg,$msg);
      if (!$drRiskAcceptance){
         push(@dataissue,$msg);
         $errorlevel=3 if ($errorlevel<3);
      }
   }



   #######################################################################
   #
   # Prüfen des des Plan-Datums für den nächsten DR Test
   #
   if ($planday eq ""){
      my $ldayok=0;  # true, if lday is more then $maxagedays/2 in the past
      if ($lastday ne "" &&
          ($lastday=~m/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/)){
         my $lday=$wf->ExpandTimeExpression($lastday,"en","GMT","GMT");
         if ($lday ne ""){
            my $duration=CalcDateDuration($lday,NowStamp("en"));
            if (defined($duration)){
               msg(INFO,"$rec->{name}: plancheck - lastday ".$duration->{days}." ago");
               if ($duration->{days}>$maxagedays/2){
                  $ldayok=1;
               }
            }
         }
      }
      if ($ldayok){  # lday exists and is more then 0.5*$maxagedays in the past
         my $msg="missing valid plan date for next DR test";
         push(@qmsg,$msg);
         if (!$drRiskAcceptance){
            push(@dataissue,$msg);
            $errorlevel=3 if ($errorlevel<3);
         }
      }
   }

   

   if ($lastday ne "" &&
       ($lastday=~m/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/)){
      if ($planday ne "" &&
          ($planday=~m/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) ){
         my $lday=$wf->ExpandTimeExpression($lastday,"en","GMT","GMT");
         my $pday=$wf->ExpandTimeExpression($planday,"en","GMT","GMT");

         if ($lday ne "" && $pday ne ""){
            my $duration=CalcDateDuration($lday,$pday);
            if (defined($duration) && $duration->{days}<(($maxagedays/2)*-1)){
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
            if (defined($duration) && $duration->{days}>0){
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
      }  # endif mit plantermin
   }


   return($self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd));
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
