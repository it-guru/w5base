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

   return(0,undef) if (!($rec->{cistatusid}==3 || $rec->{cistatusid}==4));

   
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

   if (keys(%$forcedupd)){
      if ($dataobj->ValidatedUpdateRecord($rec,$forcedupd,{id=>\$rec->{id}})){
         push(@qmsg,"all desired fields has been updated: ".
                    join(", ",keys(%$forcedupd)));
      }
      else{
         push(@qmsg,$self->getParent->LastMsg());
         $errorlevel=3 if ($errorlevel<3);
      }
   }


   if (keys(%$wfrequest)){
      my $msg="different values stored in CapeTS: ";
      push(@qmsg,$msg);
      push(@dataissue,$msg);
      $errorlevel=3 if ($errorlevel<3);
   }


   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}



1;
