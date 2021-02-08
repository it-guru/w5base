#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks software installation data against posible existing
AutoDisc Data. AutoDisc data will be used, if they are older den 7 days
to prevent fast dataissue creation.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]


[de:]

Mit der QualityRule werden die in den AutoDisc Feldern hinterlegten
Softwarebzeichnungen/Versionen mit den in der zugeordneten 
Software-Installation abgeglichen.
Sollten diese nicht übereinstimmen, muß der betreffende 
Software-Installationsdatensatz aktualisiert werden - oder es gibt 
ein Problem beim zuliefernden AutoDisc System, das die AutoDisc i
Felder befüllt hat.
Relevante Felder sind techrelstring, techproductstring und techdataupdate.
Verglichen wird mit softwareinstname und softwareinstversion.


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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
package itil::qrule::SWInstanceAutoDiscCheck;
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
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;


   return(undef,undef) if ($rec->{'cistatusid'}!=4 && 
                           $rec->{'cistatusid'}!=3);

   # techrelstring techproductstring techdataupdate

   if ($rec->{techdataupdate} ne ""){
      my $d=CalcDateDuration($rec->{techdataupdate},NowStamp("en"));
      if (defined($d)){
         if ($rec->{softwareinstversion} ne ""){ # if softwareins is related
            if ($rec->{techrelstring} ne ""){    # check version string
               if ($rec->{techrelstring} ne $rec->{softwareinstversion}){
                  my $msg=sprintf(
                       $self->T("version in software installation '%s' ".
                              "does not match version from autodiscovery '%s'"),
                       $rec->{softwareinstversion},$rec->{techrelstring});
                  push(@qmsg,$msg);
                  push(@dataissue,$msg);
                  $errorlevel=3 if ($errorlevel<3);
               }
            }
         }
         if ($rec->{softwareinstname} ne ""){
            if ($rec->{techproductstring} ne ""){    # check product string
               if ($rec->{techproductstring} ne $rec->{softwareinstname}){
                  my $msg=sprintf(
                       $self->T("software product in installation '%s' ".
                              "does not match product from autodiscovery '%s'"),
                       $rec->{softwareinstname},$rec->{techproductstring});
                  push(@qmsg,$msg);
                  push(@dataissue,$msg);
                  $errorlevel=3 if ($errorlevel<3);
               }
            }
         }
      }
   }

   my @result=$self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}


1;
