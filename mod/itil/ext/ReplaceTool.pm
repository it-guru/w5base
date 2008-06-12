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
           databoss=>{
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
           businessteam=>{
             replaceoptype=>'base::grp',
             dataobj      =>'itil::appl',
             target       =>'businessteam',
             idfield      =>'businessteamid'
           },
           sem2=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::appl',
             target       =>'sem2',
             idfield      =>'sem2id'
           },
           usercontacts=>{
             replaceoptype=>'base::user',
             dataobj      =>'itil::appl',
             target       =>'contacts',
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

   if ($tag ne "usercontacts"){
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
         my ($rec,$msg)=$dataobj->getFirst();
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
   }
   if ($tag eq "usercontacts"){
      my $dataobj=getModuleObject($self->getParent->Config,$data->{dataobj});
      my $cobj=getModuleObject($self->getParent->Config,"base::lnkcontact");
      if (defined($dataobj)){
         my $idname=$dataobj->IdField->Name();
         $dataobj->SetFilter({cistatusid=>'<=5'});
         $dataobj->SetCurrentView($data->{target});
         my ($rec,$msg)=$dataobj->getFirst();
         if (defined($rec)){
            do{
               foreach my $contact (@{$rec->{$data->{target}}}){
                  if ($contact->{target} eq $data->{replaceoptype} &&
                      $contact->{targetid}==$searchid){
                     $cobj->ResetFilter();
                     $cobj->SetFilter(id=>\$contact->{id});
                     $cobj->SetCurrentView(qw(ALL));
                     my ($rec,$msg)=$cobj->getFirst();
                     if (defined($rec)){
                        do{
                           $cobj->ValidatedUpdateRecord($rec,
                                                 {targetname=>$replace},
                                                 {id=>\$rec->{id}});
                           $count++;
                           ($rec,$msg)=$cobj->getNext();
                        }until(!defined($rec));
                     }
                  }
               }
               ($rec,$msg)=$dataobj->getNext();
           }until(!defined($rec));
        }
      }
   }

   return($count);
}

1;
