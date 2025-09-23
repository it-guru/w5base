package TeamLeanIX::qrule::compareApplMgr;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This quality rule compares the Application Manager specified in 
the ICTO Object on T.EAM to the ApplicationManager entry in
a BusinessApplication.

=head3 IMPORTS

- name of cluster

=head3 HINTS

[en:]

The Application Manager is responsible for an application, 
specified by the associated ICTO object from T.EAM.

This QualityRule ensures that in W5Base/Darwin the same 
Application Manager is registered.

Should be the wrong Application Manager reported by this rule, 
this may be due to an incorrect entry in T.EAM or a wrong number 
of ICTO application entry in W5Base/Darwin.

IT architecture awarded via the tool T.EAM.

Please contact the support of T.EAM ...

https://darwin.telekom.de/darwin/auth/base/user/ById/14549226710001


[de:]

Der für eine Anwendung verantwortliche ApplicationManager 
wird durch das zugehörige ICTO-Objekt aus T.EAM vorgegeben.

Diese QualityRule stellt sicher, dass in W5Base/Darwin der
gleiche ApplicationManager eingetragen ist.

Sollte der falsche ApplicationManager durch diese Regel gemeldet
werden, kann dies an einem Fehleintrag in T.EAM oder einer
falschen ICTO Nummer beim Anwendungseintrag in W5Base/Darwin
liegen.

IT-Architektur über das Tool T.EAM vergeben. 

Bitte kontaktieren Sie den Support von T.EAM ...

https://darwin.telekom.de/darwin/auth/base/user/ById/14549226710001


=cut
#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2025  Hartmut Vogler (it@guru.de)
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
   my $autocorrect=$checksession->{autocorrect};

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   return(0,undef) if ($rec->{cistatusid}>5);

   $autocorrect=1;

   if ($rec->{opmode} eq "prod" && $rec->{ictono} ne ""){
      delete($rec->{contacts}); # ensure contacts are new loaded
      my $par=getModuleObject($self->getParent->Config(),"TeamLeanIX::gov");
      return(undef,undef) if ($par->isSuspended());
      return(undef,undef) if (!$par->Ping());
      $par->SetFilter({ictoNumber=>\$rec->{ictono}});
      my ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      return(undef,undef) if (!$par->Ping());
      if (defined($parrec)){
         my $user=getModuleObject($self->getParent->Config,"base::user");
         if ($parrec->{applmgremail} ne "" &&
             ($parrec->{applmgremail}=~m/\@/)  &&          # looks like a email
             !($parrec->{applmgremail}=~m/^pn-dup.*\@external.*$/) # no pn-dups
             ){

            my $applmgrid=$user->GetW5BaseUserID($parrec->{applmgremail},
                          "email",{quiet=>1});
            if ($applmgrid ne $rec->{applmgrid}){
               $user->SetFilter({userid=>\$applmgrid});
               my $applmgr=$user->getVal("fullname");
               if ($applmgr ne ""){
                  $self->IfComp($dataobj,
                                $rec,"applmgr",
                                {applmgr=>$applmgr},"applmgr",
                                $autocorrect,
                                $forcedupd,$wfrequest,\@qmsg,
                                \@dataissue,\$errorlevel,
                                mode=>'string');
               }
            }
         }
      }
   }
   my @result=$self->HandleQRuleResults("T.EAM",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);

   return(@result);
}



1;
