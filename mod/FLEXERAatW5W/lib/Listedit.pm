package FLEXERAatW5W::lib::Listedit;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB );

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}



sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}



sub initSqlWhere
{
   my $self=shift;
   my $where="";

   my $userid=$self->getCurrentUserId();
   $userid=-1 if (!defined($userid) || $userid==0);

   if ($self->isDataInputFromUserFrontend()){
      if (!$self->IsMemberOf([qw(admin
                                 w5base.tsflexera.read
                              )],
          "RMember") &&
          !$self->IsMemberOf([qw(
                              DTAG.GHQ.VTI.DTIT.IT.E-DTO.E-DTOPL
                              DTAG.GHQ.VTI.DTIT.IT.IT-SC3.IT-SC3_CH.IT-SC3_CHi
                              DTAG.GHQ.VTI.DTIT.IT.IT-SC3.IT-SC3_CH.IT-SC3_CHh  
                              DTAG.GHQ.VTI.DTIT.IT.IT-SC3.IT-SC3_CH.IT-SC3_CHg
                              DTAG.TSY.INT.DTIT_HU.E.HU-IT-3-CA.HU-IT-3-CAc
                              )],
          "RMember","up") ){
         $where="(BEACONID is null or BEACONID like 'DEU0360%')";
      }
   }

   return($where);
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}





1;
