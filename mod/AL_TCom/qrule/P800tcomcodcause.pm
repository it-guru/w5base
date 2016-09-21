package AL_TCom::qrule::P800tcomcodcause;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

If there is an customercontract affected from the workflow to check,
there is P800 cause need to qualify. The cause "undefined Service" isn't
allowed.
P800 rules are only needed, if one of the affected applications of
the workflow is based on a P800 customer contract and these contract
is for customer DTAG.*

=head3 IMPORTS

NONE

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2007  Hartmut Vogler (it@guru.de)
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
   return(["AL_TCom::workflow::change",
           "AL_TCom::workflow::incident",
           "AL_TCom::workflow::businesreq",
           "AL_TCom::workflow::diary"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $exitcode=0;
   my $desc={qmsg=>[],solvtip=>[]};
   my @msg=();

   if ($rec->{stateid}<=21){  # check all
      if ($rec->{affectedcontractid} ne ""){
         my $contractid=$rec->{affectedcontractid};
         if (ref($contractid) ne "ARRAY"){ 
            $contractid=[$contractid];
         }
         if ($#{$contractid}!=-1){
            my $isp800needed=1;
            my $contr=$self->getPersistentModuleObject("AL_TCom::custcontract");
            $contr->SetFilter({id=>$contractid});
            my $oldcontracts=0;
            foreach my $cr ($contr->getHashList(qw(p800opmode cistatusid 
                                                   customer))){
               if ($cr->{cistatusid}!=4){
                  $oldcontracts++;
               }
               if ((($cr->{customer}=~m/^DTAG$/) ||
                    ($cr->{customer}=~m/^DTAG\..*$/)) &&
                   $cr->{p800opmode} ne ""){
                  $isp800needed++;
                  last;
               }
            }
            if ($oldcontracts){
               push(@msg,'found inactive or old customer contracts');
               $exitcode=3;
            }
            if ($isp800needed){
               if ($rec->{class} eq "AL_TCom::workflow::businesreq" ||
                   $rec->{tcomcodrelevant} eq "yes"){
                  if ($rec->{tcomcodcause} eq "" || 
                      $rec->{tcomcodcause} eq "undef"){
                     push(@msg,'insufficient cause description');
                     $exitcode=3;
                  }
                  my $cmt=$rec->{tcomcodcomments};
                  if ($rec->{tcomworktime}>0){ # min 15 Zeichen mit 0-9 und a-z Zeichen
                     my $cmt1=$cmt;
                     $cmt1=~s/\s//g;
                     if (!($cmt1=~m/[a-z,0-9]{15,}/i)){
                        push(@msg,'description of work to short');
                        $exitcode=3;
                     }
                     if ($exitcode<3){
                        if (!(($cmt1=~m/[0-9]/)&&($cmt1=~m/[a-z]/i))){ 
                           push(@msg,
                                'description of work not detailed enougth');
                           $exitcode=3;
                        }
                     }
                  }
                  if ($rec->{tcomworktime}>0){ # max. 1024 Zeichen
                    if (length($cmt)>1024){
                        push(@msg,"description of work to long ".
                                  "(bFlexx can handle max. 1024 char)");
                        $exitcode=3;
                    }
                  }
                  my $f='(\d{1,2}\.\d{1,2}.\d\d\d\d\s+von\s+\d{1,2}:\d\d(\s*h){0,1}\s+bis\s+\d{1,2}:\d\d(\s*h){0,1}|\d{1,2}\.\d{1,2}.\d\d\d\d\s+\d{1,2}:\d\d(\s*h){0,1}\s+-\s+\d{1,2}:\d\d(\s*h){0,1})(\n|$)';
                  if ($rec->{tcomcodcause} eq "appl.add.baseext"){
                     if (($rec->{tcomworktime}>0) &&
                         !($cmt=~m/$f/)){
                        push(@msg,"invalid delivery timerange");
                        $exitcode=3;
                     }
                     $cmt=~s/$f\s*//s;
                     my $externalid=$rec->{tcomexternalid};
                     if ($rec->{class} eq "AL_TCom::workflow::businesreq"){
                        $externalid=$rec->{customerrefno};
                     }
                     if (!($externalid=~m/(^|\s)IN:[0-9,-]{5,8}(\s|$)/)){
                        push(@msg,"invalid I-Network reference - ExternalID");
                        push(@msg,"ExternalID:'".$rec->{tcomexternalid}."'");
                        $exitcode=3;
                     }
                     my $sum=0;
                     my $z=0;
                     foreach my $l (split(/[\r\n]+/,$cmt)){
                        $z++;
                        $l=~s/\s*$//;
                        if (length($l)>80){
                           push(@msg,"detail description line to long: $z");
                        }
                        if ($l ne ""){
                           my $n=1;
                           my $h=undef;
                           if (my (undef,$anz)=$l=~
                               m/(^|\s)(\d+)MA(\s|$)/){
                              $n=$anz;
                           }
                           if (my ($a,$anz,$b)=$l=~
                               m/(^|\s)(\d+(,\d+){0,1})h(\s|$)/){
                              $anz=~s/,/./g;
                              $h=$anz;
                           }
                           my $t=$n*($h*60);
                           $sum+=$t;
                        }
                     }
                     if ($sum!=$rec->{tcomworktime}){
                        push(@msg,"worktime did not match sum of details");
                        push(@msg,"worktime:$rec->{tcomworktime} ".
                                  "!= detail:$sum");
                        $exitcode=3;
                     }
                  }
               }
            }
         }
      }
   }
   if ($#msg!=-1){
      push(@msg,"please contact Mr. Grewing Burkhard, ".
                "if you got questions to this messages");
      push(@{$desc->{qmsg}},@msg);
      push(@{$desc->{dataissue}},@msg);
   }

   return($exitcode,$desc);
}




1;
