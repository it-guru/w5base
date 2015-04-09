package itil::qrule::SystemAppls;
#######################################################################
=pod

=head3 PURPOSE

Every System in CI-Status "installed/active" or "available", needs
at least 1 link to an application. If there are no applications assigned,
this will produce an error. In this case the databoss of the logical
system has to contact one (the corret one) databoss of an application
to assign the system to the application.
This rule is inactive, if the system is a workstation and no server/applicationserver.
This rule is also inactive, if the system is a infrastructure system
and there is a sufficient description documented in comments.


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
   return(["itil::system"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);
   return(0,undef) if (!($rec->{isapplserver}) && ($rec->{isworkstation}));

   if ($rec->{isinfrastruct}) {
      my $wcnt=split(/\s+/,$rec->{comments});

      if ($wcnt<10) {
         my $msg='description in field comments '.
                 'not available resp. insufficient';
         return(3,{qmsg=>[$msg],dataissue=>[$msg]});
      }

      return(0,undef);
   }

   if (ref($rec->{applications}) ne "ARRAY" || $#{$rec->{applications}}==-1){
      return(3,{qmsg=>['no application relations'],
                dataissue=>['no application relations']});
   }
   return(0,undef);

}



1;
