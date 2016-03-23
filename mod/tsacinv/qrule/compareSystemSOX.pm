package tsacinv::qrule::compareSystemSOX;
#######################################################################
=pod

=head3 PURPOSE

This qulaity rule compares a W5Base logical system to an AssetManager logical
system and checks differences between the SOX state of the system.
Only logical systems in W5Base with state not like 'reserved' or 'disposed of waste' will be checked.


=head3 IMPORTS

NOTHING

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
   return(["itil::system"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   return(0,undef) if ($rec->{cistatusid}<=1 || $rec->{cistatusid}>=6);
   if ($rec->{systemid} ne ""){
      my $par=getModuleObject($self->getParent->Config(),"tsacinv::system");
      $par->SetFilter({systemid=>\$rec->{systemid}});
      my ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      return(undef,undef) if (!$par->Ping());
      if ($parrec->{assignmentgroup} eq "CS.DPS.DE.MSY" ||
          ($parrec->{assignmentgroup}=~m/^CS\.DPS\.DE\.MSY\..*$/)){
         # CS.DPS.DE.MSY Pflegt das SOX Flag in AM nicht
         # siehe: https://darwin.telekom.de/darwin/auth/base/workflow/ById/14072395420001
         return(0,undef);
      }
      if (defined($parrec) && !$parrec->{soxrelevant}){ # only if no SOX is
         my $issox=$dataobj->getField("issox")->RawValue($rec); # set in AM
         if ($issox!=$parrec->{soxrelevant}){
            my $msg="SOX relevance not matches the AM presets!".
                    " - please check your order";
            push(@qmsg,$msg);
            push(@dataissue,$msg);
            $errorlevel=3 if ($errorlevel<3);
         }
      }
   }

   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}



1;
