package base::qrule::CIStatusTime;
#######################################################################
=pod

=head3 PURPOSE

Checks if Config-Itmes with CI-Status field. A record will be viewed as
invalid, if a item in status ...
 - reserved             (cistatusid=1) longer then 8 weeks
 - on order             (cistatusid=2) longer then 8 weeks
 - available/in project (cistatusid=3) longer then 12 weeks
 - inactiv/stored       (cistatusid=5) longer then 12 weeks
... no be modified (the modification date will be the check referenz).

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

   return(0,undef) if (!exists($rec->{cistatusid}) || 
                       !exists($rec->{mdate}) ||
                       $rec->{mdate} eq "");

   my $now=NowStamp("en");
   my $d=CalcDateDuration($rec->{mdate},$now,"GMT");
   my @failmsg;
   if ($d->{days}>56 && $rec->{cistatusid}==1){
      push(@failmsg,"config item in ci-state 'reserved' and no changes have been done for 8 weeks");
   }
   if ($d->{days}>56 && $rec->{cistatusid}==2){
      push(@failmsg,"config item in ci-state 'on order' and no changes have been done for 8 weeks");
   }
   if ($d->{days}>84 && $rec->{cistatusid}==3){
      push(@failmsg,"config item in ci-state 'available/in project' and no changes have been done for 12 weeks");
   }
   if ($d->{days}>84 && $rec->{cistatusid}==5){
      push(@failmsg,"config item in ci-state 'inactiv/stored' and no changes have been done for 12 weeks");
   }

   if ($#failmsg!=-1){
      #printf STDERR ("check fail:%s\n",Dumper(\@failmsg));
      return(3,{qmsg=>[@failmsg],
                dataissue=>[@failmsg]});
   }
   
   return(0,undef);
}



1;
