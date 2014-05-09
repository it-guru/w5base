package AL_TCom::event::patchApplMgrWrite;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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


sub patchApplMgrWrite
{
   my $self=shift;
   my $appl=getModuleObject($self->Config,"itil::appl");


   #
   # System operation
   #
   $appl->SetFilter({cistatusid=>"<6"});
   $appl->SetCurrentView(qw(name id contacts applmgr applmgrid));
   #$sys->SetNamedFilter("X",{name=>'!ab1*'});
   $appl->Limit(10,0,0);
   my ($rec,$msg)=$appl->getFirst();
   if (defined($rec)){
      do{
         msg(INFO,"process system: $rec->{name} (applmgrid=$rec->{applmgrid})");
         $self->patchRecord("itil::appl",$rec);
         ($rec,$msg)=$appl->getNext();
      } until(!defined($rec));
   }


   return({exitcode=>0});
}

sub patchRecord
{
   my $self=shift;
   my $parent=shift;
   my $rec=shift;
   my $lnk=getModuleObject($self->Config,"base::lnkcontact");

   return(undef) if ($rec->{applmgrid} eq "");

   my $lnkcontactid;
   my $writefound=0;
   foreach my $crec (@{$rec->{contacts}}){
      if ($crec->{target} eq "base::user" &&
          $crec->{targetid} eq $rec->{applmgrid}){
         my $roles=$crec->{roles};
         if (defined($roles)){
            $roles=[$roles] if (ref($roles) ne "ARRAY");
         }
         else{
            $roles=[];
         }
         $lnkcontactid={id=>$crec->{id},roles=>$roles};
         if (in_array($roles,"write")){
            $writefound=1;
         }
      }
   }
   if ($writefound){
      msg(INFO,"alles Super - ApplMgr hat bereits write rechte");
      return(undef);
   }
   my $refid=$rec->{id};
   if (defined($lnkcontactid)){
      $lnk->ResetFilter();
      $lnk->SetFilter({id=>\$lnkcontactid->{id}});
      my ($oldlnkrec)=$lnk->getOnlyFirst(qw(ALL));
      msg(INFO,"update contact entry to $rec->{name}");
      $lnk->ValidatedUpdateRecord($oldlnkrec,{
        refid=>$refid,
        target=>'base::user',
        parentobj=>$parent,
        targetid=>$rec->{applmgrid},
        roles=>[@{$lnkcontactid->{roles}},"write"]
      },{id=>\$lnkcontactid->{id}});
   }
   else{
      $lnk->ValidatedInsertRecord({
        refid=>$refid,
        target=>'base::user',
        parentobj=>$parent,
        targetid=>$rec->{applmgrid},
        comments=>'load by SACM Processmanager instruction',
        roles=>["write"]
      });
   }
   return(undef);
}

1;
