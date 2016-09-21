package tswiw::qrule::ParentOrgUnit;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Validates the parent child structur of org-units against WhoIsWho.

=head3 IMPORTS

NONE

=cut
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
   return(["base::grp"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $errorlevel=undef;
   my @qmsg;

   if ($rec->{cistatusid}==4){
      if ($rec->{srcsys} eq "WhoIsWho"){
         if ($rec->{srcid} eq ""){
            push(@qmsg,"srcid is not defined");
            return(3,{qmsg=>\@qmsg,dataissue=>\@qmsg});
         }
         $errorlevel=0;
         my $wiw=getModuleObject($self->getParent->Config(),"tswiw::orgarea");
         $wiw->SetFilter({touid=>\$rec->{srcid}});
         my ($wiwrec,$msg)=$wiw->getOnlyFirst(qw(ALL));
         if (!defined($wiwrec)){
            push(@qmsg,"orgunit id not found in WhoIsWho");
            return(3,{qmsg=>\@qmsg,dataissue=>\@qmsg});
         }
         if ($rec->{parentid} ne "" && $wiwrec->{parentid} ne ""){
            my $grp=getModuleObject($self->getParent->Config(),"base::grp");
            $grp->SetFilter({grpid=>\$rec->{parentid}});
            my ($prec,$msg)=$grp->getOnlyFirst(qw(ALL));
            if (defined($prec)){
               if ($prec->{srcsys} eq "WhoIsWho" &&
                   $prec->{srcid} ne $wiwrec->{parentid}){
                  push(@qmsg,"parent unit in WhoIsWho doesn't matches");
                  push(@qmsg,"parent ID in WhoIsWho is: ",$wiwrec->{parentid});
                  return(3,{qmsg=>\@qmsg,dataissue=>\@qmsg});
               }
            }
         }
         $errorlevel=0;
      }
      else{
         push(@qmsg,"no group with WhoIsWho authority");
      }

   }
   return($errorlevel,{qmsg=>\@qmsg});
}



1;
