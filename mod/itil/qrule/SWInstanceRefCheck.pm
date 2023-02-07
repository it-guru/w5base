#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks if the related application, logical system and software installation
to the current instance is "active" and valid.

An aktiv software instance need to have a link to a valid logical system 
or cluster service. Also there is need to have a valid link to a software
installation.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

The Qrule checks if the related application, logical system and software
installation to the current software instance is in status
"available/in project", "installed/active" or "inactive/stored".

[de:]

Die Qrule prüft ob die, mit der Software Instanz verbundene Anwendung,
log. System oder Software-Installation im Status "verfügbar/in Projektierung",
"zeitweise inaktiv" oder "installiert/aktiv" und gültig ist.


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2009  Hartmut Vogler (it@guru.de)
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
package itil::qrule::SWInstanceRefCheck;
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
   return(["itil::swinstance"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(undef,undef) if ($rec->{'cistatusid'}!=4 && 
                           $rec->{'cistatusid'}!=5 &&
                           $rec->{'cistatusid'}!=3);
   if ($rec->{applid} ne ""){
      my @msg;
      my $appl=getModuleObject($self->getParent->Config,"itil::appl");
      $appl->SetFilter({id=>\$rec->{applid}});
      my ($arec,$msg)=$appl->getOnlyFirst(qw(cistatusid id));
      if (!defined($arec)){
         push(@msg,"invalid application reference");
      }
      else{
         if ($arec->{cistatusid}>5 || $arec->{cistatusid}<3){
            push(@msg,"referenced application application is not active");
         }
      }
      if (defined($arec)){ # further checks are only needed, if appl found
         my $swinstvalid=1;
         if ($rec->{runon} eq "2"){
            $swinstvalid=0 if ($rec->{software} eq ""); 
         }
         else{
            $swinstvalid=0 if ($rec->{lnksoftwaresystemid} eq ""); 
         }
         if ($rec->{runon} eq "2"){   # now do itcloudarea checks
            if ($rec->{itcloudarea} eq ""){
               push(@msg,"no CloudArea specified");
            }
            else{
               my $c=getModuleObject($self->getParent->Config,
                                     "itil::itcloudarea");
               my $itcloudareaid=$rec->{itcloudareaid};
               my $applid=$arec->{id};
               $c->SetFilter({id=>\$itcloudareaid,applid=>\$applid});
               my ($itcrec,$msg)=$c->getOnlyFirst(qw(id cistatusid));

               if (!defined($itcrec)){
                  push(@msg,"application does not match application ".
                            "in CloudArea");
               }
               else{
                  if ($itcrec->{cistatusid}>5 || $itcrec->{cistatusid}<3){
                     push(@msg,"referenced CloudArea is not active");
                  }
               }
            }
         }
         if ($rec->{runon} eq "1"){   # now do cluster checks
            if ($rec->{itclusts} eq ""){
               push(@msg,"no cluster service specified");
            }
            else{
               my $c=getModuleObject($self->getParent->Config,
                                     "itil::lnkitclustsvcappl");
               my $clustsid=$rec->{itclustsid};
               my $applid=$arec->{id};
               $c->SetFilter({itclustsvcid=>\$clustsid,applid=>\$applid});
               my ($svcrec,$msg)=$c->getOnlyFirst(qw(id));

               if (!defined($svcrec)){
                  push(@msg,"application does not match application ".
                            "in cluster service");
               }
            }
         }
         if ($rec->{runon} eq "0"){                       # now do system checks
            my $systemid=$rec->{systemid};
            my $sys=getModuleObject($self->getParent->Config,"itil::system");
            $sys->SetFilter({id=>\$systemid});
            my ($sysrec,$msg)=$sys->getOnlyFirst(qw(id cistatusid));
            if (!defined($sysrec)){
               push(@msg,"no system specified");
            }
            else{
               if ($sysrec->{cistatusid}>5 || $sysrec->{cistatusid}<3){
                  push(@msg,"referenced logical system is not active");
               }
               my $c=getModuleObject($self->getParent->Config,
                                     "itil::lnkapplsystem");
               my $applid=$arec->{id};
               $c->SetFilter({systemid=>\$systemid,
                              applid=>\$applid,
                              reltyp=>'!instance'});
               my ($chkrec,$msg)=$c->getOnlyFirst(qw(id));

               if (!defined($chkrec)){
                  push(@msg,"application does not match direct application ".
                            "in system");
               }
            }
         }
         if (!$rec->{isembedded}){
            if ($rec->{runon} ne "2" && 
                $swinstvalid){ # detail check of software-Installation
               my $swi=getModuleObject($self->getParent->Config,
                                       "itil::lnksoftware");
               $swi->SetFilter({id=>\$rec->{lnksoftwaresystemid}});
               my ($swirec,$msg)=$swi->getOnlyFirst(qw(id systemid 
                                                       itclustsvcid));
               if (!defined($swirec)){
                  $swinstvalid=0
               }
               else{
                  # detail check of found software installation
                  # printf STDERR ("swirec=%s\n",Dumper($swirec));
                  if (defined($rec->{systemid}) &&
                      $swirec->{systemid} ne $rec->{systemid}){
                     push(@msg,
                       "software installation no longer belongs to the system");
                  }
               }
            }
            if (!$swinstvalid){
               if ($self->isValidSoftwareInstallationMandatory($rec)){
                  push(@msg,
                    "invalid or not existing software installation specified");
               }
            }
         }
      }
      
      if ($#msg!=-1){
         return(3,{qmsg=>[@msg],dataissue=>[@msg]});
      }
   }

   return(0,undef);

}


sub isValidSoftwareInstallationMandatory
{
   my $self=shift;
   my $rec=shift;

   return(1);

}




1;
