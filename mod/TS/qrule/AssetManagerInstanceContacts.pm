package TS::qrule::AssetManagerInstanceContacts;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Import handler for SAP Software-Instances contact inherit from appl

=head3 IMPORTS

NONE

=head3 HINTS
no hints

[de:]

keine Tips

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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
   return(["itil::swinstance"]);
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

   my $srcsys="AssetManagerApplInstSAP";

   return(undef) if ($rec->{srcsys} ne $srcsys);



   my $w5appl=getModuleObject($dataobj->Config,"itil::appl");

   $w5appl->SetFilter({id=>$rec->{applid}});

   my @l=$w5appl->getHashList(qw(id name contacts));


   my $isUserEdited=0;

   foreach my $crec (@{$rec->{contacts}}){
       $isUserEdited++ if ($crec->{srcsys} ne $self->Self());
   }
   if ($isUserEdited){
      push(@qmsg,"contacts are edited by users");
   }
   if (!$isUserEdited){
      my %contacts;
      foreach my $arec (@l){
         foreach my $crec (@{$arec->{contacts}}){
            my $roles=$crec->{roles};
            $roles=[$roles] if (ref($roles) ne "ARRAY");
            if (in_array($roles,"write")){
               $contacts{ $crec->{target}.":".$crec->{targetid} }={
                  roles=>['write'],
                  target=>$crec->{target},
                  targetid=>$crec->{targetid}
               }
            }
         }
      }
      my @soll=values(%contacts);
      my @ist=@{$rec->{contacts}};


      my @opList;
      my $res=kernel::QRule::OpAnalyse(
         sub{  # comperator
            my ($a,$b)=@_;   # a=swisoll b=curlist in W5Base
            my $eq;          # undef= nicht gleich

            if ( $a->{target} eq $b->{target} &&
                 $a->{targetid} eq $b->{targetid}){
               $eq=0;  # rec found - aber u.U. update notwendig
               #if (lc($a->{name}) eq lc($b->{name}) &&
               #    $a->{applid} eq $b->{applid}  &&
               #    $a->{cistatusid} eq $b->{cistatusid}){
                  $eq=1;   # alles gleich - da braucht man nix machen
               #}
            }
            return($eq);
         },
         sub{  # oprec generator
            my ($mode,$oldrec,$newrec,%p)=@_;
            if ($mode eq "insert" || $mode eq "update"){
               my $oprec={
                  OP=>$mode,
                  DATAOBJ=>'base::lnkcontact',
                  DATA=>$newrec
               };
               if ($mode eq "insert"){
                  $oprec->{DATA}->{parentobj}=$dataobj->SelfAsParentObject();
                  $oprec->{DATA}->{refid}=$rec->{id};
                  $oprec->{DATA}->{srcsys}=$self->Self();
                  $checksession->{EssentialsChangedCnt}++;
               }
               if ($mode eq "update"){
                  $oprec->{IDENTIFYBY}=$oldrec->{id};
               }
               return($oprec);
            }
            if ($mode eq "delete"){
               my $oprec={
                  OP=>$mode,
                  DATAOBJ=>'base::lnkcontact'
               };
               $oprec->{IDENTIFYBY}=$oldrec->{id};
               $checksession->{EssentialsChangedCnt}++;
               return($oprec);
            }

            return(undef);
         },
         \@ist,\@soll,\@opList
      );
      if (!$res){
         my $opres=ProcessOpList($self->getParent,\@opList);
      }
   }

   my @result=$self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}




1;
