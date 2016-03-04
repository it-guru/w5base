package tssm::event::smchange;
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
use kernel::Event;
use tssm::lib::io;
@ISA=qw(kernel::Event tssm::lib::io);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->{timeout}=1800;

   return($self);
}

sub Init
{
   my $self=shift;


   $self->RegisterEvent("smchange","smchange",timeout=>$self->{timeout});
}

sub smchange
{
   my $self=shift;
   my %param=@_;

   my $selfname=$self->Self();
   $self->InitScImportEnviroment();
   my $chm=getModuleObject($self->Config,"tssm::chm");
   msg(DEBUG,"ServiceManager chm is connected");
   $chm->SetCurrentView(qw(addgrp approvalstatus approved assignarea
                           assignedto category changenumber closecode
                           closedby closetime complexity coordinator
                           coordinatorname coordinatorposix chmmgrgrp
                           createtime criticality description device editor
                           fallback impact implementor name phase
                           plannedend plannedstart priority project
                           reason relations requestedby resolvedby
                           resolvetime resources risk srcid srcsys
                           status sysmodtime tasks type
                           urgency workduration workend workstart));

   $chm->SetCurrentOrder("sysmodtime");
   msg(DEBUG,"view is set");
   my $focus="now";
   my %flt=(sysmodtime=>">$focus-24h");
   if (!defined($param{changenumber}) && !defined($param{sysmodtime}) &&
       !defined($param{plannedend})){
      $self->{wf}->SetFilter(srcsys=>\$selfname,srcload=>">now-3d");
      msg(DEBUG,"finding last srcload");
      my ($wfrec,$msg)=$self->{wf}->getOnlyFirst(qw(srcload));
      if (defined($wfrec)){
         $focus=$wfrec->{srcload};
     #    my $nowstamp=NowStamp("en");
     #    my $dur=CalcDateDuration($focus,$nowstamp);
     #    if (abs($dur->{totalminutes}>120)
     #    printf STDERR ("fifi dur=%s\n",Dumper($dur));
     #    printf STDERR ("focus=$focus nowstamp=$nowstamp\n");
     #    exit(1);

         %flt=(sysmodtime=>"\">$focus-4m\"");
      }
   }
   else{
      if (defined($param{plannedend})){
         %flt=(plannedend=>$param{plannedend});
      }
      if (defined($param{changenumber})){
         %flt=(changenumber=>\$param{changenumber});
      }
      if (defined($param{sysmodtime})){
         %flt=(sysmodtime=>$param{sysmodtime});
      }
   }
   $flt{plannedstart}="![EMPTY]";
   msg(DEBUG,"filter=%s",Dumper(\%flt));
   $chm->SetFilter(\%flt);
   my ($rec,$msg)=$chm->getFirst();
   if (defined($rec)){
      READLOOP: do{
         if ($self->ServerGoesDown()){  # this is needed, because this is a
            last READLOOP;              # long running event!
         }
         if ((!$chm->Ping()) || (!$self->{wf}->Ping())){
            my $msg="database connection aborted";
            msg(ERROR,"db record problem: %s",$msg);
            return({exitcode=>2,msg=>$msg});
         }
         $self->ProcessServiceManagerRecord($selfname,$rec,$chm);
         ($rec,$msg)=$chm->getNext();
         if (defined($msg)){
            msg(ERROR,"db record problem: %s",$msg);
            return({exitcode=>1,msg=>$msg});
         }
      }until(!defined($rec));
   }
   else{
      if (defined($msg)){
         msg(ERROR,"db init problem: %s",$msg);
         return({exitcode=>1});
      }
   }
   
   return({exitcode=>0,msg=>'OK'}); 
}


1;
