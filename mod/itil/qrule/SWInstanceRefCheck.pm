#######################################################################
=pod

=head3 PURPOSE

Checks the related application (and in the further the system too)
to the current instance is "active".

=head3 IMPORTS

NONE

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2009  Hartmut Vogler (it@guru.de)
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
package itil::qrule::SWInstanceRefCheck;
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
   return(["itil::swinstance"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if ($rec->{'cistatusid'}!=4 && 
                       $rec->{'cistatusid'}!=5 &&
                       $rec->{'cistatusid'}!=3);
   if ($rec->{applid} ne ""){
      my @msg;
      my $appl=getModuleObject($self->getParent->Config,"itil::appl");
      $appl->SetFilter({id=>\$rec->{applid}});
      my ($arec,$msg)=$appl->getOnlyFirst(qw(cistatusid id));
      if (!defined($arec)){
         push(@msg,"invalid application reference");
      }
      else{
         if ($arec->{cistatusid}>5 || $arec->{cistatusid}<2){
            push(@msg,"referenced application application is not active");
         }
      }
      if (defined($arec)){ # further checks are only needed, if appl found
         if ($rec->{runonclusts}){   # now do cluster checks
            if ($rec->{itclusts} eq ""){
               push(@msg,"no cluster service specified");
            }
            else{
               my $c=getModuleObject($self->getParent->Config,
                                     "itil::lnkitclustsvcappl");
               my $clustsid=$rec->{itclustsid};
               my $applid=$arec->{id};
               $c->SetFilter({itclustsvcid=>\$clustsid,applid=>\$applid});
               my ($chkrec,$msg)=$c->getOnlyFirst(qw(id));

               if (!defined($chkrec)){
                  push(@msg,"application does not match application ".
                            "in cluster service");
               }
            }
         }
         else{                       # now do system checks
            if ($rec->{system} eq ""){
               push(@msg,"no system specified");
            }
            else{
               my $c=getModuleObject($self->getParent->Config,
                                     "itil::lnkapplsystem");
               my $systemid=$rec->{systemid};
               my $applid=$arec->{id};
               $c->SetFilter({systemid=>\$systemid,applid=>\$applid});
               my ($chkrec,$msg)=$c->getOnlyFirst(qw(id));

               if (!defined($chkrec)){
                  push(@msg,"application does not match application ".
                            "in system");
               }
            }
         }
      }




      if ($#msg!=-1){
         return(3,{qmsg=>[@msg],dataissue=>[@msg]});
      }
   }

   return(0,undef);

}




1;
