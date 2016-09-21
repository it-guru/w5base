package itil::qrule::URLlist;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Check if there are software instances on an application with CI-Status
"available/in project", "installed/active" or "inactiv/stored"
and no application URLs are registered.

=head3 IMPORTS

NONE

=head3 HINTS
If there are software-instances of type ... 
Apache, SunONE, IIS, OpenLDAP, LDAP-Server
... in CI-Status "installed/active" it is mandatory to enter
at least one communication URL.


[de:]

Wenn es bei einer Anwendung Software-Instanzen vom Type ...
Apache, SunONE, IIS, OpenLDAP, LDAP-Server
... im Status "installiert/aktiv" gibt,
muss es auch min. eine Anwendungs-URL geben.



=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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

sub isURLlistCheckNeeded
{
   my $self=shift;
   my $rec=shift;

   return(0) if ($rec->{cistatusid}<3 || $rec->{cistatusid}>5);
   return(1);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   if (!$self->isURLlistCheckNeeded($rec)){
      return(0,undef);
   }

   my $urlswi=0;
   my @needed=qw(Apache SunONE IIS OpenLDAP LDAP-Server);
   foreach my $swi (@{$rec->{swinstances}}){
      next if ($swi->{cistatusid}!=4);
      if (in_array(\@needed,$swi->{swnature})){
         $urlswi++;
      }
   }
   if ($urlswi>0 && $#{$rec->{applurl}}==-1){
      $errorlevel=3;
      my $msg="missing communication urls in application documentation";
      push(@dataissue,$msg);
      push(@qmsg,$msg);
   }

   my @result=$self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}




1;
