package itcrm::qrule::compareApplOwner;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This rule compares the application owner from the customer portal
to the leading it-inventar system.

=head3 IMPORTS

The contact "application owner" will be synced on itil applications
in cistatus<=5

=cut
#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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

   return(0,undef) if ($rec->{cistatusid}<=1 &&
                       $rec->{cistatusid}>=6); # ist notwendig, damit CIs
                                               # auch wieder aktiviert
                                               # werden.
   if ($rec->{id} ne ""){
      my $par=getModuleObject($self->getParent->Config,"itcrm::custappl");
      $par->SetFilter({id=>\$rec->{id}});
      my ($parrec,$msg)=$par->getOnlyFirst(qw(businessowner));
      return(undef,undef) if (!$par->Ping());

      $self->IfComp($dataobj,
                    $rec,"applowner",
                    $parrec,"businessowner",
                    $autocorrect,$forcedupd,$wfrequest,
                    \@qmsg,\@dataissue,\$errorlevel,
                    mode=>'text');
   }

   if (keys(%$forcedupd)){
      #printf STDERR ("fifi request a forceupd=%s\n",Dumper($forcedupd));
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
      my $msg="different values stored in Customer Portal: ";
      push(@qmsg,$msg);
      push(@dataissue,$msg);
      $errorlevel=3 if ($errorlevel<3);
   }
   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}


1;
