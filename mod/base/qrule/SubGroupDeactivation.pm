package base::qrule::SubGroupDeactivation;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This quality rule deaktivates subgroups, if parentgroup is more
then 7 days "disposed of wasted"


=head3 HINTS

Deaktivation of subgroups, if parent group is more then 7 days
"disposed of wasted"

[de:]

Deaktivierung einer Untergruppe, wenn die Elterngruppe länger
als 7 Tage auf "veraltet/gelöscht" steht.

=cut
#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
   return(["base::grp"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=shift;

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   return(0,undef) if ($rec->{cistatusid}!=4);
   return(0,undef) if ($rec->{parentid} eq "");

   my $inactivategroup=0;

   $dataobj->ResetFilter();
   $dataobj->SetFilter({grpid=>\$rec->{parentid}});
   my ($prec,$msg)=$dataobj->getOnlyFirst(qw(fullname cistatusid mdate));

   if (!defined($prec)){
      $forcedupd->{cistatusid}=6;
      push(@qmsg,"not existing parent group - internal strukture error");
      $checksession->{EssentialsChangedCnt}++;
   }
   else{
      my $d=CalcDateDuration($prec->{mdate},NowStamp('en'));
      if ($d->{days}>7){ # parentgroup is in an stable state since 7 days
         if ($prec->{cistatusid}>5){
            $forcedupd->{cistatusid}=6;
            push(@qmsg,"parent group not active - deactivating group");
            $checksession->{EssentialsChangedCnt}++;
         }
      }
   }
   


   my @result=$self->HandleQRuleResults("none",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);

   return(@result);
}



1;
