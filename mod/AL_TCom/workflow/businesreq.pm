package AL_TCom::workflow::businesreq;
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
use kernel::WfClass;
use Data::Dumper;
use itil::workflow::businesreq;
use AL_TCom::lib::workflow;
@ISA=qw(itil::workflow::businesreq AL_TCom::lib::workflow);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my @l=();

   return($self->SUPER::getDynamicFields(%param),
          $self->InitFields(
           new kernel::Field::Select(    name       =>'tcomcodcause',
                                         label      =>'Activity',
                                         htmleditwidth=>'80%',
                                         translation=>'AL_TCom::lib::workflow',
                                         value      =>
                             [AL_TCom::lib::workflow::tcomcodcause()],
                                         default    =>'undef',
                                         group      =>'tcomcod',
                                         container  =>'headref'),
   
           new kernel::Field::Textarea(  name        =>'tcomcodcomments',
                                         label       =>'Comments',
                                         group       =>'tcomcod',
                                         container   =>'headref'),

           new kernel::Field::Number(    name       =>'tcomworktime',
                                         unit       =>'min',
                                         onUnformat =>
                                      \&AL_TCom::lib::workflow::minUnformat,
                                         detailadd  =>
                                      \&AL_TCom::lib::workflow::tcomworktimeadd,
                                         label      =>'Worktime',
                                         group      =>'tcomcod',
                                         container  =>'headref'),

   ));
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;
   if (defined($oldrec) && defined($newrec) &&
       $oldrec->{stateid}!=16 && $newrec->{stateid}==16){
      if (ref($oldrec->{affectedcontractid}) eq "ARRAY" &&
          $#{$oldrec->{affectedcontractid}}!=-1){ 
         if (($oldrec->{tcomcodcause} eq "undef" || 
              $oldrec->{tcomcodcause} eq "") &&
             $newrec->{tcomcodcause} eq ""){
            $newrec->{tcomcodcause}=$oldrec->{reqnature};
         }
         if (($oldrec->{tcomworktime} eq "") &&
             $newrec->{tcomworktime} eq ""){
            if (ref($oldrec->{shortactionlog}) eq "ARRAY"){
               foreach my $arec (@{$oldrec->{shortactionlog}}){
                  if ($arec->{effort}>0){
                     $newrec->{tcomworktime}+=$arec->{effort};
                  }
               }
            }
         }
      }
   }
   return($self->SUPER::Validate($oldrec,$newrec,$origrec));

}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","extdesc","affected",
          "customerdata","tcomcod","init","flow","relations");
}

sub getRequestNatureOptions
{
   my $self=shift;
   my $vv=[AL_TCom::lib::workflow::tcomcodcause()];
   my @l;
   foreach my $v (@$vv){
      push(@l,$v,$self->getParent->T($v,"AL_TCom::lib::workflow"));
   }
   return(@l);
}





sub isViewValid
{
   my $self=shift;  
   my $rec=$_[0];  
   if (ref($rec->{affectedcontractid}) eq "ARRAY" &&
       $#{$rec->{affectedcontractid}}!=-1){ 
      return($self->SUPER::isViewValid(@_),"tcomcod");
   }
   return($self->SUPER::isViewValid(@_));
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my @grps=$self->SUPER::isWriteValid($rec);
   if ($rec->{stateid}<16 ||  $rec->{stateid}==18){
      if ($self->isUserTrusted($rec)){
         push(@grps,"tcomcod","relations");
      }
   }
   return(@grps);
}

sub isUserTrusted          # allow extended edit on Workflow
{
   my $self=shift;
   my $rec=shift;

   my $mandatoridfo=$self->getParent->getField("mandatorid");
   my $mandatorid=$mandatoridfo->RawValue($rec);
   $mandatorid=[$mandatorid] if (ref($mandatorid) ne "ARRAY");
   @$mandatorid=grep(!/^\s*$/,@$mandatorid);
   if ($#{$mandatorid}!=-1){
      if ($self->getParent->IsMemberOf($mandatorid,"RMember")){
         return(1);
      }
      my $affectedapplicationid=$rec->{affectedapplicationid};
      if (ref($affectedapplicationid) ne "ARRAY"){
         $affectedapplicationid=[$affectedapplicationid];
      }
      if ($#{$affectedapplicationid}!=-1){
         my $app=getModuleObject($self->Config,"itil::appl");
         $app->SetFilter({id=>$affectedapplicationid});
         my ($arec,$msg)=$app->getOnlyFirst(qw(responseteamid 
                                               businessteamid 
                                               opmid opm2id
                                               tsmid semid tsm2id sem2id));
         return(0) if (!defined($arec));
         my $userid=$self->getParent->getCurrentUserId();

         if (($arec->{tsmid} ne "" && $arec->{tsmid}==$userid) ||
             ($arec->{opmid} ne "" && $arec->{opmid}==$userid) ||
             ($arec->{opm2id} ne "" && $arec->{opm2id}==$userid) ||
             ($arec->{tsm2id} ne "" && $arec->{tsm2id}==$userid) ||
             ($arec->{semid} ne "" && $arec->{semid}==$userid) ||
             ($arec->{sem2id} ne "" && $arec->{sem2id}==$userid) ){
            return(1);
         }
         my @g=();
         push(@g,$arec->{responseteamid}) if ($arec->{responseteamid} ne "");
         push(@g,$arec->{businessteamid}) if ($arec->{businessteamid} ne "");
         if ($#g!=-1){
            if ($self->getParent->IsMemberOf(\@g,"RMember")){
               return(1);
            }
         }
      }
   }
   else{
      return(1);
   }
   return(0);
}

sub isEffortReadAllowed
{
   my $self=shift;
   my $WfRec=shift;
   my $tstate=$self->isUserTrusted($WfRec);
   return(1) if ($tstate);
   return($self->SUPER::isEffortReadAllowed($WfRec));
}




1;
