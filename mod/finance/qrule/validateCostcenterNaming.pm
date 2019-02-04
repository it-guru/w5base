package finance::qrule::validateCostcenterNaming;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Validation of costcenter naming against w5base internal nameing 
convention tables.


=cut

#######################################################################
#
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
   return(["finance::costcenter"]);
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

   my $par;
   my $parrec;

   if ($rec->{cistatusid}<6){
      if (!exists($dataobj->{costcenter})){
         $dataobj->LoadSubObjs("ext/costcenter","costcenter");
      }
      foreach my $obj (values(%{$dataobj->{costcenter}})){
         if (!$obj->ValidateCONumber($dataobj->SelfAsParentObject,
                                     "name",$rec,$rec)){
            my $msg="invalid or unknown number format for cost element";
            push(@qmsg,$msg);
            push(@dataissue,$msg);
            $errorlevel=3;
         }
      }
   }

   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}



1;
