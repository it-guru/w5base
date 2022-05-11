#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Validates the results in alle related installation monitoring
records in SIMon.

=head3 IMPORTS

NONE

=head3 HINTS

SIMon Inst Monitor

[de:]

SIMon Inst Monitor

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
package SIMon::qrule::InstPackMonCheck;
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
   return(["itil::system"]);
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


   my ($parrec,$msg);
   my $par=getModuleObject($self->getParent->Config(),"SIMon::lnkmonpkgrec");
   return(undef,undef) if (!$par->Ping());
   return(undef,undef) if ($rec->{cistatusid}<3 || $rec->{cistatusid}>5);

   $par->SetFilter({systemid=>\$rec->{id}});

   my @simonrec=$par->getHashList(qw(ALL));
   foreach my $irec (@simonrec){
      msg(INFO,"check SIMon Package:". $irec->{monpkg});
      if ($irec->{rawreqtarget} eq "MAND" &&
          $irec->{curinststate} eq "NOTFOUND"){
         if ($irec->{notifydate} ne "" ||    # es ging schon eine Mail raus
             $irec->{exception} ne "REJECTED"){ 
            my $inforunning=0;
            if ($irec->{exception} ne "REJECTED" && $irec->{notifydate} ne ""){
               my $d=CalcDateDuration($irec->{notifydate},NowStamp('en'));
               if ($d->{totaldays}<28){  #4 Wochen Mail bekommen - und nix inst.
                  $inforunning=1;
               }
            }
            if (!$inforunning){
               my $exceptreqvalid=0;
               if ($irec->{exception} eq "ACCEPTED" ||
                   $irec->{exception} eq "AUTOACCEPT"){
                  $exceptreqvalid=1;
               }
               if ($irec->{exception} ne "REJECTED"){
                  if ($irec->{exceptreqdate} ne ""){ # except beantragt
                     my $d=CalcDateDuration($irec->{exceptreqdate},
                                            NowStamp('en'));
                     if (defined($d) && $d->{totaldays}<28){
                        $exceptreqvalid=1;
                     }
                  }
               }
               if (!$exceptreqvalid){
                  my $msg="missing installation package: ".$irec->{monpkg};
                  push(@qmsg,$msg);
                  push(@dataissue,$msg);
                  $errorlevel=3 if ($errorlevel<3);
   
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


1;
