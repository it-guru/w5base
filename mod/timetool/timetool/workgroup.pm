package timetool::timetool::workgroup;
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
use kernel::date;
use timetool::timetool::teamplan;

@ISA=qw(timetool::timetool::teamplan);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub getCalendars
{
   my $self=shift;
   my $myuserid=$self->getParent->getCurrentUserId();

   my $wg=$self->getParent->getPersistentModuleObject("timetool::workgroup");
   $wg->SetFilter({contactids=>\$myuserid});
   my @callist;
   my @wg=$wg->getHashList(qw(id name contactids));
   my @cal;
   foreach my $wg (@wg){
      push(@cal,"timetool::timetool::workgroup;$wg->{id}",100,
               "Workgroup: ".$wg->{name});
   }
   return(@cal);
}

sub AddLineLabels
{
   my $self=shift;
   my $vbar=shift;
   my $id=shift;
   my $myuserid=$self->getParent->getCurrentUserId();

   my %user;
   my $con=$self->Context();
   $con->{uid}=[];
   if ($id!=0){
      my $grp=$self->getParent->getPersistentModuleObject("timetool::workgroup");
      $grp->SetFilter({id=>\$id});
      my ($wg,$msg)=$grp->getOnlyFirst(qw(contacts));
      if (ref($wg->{contacts}) eq "ARRAY"){
         foreach my $rec (@{$wg->{contacts}}){
            $user{$rec->{targetid}}={userid=>$rec->{targetid},
                                    fullname=>$rec->{targetid}};
         }
      }
   }
   my $user=$self->getParent->getPersistentModuleObject("base::user");
   foreach my $userid (keys(%user)){
      $user->ResetFilter();
      $user->SetFilter({userid=>\$userid});
      push(@{$con->{uid}},$userid);
      my ($rec,$msg)=$user->getOnlyFirst(qw(fullname surname givenname));
      if (defined($rec)){
         my $name=$rec->{surname};
         $name.=", " if ($name ne "" && $rec->{givenname} ne "");
         $name.=$rec->{givenname} if ($rec->{givenname} ne "");
         $name=$rec->{fullname} if ($name eq "");
         $user{$userid}->{fullname}=$name;
      }
   }
   my $c=0;
   foreach my $userid (sort({$user{$a}->{fullname} cmp $user{$b}->{fullname}} 
                            keys(%user))){
      my $fullname=$user{$userid}->{fullname};
      if ($userid==$myuserid){
         $fullname="<b>".$fullname."</b>";
      }
      $vbar->SetLabel($userid,$fullname,{order=>$c});
      $c++;
   }
}


sub getAdditionalSearchMask
{
   my $self=shift;
   return("");
}


1;
