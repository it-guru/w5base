package tbonedb::lib::Listedit;
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

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tbone"));
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
                                 w5base.tbone.bupstat.read
                              )],
          "RMember")){
         my @systemid;
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
         push(@flt,{cistatusid=>[3,4,5],tsmid=>\$userid});
         push(@flt,{cistatusid=>[3,4,5],tsm2id=>\$userid});
         push(@flt,{cistatusid=>[3,4,5],opmid=>\$userid});
         push(@flt,{cistatusid=>[3,4,5],opm2id=>\$userid});
         push(@flt,{cistatusid=>[3,4,5],businessteamid=>\@grpid});
        
         $appl->SetFilter(\@flt);
         $appl->SetCurrentView(qw(id));
         my $i=$appl->getHashIndexed("id");
        
         my @appid=keys(%{$i->{id}});
         @appid=qw(-1) if ($#appid==-1);

         if (keys(%{$i->{id}})){
            my $svcappl=$self->getPersistentModuleObject("w5svcall",
                                                   "itil::lnkitclustsvcappl");
            $svcappl->SetFilter({applid=>\@appid});
            $svcappl->SetCurrentView(qw(id itclustid));
            my $s=$svcappl->getHashIndexed("itclustid");
            my @itclustid=keys(%{$s->{itclustid}}); 
            if ($#itclustid!=-1){
               my $itc=$self->getPersistentModuleObject("w5itc",
                                                   "itil::itclust");
               $itc->SetFilter({clusterid=>'!""',id=>\@itclustid});
               $itc->SetCurrentView(qw(id clusterid));
               my $s=$itc->getHashIndexed("clusterid");
               my @clusterid=keys(%{$s->{clusterid}});
               if ($#clusterid!=-1){
                  push(@systemid,@clusterid);
               }
            }
         }
         $lappsys->SetFilter({applid=>\@appid});
         $lappsys->SetCurrentView(qw(systemsystemid));
         my $s=$lappsys->getHashIndexed("systemsystemid");

         my @flt=();
         push(@flt,{cistatusid=>[3,4,5],databossid=>\$userid});
         push(@flt,{cistatusid=>[3,4,5],admid=>\$userid});
         push(@flt,{cistatusid=>[3,4,5],adm2id=>\$userid});
         push(@flt,{cistatusid=>[3,4,5],adminteamid=>\@grpid});
         $sys->SetFilter(\@flt);
         $sys->SetCurrentView(qw(systemid));
         my $ss=$sys->getHashIndexed("systemid");
         foreach my $k (keys(%{$ss->{systemid}})){
            $s->{systemsystemid}->{$k}="1";
         }


        
         push(@systemid,grep(/^S[0-9]+$/,keys(%{$s->{systemsystemid}})));
        
         my @secsystemid;
         while (my @sid=splice(@systemid,0,500)){ #needed to fix ora "in" limits
            push(@secsystemid,"SYSTEMID in (".
                              join(",",map({"'".$_."'"} @sid)).")");
         }
         if ($#secsystemid!=-1){
            $where="(".join(" OR ",@secsystemid).")";
         }
         else{
            $where="(1=0)";
         }
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






