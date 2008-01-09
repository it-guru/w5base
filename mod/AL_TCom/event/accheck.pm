package AL_TCom::event::accheck;
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
use Data::Dumper;
use kernel;
use kernel::Event;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;


   $self->RegisterEvent("acgroupcheck","acgroupcheck");
   $self->RegisterEvent("acusercheck","acusercheck");
   return(1);
}

sub acusercheck
{
   my $self=shift;
   my $user=getModuleObject($self->Config,"tsacinv::user");
   my $c=0;
   my $ecount=0;
   my $wcount=0;
   #$user->Limit(1000);
   my %byuserid=();
   my %bycontactid=();
   my %byfullname=();
   my %countbycontactid=();
   foreach my $rec ($user->getHashList(qw(lempldeptid srcsys srcid  loginname
                                          name fullname))){
      #msg(INFO,"Check group %s\n",$rec->{name});
      msg(DEBUG,"rec=%s",Dumper($rec)) if ($c==0);
      $rec->{name}=lc($rec->{name});
      $rec->{fullname}=lc($rec->{fullname});
      $byuserid{$rec->{lempldeptid}}=$rec;
      if (defined($byfullname{$rec->{fullname}})){
         msg(ERROR,"fullname '%s' multiple used",$rec->{fullname});
         $ecount++;
      }
      $byfullname{$rec->{fullname}}=$rec;
      $bycontactid{$rec->{name}}=$rec;
      $countbycontactid{lc($rec->{name})}++;
      $c++;
   }
   foreach my $id (keys(%countbycontactid)){
      if ($countbycontactid{$id}>1){
         msg(ERROR,"contactid '%s' is %d times used",$id,$countbycontactid{$id});
         $ecount++;
      }
   }
   foreach my $id (keys(%byuserid)){
      if ($byuserid{$id}->{srcid}=~m/^gerger/i){
         if ($countbycontactid{$byuserid{$id}->{name}}<=1){
            msg(WARN,"empldeptid '%s' (%s) obviously bad externalid '%s'",
                $id,$byuserid{$id}->{name},$byuserid{$id}->{srcid});
            $wcount++;
         }
      }
   }
   msg(INFO,"checked %d users - errors=%d - wanings %d",$c,$ecount,$wcount);
   my $prob=$ecount+$wcount;
   if ($prob>1){
      msg(INFO,"%3.2f%% buggy user",$prob*100/$c);
   }
}

sub acgroupcheck
{
   my $self=shift;

   my $grp=getModuleObject($self->Config,"tsacinv::group");
   my $c=0;
   my $ecount=0;
   my $wcount=0;
   my %bygrpid=();
   foreach my $rec ($grp->getHashList(qw(lgroupid name parentid ))){
      #msg(INFO,"Check group %s\n",$rec->{name});
      msg(DEBUG,"rec=%s",Dumper($rec)) if ($c==0);
      $bygrpid{$rec->{lgroupid}}=$rec;
      $c++;
   }
   foreach my $id (keys(%bygrpid)){
      if ($bygrpid{$id}->{parentid} ne "" &&
          $bygrpid{$id}->{parentid}!=0 &&
          !exists($bygrpid{$bygrpid{$id}->{parentid}})){
         msg(ERROR,"parentid '%s' of group %s doesn't exists",
                   $bygrpid{$id}->{parentid},$bygrpid{$id}->{name});
         $ecount++;
         next;
      }
      my $name=$bygrpid{$id}->{name};
      my $pname=$bygrpid{$bygrpid{$id}->{parentid}}->{name};
      my @name=split(/\./,$name);
      my @pname=split(/\./,$pname);
      if ($bygrpid{$id}->{parentid} ne "" &&
          $bygrpid{$id}->{parentid}!=0){
         my @pnameshould=@name;
         pop(@pnameshould);
         if (join(".",@pnameshould) ne join(".",@pname)){
            msg(ERROR,"parentname of '%s' is '%s'",$name,$pname);
            $ecount++;
            next;
         }
      }
      if ($#name>0 && $bygrpid{$id}->{parentid}==0){
         msg(WARN,"missing parent group of '%s'",$name);
         $wcount++;
         next;
      }
      if ($name=~m/\s+$/){
         msg(WARN,"group '%s' have suffixed white spaces",$name);
         $wcount++;
         next;
      }
      if ($name=~m/\s/){
         msg(WARN,"group '%s' have white spaces",$name);
         $wcount++;
         next;
      }
   }
   msg(INFO,"checked %d groups - errors=%d - wanings %d",$c,$ecount,$wcount);
   my $prob=$ecount+$wcount;
   if ($prob>1){
      msg(INFO,"%3.2f%% buggy groups",$prob*100/$c);
   }
   return({exitcode=>0});
}



1;
