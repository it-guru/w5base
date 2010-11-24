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
      my ($arec,$msg)=$appl->getOnlyFirst(qw(cistatusid));
      if (!defined($arec)){
         push(@msg,"invalid application reference");
      }
      else{
         if ($arec->{cistatusid}>5 || $arec->{cistatusid}<2){
            push(@msg,"referenced application application is not active");
         }
      }
      if ($#msg!=-1){
         return(3,{qmsg=>[@msg],dataissue=>[@msg]});
      }
   }

   return(0,undef);

}




1;
