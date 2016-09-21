package TS::qrule::AppDatabossOfSubIsService;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This rule analyses all applications 
(except those in the CI-State "disposed of waste"), 
whether there are sub-Config-Items (e.g. systems or assets) where the databoss 
is a user of the type "service". If this is true, a DataIssue is created.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

Check the sub-CIs (e.g. the systems and/or hardware) of your application 
for those that have a Service-User entered as databoss. 
Ensure that a regular User takes over the databoss role for these CIs 
in place of the Service-User.

[de:]

Prüfen Sie die sub-CIs (z.B. Systeme, Assets), die an Ihrer Anwendung hängen, 
ob dort ein Service-User als Datenverantwortlicher eingetragen ist. 
Sorgen Sie dafür, dass ein normaler User die Datenverantwortung 
für diese CIs übernimmt.


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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
   return(["itil::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $exitcode=0;
   my $desc={qmsg=>[],solvtip=>[]};
   $desc->{'dataissue'}=$desc->{'qmsg'};
   return($exitcode,$desc) if ($rec->{cistatusid}==6);

   my @systemid;
   foreach my $sysrec (@{$rec->{systems}}){
      push(@systemid,$sysrec->{systemid});
   }
   if ($#systemid!=-1){
      my $sys=getModuleObject($self->getParent->Config,"itil::system");
      $sys->SetFilter({id=>\@systemid});
      my @assetid;
      foreach my $sysrec ($sys->getHashList(qw(name databossid assetid))){
         if ($sysrec->{assetid} ne ""){
            push(@assetid,$sysrec->{assetid});
         }
         if (!$self->isDatabossOk($sysrec->{databossid})){
            push(@{$desc->{qmsg}},
                   "inaccepatable databoss at system: ".$sysrec->{name});
            $exitcode=3 if ($exitcode<3);
         }
      }
      if ($#assetid!=-1){
         my $ass=getModuleObject($self->getParent->Config,"itil::asset");
         $ass->SetFilter({id=>\@assetid});
         foreach my $assrec ($ass->getHashList(qw(name databossid assetid))){
            if (!$self->isDatabossOk($assrec->{databossid})){
               push(@{$desc->{qmsg}},
                      "inaccepatable databoss at asset: ".$assrec->{name});
               $exitcode=3 if ($exitcode<3);
            }
         }
      }
 
   }
   return($exitcode,$desc);
}

sub isDatabossOk
{
   my $self=shift;
   my $userid=shift;

   return(0) if ($userid eq "");
   if (!defined($self->{userok})){
      $self->{userok}={};
   }
   my $user=getModuleObject($self->getParent->Config,"base::user");

   $user->SetFilter({userid=>\$userid});
   my ($urec)=$user->getOnlyFirst(qw(userid usertyp));
   if (!defined($urec) || $urec->{usertyp} eq "service"){
      $self->{userok}->{$urec->{userid}}=0;
   }
   else{
      $self->{userok}->{$urec->{userid}}=1;
   }
   return($self->{userok}->{$urec->{userid}});



}




1;
