package caas::qrule::CaaS_Project_URLvalidate;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Validates a URL in CaaS Project with communication URLs
on related application.

=head3 IMPORTS

NONE

=head3 HINTS
Check if DNS-Path in CaaS Project still exists
and remove of URL, if it does'nt anymore.

[de:]

Prüfung, ob der DNS-Pfaden im CaaS Projekt noch
existiert und Entferung der URL, falls dies nicht mehr
der Fall ist.

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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
   return(["itil::lnkapplurl"]);
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

   my $srcsys="caas::qrule::CaaS_Project_URLsync";

   return(undef,undef) if ($rec->{srcsys} ne $srcsys);

   my $parobj=getModuleObject($dataobj->Config,"caas::url");
   my ($chkid,$projectid)=$rec->{srcid}=~m/^(.*)\@(.*)$/;

   if ($chkid ne ""){
      $parobj->SetFilter({id=>\$chkid,projectid=>$projectid});

      my @l=$parobj->getHashList(qw(ALL));
      if ($#l==-1){
         push(@qmsg,"removing URL due not exists on CaaS anymore");
         $dataobj->ValidatedDeleteRecord($rec);
         $checksession->{abortSession}="1";
      }
   }

   my @result=$self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}




1;
