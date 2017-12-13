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
   my $iarec=$self->readCurrentAnswers($ia,$rec);

   $i->SetFilter({qtag=>'SOB*'});
   $i->SetCurrentView(qw(id qtag));
   $self->{intv}=$i->getHashIndexed("qtag");

   my $changenumberok=1;
   my $interviewchanged=0;

   if (exists($iarec->{qtag}->{SOB_003}) &&
       $iarec->{qtag}->{SOB_003}->{relevant} eq "1" &&
       $iarec->{qtag}->{SOB_003}->{answer} ne ""){
      my $changenumber=$iarec->{qtag}->{SOB_003}->{answer};
      if ($changenumber=~/^C\d+$/){
         $wf->SetFilter({srcid=>\$changenumber,srcsys=>'*change'});
         my ($wfrec,$msg)=$wf->getOnlyFirst(qw(eventend));
         if (defined($wfrec)){
            my $qtag="SOB_004";
            my $day=$wfrec->{eventend};
            $day=~s/ .*$//; # cut of time
            my ($y,$m,$d)=$day=~m/(\d+)-(\d+)-(\d+)/;
            $day="$y-$m-$d";
            if (!defined($iarec->{qtag}->{$qtag})){
               # insert new
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
               $ia->ValidatedUpdateRecord($iarec->{qtag}->{$qtag},
                  { relevant=>1, answer=>$day},
                  {id=>$iarec->{qtag}->{$qtag}->{id}});
               $interviewchanged++;
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
   if ($lastday ne "" && $rec->{soslanumdrtests}>0){
      $maxagedays=365/$rec->{soslanumdrtests};
      my $lday=$wf->ExpandTimeExpression($lastday,"en","GMT","GMT");
      if ($lday ne ""){
         my $duration=CalcDateDuration(NowStamp("en"),$lday);
         if (defined($duration) && $duration->{days}<($maxagedays*-1)){
            my $msg="age of Disaster-Recovery Test violates SLA definition";
            push(@qmsg,$msg);
            push(@dataissue,$msg);
         }
      }
   }
   if ($lastday ne "" && $planday ne ""){
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
      if ($#qmsg==-1 && $pday ne ""){
         my $duration=CalcDateDuration(NowStamp("en"),$pday);
         if (defined($duration) && $duration->{days}>$maxagedays){
            my $msg="Disaster-Recovery Test plan date is to far in the future";
            push(@qmsg,$msg);
            push(@dataissue,$msg);
            $errorlevel=3 if ($errorlevel<3);
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
