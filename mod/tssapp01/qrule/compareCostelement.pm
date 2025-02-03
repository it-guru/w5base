package tssapp01::qrule::compareCostelement;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This QualityRule compares a W5Base/Darwin costelement against SAP P01
and adds on found srcsys and srcid.

=head3 IMPORTS

The fields srcsys,srcid and accarea

=head3 HINTS

[en:]


[de:]



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
   return(["finance::costcenter"]);
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

   my $par;
   my $parrec;

   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);


   if ($rec->{name}=~m/^T2[A-Z][0-9]{7}$/ &&
       $rec->{costcentertype} eq 'costcenter'){
      return(undef,{qmsg=>'TS Slovakia costcenter detected'});
   }
   if ($rec->{name}=~m/^Y-[A-Z0-9]{3}-/ &&
       $rec->{costcentertype} eq 'pspelement'){
      return(undef,{qmsg=>'DT Technic costcenter detected'});
   }
   if ($rec->{name}=~m/^Z-[A-Z0-9]{3}-/ &&
       $rec->{costcentertype} eq 'pspelement'){
      return(undef,{qmsg=>'GHS costcenter detected'});
   }
   if ($rec->{name}=~m/^[0-9]{8}$/ &&
       $rec->{costcentertype} eq 'costcenter' &&
       $rec->{accarea} eq "0190"){
      return(undef,{qmsg=>'costcenter of InternalIT HU detected'});
   }



   if ($rec->{srcsys} eq "" || 
       lc($rec->{srcsys}) eq "w5base" ||
       lc($rec->{srcsys}) eq "w5basev1"){
      $par=getModuleObject($self->getParent->Config(),"tssapp01::psp");
      $par->SetFilter({name=>\$rec->{name}});
      ($parrec)=$par->getOnlyFirst(qw(ALL));
      if (defined($parrec)){
         $forcedupd->{srcload}=NowStamp("en");
         $forcedupd->{srcsys}=$par->Self();
      }
      else{
          $par=getModuleObject($self->getParent->Config(),
                               "tssapp01::costcenter");
          $par->SetFilter({name=>\$rec->{name}});
          ($parrec)=$par->getOnlyFirst(qw(ALL));
          if (defined($parrec)){
             $forcedupd->{srcload}=NowStamp("en");
             $forcedupd->{srcsys}=$par->Self();
          }
          else{
             my $msg="can't validate costobject against SAPP01";
             push(@qmsg,$msg);
             push(@dataissue,$msg);
             $errorlevel=3 if ($errorlevel<3);
          }
      }
   }
   else{
      if ($rec->{srcsys} eq "tssapp01::psp" ||
          $rec->{srcsys} eq "tssapp01::costcenter"){
         $par=getModuleObject($self->getParent->Config(),$rec->{srcsys});
         $par->SetFilter({name=>\$rec->{name}});
         ($parrec)=$par->getOnlyFirst(qw(ALL));
         if (!defined($parrec)){
            my $msg='costelement does not exists in SAP P01';
            push(@qmsg,$msg);
            push(@dataissue,$msg);
            $errorlevel=3 if ($errorlevel<3);
         }
         else{
            $forcedupd->{srcload}=NowStamp("en");
         }
      }
   }

   if (defined($par) && defined($parrec)){
      if ($rec->{cistatusid}==4 || $rec->{cistatusid}==3 ||
          $rec->{cistatusid}==5){
            $self->IfComp($dataobj,
                          $rec,"accarea",
                          $parrec,"accarea",
                          $autocorrect,$forcedupd,$wfrequest,
                          \@qmsg,\@dataissue,\$errorlevel,
                          mode=>'string');
      }
      if ($rec->{cistatusid} < 6){
         my @nomsg;
         my $noerrorlevel;
         if ($rec->{shortdesc} eq "" || $autocorrect){
            $self->IfComp($dataobj,
                          $rec,"shortdesc",
                          $parrec,"description",
                          $autocorrect,$forcedupd,$wfrequest,
                          \@nomsg,\@nomsg,\$noerrorlevel,
                          mode=>'string');
         }
      }
      if ($par->Self() eq "tssapp01::costcenter"){
         if ($rec->{costcentertype} ne "costcenter"){
            $forcedupd->{costcentertype}="costcenter";
         }
      }
      if ($par->Self() eq "tssapp01::psp"){
         if ($rec->{costcentertype} ne "pspelement"){
            $forcedupd->{costcentertype}="pspelement";
         }
      }
      if ($rec->{srcid} ne $parrec->{id}){  
         $forcedupd->{srcid}=$parrec->{id};
      }
   }

   if (keys(%$forcedupd)){
      if ($dataobj->ValidatedUpdateRecord($rec,$forcedupd,{id=>\$rec->{id}})){
         my @fld=grep(!/^(srcload|srcsys)$/,keys(%$forcedupd));
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
      my $msg="different values stored in SAP: ";
      push(@qmsg,$msg);
      push(@dataissue,$msg);
      $errorlevel=3 if ($errorlevel<3);
   }
   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}



1;
