package kernel::Field::InterviewState;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
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
use kernel::InterviewField;
use kernel::Field::Textarea;
@ISA    = qw(kernel::Field::Select kernel::InterviewField);


sub new
{
   my $type=shift;
   my $self={@_};
   $self->{group}='interview'              if (!defined($self->{qc}));
   $self->{name}='interviewst'             if (!defined($self->{name}));
   $self->{label}='Interview state'        if (!defined($self->{label}));
   $self->{history}=0;
   $self->{readonly}=1;
   $self->{htmldetail}=0;
   $self->{searchable}=0;
   $self->{onRawValue}=\&onRawValue;
   my $o=bless($type->SUPER::new(%$self),$type);
   return($o);
}

sub onRawValue
{
   my $self=shift;
   my $current=shift;
   my $parent=$self->getParent();
   my $idname=$parent->IdField->Name();
   my $id=$current->{$idname};
   my $parent=$self->getParent->SelfAsParentObject();
   my $answered=$self->getAnsweredQuestions($parent,$idname,$id);
   my $total=$self->getTotalActiveQuestions($parent,$idname,$id,$answered);


   my $totalcnt=$#{$total}+1;
   my $todo=0;
   my $outdated=0;
   my %pendingInterviewPartner=();
   if ($totalcnt>0){
      foreach my $q (@{$total}){
         if (!exists($answered->{interviewid}->{$q->{id}})){
            $todo++;
            $pendingInterviewPartner{$q->{boundpcontact}}->{todo}++;
         }
         else{
            if ($answered->{interviewid}->{$q->{id}}->{needverify}){
               $outdated++;
               $pendingInterviewPartner{$q->{boundpcontact}}->{outdated}++;
            }
         }
      }
   }
   my $state={TotalActiveQuestions=>$total,
              total=>$totalcnt, todo=>$todo, outdated=>$outdated,
              pendingInterviewPartner=>\%pendingInterviewPartner,
              AnsweredQuestions=>$answered};
   my %qStat;
   tie(%qStat,'kernel::Field::InterviewState::qStat',%$state);
   $state->{'qStat'}=\%qStat;
              
   return($state);
}

sub FormatedResult
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);

   my $totalcnt=$d->{total};
   my $todo=$d->{todo};
   my $outdated=$d->{outdated};
   $totalcnt="0" if (!defined($totalcnt));
   $todo="0" if (!defined($todo));
   $outdated="0" if (!defined($outdated));
   if (($mode=~m/^Html/) || ($mode=~m/^Xls/)){
      return("Total: $totalcnt / Open: $todo / Outdated: $outdated");
   }
   return({total=>$totalcnt,
           todo=>$todo,
           outdated=>$outdated,
           qStat=>$d->{qStat},
           questStat=>$d->{questStat}});
}


package kernel::Field::InterviewState::qStat;

use strict;
use vars qw(@ISA);
use kernel;
use Tie::Hash;

@ISA=qw(Tie::Hash);

sub TIEHASH
{
   my $type=shift;
   my $self=bless({@_},$type);
   return($self);
}

sub FIRSTKEY
{
   my $self=shift;

   $self->{s}=$self->dynCalc() if (!defined($self->{s}));

   $self->{'keylist'}=[keys(%{$self->{s}})];
   return(shift(@{$self->{'keylist'}}));
}

sub NEXTKEY
{
   my $self=shift;
   return(shift(@{$self->{'keylist'}}));
}

sub FETCH
{
   my $self=shift;
   my $key=shift;
   $self->{s}=$self->dynCalc() if (!defined($self->{s}));
   return($self->{s}->{$key});
}


sub STORE
{
   my $self=shift;
   my $key=shift;
   my $value=shift;
   $self->{s}->{$key}=$value;
   return($self->{s}->{$key});
}


sub dynCalc
{
   my $self=shift;

   my $s=0.00;
   my $total=$#{$self->{TotalActiveQuestions}}+1;
   my $nsum=0;
   my %qstat;
   my @notrelevant;
   my $activeQuestions={};

   foreach my $q (@{$self->{TotalActiveQuestions}}){
      $activeQuestions->{id}->{$q->{id}}=$q;
      $activeQuestions->{qtag}->{$q->{qtag}}=$q;
      $qstat{$q->{id}}=0.0;
      my $prio=$q->{prio};
      $prio=100 if ($q->{prio} eq "");  # if prio=undef use 100 (uninteressing)
      my $curs=0.0;
      my $a=undef;
      if (exists($self->{AnsweredQuestions}->{interviewid}->{$q->{id}})){
         $a=$self->{AnsweredQuestions}->{interviewid}->{$q->{id}};
      }
      if (defined($a)){
         #if ($q->{questtyp} eq "booleana"){
         #   if (defined($a)){
         #      $curs=100.0;
         #   }
         #}
         #elsif ($q->{questtyp} eq "boolean"){
         #   if (defined($a) &&  $a->{answer} eq "1"){
         #      $curs=100.0;
         #   }
         #   else{
         #      $curs=0.0;
         #   }
         #}
         #elsif ($q->{questtyp} eq "percenta"){
         #   if (defined($a)){
         #      $curs=100.0;
         #   }
         #}
         #elsif ($q->{questtyp} eq "percent" ||
         #       $q->{questtyp} eq "percent4"){
         #   if (defined($a) && $a->{answer} ne ""){
         #      $curs=$a->{answer};
         #   }
         #   else{
         #      $curs=0.0;
         #   }
         #}
         #elsif ($q->{questtyp} eq "date"){
         #   if (defined($a) &&
         #       $a ne "" &&
         #       ($a=~m/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/)){
         #      $curs=100.0;
         #   }
         #   else{
         #      $curs=0.0;
         #   }
         #}
         #else{
         #   if (defined($a) && $a->{answer} ne ""){
         #      $curs=100.0;
         #   }
         #   else{
         #      $curs=0.0;
         #   }
         #}
         $curs=$a->{answerlevel};
         my $n=1;
         $n=5 if ($prio==1);
         $n=2  if ($prio==2);
         $qstat{$q->{id}}=$curs;
         $s=$s+($curs*$n);
         $nsum+=$n;
      }
      else{
         $qstat{$q->{id}}=0;
      }
      if (defined($a) && !$a->{relevant}){
         push(@notrelevant,$q->{id});
      }
   }
   if ($nsum==0){
      $s=100.0;
   }
   else{
      $s=$s/$nsum;
   }
   my %s=(
      totalStat=>$s,
      questStat=>\%qstat,
      activeQuestions=>$activeQuestions,
      notrelevant=>\@notrelevant
   );

   return(\%s);
}









1;
