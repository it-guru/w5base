package base::event::RefreshRoleRelation;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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

#
# Der Job ermöglicht es, verfallende Gruppenrelationen anhand von Rollenangaben
# automatisch verlängern zu lassen.
#
# 1. Parameter ist die Gruppe die analysiert werden soll
# 2. Parameter ist die Rollen-Liste die auf andere Relationen der Gruppen
#    Mitglieder hin überprüft werden soll.
# 3. Parameter ist der Request mit dem die Sache angefordert wurde
#
# Alle Relationen zu den aufgeführten Gruppen die in den nächsten <80 Tagen
# verfallen würden, werden dann automatisch um 200 Tage verlängert.
#



use strict;
use vars qw(@ISA);
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

sub RefreshRoleRelation
{
   my $self=shift;
   my $group=shift;
   my $roles=shift;
   my $request=shift;

   if ($roles eq "" || $group eq ""){
      return({msg=>msg(ERROR,"no group or roles specified"),exitcode=>1});
   }

   my @roles=split(/,/,$roles);

   my $grp=getModuleObject($self->Config,"base::grp");
   $grp->SetFilter({fullname=>\$group,cistatusid=>"<=5"});
   my ($grec,$msg)=$grp->getOnlyFirst(qw(fullname grpid cistatusid));
   if (!defined($grec)){
      return({msg=>msg(ERROR,"missing valid group fullname"),exitcode=>1});
   }

   my %uid;
   my $lnkgrp=getModuleObject($self->Config,"base::lnkgrpuser");
   $lnkgrp->SetFilter({grpid=>\$grec->{grpid},roles=>\"RMember"});
   foreach my $lnkrec ($lnkgrp->getHashList(qw(userid))){
      $uid{$lnkrec->{userid}}++;
   }

   if (!keys(%uid)){
      return({msg=>msg(ERROR,"no users found in group ".$group),exitcode=>1});
   }

   my @upd;
   $lnkgrp->ResetFilter();
   $lnkgrp->SetFilter({userid=>[keys(%uid)]});
   foreach my $lnkrec ($lnkgrp->getHashList(qw(lnkgrpuserid comments
                                               userid grpid roles expiration))){
      next if (!in_array($lnkrec->{roles},\@roles));
      if ($lnkrec->{expiration} ne ""){
         my $now=NowStamp("en");
         my $dlt=CalcDateDuration($now,$lnkrec->{expiration});
         if (defined($dlt) && $dlt->{totaldays}<80){ #in weniger als 80 tagen
            my $newexp=
                  $lnkgrp->ExpandTimeExpression($lnkrec->{expiration}."+200d",
                                            "en","GMT","GMT");
            my $newcom=$lnkrec->{comments};
            $newcom.="\n" if (!($newcom=~m/\n$/));
            $newcom.="\nExpiration refreshed by ".$self->Self."\n".
                     "at $now GMT for 200 days\n";
            if ($request ne ""){
               $newcom.="based on ".$request."\n";
            }
            push(@upd,{lnkgrpuserid=>$lnkrec->{lnkgrpuserid},
                       comments=>$newcom,
                       expiration=>$newexp});
            

         }
      }
   }
   my $c=0;
   foreach my $updrec (@upd){
      my $id=$updrec->{lnkgrpuserid};
      if ($id ne ""){
         delete($updrec->{lnkgrpuserid});
         $lnkgrp->ResetFilter();
         $lnkgrp->SetFilter({lnkgrpuserid=>\$id});
         my ($oldrec,$msg)=$lnkgrp->getOnlyFirst(qw(ALL));
         if (defined($oldrec)){
            if ($lnkgrp->ValidatedUpdateRecord($oldrec,$updrec,
                                           {lnkgrpuserid=>\$id})){
               $c++;
            }
         }
      }
   }
   return({msg=>'OK - '.$c.' entries updated',exitcode=>0});
}



1;
