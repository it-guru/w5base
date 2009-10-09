package itil::ext::ReplaceTool;
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
           appldataboss=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::appl',
             target       =>'databoss',
             idfield      =>'databossid'
           },
           tsm=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::appl',
             target       =>'tsm',
             idfield      =>'tsmid'
           },
           tsm2=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::appl',
             target       =>'tsm2',
             idfield      =>'tsm2id'
           },
           sem=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::appl',
             target       =>'sem',
             idfield      =>'semid'
           },
           guardianteam=>{
             replaceoptype=>'base::grp',
             dataobj      =>'itil::asset',
             target       =>'guardianteam',
             idfield      =>'guardianteamid'
           },
           adminteam=>{
             replaceoptype=>'base::grp',
             dataobj      =>'itil::system',
             target       =>'adminteam',
             idfield      =>'adminteamid'
           },
           businessteam=>{
             replaceoptype=>'base::grp',
             dataobj      =>'itil::appl',
             target       =>'businessteam',
             idfield      =>'businessteamid'
           },
           responseteam=>{
             replaceoptype=>'base::grp',
             dataobj      =>'itil::appl',
             target       =>'responseteam',
             idfield      =>'responseteamid'
           },
           sem2=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::appl',
             target       =>'sem2',
             idfield      =>'sem2id'
           },
           systemdataboss=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::system',
             target       =>'databoss',
             idfield      =>'databossid'
           },
           assetdataboss=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::asset',
             target       =>'databoss',
             idfield      =>'databossid'
           },
           swinstancedataboss=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::swinstance',
             target       =>'databoss',
             idfield      =>'databossid'
           },
           lnkapplappl=>{
             replaceoptype=>'itil::appl',
             dataobj      =>'itil::lnkapplappl',
             target       =>'toappl',
             idfield      =>'toapplid'
           },
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
      my %flt=($data->{idfield}=>\$searchid);
      my $cistatusobj=$dataobj->getField("cistatusid");
      if (defined($cistatusobj)){
         $flt{cistatusid}='<=5';
      }
      $dataobj->SetFilter(\%flt);
      $dataobj->SetCurrentView(qw(ALL));
      my ($rec,$msg)=$dataobj->getFirst(unbuffered=>1);
      if (defined($rec)){
         do{
            $opdataobj->ValidatedUpdateRecord($rec,
                                  {$data->{target}=>$replace},
                                  {$idname=>\$rec->{$idname}});
            $count++;
            ($rec,$msg)=$dataobj->getNext();
         }until(!defined($rec));
      }
   }

   return($count);
}

1;
