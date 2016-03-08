package base::qrule::ContactRights;
#######################################################################
=pod

=head3 PURPOSE

Checks if there is an "installed/active" CO-Number selected in
every application with CI-Status "installed/active" or "available".
If there is no valid CO-Number defined, an error will be procceeded.

=head3 IMPORTS

NONE

=head3 HINTS

[de:]

Bitte hinterlegen Sie mindestens einen Kontakt mit der Rolle "schreiben", 
der nicht gleichzeitig Datenverantwortlicher für diesen Datensatz ist. 

Verantwortlich: Datenverantwortlicher

Bei Fragen wenden Sie sich bitte an den Darwin Support:
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001


[en:]

Please enter at least one person, other than the current databoss, 
into the field Contacts with the role application write.

Accountable: Databoss

If you have any questions please contact the Darwin Support:
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001


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

   return(0,undef) if (!exists($rec->{cistatusid}) || $rec->{cistatusid}>5);
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
