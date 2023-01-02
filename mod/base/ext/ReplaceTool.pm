package base::ext::ReplaceTool;
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
use kernel::Universal;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub getControlRecord
{
   my $self=shift;
   my $d=[ 

           menuentry=>{
             replaceoptype=>'base::grp',
             dataobj      =>'base::menuacl',
             target       =>'acltargetname',
             idfield      =>'acltargetid',
             targetlabel  =>'fullname',
             baseflt      =>{acltarget=>\'base::grp'}
           },
           fileacl=>{
             replaceoptype=>'base::grp',
             dataobj      =>'base::fileacl',
             target       =>'acltargetname',
             idfield      =>'acltargetid',
             targetlabel  =>'fullname',
             baseflt      =>{acltarget=>\'base::grp'}
           },
           teamcontact=>{
             replaceoptype=>'base::grp',
             dataobj      =>'base::lnkcontact',
             target       =>'targetname',
             idfield      =>'targetid',
             targetlabel  =>'fullname',
             baseflt      =>{target=>\'base::grp'}
           },
           locationgrp=>{
             replaceoptype=>'base::grp',
             dataobj      =>'base::lnklocationgrp',
             target       =>'grp',
             idfield      =>'grpid',
             targetlabel  =>'fullname',
             baseflt      =>{}
           },
           locationdataboss=>{
             replaceoptype=>'base::user',
             dataobj      =>'base::location',
             target       =>'databoss',
             idfield      =>'databossid',
             targetlabel  =>'name',
             baseflt      =>{cistatusid=>'1 2 3 4 5'}
           }
         ];
   return($d);
}

sub doReplaceOperation
{
   my $self=shift;
   my $tag=shift;
   my $data=shift;
   my ($replacemode,$search,$searchid,$replace,$replaceid)=@_;
   my $count=0;

   my $dataobj=getModuleObject($self->getParent->Config,$data->{dataobj});
   my $opdataobj=getModuleObject($self->getParent->Config,$data->{dataobj});
   if (defined($dataobj)){
      my $idname=$dataobj->IdField->Name();
      my %flt;
      if (exists($data->{baseflt}) && ref($data->{baseflt}) eq "HASH"){
         %flt=%{$data->{baseflt}};
      }
      $flt{$data->{idfield}}=\$searchid;
      $dataobj->SetFilter(\%flt);
      $dataobj->SetCurrentView(qw(ALL));
      my ($rec,$msg)=$dataobj->getFirst(unbuffered=>1);
      if (defined($rec)){
         do{
            if ($opdataobj->ValidatedUpdateRecord($rec,
                                  {$data->{target}=>$replace},
                                  {$idname=>\$rec->{$idname}})){
               $count++;
            }
            ($rec,$msg)=$dataobj->getNext();
         }until(!defined($rec));
      }
   }

   return($count);
}

1;
