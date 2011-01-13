package AL_TCom::event::patchTSMwriteSystemAsset;
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
use kernel::Event;
use kernel::database;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;


   $self->RegisterEvent("patchTSMwriteSystemAsset","patchTSMwriteSystemAsset");
   return(1);
}

sub patchTSMwriteSystemAsset
{
   my $self=shift;
   my $sys=getModuleObject($self->Config,"itil::system");
   my $ass=getModuleObject($self->Config,"itil::asset");


   #
   # System operation
   #
   $sys->SetFilter({databoss=>'"service: ICIT2W5Base*"',cistatusid=>"<6"});
   $sys->SetCurrentView(qw(name id contacts applications));
   #$sys->SetNamedFilter("X",{name=>'!ab1*'});
   #$sys->Limit(10,0,0);
   my ($rec,$msg)=$sys->getFirst();
   if (defined($rec)){
      do{
         msg(INFO,"process system: $rec->{name}");
         if (!$self->addTSM("itil::system",$rec)){
            msg(ERROR,"no tsm for system $rec->{name}");
         }
         ($rec,$msg)=$sys->getNext();
      } until(!defined($rec));
   }

   #
   # Asset operation
   #
   $ass->SetFilter({databoss=>'"service: ICIT2W5Base*"',cistatusid=>"<6"});
   $ass->SetCurrentView(qw(name id contacts applications));
   #$ass->SetNamedFilter("X",{name=>'A00434*'});
   #$ass->Limit(20,0,0);
   my ($rec,$msg)=$ass->getFirst();
   if (defined($rec)){
      do{
         msg(INFO,"process asset: $rec->{name}");
         if (!$self->addTSM("itil::asset",$rec)){
            msg(ERROR,"no tsm for asset $rec->{name}");
         }
         ($rec,$msg)=$ass->getNext();
         
      } until(!defined($rec));
   }


   return({exitcode=>0});
}

sub addTSM
{
   my $self=shift;
   my $parent=shift;
   my $rec=shift;
   my $appl=getModuleObject($self->Config,"itil::appl");
   my $lnk=getModuleObject($self->Config,"base::lnkcontact");
   my $tsmcount=0;

   my $refid=$rec->{id};
   my $parentobj=$parent;

   foreach my $arec (@{$rec->{applications}}){
      $appl->ResetFilter();
      $appl->SetFilter({id=>\$arec->{applid},cistatusid=>'<6'});
      foreach my $arec ($appl->getHashList(qw(id name databossid tsmid tsm2id))){
         foreach my $contact (qw(tsmid tsm2id opmid opm2id databossid)){
            my $target="base::user";
            my $targetid=$arec->{$contact};
            if ($targetid ne ""){
               $tsmcount++ if ($contact ne "databossid");
               $lnk->ValidatedInsertOrUpdateRecord({
                     refid=>$refid,
                     parentobj=>$parentobj,
                     target=>'base::user',
                     targetid=>$targetid,
                     roles=>['write'],
                     comments=>'write right by ICIT2Darwin initial load'},
                     {
                     refid=>$refid,
                     parentobj=>$parentobj,
                     target=>'base::user',
                     targetid=>$targetid,
               });
            }
         }
      
      }
   }
   return($tsmcount);
}

1;
