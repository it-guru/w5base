package itil::lib::SecurityRestrictor;
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




sub getSecurityRestrictedAllowedSystemIDs
{
   my $self=shift;
   my $seclevel=shift;   #  10 = low   20 = middle  30=high (only named persons)


   my $userid=$self->getCurrentUserId();
   $userid=-1 if (!defined($userid) || $userid==0);

   my %grp=$self->getGroupsOf($ENV{REMOTE_USER},[orgRoles()],"both");
   my @grpid=grep(/^[0-9]+/,keys(%grp));
   @grpid=qw(-99) if ($#grpid==-1);
   
   my $appl=$self->getPersistentModuleObject("w5appl","itil::appl");
   my $sys=$self->getPersistentModuleObject("w5sys","itil::system");
   my $lappsys=$self->getPersistentModuleObject("w5lappsys",
      "itil::lnkapplsystem");
   
   my @flt=();
   push(@flt,{cistatusid=>[3,4,5],databossid=>\$userid});
   push(@flt,{cistatusid=>[3,4,5],applmgrid=>\$userid});
   push(@flt,{cistatusid=>[3,4,5],secapplmgr2id=>\$userid});
   if ($seclevel<20){
      push(@flt,{cistatusid=>[3,4,5],semid=>\$userid});
      push(@flt,{cistatusid=>[3,4,5],sem2id=>\$userid});
   }
   push(@flt,{cistatusid=>[3,4,5],tsmid=>\$userid});
   push(@flt,{cistatusid=>[3,4,5],tsm2id=>\$userid});
   push(@flt,{cistatusid=>[3,4,5],opmid=>\$userid});
   push(@flt,{cistatusid=>[3,4,5],opm2id=>\$userid});
   if ($seclevel<30){
      push(@flt,{cistatusid=>[3,4,5],businessteamid=>\@grpid});
   }
   if ($seclevel<20){
      push(@flt,{cistatusid=>[3,4,5],itsemteamid=>\@grpid});
      push(@flt,{cistatusid=>[3,4,5],responseteam=>\@grpid});
   }
   
   $appl->SetFilter(\@flt);
   $appl->SetCurrentView(qw(id));
   my $i=$appl->getHashIndexed("id");
   
   my @appid=keys(%{$i->{id}});
   @appid=qw(-1) if ($#appid==-1);
   
   $lappsys->SetFilter({
      applid=>\@appid,
      applcistatusid=>"<6",
      systemcistatusid=>"<6",
      cistatusid=>\'4'
   });
   $lappsys->SetCurrentView(qw(systemsystemid));
   my $s=$lappsys->getHashIndexed("systemsystemid");

   my @flt=();
   push(@flt,{cistatusid=>[3,4,5],databossid=>\$userid});
   push(@flt,{cistatusid=>[3,4,5],admid=>\$userid});
   push(@flt,{cistatusid=>[3,4,5],adm2id=>\$userid});
   if ($seclevel<30){
      push(@flt,{cistatusid=>[3,4,5],adminteamid=>\@grpid});
   }
   $sys->SetFilter(\@flt);
   $sys->SetCurrentView(qw(systemid));
   my $ss=$sys->getHashIndexed("systemid");
   foreach my $k (keys(%{$ss->{systemid}})){
      $s->{systemsystemid}->{$k}="1";
   }


   
   my @systemid=grep(/^S[0-9]+$/,keys(%{$s->{systemsystemid}}));





}




1;
