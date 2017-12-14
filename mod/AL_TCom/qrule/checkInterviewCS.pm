package AL_TCom::qrule::checkInterviewCS;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks and extend Interview-answers of ClusterServiceSwitch-Test.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

Checks and extends Interviews-Answers on ClusterServiceSwitch-Test topic.

[de:]

Prüft und erweitert die Interview-Antworten im Themenblock ClusterServiceSwitch-Test.
Wenn die eingegebene Changenummer wie eine SM9 Changenummer aussieht,
dann wird das Datum des letzten ClusterService Switch Tests automatisch 
aus dem Change entnommen und in die Antwort eingefügt.

Wurde eine Anwendung neu aufgebaut (und hat somit noch keinen
"letzten ClusterService Switch Test", so sind die betreffenden Fragen alle auf
"relevant"="nein" zu setzen.

[en:]

Checks and extends Interviews-Answers on ClusterServiceSwitch-Test 
topic. When the inserted change number looks like SM9 change number, 
the date of last ClusterService Switch test will be automatically 
filled out from the entered change.

In case of a new application (which doesnt have the "last DR test") 
set all question under "relevant" to "no".


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

   if (exists($iarec->{qtag}->{SOB_009}) &&
       $iarec->{qtag}->{SOB_009}->{relevant} eq "1" &&
       $iarec->{qtag}->{SOB_009}->{answer} ne ""){
      my $changenumber=$iarec->{qtag}->{SOB_009}->{answer};
      if ($changenumber=~/^C\d+$/){
         $wf->SetFilter({srcid=>\$changenumber,srcsys=>'*change'});
         my ($wfrec,$msg)=$wf->getOnlyFirst(qw(eventend));
         if (defined($wfrec)){
            my $qtag="SOB_010";
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
                       {qtag}->{SOB_009})){
               my $msg="not existing ClusterServiceSwitch change number";
               push(@qmsg,$msg);
               push(@dataissue,$msg);
               $errorlevel=3 if ($errorlevel<3);
            }
         }
      }
   }
   if (!exists(   # break, if answer on changenumber is not active
        $rec->{interviewst}->{qStat}->{activeQuestions}->{qtag}->{SOB_009})){
      return(undef);
   }
   if ($interviewchanged){
      $iarec=$self->readCurrentAnswers($ia,$rec);
   }

   my $lastday="";
   if (defined($iarec->{qtag}->{SOB_010}) &&
       $iarec->{qtag}->{SOB_010}->{relevant} eq "1"){
      $lastday=$iarec->{qtag}->{SOB_010}->{answer};
   }

   $lastday=~s#/#.#g;
   my $maxagedays=365;
   if ($lastday ne "" &&
       ($lastday=~m/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) &&
       $rec->{soslanumclusttests}>0){
      $maxagedays=365/$rec->{soslanumclusttests};
      my $lday=$wf->ExpandTimeExpression($lastday,"en","GMT","GMT");
      if ($lday ne ""){
         my $duration=CalcDateDuration(NowStamp("en"),$lday);
         if (defined($duration) && $duration->{days}<($maxagedays*-1)){
            my $msg="age of ClusterServiceSwitch Test violates SLA definition";
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
