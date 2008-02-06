package tsacinv::qrule::compareSystem;
#  Functions:
#  * at cistatus "installed/active":
#    - check if systemid is valid in tsacinv::system
#    - check if assetid is valid in tsacinv::asset 
#
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
   return(["itil::system","OSY::system","AL_TCom::system"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my $errorlevel=0;

   return(0,undef) if ($rec->{cistatusid}!=4);
   if ($rec->{systemid} ne ""){
      my $par=getModuleObject($self->getParent->Config(),"tsacinv::system");
      $par->SetFilter({systemid=>\$rec->{systemid}});
      my ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      if (!defined($parrec)){
         push(@qmsg,'given systemid not found as active in AssetCenter');
         $errorlevel=3 if ($errorlevel<3);
      }
      else{
         $self->IfaceCompare($dataobj,
                             $rec,"servicesupport",
                             $parrec,"systemola",
                             $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
                             mode=>'leftouterlinkcreate',
                             onCreate=>{
                               comments=>"automaticly create by QualityCheck",
                               cistatusid=>4,
                               name=>$parrec->{systemola}}
                             );
         $self->IfaceCompare($dataobj,
                             $rec,"memory",
                             $parrec,"systemmemory",
                             $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
                             tolerance=>5,mode=>'integer');
      }
   }
   else{
      push(@qmsg,'no systemid specified');
      $errorlevel=3 if ($errorlevel<3);
   }

   if ($rec->{asset} ne ""){
      my $par=getModuleObject($self->getParent->Config(),"tsacinv::asset");
      $par->SetFilter({assetid=>\$rec->{asset}});
      my ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      if (!defined($parrec)){
         push(@qmsg,'given assetid not found as active in AssetCenter');
         $errorlevel=3 if ($errorlevel<3);
      }
   }
   else{
      push(@qmsg,'no assetid specified');
      $errorlevel=3 if ($errorlevel<3);
   }



   if (keys(%$forcedupd)){
      printf STDERR ("fifi request a forceupd=%s\n",Dumper($forcedupd));
      if ($dataobj->ValidatedUpdateRecord($rec,$forcedupd,{id=>\$rec->{id}})){
         push(@qmsg,"all desired fields has been updated");
      }
      else{
         push(@qmsg,$self->getParent->LastMsg());
         $errorlevel=3 if ($errorlevel<3);
      }
   }
   if (keys(%$wfrequest)){
      printf STDERR ("fifi request a DataIssue Workflow=%s\n",Dumper($wfrequest));
   }

   # now process workflow request for traditional W5Deltas

   # todo

   #######################################################################

   if ($#qmsg!=-1 || $errorlevel>0){
      return($errorlevel,{qmsg=>\@qmsg});
   }

   return($errorlevel,undef);
}



1;
