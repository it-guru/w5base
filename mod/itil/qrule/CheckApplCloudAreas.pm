package itil::qrule::CheckApplCloudAreas;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Validate if there are CloudAreas assigned to current application with CI-Status
"available/in project" for a time longer then 6 weeks.

=head3 IMPORTS

NONE

=head3 HINTS
If there are CloudAreas assigned to the application, the are need to 
be set as "installed/active" from the application write enabled team
to document the areas as used.

If the CloudAreas are assigned to the application in a wrong way, you
have to contact the cloud-admins to fix this mistake.

If "unclean processes" are allowed with a cloud, the activation of 
a CloudArea after a few weeks then does not matter.


[de:]

Wenn einer Anwendung CloudAreas zugewiesen sind, müssen diese
von den Schreibberechtigten der Anwendung als "installiert/aktiv"
markiert werden, damit dokumentiert ist das diese Areas auch
wirklich von der Anwendung verwendet werden.

Falls die CloudAreas fälschlicher Weise der Anwendungen zugeordnet
wurden, muß Kontakt mit den Cloud-Admins aufgenommen werden, damit
diese den Fehler korrigieren.

Wenn bei einer Cloud "unsaubere Prozesse" zugelassen sind, ist die
Aktivierung einer CloudArea nach einigen Wochen dann egal.


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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

sub isCheckNeeded
{
   my $self=shift;
   my $rec=shift;

   return(0) if ($rec->{cistatusid}<3 || $rec->{cistatusid}>5);
   return(1);
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

   if (!$self->isCheckNeeded($rec)){
      return(undef,undef);
   }

   my @needToAct;

   my $now=NowStamp("en");
   if (ref($rec->{itcloudareas}) eq "ARRAY"){
      foreach my $crec (@{$rec->{itcloudareas}}){
         if ($crec->{cistatusid}!=4 && $crec->{cistatusid}<5){
            my $t=CalcDateDuration($crec->{cdate},$now,"GMT");
            if (!defined($t) || $t->{totaldays}>(2*7)){ # 2 weeks
               if ($crec->{allowuncleanseq}){
                  if ($t->{totaldays}<(10*7)){ # 10 weeks
                     push(@needToAct,$crec->{fullname});
                  }
               }
               else{
                  push(@needToAct,$crec->{fullname});
               }
            }
         }
      }
   } 

   if ($#needToAct!=-1){
      $errorlevel=3;
      my $msg="assigned CloudAreas need to be activated";
      push(@dataissue,$msg);
      push(@qmsg,$msg.":"); # add : to get a correct translation
      push(@qmsg,@needToAct);
   }

   my @result=$self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}




1;
