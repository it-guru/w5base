package tscape::qrule::compareICTO;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This quaity rule compares the specified ICTO ID to CAPE. A DataIssue
will be produced, if the ICTO Objekt doesn't exist in CAPE or it
is marked as "Retired" (if the application is in CI-status 3 or 4)

=head3 IMPORTS

- name of cluster

=head3 HINTS

Every application needs an ICTO-ID. This ID must be provided by 
IT architecture by means of the tool CAPE.

The application manager should know the ICTO-IDs of his applications. 

In case that you cannot determine the ICTO-ID  
please contact the Helpdesk ...

https://darwin.telekom.de/darwin/auth/base/user/ById/14549173480001

If you are sure that an application is not relevant for architecture 
and is not configured in CAPE (i.e. pure technical applications 
that provide technical access to networks) , then there is the 
possibility - in the configuration data of the application - 
to set the flag  "Application is not architecture relevant" to "yes".

So there are two possibilities of providing correct data 
concerning the architecture relevance of an application:

1. The application is architecture relevant, then 
the attribute  "Application is not architecture 
relevant" has to be set to "no" and a valid ICTO-ID has to 
be entered.

2. The application is not architecture relevant, then 
the attribute "Application is not architecture relevant" has 
to be set to "yes" and you are not allowed to enter an 
ICTO-ID, i.e. you must delete the actual ICTO-ID, if one 
has been given already.  If the existing entry in the 
field "Application is not IT architecture relevant" has to 
be changed, please contact the mailbox "FMB SACM.TelekomIT" 
 mailto:SACM.TelekomIT@telekom.de

The rule which lead to this issue won't be executed on 
this application anymore. 

If the ICTO-ID can not be entered, it may be because this 
default is not provided from Cape. In this case please 
contact the "FMB SD-PQIT-NC" and ask to provide 
the ICTO-ID for the entry in Darwin.

[de:]

Jede Anwendung benötigt eine ICTO-ID. Diese wird von der 
IT-Architektur über das Tool CAPE vergeben. 
Der Application-Manager einer Anwendung sollte die 
betreffende ICTO-ID seiner Anwendung kennen.

Sollte die ICTO-ID nicht bekannt sein, 
kontaktieren Sie bitte den HelpDesk:

https://darwin.telekom.de/darwin/auth/base/user/ById/14549173480001

Sollte sicher sein, dass eine Anwendung nicht durch die 
IT-Architektur erfasst wird (z.B. eine rein technische Anwendung 
die technischen Zugang zu Netzwerken ermöglicht), so muss in 
den Config-Daten der Anwendung das Feld "Anwendung ist 
nicht IT-Architektur relevant" = "Ja" gesetzt werden.

Es gibt also zwei Möglichkeiten für die korrekte Angabe der 
Architektur-Relevanz einer Anwendung:

1. Die Anwendung ist IT-Architektur-relevant, 
dann muss das Attribut "Anwendung ist nicht IT-Architektur 
relevant" auf "nein" gesetzt werden und es muss eine 
gültige ICTO-ID angegeben werden.

2. Die Anwendung ist nicht IT-Architektur-relevant, 
dann muss das Attribut "Anwendung ist nicht IT-Architektur 
relevant" auf "ja" gesetzt werden und es darf keine 
ICTO-ID angegeben werden. Muss eine Änderung des vorhandenen 
Eintrages an dem Feld "Anwendung ist nicht IT-Architektur relevant" 
vorgenommen werden, so kontaktieren Sie bitte das 
Postfach "FMB SACM.TelekomIT"
 mailto:SACM.TelekomIT@telekom.de

Die Regel, die zu diesem Data-Issue führte, wird dann auf 
die Anwendung nicht mehr angewendet.

Sollte die ICTO-ID nicht erfasst werden können, kann es daran 
liegen, dass diese Default nicht aus Cape zur Verfügung 
gestellt wird. In diesem Fall wenden Sie sich bitte an 
das "FMB SD-PQIT-NC" und bitten um Bereitstellung der 
ICTO-ID, um den Eintrag in Darwin durchführen zu können.


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
   return(["TS::appl","AL_TCom::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=0;
   if (ref($checksession) eq "HASH"){
      $autocorrect=$checksession->{autocorrect};
   }

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
      return(undef,undef) if ($par->isSuspended());
      return(undef,undef) if (!$par->Ping());
      $par->SetFilter({archapplid=>\$rec->{ictono}});
      my ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      return(undef,undef) if (!$par->Ping());
      if (!defined($parrec)){
         my $msg="the given ICTO-ID does not exist anymore in CAPE";
         push(@qmsg,$msg);
         push(@dataissue,$msg);
         $errorlevel=3 if ($errorlevel<3);
      }
      else{
         if (lc($parrec->{status}) eq lc("Retired")){

            my $retiredReached=1;
            if ($retiredReached){
               my $msg="the given ICTO-ID is marked as retired in CAPE";
               push(@qmsg,$msg);
               push(@dataissue,$msg);
               $errorlevel=3 if ($errorlevel<3);
            }
         }
      }
   }

   # isnotarchrelevant

   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}



1;
