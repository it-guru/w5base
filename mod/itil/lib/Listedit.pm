package itil::lib::Listedit;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5base"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1);
}


sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $wrgroups=shift;

   return(0) if (!$self->ProtectObject($oldrec,$newrec,$self->{adminsgroups}));
   return($self->SUPER::SecureValidate($oldrec,$newrec,$wrgroups));
}



sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   if ($self->getField("cistatusid")){
      $self->NotifyOnCIStatusChange($oldrec,$newrec);
   }
   return($bak);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   return("default") if ( $self->IsMemberOf($self->{adminsgroups}));

   my $effowner=defined($rec) ? $rec->{owner} : undef;
   my $userid=$self->getCurrentUserId();
   if (defined($effowner) && $effowner!=$userid){
      return(undef);
   }

   return("default") if (!defined($rec) || 
                         (defined($rec) && $rec->{cistatus}<=2 &&
                          $rec->{owner}==$userid));
   return(undef);
}


sub isWriteOnCustContractValid
{
   my $self=shift;
   my $contractid=shift;
   my $group=shift;

   my $contract=$self->getPersistentModuleObject("itil::custcontract");
   $contract->SetFilter({id=>\$contractid});
   my ($crec,$msg)=$contract->getOnlyFirst(qw(ALL));
   my @g=$contract->isWriteValid($crec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}

sub isWriteOnApplValid
{
   my $self=shift;
   my $applid=shift;
   my $group=shift;

   my $appl=$self->getPersistentModuleObject("itil::appl");
   $appl->SetFilter({id=>\$applid});
   my ($arec,$msg)=$appl->getOnlyFirst(qw(ALL));
   my @g=$appl->isWriteValid($arec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}

sub isWriteOnSwinstanceValid
{
   my $self=shift;
   my $swinstanceid=shift;
   my $group=shift;

   my $swinstance=$self->getPersistentModuleObject("itil::swinstance");
   $swinstance->SetFilter({id=>\$swinstanceid});
   my ($arec,$msg)=$swinstance->getOnlyFirst(qw(ALL));
   my @g=$swinstance->isWriteValid($arec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}


sub isWriteOnApplgrpValid
{
   my $self=shift;
   my $applgrpid=shift;
   my $group=shift;

   my $applgrp=$self->getPersistentModuleObject("itil::applgrp");
   $applgrp->SetFilter({id=>\$applgrpid});
   my ($arec,$msg)=$applgrp->getOnlyFirst(qw(ALL));
   my @g=$applgrp->isWriteValid($arec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}


sub isWriteOnSoftwaresetValid
{
   my $self=shift;
   my $softwaresetid=shift;
   my $group=shift;

   my $softwareset=$self->getPersistentModuleObject("itil::softwareset");
   $softwareset->SetFilter({id=>\$softwaresetid});
   my ($arec,$msg)=$softwareset->getOnlyFirst(qw(ALL));
   my @g=$softwareset->isWriteValid($arec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}


sub isWriteOnBProcessValid
{
   my $self=shift;
   my $bprocessid=shift;
   my $group=shift;

   my $bp=$self->getPersistentModuleObject("itil::businessprocess");
   $bp->SetFilter({id=>\$bprocessid});
   my ($arec,$msg)=$bp->getOnlyFirst(qw(ALL));
   my @g=$bp->isWriteValid($arec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}


sub preQualityCheckRecord
{
   my $self=shift;
   my $rec=shift;

   # load Autodiscovery Data from all configured engines

   my $p=$self->SelfAsParentObject();
   if ($p eq "itil::system" || $p eq "itil::swinstance"){
      my $add=$self->getPersistentModuleObject("itil::autodiscdata");
      my $ade=$self->getPersistentModuleObject("itil::autodiscengine");
      $ade->SetFilter({localdataobj=>\$p});
      foreach my $engine ($ade->getHashList(qw(ALL))){
         my $rk;
         $rk="systemid"     if ($p eq "itil::system");
         $rk="swinstanceid" if ($p eq "itil::swinstance");
         $add->SetFilter({$rk=>\$rec->{id},engine=>\$engine->{name}});
         my ($oldadrec)=$add->getOnlyFirst(qw(ALL));
         my $ado=$self->getPersistentModuleObject($engine->{addataobj});
         if (defined($ado)){
            $ado->SetFilter({$engine->{adkey}=>\$rec->{$engine->{localkey}}});
            my ($adrec)=$ado->getOnlyFirst(qw(ALL));
            if ($ado->Ping()){
               my $adxml=hash2xml($adrec);
               if (!defined($oldadrec)){
                  $add->ValidatedInsertRecord({engine=>$engine->{name},
                                               $rk=>$rec->{id},
                                               data=>$adxml});
               }
               else{
                  $add->ValidatedUpdateRecord($oldadrec,
                                              {data=>$adxml},
                                              {engine=>\$engine->{name},
                                               $rk=>\$rec->{id}});
               }
            }
         }
      }
   }
   return(1);
}






1;
