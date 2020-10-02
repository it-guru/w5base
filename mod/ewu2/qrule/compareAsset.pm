package ewu2::qrule::compareAsset;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This QualityRule compares a W5Base physical system to an ewu2 
physical system (Asset) and updates the defined fields if necessary. 
Automated imports are only done if the field "Allow automatic interface updates"
is set to "yes".
Only assets in W5Base/Darwin with the CI-State "installed/active" are synced!


=head3 HINTS

[en:]

If the asset is maintained in ewu2 by the EWU2 and only mirrored 
to W5Base/Darwin, set the field "allow automatic updates by interfaces"
in the block "Control-/Automationinformations" to "yes". 
The data will be synced automatically.

[de:]

Falls das Asset in ewu2 durch die EWU2 gepflegt wird, sollte 
das Feld "automatisierte Updates durch Schnittstellen zulassen" im Block 
"Steuerungs-/Automationsdaten" auf "ja" gesetzt werden.


=cut

#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
   return(["itil::asset","OSY::asset","AL_TCom::asset"]);
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


   return(undef,undef) if ($rec->{srcsys} ne "EWU2");

   my ($parrec,$msg);
   my $par=getModuleObject($self->getParent->Config(),"ewu2::asset");


   #
   # Level 0
   #
   if ($rec->{srcid} ne ""){   # pruefen ob ASSETID von ewu2
      my $ewu2id=$rec->{srcid};
      $ewu2id=~s/\[[0-9]+\]$//;
      $par->SetFilter({id=>\$ewu2id});
      ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      return(undef,undef) if (!$par->Ping());
      if (!defined($parrec)){
         if ($rec->{name} ne $rec->{id}){
            # hier koennte u.U. noch eine Verbindung zu EWU2 über
            # den Namen aufgebaut werden
         }
      }
   }

   if ($rec->{cistatusid}==4 || $rec->{cistatusid}==3 ||
       $rec->{cistatusid}==5){
      if ($rec->{srcid} ne "" && $rec->{srcsys} eq "EWU2"){
         if (!defined($parrec)){
            push(@qmsg,'given assetid not found as active in ewu2');
            push(@dataissue,
                       'given assetid not found as active in ewu2');
            $errorlevel=3 if ($errorlevel<3);
         }
         else{
             if ($rec->{srcsys} eq "EWU2"){
                # hack für die Spezialisten, die die AssetID in Kleinschrift
                # erfasst haben.
                if ($parrec->{commonname} ne $rec->{name} &&
                    $parrec->{commonname} ne ""){
                   msg(INFO,"force rename of $rec->{name} to ".
                      $parrec->{commonname});
                   $forcedupd->{name}=$parrec->{commonname};   
                }
                ################################################################
                my $acroom=$parrec->{room};


                $self->IfComp($dataobj,
                              $rec,"serialno",
                              $parrec,"serialno",
                              $autocorrect,$forcedupd,$wfrequest,
                              \@qmsg,\@dataissue,\$errorlevel,mode=>'string');

               $self->IfComp($dataobj,
                             $rec,"memory",
                             $parrec,"memory",
                             $autocorrect,$forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             tolerance=>5,mode=>'integer');

               $self->IfComp($dataobj,
                             $rec,"cpucount",
                             $parrec,"cpucount",
                             $autocorrect,$forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'integer');
               $self->IfComp($dataobj,
                             $rec,"corecount",
                             $parrec,"corecount",
                             $autocorrect,$forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'integer');

               $self->IfComp($dataobj,
                             $rec,"cpuspeed",
                             $parrec,"cpuspeed",
                             $autocorrect,$forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'integer');

               $self->IfComp($dataobj,
                             $rec,"hwmodel",
                             $parrec,"model",
                             $autocorrect,$forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'leftouterlinkbaselogged',
                             iomapped=>$par);

               $self->IfComp($dataobj,
                             $rec,"locationid",
                             $parrec,"locationid",
                             $autocorrect,$forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'integer');

               return(undef,undef) if (!$par->Ping());
            }
         }
      }
   }

   if (keys(%$forcedupd)){
      if ($dataobj->ValidatedUpdateRecord($rec,$forcedupd,{id=>\$rec->{id}})){
         my @fld=grep(!/^srcload$/,keys(%$forcedupd));
         if ($#fld!=-1){
            push(@qmsg,"all desired fields has been updated: ".join(", ",@fld));
         }
      }
      else{
         push(@qmsg,$self->getParent->LastMsg());
         $errorlevel=3 if ($errorlevel<3);
      }
   }
   if (keys(%$wfrequest)){
      my $msg="different values stored in ewu2: ";
      push(@qmsg,$msg);
      push(@dataissue,$msg);
      $errorlevel=3 if ($errorlevel<3);
   }
   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}


1;
