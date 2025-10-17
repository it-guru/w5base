package tsacinv::qrule::clusterSysCheck;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This QualityRule checks, if the logical system is recorded as a part of 
a cluster in AssetManager. If this is true, the field "is_clusternode"
must be set to "true". If the cluster exists in W5Base/Darwin, 
the link to the cluster must be documented.

=head3 IMPORTS

From AssetManager the relation to a cluster will be generated.

=head3 HINTS

[en:]

Check whether the System is part of a cluster and whether the cluster 
is available in W5Base/Darwin. If the needed cluster is not present 
in W5Base/Darwin, it is necessary to create or import the cluster.

[de:]

Prüfen Sie, ob das System zu einem Cluster gehört und ob der Cluster in 
W5base/Darwin vorhanden ist. Falls der benötigte Cluster noch nicht 
vorhanden ist, muss er angelegt bzw. importiert werden.


=cut
#######################################################################
#
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
   return(["itil::system","AL_TCom::system"]);
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


   return(0,undef) if ($rec->{cistatusid}!=4);
   if ($rec->{systemid} ne "" &&
       $rec->{systemid} ne $rec->{srcid}){ # this indicates a MCOS System
      return(undef,{qmsg=>'MCOS similar constellation detected'});
   }
   if ($rec->{systemid} ne "" && $rec->{srcsys} eq "AssetManager"){
      my %parrec=(); 
      $parrec{isclusternode}=0;
      my $sys=getModuleObject($self->getParent->Config(),"tsacinv::system");
      $sys->SetFilter({systemid=>\$rec->{systemid}});
      #$sys->SetFilter({systemid=>'xx'});
      my ($amsysrec,$msg)=$sys->getOnlyFirst(qw(lclusterid));
      return(undef,undef) if (!$sys->Ping());
      if (defined($amsysrec)){
         if ($amsysrec->{lclusterid} ne ""){
            my $cl=getModuleObject($self->getParent->Config(),
                                   "tsacinv::itclust");
            $cl->SetFilter({lclusterid=>\$amsysrec->{lclusterid}});
            my ($amclust,$msg)=$cl->getOnlyFirst(qw(clusterid));
            if (defined($amclust)){
               if ($rec->{isembedded}){
                  $parrec{isembedded}=0;
               }
               $parrec{isclusternode}=1;
               my $cl=getModuleObject($self->getParent->Config(),
                                      "itil::itclust");
               $cl->SetFilter({clusterid=>\$amclust->{clusterid}});
               my ($w5clust,$msg)=$cl->getOnlyFirst(qw(id fullname cistatusid));
               if (defined($w5clust)){
                  if ($w5clust->{cistatusid}>5){
                     push(@qmsg,"can not create needed cluster relation: ".
                          $w5clust->{'fullname'});
                     $errorlevel=3 if ($errorlevel<3);
                     $parrec{itclust}=undef;
                  }
                  else{
                     $parrec{itclust}=$w5clust->{'fullname'};
                  }
                 # printf STDERR ("found\n");
                 # printf STDERR ("amclust=%s\n",Dumper($amclust));
                 # printf STDERR ("w5clust=%s\n",Dumper($w5clust));
               }
               else{
                  push(@qmsg,"ClusterID not found in ".
                             "W5Base/Darwin IT-Inventory: ".
                       $amclust->{clusterid});
                  push(@dataissue,"ClusterID not found in ".
                                  "W5Base/Darwin IT-Inventory: ".
                       $amclust->{clusterid});
                  $errorlevel=3 if ($errorlevel<3);
               }
            }
         }
      }

      $self->IfComp($dataobj,
                    $rec,"isembedded",
                    \%parrec,"isembedded",
                    $autocorrect,$forcedupd,$wfrequest,
                    \@qmsg,\@dataissue,\$errorlevel,
                    mode=>'boolean');

      $self->IfComp($dataobj,
                    $rec,"isclusternode",
                    \%parrec,"isclusternode",
                    $autocorrect,$forcedupd,$wfrequest,
                    \@qmsg,\@dataissue,\$errorlevel,
                    mode=>'boolean');

      $self->IfComp($dataobj,
                    $rec,"itclust",
                    \%parrec,"itclust",
                    $autocorrect,$forcedupd,$wfrequest,
                    \@qmsg,\@dataissue,\$errorlevel,
                    mode=>'leftouterlink');
      if (!$forcedupd->{isclusternode}){  # only take cluster relation if
         delete($forcedupd->{itclust});   # system is realy a cluster node
      }
      if (keys(%$forcedupd)){
       #  printf STDERR ("found DataIssue cluster on system $rec->{name}\n");
         if ($dataobj->ValidatedUpdateRecord($rec,$forcedupd,
             {id=>\$rec->{id}})){
            push(@qmsg,"all desired fields has been updated: ".
                       join(", ",keys(%$forcedupd)));
         }
         else{
            push(@qmsg,$self->getParent->LastMsg());
            $errorlevel=3 if ($errorlevel<3);
         }
      }
      if (keys(%$wfrequest)){
         my $msg="different values stored in AssetManager: ";
         push(@qmsg,$msg);
         push(@dataissue,$msg);
         $errorlevel=3 if ($errorlevel<3);
      }

      return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
   }
   return(0,undef);
}



1;
