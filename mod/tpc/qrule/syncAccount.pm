package tpc::qrule::syncAccount;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This QualityRule compares a W5Base/Darwin CloudArea to TPC Account.

=head3 IMPORTS


=head3 HINTS

[en:]


[de:]



=cut

#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
   return(["itil::itcloudarea"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=shift;

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;


   return(undef,undef) if (!($rec->{itcloudshortname}=~m/^TPC\d+$/));

   return(undef,undef) if ($rec->{cistatusid}<4);

   my $tpccode=$rec->{itcloudshortname};

   my $app=getModuleObject($self->getParent->Config(),"itil::appl");
   $app->SetFilter({id=>\$rec->{applid}});
   my ($arec)=$app->getOnlyFirst(qw(id cistatusid));

   if (!defined($arec)){
      push(@qmsg,"invalid application reference");
   }
   else{
      if ($arec->{cistatusid} ne "4" &&
          $arec->{cistatusid} ne "3"){
          push(@qmsg,"invalid CI-State for application");
      }
   }
   my $tpcprojectid=$rec->{srcid};  
   { 
      my $chk=getModuleObject($self->getParent->Config(),$tpccode."::project");
      return(undef,undef) if (!$chk->Ping());
      $chk->SetFilter({id=>$tpcprojectid,cistatusid=>"4"});
      my @acc=$chk->getHashList(qw(id));
      if ($#acc==-1){
         my $msg="TPC account invalid or not accessable";
         push(@qmsg,$msg);
         #push(@dataissue,$msg);  # DataIssues for clouareas are not defined
         $errorlevel=3;
      }
   }

   if ($#qmsg==-1){
      my $par=getModuleObject($self->getParent->Config(),$tpccode."::machine");
      return(undef,undef) if (!$par->Ping());

      $par->SetFilter({projectId=>$tpcprojectid});

      my @l=$par->getHashList(qw(id cdate));

      my @id;
      my %srcid;
      foreach my $irec (@l){
         push(@id,$irec->{id});
         $srcid{$irec->{id}}={
            cdate=>$irec->{cdate}
         };
      }
      my $sys=getModuleObject($self->getParent->Config(),"itil::system");

      $sys->SetFilter([
         {
            srcid=>[keys(%srcid)]
         },
         {
            srcsys=>['TPC','AssetManager'],   # AssetManager because MCOS!
            itcloudareaid=>$rec->{id},
      #      cistatusid=>"<6"
         }]
      );
      my @cursys=$sys->getHashList(qw(id srcid srcsys cistatusid));

      my @delsys;
      my @inssys;
      my @updsys;

      foreach my $sysrec (@cursys){
         my $srcid=$sysrec->{srcid};
         if (exists($srcid{$srcid})){
            if ($sysrec->{cistatusid} ne "4"){
               $srcid{$srcid}->{op}="upd";
            }
            else{
               $srcid{$srcid}->{op}="ok";
            }
         }
      }
      foreach my $sysrec (@cursys){
         my $srcid=$sysrec->{srcid};
         if (!exists($srcid{$srcid}->{op})){
            push(@delsys,$srcid);
         }
      }
      foreach my $srcid (keys(%srcid)){
         if (!exists($srcid{$srcid}->{op})){
            push(@inssys,$srcid);
         }
         elsif($srcid{$srcid}->{op} eq "upd"){
            push(@updsys,$srcid);
         }
      }

      if ($#updsys!=-1){
         $sys->ResetFilter();
         $sys->SetFilter({itcloudareaid=>$rec->{id},srcid=>\@updsys});
         my $op=$sys->Clone();
         foreach my $rec ($sys->getHashList(qw(ALL))){
            $op->ValidatedUpdateRecord($rec,{
               name=>$rec->{srcid},   # give a temp name for reactivation to
               cistatusid=>4          # ensure reactivation works
            },{id=>\$rec->{id}});
         }
      }
      foreach my $srcid (@inssys){
         $par->ResetFilter();
         $par->SetFilter({id=>\$srcid});
         my ($imprec)=$par->getOnlyFirst(qw(ALL));
         if (defined($imprec)){
            push(@qmsg,"import $srcid");
            $par->ResetFilter();
            $par->Import({importrec=>$imprec});
         }
      }
      if (keys(%srcid) &&   # ensure, restcall get at least one result
          $#delsys!=-1){
         $sys->ResetFilter();
         $sys->SetFilter({itcloudareaid=>$rec->{id},srcid=>\@delsys});
         my $op=$sys->Clone();
         foreach my $rec ($sys->getHashList(qw(ALL))){
            $op->ValidatedUpdateRecord($rec,{cistatusid=>6},{id=>\$rec->{id}});
         }
      }
   }

   my @result=$self->HandleQRuleResults("TPC",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);

   return(@result);
}



1;
