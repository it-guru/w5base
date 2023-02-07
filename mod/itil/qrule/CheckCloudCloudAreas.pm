package itil::qrule::CheckCloudCloudAreas;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Validate if there are CloudAreas assigned to valid application with CI-Status
"available/in project" for a time longer then 8 weeks.

=head3 IMPORTS

NONE

=head3 HINTS
If there are CloudAreas assigned, the are need to 
be set as "installed/active" from the application write enabled team
to document the areas as used.

If the CloudAreas are assigned to the application in a wrong way, you
have to contact the cloud-admins to fix this mistake.

If "unclean processes" are permitted for a cloud, then only a minimal 
only a minimal check of the CI status of the CloudAreas or the 
applications or the applications listed therein is performed.


[de:]

Wenn einer Anwendung CloudAreas zugewiesen sind, müssen diese
von den Schreibberechtigten der Anwendung als "installiert/aktiv"
markiert werden, damit dokumentiert ist das diese Areas auch
wirklich von der Anwendung verwendet werden.
Sind bei einer Cloud "unsaubere Prozesse" zugelassen, dann wird
nur noch eine minimale Prüfung des CI-Status der CloudAreas 
bzw. der darin aufgeführten Anwendungen durchgeführt.

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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
   return(["itil::itcloud"]);
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


   my $now=NowStamp("en");
   if (ref($rec->{cloudareas}) eq "ARRAY"){
      my $appl=getModuleObject($self->getParent->Config,"itil::appl");
      foreach my $crec (@{$rec->{cloudareas}}){
         if (!($rec->{allowuncleanseq})){
            if ($crec->{cistatusid}==3){
               my $t=CalcDateDuration($crec->{mdate},$now,"GMT");
               if (!defined($t) || $t->{totaldays}>(8*7)){ # 6 weeks
                  my $msg="CloudArea has not been activated: ".
                          $crec->{fullname};
                  push(@qmsg,$msg);
                  push(@dataissue,$msg);
                  $errorlevel=3 if ($errorlevel<3);
               }
            }
         }
         if ($crec->{applid} ne ""){
            $appl->ResetFilter();
            $appl->SetFilter({id=>\$crec->{applid}});
            my ($arec,$msg)=$appl->getOnlyFirst(qw(id cistatusid));
            if (!defined($arec)){
               my $msg="invalid application in CloudArea: ".$crec->{fullname};
               push(@qmsg,$msg);
               push(@dataissue,$msg);
               $errorlevel=3 if ($errorlevel<3);
            }
            else{
               if ($arec->{cistatusid}>5){
                  my $msg="invalid application in CloudArea: ".
                          $crec->{fullname};
                  push(@qmsg,$msg);
                  push(@dataissue,$msg);
                  $errorlevel=3 if ($errorlevel<3);
               }
               if (!($rec->{allowuncleanseq})){
                  if ($arec->{cistatusid}<3){
                     my $msg=
                         "application not active or available in CloudArea: ".
                         $crec->{fullname};
                     push(@qmsg,$msg);
                     push(@dataissue,$msg);
                     $errorlevel=3 if ($errorlevel<3);
                  }
               }
            }
         }
         else{
            my $msg="missing application in CloudArea: ".$crec->{fullname};
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




1;
