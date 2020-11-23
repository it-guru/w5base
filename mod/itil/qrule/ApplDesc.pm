package itil::qrule::ApplDesc;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Every application in CI-Status "installed/active" or "available" needs to
have an application description. If there is no application description
defined, an error will be produced.
If the description has less than 15 words, the description will taken
as not detailed enough. This will also create a DataIssue.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

Please enter a detailed description of the application. 
The description has to have more than 15 words. 

Accountable: Databoss, TSM

If you have any questions please contact the Darwin Support:
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001


[de:]

Bitte hinterlegen Sie eine detaillierte Beschreibung der Anwendung. 
Die Beschreibung muss aus mehr als 15 Worten bestehen. 

Verantwortlich: Datenverantwortlicher, TSM

Bei Fragen wenden Sie sich bitte an den DARWIN Support:
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
   return(['^.*::appl$']);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $exitcode=0;
   my $desc={qmsg=>[],solvtip=>[]};
   return($exitcode,$desc) if ($rec->{cistatusid}!=4 
                               && $rec->{cistatusid}!=3);
   return($exitcode,$desc) if ($rec->{allowifupdate}==1 &&
                               (lc($rec->{srcsys}) ne "w5base")); 
                                     # bei auto updates
                                     # kann der 
                                     # databoss keine
                                     # verantwortung für die beschreibung haben
                

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
      
   }
   return($exitcode,$desc);
}




1;
