package base::qrule::ContactRights;
#######################################################################
=pod

=head3 PURPOSE

Checks if there is an "installed/active" CO-Nummer is selected in
every application with an CI-Status "installed/active" or "available".
If there is no valid CO-Number defined, an error will be procceded.

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
   return([".*"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if ($rec->{cistatusid}>5);
   my $fo=$dataobj->getField("contacts");
   return(0,undef) if (!defined($fo));
   my $l=$fo->RawValue($rec);
   my $found=0;
   my $databossid=$rec->{databossid};
   if (ref($l) eq "ARRAY"){
      foreach my $crec (@$l){
         my $r=$crec->{roles};
         $r=[$r] if (ref($r) ne "ARRAY");
         if ($crec->{target} eq "base::grp" && grep(/^write$/,@$r)){
            $found++;
            last;
         }
         if ($crec->{target} eq "base::user" && grep(/^write$/,@$r) &&
             $databossid ne "" && $databossid ne $crec->{targetid}){
            $found++;
            last;
         }
      }
   }
   if (!$found){
      return(3,{qmsg=>['no additional contacts with role write registered'],
             dataissue=>['no additional contacts with role write registered']});
   }

   return(0,undef);
}



1;
