package base::event::sample;
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


   $self->RegisterEvent("sample","SampleEvent1");
   $self->RegisterEvent("sample1","SampleEvent1",timeout=>180);
   $self->RegisterEvent("timeoutcheck","TimeOutError",timeout=>5);
   $self->RegisterEvent("sample","SampleEvent2");
   $self->RegisterEvent("sample2","SampleEvent2");
   $self->RegisterEvent("MyTime","SampleEvent2");
   $self->RegisterEvent("long","base::event::sample::SampleEvent1");
   $self->RegisterEvent("long","SampleEvent3");
   $self->RegisterEvent("loadsys","loadsys");
   $self->RegisterEvent("testmail1","TestMail1");
   $self->RegisterEvent("testmail2","TestMail2");
   $self->CreateIntervalEvent("MyTime",10);
   return(1);
}

sub TimeOutError
{
   my $self=shift;

   sleep(10);
   return({exitcode=>0,msg=>'ok'});
}

sub TestMail1
{
   my $self=shift;

   my $wf=getModuleObject($self->Config,"base::workflow");
   my $r=$wf->Store(12295216960002,{mandator=>['AL T-Com','xx',mandatorid=>44]});
   return({msg=>'shit'});
}

sub TestMail2
{
   my $self=shift;

   my $wf=getModuleObject($self->Config,"base::workflow");
   if (my $id=$wf->Store(undef,{
          class    =>'base::workflow::mailsend',
          step     =>'base::workflow::mailsend::dataload',
          name     =>'eine Mail vom Testevent1 mit äöüß',
          emailto  =>'hartmut.vogler@xxxxxx.com',
          emailtext=>["Dies ist der\n 1. Text",'dies der 2.','und der d 100 Zeichen: 12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890ritte'],
          emailhead=>['Head1','Head2 mal ein gaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaanz langer Text1234567345624354357246357832','Head3'],
          emailtstamp=>['01.01.2000 14:14:00',undef,'02.02.2000 01:01:01'],
          emailprefix=>['sued/vogler.hartmut',undef,'nobody'],
         })){
      my $r=$wf->Store($id,step=>'base::workflow::mailsend::waitforspool');
      return({msg=>'versandt'});
   }
   return({msg=>'shit'});
}

sub SampleEvent1
{
   my $self=shift;

   msg(DEBUG,"Start(Event1): ... sleep no");
   my $user=getModuleObject($self->Config,"base::user");
   $user->SetFilter({fullname=>'vog* wiescho*'});
   my @l=$user->getHashList(qw(fullname owner accounts));
   printf STDERR ("fifi l=%s\n",Dumper(\@l));
   msg(DEBUG,"End  (Event1):");
   return({msg=>'heinz',exitcode=>0});
}


sub SampleEvent2
{
   my $self=shift;

   my $user=getModuleObject($self->Config,"tsacinv::system");
   msg(DEBUG,"user=$user");
   msg(DEBUG,"Start(Event2):");
   my $n=$user->CountRecords();
   msg(DEBUG,"End(Event2): n=$n");
   return({exitcode=>-1});
}

sub SampleEvent3
{
   my $self=shift;
   my $sec=shift;
   my $this="SampleEvent3";
   $sec=3 if (!defined($sec));

   msg(DEBUG,"Start(Event3) config=%s",$self->Config);
   for(my $c=0;$c<$sec;$c++){
      msg(DEBUG,"Wait(Event3): ... sleep 1");sleep(1);
      $self->ipcStore("working at $c");
   }
   msg(DEBUG,"End  (Event3): self=$self ipc=$self->{ipc}");
   return({result=>"jo"});
}

sub loadsys
{
   my $self=shift;
   my $name=shift;
   my $res={};

   my $sys=getModuleObject($self->Config,"tsacinv::system");
   $sys->SetFilter({systemname=>$name});
   my @l=$sys->getHashList(qw(systemid assetassetid systemname));
printf STDERR ("res=%s\n",Dumper(\@l));
   $res=$l[0]->{assetassetid};


   return($res); 
}





1;
