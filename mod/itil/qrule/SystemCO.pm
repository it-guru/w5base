package itil::qrule::SystemCO;
#######################################################################
=pod

=head3 PURPOSE

Checks if there is an "installed/active" Costcenter is selected in
every application with an CI-Status "installed/active" or "available".
If there is no valid Costcenter defined, an error will be procceded.

=head3 IMPORTS

NONE

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
   my $coobj=getModuleObject($self->getParent->Config,"itil::costcenter");
   if (!($coobj->ValidateCONumber($dataobj->Self,"conumber",$rec,undef))){
      return(3,{qmsg=>['no valid costcenter'],
                dataissue=>['no valid costcenter']});
   }
   else{
      $coobj->SetFilter({cistatusid=>4,name=>\$rec->{conumber}});
      my ($rec,$msg)=$coobj->getOnlyFirst(qw(id));
      if (!defined($rec)){
         return(3,{qmsg=>['costcenter object is empty or record not installed/active'],
            dataissue=>['costcenter object is empty or record not installed/active']});
      }
   }
   return(0,undef);

}



1;
