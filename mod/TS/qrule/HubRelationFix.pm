package TS::qrule::HubRelationFix;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

fix direct Hub relations


=head3 HINTS

[en:]

-

[de:]

Von den Hub-Org-Admins wird oft der Fehler begangen,
dass wenn Untergruppen definiert sind, dennoch "normale" Mitarbeiter
direkt dem Hub zugeordnet werden.
Dies führt zu ungewollten Effekten, wenn z.B. Schreibrechte an eine
Untergruppe des Hubs zugewiesen werden.
Diese QRule korrigiert derartige direkte Hub-Zuordnungen in 
die Untergruppe "People".


=cut

#######################################################################
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
   return(["base::grp"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   return(undef,undef) if (!($rec->{fullname}=~m/\.Hub\.[^.]+$/));

   my $isPeopleGroupId;
   my @subgrpid;

   foreach my $subrec (@{$rec->{subunits}}){
      push(@subgrpid,$subrec->{grpid});
      if (lc($subrec->{name}) eq "people"){
         $isPeopleGroupId=$subrec->{grpid}
      }
   }
   return(undef,undef) if (!defined($isPeopleGroupId)); 
   my $o=getModuleObject($dataobj->Config(),"base::lnkgrpuser");
   foreach my $lnkrec (@{$rec->{users}}){
      my $op;
      my $roles=$lnkrec->{roles};
      $roles=[$roles] if (ref($roles) ne "ARRAY");
      next if (in_array($roles,[qw(RBoss RBoss2 RAdmin)]));
      $o->ResetFilter();
      $o->SetFilter([
         {userid=>\$lnkrec->{userid}},
         {grpid=>\@subgrpid,userid=>\$lnkrec->{userid}}
      ]);
      my @l=$o->getHashList(qw(userid grpid));
      foreach my $chkrec (@l){
         if ($chkrec->{grpid} eq $isPeopleGroupId &&
             $chkrec->{userid} eq $lnkrec->{userid}){
            $op="DEL";
         }
      }

      if ($op eq "DEL"){
         push(@qmsg,"delete: ".$lnkrec->{user});
         $o->ResetFilter();
         $o->ValidatedDeleteRecord($lnkrec,{
            grpid=>\$rec->{grpid},
            userid=>\$lnkrec->{userid}
         });
      }
      else{
         push(@qmsg,"move: ".$lnkrec->{user});
         $o->ResetFilter();
         $o->ValidatedUpdateRecord($lnkrec,{
            grpid=>$isPeopleGroupId
         },{
            grpid=>\$rec->{grpid},
            userid=>\$lnkrec->{userid}
         });
      }
   }









   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}



1;
