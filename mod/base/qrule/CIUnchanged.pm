package base::qrule::CIUnchanged;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks if Config-Itmes is longer then 36 month not modified. If this is
it, it seems the Config-Item is obsolete. The databoss needs to check,
if the item is still needed. This can be done by a simple save on
the Config-Item record.

=head3 IMPORTS

NONE

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
   return([".*"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my @failmsg;

   return(0,undef) if (!exists($rec->{mdate}));

   if ($rec->{mdate} eq ""){
      push(@failmsg,"invalid modification date in config-item - ".
                    "contact the w5base admin");
   }

   my $now=NowStamp("en");
   my $d=CalcDateDuration($rec->{mdate},$now,"GMT");
   my @failmsg;
   if ($d->{days}>1090 && $rec->{cistatusid}<6){
      push(@failmsg,"config item longer then 3 years unchanged - please check actuality of the config data");
   }
   if ($#failmsg!=-1){
      return(3,{qmsg=>[@failmsg],
                dataissue=>[@failmsg]});
   }
   
   return(0,undef);
}



1;
