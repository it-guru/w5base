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
           contacts=>{
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

   if ($tag ne "contacts"){
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
         });

         
      }
   }

   return("$tag:ok\n");
}

1;
