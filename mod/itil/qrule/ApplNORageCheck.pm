package itil::qrule::ApplNORageCheck;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks if the NOR verification is older then 365d. If the nor verification
is older or not anchored, a dataissue will be created.

=head3 IMPORTS

NONE

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
   return(["itil::applnor"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my $errorlevel=0;


   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);

   printf STDERR ("fifi appl=%s\n",$rec->{name});
   printf STDERR ("fifi appl cistatus=%s\n",$rec->{cistatusid});
   printf STDERR ("fifi isactive=%s\n",$rec->{isactive});
   printf STDERR ("fifi mdate=%s\n\n",$rec->{mdate});

   if ($rec->{isactive}==1){
      if ($rec->{mdate} eq ""){
         push(@qmsg,"no anchored NOR verification");
         $errorlevel=3 if ($errorlevel<3);
      }
      else{
         my $now=NowStamp("en");
         my $d=CalcDateDuration($now,$rec->{mdate},"GMT");
         my $max=6;
         if ($d->{days}<$max){
            my $m="NOR verification out of date - please create a new one";
            push(@qmsg,$m);
            $errorlevel=3 if ($errorlevel<3);
         }
      }
   }

   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@qmsg,\$errorlevel,$wfrequest));
}







1;
