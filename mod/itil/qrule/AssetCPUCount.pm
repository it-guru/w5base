package itil::qrule::AssetCPUCount;
#######################################################################
=pod

=head3 PURPOSE

Every asset needs one CPU at minimum to work. If there is no or 0 cpu-count
defined on a phyiscal system in CI-Status "installed/active" or "available",
this will produce an error.
If the Core-Count is lower then the CPU-Count, this will also produce an
error.
A core count of more then 4096 and a cpucount of more then 1024 will be
handled as not realistic.

=head3 IMPORTS

NONE

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2007  Hartmut Vogler (it@guru.de)
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
   return(["itil::asset"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);
   my @msg;
   if ($rec->{cpucount}<=0){
      my $msg='no cpu count defined';
      push(@msg,$msg);
   }
   if ($rec->{cpucount}>1024){
      my $msg='cpu count is not realistic';
      push(@msg,$msg);
   }
   if ($rec->{corecount}>1024){
      my $msg='core count is not realistic';
      push(@msg,$msg);
   }
   if ($rec->{corecount}<$rec->{cpucount}){
      my $msg='core count is less then cpu count';
      push(@msg,$msg);
   }
   if ($#msg>=0){
      return(3,{qmsg=>\@msg,dataissue=>\@msg});
   }
   return(0,undef);

}




1;
