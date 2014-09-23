package TS::event::TSNotifyMgmtItemGroupOnOff;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
use itil::event::NotifyMgmtItemGroupOnOff;
@ISA=qw(itil::event::NotifyMgmtItemGroupOnOff);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{FMB_PRM} ='14111237770001';
   $param{topTelIT}=qr/^top\d+.*telekomit$/i;

   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}


sub TSNotifyMgmtItemGroupOnOff
{
   my $self=shift;
   return($self->NotifyMgmtItemGroupOnOff(@_));
}


sub getParsedNotifyTemplate
{
   my $self=shift;
   my $act=shift;
   my $static=shift;

   if ($static->{rawcitype} eq 'application' &&
       $static->{mgmtitemgroup}=~m/$self->{topTelIT}/) {
      my $mailtxt=$self->getParsedTemplate("tmpl/mgmtitemgroupmail$act",
                            {
                               skinbase=>'TS',
                               static=>$static
                            });
      return($mailtxt);
   }
   return($self->SUPER::getParsedNotifyTemplate($act,$static));
}


sub getStaticMailCC {
   my $self=shift;
   my $citype=shift;
   my $mgmtitemgroup=shift;

   if (defined($self->{FMB_PRM}) &&
       $citype eq 'application'  &&
       $mgmtitemgroup=~m/$self->{topTelIT}/) {
      return($self->{FMB_PRM});
   }

   return(undef);
}



1;
