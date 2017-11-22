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

Prüft und erweitert die Interview-Antworten im Themenblock DR-Test


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
      if ($changenumber=~/^C\d{5,9}$/){
         $wf->SetFilter({srcid=>\$changenumber,srcsys=>'*change'});
         my ($wfrec,$msg)=$wf->getOnlyFirst(qw(eventend));
         if (defined($wfrec)){
            my $qtag="SOB_004";
            my $day=$wfrec->{eventend};
            $day=~s/ .*$//; # cut of time
            my ($y,$m,$d)=$day=~m/(\d+)-(\d+)-(\d+)/;
            $day="$d/$m/$y";
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
      }
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
   if ($lastday ne "" && $planday ne ""){
      my $lday=$wf->ExpandTimeExpression($lastday,"en","GMT","GMT");
      my $pday=$wf->ExpandTimeExpression($planday,"en","GMT","GMT");
      if ($lday ne "" && $pday ne ""){
         my $duration=CalcDateDuration($lday,$pday);
         if (defined($duration) && $duration->{days}<0){
            my $msg="Disaster-Recovery Test plan date is bevor last test";
            push(@qmsg,$msg);
            push(@dataissue,$msg);
         }
      }
      if ($#qmsg==-1 && $pday ne ""){
         my $duration=CalcDateDuration(NowStamp("en"),$pday);
         if (defined($duration) && $duration->{days}<0){
            my $msg="Disaster-Recovery Test plan date is in the past";
            push(@qmsg,$msg);
            push(@dataissue,$msg);
         }
      }
      if ($#qmsg==-1 && $pday ne ""){
         my $duration=CalcDateDuration(NowStamp("en"),$pday);
         if (defined($duration) && $duration->{days}>365){
            my $msg="Disaster-Recovery Test plan date is to far in the future";
            push(@qmsg,$msg);
            push(@dataissue,$msg);
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
