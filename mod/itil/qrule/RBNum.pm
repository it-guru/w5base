package itil::qrule::RBNum;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Every Element in CI-Status "installed/active" or "available", must
have call on duty phone number registered in phonenumber list, if
the service&support class presupposes a call on duty service.

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
   return(["itil::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);
   if ($rec->{servicesupportid} ne ""){
      my $s=$self->getParent->getPersistentModuleObject("itil::servicesupport");
      $s->SetFilter({id=>\$rec->{servicesupportid}});
      my ($srec,$msg)=$s->getOnlyFirst(qw(ALL));
      if (defined($srec) && $srec->{isoncallservice}==1){
         my $found=0;
         if (ref($rec->{phonenumbers}) eq "ARRAY"){
            foreach my $prec (@{$rec->{phonenumbers}}){
               if ($prec->{name} eq "phoneRB"){
                  $found=1;last;
               }
            }
         }
         if (!$found){
            my $m="missing on call service phone number";
            return(3,{qmsg=>[$m],dataissue=>[$m]});
         }
      }
   }
   return(0,undef);

}



1;
