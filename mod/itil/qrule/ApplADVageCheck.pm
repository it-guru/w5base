package itil::qrule::ApplADVageCheck;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

A ADV must exists for every application with cisatus=3|4 and an age
of more the 8 weeks.

=head3 IMPORTS

NONE

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
   return(["itil::appladv"]);
}

sub qcheckRecord
{  
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my $errorlevel=0;


   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);

   printf STDERR ("fifi appl=%s\n",$rec->{name});
   printf STDERR ("fifi appl cistatus=%s\n",$rec->{cistatusid});
   printf STDERR ("fifi isactive=%s\n",$rec->{isactive});
   printf STDERR ("fifi mdate=%s\n\n",$rec->{mdate});

   if ($rec->{isactive}==1){
      if ($rec->{mdate} eq ""){
         push(@qmsg,"no anchored ADV/NOR Vorgabe");
         $errorlevel=3 if ($errorlevel<3);
      }
   }

   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@qmsg,\$errorlevel,$wfrequest));
}




1;
