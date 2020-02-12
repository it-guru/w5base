package tssiem::lib::Listedit;
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
   if (defined($self->{DB})){
      $self->{DB}->do("alter session set cursor_sharing=force");
   }
   if (defined($self->{DB})){
      $self->{DB}->{db}->{LongReadLen}=1024*1024*15;    #15MB
   }

   return(1) if (defined($self->{DB}));
   return(0);
}



sub getSecscanFromSQL
{
   my $self=shift;

   my $PerspectiveDecode="case ".
                         "when title like '%_vFWI_%' ".
                         "then 'SharedVLAN' ".
                         "else 'CNDTAG' ".
                         "end";

   my $d="select W5SIEM_secscan.*,".
         "decode(rank() over (partition by ictoid||($PerspectiveDecode) ".
         "order by launch_datetime desc),1,1,0) islatest,".
         "($PerspectiveDecode) scanperspective ".
         "from W5SIEM_secscan ".
#         "where launch_datetime>current_date-100 ".  #Scan needs from last 100d
         "order by ictoid";

   return($d);
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

         



1;
