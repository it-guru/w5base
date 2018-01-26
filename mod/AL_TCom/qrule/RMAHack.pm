package AL_TCom::qrule::RMAHack;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

The QualityRule checks for Interview questions qtag 
like "RMA_Risiko?_Question01" and relevant=0. If there 
are found these kind of anserws, all sub questions
to this answer will be set to relevant=0.
(A very bad hack for RMA)

=head3 IMPORTS

NONE

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

   my $exitcode=0;
   my $desc={qmsg=>[],solvtip=>[]};
   return($exitcode,$desc) if ($rec->{cistatusid}<1  || $rec->{cistatusid}>5);

   my $ia=getModuleObject($self->getParent->Config,"itil::lnkapplinteranswer");
   my $iaop=$ia->Clone();
   $ia->SetFilter({parentid=>\$rec->{id},
                   qtag=>"RMA_Risiko?_Question01",
                   relevant=>\'0'});
   my @a=$ia->getHashList(qw(qtag relevant));
   if ($#a!=-1){  # detect a given not relevant RMA risk - detail analyse needed
      my %praeflist;
      foreach my $a (@a){
          my $name=$a->{qtag};
          $name=~s/_Question.*$/_/;
          $praeflist{$name}=$a->{qtag};
      }
      #
      # analyse which qtags are answerable with RMA_Risiko?Question* Mask
      #
      my %q;
      foreach my $aq (@{$rec->{interviewst}->{TotalActiveQuestions}}){
         if ($aq->{qtag}=~m/^RMA_Risiko._Question.*$/){
            $q{$aq->{id}}={
               qtag=>$aq->{qtag},
               id=>$aq->{id}
            };
         }
      }
      $ia->ResetFilter();
      $ia->SetFilter({parentid=>\$rec->{id},
                      interviewid=>[keys(%q)]});
      my @given=$ia->getHashList(qw(qtag id relevant));

      foreach my $checkpraef (keys(%praeflist)){
         # analyse which qtags needs to be set to relevant=0 based on
         # the given ..._Question01 answer
         # _Question11 should not be changed
         my %need;
         foreach my $qrec (values(%q)){
            if ($qrec->{qtag} ne $praeflist{$checkpraef} &&
                 $qrec->{qtag} ne $checkpraef."Question11" &&
                 $qrec->{qtag} ne $checkpraef."Question999" &&
                ($qrec->{qtag}=~m/^$checkpraef.*/)){
               $need{$qrec->{qtag}}=$qrec->{id};
            }
         }
         foreach my $needtounrelevant (keys(%need)){
            my $found;
            foreach my $a (@given){
               if ($a->{qtag} eq $needtounrelevant){
                  if ($a->{relevant} eq "0"){
                     $found=0;
                  }
                  else{
                     $found=$a->{id};
                  }
               }
            }
            if (!defined($found)){
               $iaop->ValidatedInsertRecord({
                  interviewid=>$need{$needtounrelevant},
                  relevant=>'0',
                  parentid=>$rec->{id}
               });
            }
            elsif ($found eq "0"){
               #msg(INFO,"nothing needs to be done for $needtounrelevant");
            }
            else{
               $iaop->ValidatedUpdateRecord({
                  relevant=>'1'
               },{
                  relevant=>'0'
               },{id=>\$found});
            }
         }
      }
   }
   return($exitcode,$desc);
}




1;
