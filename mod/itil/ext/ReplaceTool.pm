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
             idfield      =>'databossid',
             targetlabel  =>'name'
           },
           tsm=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::appl',
             target       =>'tsm',
             idfield      =>'tsmid',
             targetlabel  =>'name'
           },
           tsm2=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::appl',
             target       =>'tsm2',
             idfield      =>'tsm2id',
             targetlabel  =>'name'
           },
           sem=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::appl',
             target       =>'sem',
             idfield      =>'semid',
             targetlabel  =>'name'
           },
           applmgr=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::appl',
             target       =>'applmgr',
             idfield      =>'applmgrid',
             targetlabel  =>'name'
           },
           guardianteam=>{
             replaceoptype=>'base::grp',
             dataobj      =>'itil::asset',
             target       =>'guardianteam',
             idfield      =>'guardianteamid',
             targetlabel  =>'name'
           },
           adminteam=>{
             replaceoptype=>'base::grp',
             dataobj      =>'itil::system',
             target       =>'adminteam',
             idfield      =>'adminteamid',
             targetlabel  =>'name'
           },
           businessteam=>{
             replaceoptype=>'base::grp',
             dataobj      =>'itil::appl',
             target       =>'businessteam',
             idfield      =>'businessteamid',
             targetlabel  =>'name'
           },
           responseteam=>{
             replaceoptype=>'base::grp',
             dataobj      =>'itil::appl',
             target       =>'responseteam',
             idfield      =>'responseteamid',
             targetlabel  =>'name'
           },
           sem2=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::appl',
             target       =>'sem2',
             idfield      =>'sem2id',
             targetlabel  =>'name'
           },
           systemdataboss=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::system',
             target       =>'databoss',
             idfield      =>'databossid',
             targetlabel  =>'name'
           },
           assetdataboss=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::asset',
             target       =>'databoss',
             idfield      =>'databossid',
             targetlabel  =>'name'
           },
           itclustdataboss=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::itclust',
             target       =>'databoss',
             idfield      =>'databossid',
             targetlabel  =>'name'
           },
           swinstancedataboss=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::swinstance',
             target       =>'databoss',
             idfield      =>'databossid',
             targetlabel  =>'fullname'
           },
           lnkapplappl=>{
             replaceoptype=>'itil::appl',
             dataobj      =>'itil::lnkapplappl',
             target       =>'toappl',
             idfield      =>'toapplid',
             targetlabel  =>'name'
           },
           servicesupportdataboss=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::servicesupport',
             target       =>'databoss',
             idfield      =>'databossid',
             targetlabel  =>'fullname'
           },
           servicesupportdataboss2=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::servicesupport',
             target       =>'databoss2',
             idfield      =>'databoss2id',
             targetlabel  =>'fullname'
           },
           businessservicedataboss=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::businessservice',
             target       =>'databoss',
             idfield      =>'databossid',
             targetlabel  =>'fullname'
           },
           businessservicefuncmgr=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::businessservice',
             target       =>'funcmgr',
             idfield      =>'funcmgrid',
             targetlabel  =>'fullname'
           },
           userbscontact=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::lnkbscontact',
             target       =>'targetname',
             idfield      =>'targetid',
             targetlabel  =>'businessservice',
             baseflt      =>{secparentobj=>\'itil::businessservice'}
           },
           userapplcontact=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::lnkapplcontact',
             target       =>'targetname',
             idfield      =>'targetid',
             targetlabel  =>'application',
             baseflt      =>{applcistatusid=>"<6"}
           },
           usersystemcontact=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::lnksystemcontact',
             target       =>'targetname',
             idfield      =>'targetid',
             targetlabel  =>'system',
             baseflt      =>{systemcistatusid=>"<6"}
           },
           userassetcontact=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::lnkassetcontact',
             target       =>'targetname',
             idfield      =>'targetid',
             targetlabel  =>'asset',
             baseflt      =>{assetcistatusid=>"<6"}
           },
           userswinstancecontact=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::lnkswinstancecontact',
             target       =>'targetname',
             idfield      =>'targetid',
             targetlabel  =>'swinstance',
             baseflt      =>{swinstancecistatusid=>"<6"}
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
