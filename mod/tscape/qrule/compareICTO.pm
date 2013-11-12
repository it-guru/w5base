package tscape::qrule::compareICTO;
#######################################################################
=pod

=head3 PURPOSE

This qulaity rule compares the specified ICTO ID to CapeTS. A DataIssue
will be produced, if the ICTO Objekt doesn't exists in CapeTS or it
is marked as "Retired" (if the application is in CI-status 3 or 4)

=head3 IMPORTS

- name of cluster

=head3 HINTS

Every application needs an ICTO-Id. This Id must be provided by 
IT architecture by means of the tool CapeTS.

The application manager should know the ICTO-Ids of his applications. 

In the case that you cannot determine the ICTO-Id  
please contact Mr. Krohn ...

https://darwin.telekom.de/darwin/auth/base/user/ById/13627534400001  .

In case of problems determining the ICTO-Id please 
contact  Mr. Striepecke ...

https://darwin.telekom.de/darwin/auth/base/user/ById/13401048580000  .

If you are sure that an application is not relevant for architecture 
and is not configured in CapeTS (i.e. pure technical applications 
that provide technical access to networks) , then there is the 
possibility - in the configuration data of the application - 
to set the flag  " Application is not architecture relevant:" to  "yes".

The rule which lead to this issue won't be executed on 
this application anymore. 

[de:]

Jede Anwendung benötigt eine ICTO-ID. Diese wird von der 
IT-Architektur über das Tool CapeTS vergeben. 
Der Application-Manager einer Anwendung sollte die 
betreffende ICTO-ID seiner Anwendung kennen.

Sollte die ICTO-ID nicht bekannt sein, so kann 
diese über Hr. Krohn ...

https://darwin.telekom.de/darwin/auth/base/user/ById/13627534400001

... erfragt werden. Sollte es Probleme bei der Ermittlung 
der ICTO-ID geben, so können Sie Hr. Striepecke ...

https://darwin.telekom.de/darwin/auth/base/user/ById/13401048580000

... kontaktieren.

Sollte sicher sein, dass eine Anwendung nicht durch die 
IT-Architektur erfasst wird (z.B. ein rein technische Anwendung 
die technischen Zugang zu Netzwerken ermöglicht), so muß in 
den Config-Daten der Anwendung das Feld "Anwendung ist 
nicht IT-Architektur relevant" = "Ja" gesetzt werden.

Die Regel, die zu diesem Data-Issue führte, wird dann auf 
die Anwendung nicht mehr angewendet.


=cut
#######################################################################
#
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
   return(["AL_TCom::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $autocorrect=shift;

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   return(0,undef) if (!($rec->{cistatusid}==3 || $rec->{cistatusid}==4));

   
   if ($rec->{isnotarchrelevant}){
      if ($rec->{ictono} ne ""){
         my $msg="found ICTO-ID on an non architecture relevant application";
         push(@qmsg,$msg);
         push(@dataissue,$msg);
         $errorlevel=3 if ($errorlevel<3);
      }
   }
   else{
      if ($rec->{ictono} eq ""){
         my $msg="missing ICTO-ID";
         push(@qmsg,$msg);
         push(@dataissue,$msg);
         $errorlevel=3 if ($errorlevel<3);
      }
   }


   if ($rec->{ictono} ne ""){
      my $par=getModuleObject($self->getParent->Config(),"tscape::archappl");
      $par->SetFilter({archapplid=>\$rec->{ictono}});
      my ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      return(undef,undef) if (!$par->Ping());
      if (!defined($parrec)){
         my $msg="the given ICTO-ID does not exist anymore in CapeTS";
         push(@qmsg,$msg);
         push(@dataissue,$msg);
         $errorlevel=3 if ($errorlevel<3);
      }
      else{
         if (lc($parrec->{status}) eq lc("Retired")){
            my $msg="the given ICTO-ID is marked as retired in CapeTS";
            push(@qmsg,$msg);
            push(@dataissue,$msg);
            $errorlevel=3 if ($errorlevel<3);
         }
      }
   }

   # isnotarchrelevant

   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}



1;
