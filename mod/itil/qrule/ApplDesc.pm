package itil::qrule::ApplDesc;
#######################################################################
=pod

=head3 PURPOSE

Every application in CI-Status "installed/active" or "available" need to
have an application description. If there is no application description
defined, an error will be produced.

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
   return(['^.*::appl$']);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $exitcode=0;
   my $desc={qmsg=>[],solvtip=>[]};
   return($exitcode,$desc) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);

   if ($rec->{description}=~m/^\s*$/){
      $exitcode=3 if ($exitcode<3);
      push(@{$desc->{qmsg}},
           $self->T('there is no description defined'));
      push(@{$desc->{dataissue}},
           $self->T('there is no description defined'));
      push(@{$desc->{solvtip}},
           $self->T('descripe the application'));
   }
   else{
      my @words=grep(/\S{3}/,split(/\s+/,$rec->{description}));
      if ($#words<15){
         my $msg="description is not detailed enough";
         push(@{$desc->{dataissue}},$msg);
         push(@{$desc->{qmsg}},$msg);
         $exitcode=3 if ($exitcode<3);
      }
      
      printf STDERR ("fifi $#words words=%s\n",join(";",@words)); 
   }
   return($exitcode,$desc);
}




1;
