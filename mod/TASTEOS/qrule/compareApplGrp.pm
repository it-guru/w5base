package TASTEOS::qrule::compareApplGrp;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This quality rule compares a W5Base ApplicationGroup to a TasteOS 
system (which is a application in W5Base spelling).

=head3 IMPORTS

- name of cluster

=head3 HINTS

Sync to TasteOS

[de:]

Syncronisation der Anwendungsgruppen in Darwin mit den "Systemen"
in TasteOS.

=cut
#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2020  Hartmut Vogler (it@guru.de)
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
   return(["itil::applgrp"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=shift;

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   return(0,undef) if ($rec->{cistatusid}!=4);

   my $lobj=getModuleObject($dataobj->Config,"itil::lnkapplsystem");

   $lobj->SetFilter({
      applgrpid=>\$rec->{id},
      systemcistatusid=>[4],
      applcistatusid=>[4]
   });

   my @l=$lobj->getHashList(qw(systemid applid));

   printf STDERR ("l=%s\n",Dumper(\@l));
   printf STDERR ("n=%d\n",$#l+1);




   my @result=$self->HandleQRuleResults("TasteOS",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);

   return(@result);
}



1;
