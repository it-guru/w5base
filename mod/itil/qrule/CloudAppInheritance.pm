package itil::qrule::CloudAppInheritance;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Realize inheritance of attributes from CloudArea assigned application
to imported CIs.

=head3 IMPORTS

NONE

=head3 HINTS

The attributes ...

- cost assignment object 

... is taken over from the application associated with the CloudArea 
on CIs imported from the CloudArea.



[de:]

Von der, der CloudArea zugeordneten Anwendung werden die
Attribute ...

- Kontierungsobjekt

... an die von der CloudArea importierte CIs vererbt.


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
   return(["itil::system"]);
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
   my $parrec={};



   return(undef) if (!($rec->{cistatusid}<=5));
   return(undef) if ($rec->{itcloudareaid} eq "");


   my $cloudshortname=$rec->{itcloudshortname};


   my $ca=getModuleObject($self->getParent->Config,"itil::itcloudarea");

   $ca->SetFilter({cistatusid=>\'4',id=>\$rec->{itcloudareaid}});

   my ($carec)=$ca->getOnlyFirst(qw(id applid));
   if (defined($carec) && $carec->{applid} ne ""){
      $dataobj->updateCostCenterByApplId($cloudshortname,
         $rec,$forcedupd,$carec->{applid},$autocorrect,\@qmsg,\@dataissue
      );
      $errorlevel=4 if ($#dataissue!=-1);
   }

   my @result=$self->HandleQRuleResults("CloudAreaInheritance",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}



1;
