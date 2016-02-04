package base::qrule::CheckStateOfParentGroup;
#######################################################################
=pod

=head3 PURPOSE

Validates the parent of a group. If the parent is in state "disposed of waste"
and there are no child groups in current group, a DataIssue workflow will
be started.

=head3 IMPORTS

NONE

=head3 HINTS
No Hints

[de:]

Die Elterngruppe darf nicht im Status "veraltet/gelöscht" sein, wenn
die aktuelle Gruppe keine Untergruppen aufweist. 
Sollte die Elterngruppe "veraltet/gelöscht" sein, so muß die aktuelle
Gruppe ebenfalls "veraltet/gelöscht" gekennzeichnet werden, falls
nicht geklärt werden kann, "unter" welche neue Elterngruppe die aktuelle
Gruppe verschoben werden muß.

=cut
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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
   my $autocorrect=$checksession->{autocorrect};

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my $errorlevel=0;

   if ($rec->{cistatusid}<=5){
      if ($rec->{parentid} ne ""){
         if ($#{$rec->{subunits}}==-1){
            my $grp=$dataobj->Clone();
            $grp->SetFilter({grpid=>\$rec->{parentid}});
            my ($chkrec)=$grp->getOnlyFirst(qw(cistatusid grpid));
            if (!defined($chkrec) || $chkrec->{cistatusid}==6){
               push(@qmsg,"parrent group invalid or in deleted state");
            }
         }
      }
   }
   if ($#qmsg!=-1){
      $errorlevel=3 if ($errorlevel==0);
      return($errorlevel,{qmsg=>\@qmsg,dataissue=>\@qmsg});
   }
   return($errorlevel,undef);
}



1;
