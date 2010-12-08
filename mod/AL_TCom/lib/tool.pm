package AL_TCom::lib::tool;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
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



sub getRequestedApplicationIds
{
   my $self=shift;
   my $userid=shift;
   my %param=@_;

   my @grps;
   if ($param{team} || $param{dep}){
      my @r=();
      push(@r,qw(REmployee RApprentice RFreelancer RBoss 
                 RBackoffice RQManager RMonitor)) if ($param{team});
      push(@r,qw(RBoss2)) if ($param{dep});
      my %grp=$self->getParent->getGroupsOf($userid,\@r,"down");
      @grps=keys(%grp);
   }
   push(@grps,"none") if ($#grps==-1);
   if ($#grps>30){
      @grps=("overflow");
   }
   my $flt=[];
   if ($param{databoss}){
      push(@$flt,{ databossid=>\$userid,cistatusid=>"<6" });
   }
   if ($param{user} || $param{college}){
      my @uids;
      push(@uids,$userid) if ($param{user});
      if ($param{college} ne ""){
         push(@uids,$param{college});  # hier ist noch ein check notwendig!
      }
      foreach my $uid (@uids){
         push(@$flt,{ semid=>\$uid,cistatusid=>"<6" },
                    { tsmid=>\$uid,cistatusid=>"<6" },
                    { opmid=>\$uid,cistatusid=>"<6" },
                    { delmgrid=>\$uid,cistatusid=>"<6" });
      }
   }
   if ($param{dep}){
      push(@$flt,{ sem2id=>\$userid,cistatusid=>"<6" },
                 { tsm2id=>\$userid,cistatusid=>"<6" },
                 { opm2id=>\$userid,cistatusid=>"<6" },
                 { delmgr2id=>\$userid,cistatusid=>"<6" });
   }
   if ($param{team}){
      push(@$flt,{ responseteamid=>\@grps,cistatusid=>"<6"},
                 { delmgrteamid=>\@grps,cistatusid=>"<6"},
                 { businessteamid=>\@grps,cistatusid=>"<6"});
   }
   my @appl=("none");
   return(@appl) if ($#{$flt}==-1);
   $self->{appl}->ResetFilter();
   $self->{appl}->SecureSetFilter($flt);
   my @l=$self->{appl}->getHashList("id");
   if ($#l>-1){
      @appl=map({$_->{id}} @l);
   }
   return(@appl);
}






1;
