package tssm::event::smproblem;
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

   return($self);
}

sub Init
{
   my $self=shift;


   $self->RegisterEvent("smproblem","smproblem",timeout=>1800);
}

sub smproblem
{
   my $self=shift;
   my %param=@_;

   my $selfname=$self->Self();
   $self->InitScImportEnviroment();
   my $prm=getModuleObject($self->Config,"tssm::prm");
   msg(DEBUG,"ServiceManager prm is connected");
   $prm->SetCurrentView(qw(sysmodtime closetime problemnumber name description 
                           status assignedto priority impact urgency
                           solution deviceid devicename
                           createtime closetime srcid triggeredby
                           creator editor softwareid assignedto homeassignment
                           createtime type resources closecode));

   msg(DEBUG,"view is set");
   my $focus="now";
   my %flt=(sysmodtime=>">$focus-24h");
   if (!defined($param{problemnumber}) && !defined($param{sysmodtime}) &&
       !defined($param{closetime})){
      $self->{wf}->SetFilter(srcsys=>\$selfname,srcload=>">now-3d");
      msg(DEBUG,"finding last srcload");
      my ($wfrec,$msg)=$self->{wf}->getOnlyFirst(qw(srcload));
      if (defined($wfrec)){
         $focus=$wfrec->{srcload};
         %flt=(sysmodtime=>"\">$focus-4m\"");
      }
   }
   else{
      if (defined($param{closetime})){
         %flt=(closetime=>$param{closetime});
      }
      if (defined($param{problemnumber})){
         %flt=(problemnumber=>\$param{problemnumber});
      }
      if (defined($param{sysmodtime})){
         %flt=(sysmodtime=>$param{sysmodtime});
      }
   }
   #my %flt=(creator=>"WBEEZ",sysmodtime=>'>now-24h');
   msg(DEBUG,"filter=%s",Dumper(\%flt));
   $prm->SetFilter(\%flt);
   my ($rec,$msg)=$prm->getFirst();
   if (defined($rec)){
      READLOOP: do{
         if ($self->ServerGoesDown()){
            last READLOOP;
         }
         if ((!$prm->Ping()) || (!$self->{wf}->Ping())){
            my $msg="database connection aborted";
            msg(ERROR,"db record problem: %s",$msg);
            return({exitcode=>2,msg=>$msg});
         }
         $self->ProcessServiceManagerRecord($selfname,$rec,$prm);
         ($rec,$msg)=$prm->getNext();
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
