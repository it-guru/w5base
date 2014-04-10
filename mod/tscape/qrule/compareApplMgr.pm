package tscape::qrule::compareApplMgr;
#######################################################################
=pod

=head3 PURPOSE

This quality rule compares the Application Manager specified in 
the ICTO Object on CapeTS to the ApplicationManager entry in
a BusinessApplication.

=head3 IMPORTS

- name of cluster

=head3 HINTS

Der ApplicationManager der für eine Anwendung verantwortlich
ist, wird durch das zugehörige ICTO-Objekt aus CapeTS vorgeben.

Diese QualityRule stellt sicher, dass in W5Base/Darwin der
gleiche ApplicationManager eingetragen ist.

Sollte der falsche ApplicationManager durch diese Regel gemeldet
werden, so kann dies an einem Fehleintrag in CapeTS oder einer
falschen ICTO Nummer beim Anwendungseintrag in W5Base/Darwin
liegen.

IT-Architektur über das Tool CapeTS vergeben. 

Ansprechpartner für CapeTS ist Hr. Krohn ...

https://darwin.telekom.de/darwin/auth/base/user/ById/13627534400001


=cut
#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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

   return(0,undef) if (!($rec->{cistatusid}==3 || 
                         $rec->{cistatusid}==4));

   return(0,undef) if ($rec->{opmode} ne "prod"); # ApplicationManager sind
                                                  # nur für die Prod Umgebungen
                                                  # definiert.
   if ($rec->{ictono} ne ""){
      my $par=getModuleObject($self->getParent->Config(),"tscape::archappl");
      $par->SetFilter({archapplid=>\$rec->{ictono}});
      my ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      return(undef,undef) if (!$par->Ping());
      if (defined($parrec)){
         my $tswiw=getModuleObject($self->getParent->Config,"tswiw::user");
         my $user=getModuleObject($self->getParent->Config,"base::user");
         if ($parrec->{applmgremail} ne ""){
            my $applmgrid=$tswiw->GetW5BaseUserID($parrec->{applmgremail});
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
   else{
      return(0,undef);
   }

   return($self->HandleQRuleResults("CapeTS",
          $dataobj,$rec,$checksession,
          \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd
   ));
}



1;
