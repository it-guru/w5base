package AL_TCom::event::patchSWInstance;
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

sub Init
{
   my $self=shift;


   $self->RegisterEvent("patchSWInstance","patchSWInstance");
   return(1);
}

sub patchSWInstance
{
   my $self=shift;
   my %n;
   my $n=0;
   $W5V2::HistoryComments="Workflow: https://darwin.telekom.de/darwin/auth/base/workflow/ById/12421206460002";
   my @ak=qw(12342243800002 12342243790002 12337059420002 12337059410002 12337059400002 12271395220004 12271395210002 12253536450002 12244907410004 12244904600002 12235070550002 12222391220002 12222389810002 12222388380002 12222386780002 12222384950002 12203444450012 12200114720020 12200114650006 12136197140002 12136197090002 12136195780004 12133555740002 12133554730002 12133551550004 12133551540006 12133551540002 12133551530002 12133551520004 12133551510004 12133551500004 12133551490004 12133551210010 12133551200007 12133551190004 12133551180008 12133551170004 12133551160006 12133551150010 12133551130006 12133551050004 12133550880002 12133550870002 12133550860002 12133550850002 12133550840002 12133550810004 12133550800008 12133550770002 12133550710008 12133550700006 12133550690004 12133550660002 12133550620004 12133550610002 12133550590002 12133550490002 12133550480002 12133550450004 12133550440004 12133550290006 12133550280008 12133550130002 12133550030004 12133550010002 12133549980004 12133549970002 12133549960002 12133549910002 12133549900002 12133549840008 12133549720004 12133549700004 12133549690006 12133549550002 12133549540002 12133549510004 12133549470004 12133549410006 12133549400006 12133549360004 12133549250008 12133549240002 12133549220008 12133549200004 12133549080004 12133549070004 12133549060004 12133549050004 12133549020004 12133549010006 12133549000002 12133548950002 12133548920004 12133548900004 12133548880002 12133548840002 12133548830002);
   my $user=getModuleObject($self->Config,"base::user");
   my $swi=getModuleObject($self->Config,"itil::swinstance");
   my $opswi=$swi->Clone();
   $swi->SetFilter({cistatusid=>4});
   $swi->SetCurrentOrder("NONE");
   $swi->SetCurrentView(qw(ALL));
   my ($rec,$msg)=$swi->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         if ($rec->{custcostalloc}==1 && !grep(/^$rec->{id}$/,@ak)){
            msg(INFO,"process $rec->{fullname}");
            $user->ResetFilter();
            $user->SetFilter({userid=>\$rec->{databossid}}); 
            my ($urec,$msg)=$user->getOnlyFirst(qw(email));
            if ($urec->{email} ne ""){
               $n{$urec->{email}}++;
            }
            if ($opswi->ValidatedUpdateRecord($rec,{custcostalloc=>0},
                                              {id=>\$rec->{id}})){
               msg(INFO,"changed customer cost alloc ".
                        "from 1 to 0");
            }
            $n++;
         }
         ($rec,$msg)=$swi->getNext();
         
      } until(!defined($rec));
   }
   msg(INFO,"relevant software instances: ".$n);
   msg(INFO,"notify databoss: ".join("; ",keys(%n)));

   return({exitcode=>0});
}

1;
