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
      if (defined($dataobj)){
         my $idname=$dataobj->IdField->Name();
         $dataobj->SetFilter({cistatusid=>'<=5',
                              $data->{idfield}=>\$searchid});
         $dataobj->SetCurrentView(qw(ALL));
         $dataobj->ForeachFilteredRecord(sub{
               my $rec=$_;
               $dataobj->ValidatedUpdateRecord($rec,
                                     {$data->{target}=>$replace},
                                     {$idname=>\$rec->{$idname}});
               $count++;
         });
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
                     $cobj->ForeachFilteredRecord(sub{
                           my $rec=$_;
                           $cobj->ValidatedUpdateRecord($rec,
                                                 {targetname=>$replace},
                                                 {id=>\$rec->{id}});
                           $count++;
                     });
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
