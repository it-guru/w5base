package itil::qrule::ApplSystems;
#######################################################################
=pod

=head3 PURPOSE

Every Application in in CI-Status "installed/active" or "available", needs
at least 1 logical system linked. If there are no logical systems assigned,
this will produce an error.
In some cases (applications witch ships licenses f.e.) you can set the
flag "application has no systems". In this case, this rule produces an
error, if logical systems are assinged.

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
   if (!$rec->{isnosysappl}){
      if (ref($rec->{systems}) ne "ARRAY" || $#{$rec->{systems}}==-1){
         return(3,{qmsg=>['no system relations'],
                   dataissue=>['no system relations']});
      }
   }
   return(0,undef);

}



1;
