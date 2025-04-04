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


   $self->RegisterEvent("wftest","wftest");
   $self->RegisterEvent("memtest","memtest");
   $self->RegisterEvent("filecheck","filecheck");
   $self->RegisterEvent("test","test");
   $self->RegisterEvent("sample","SampleEvent1");
   $self->RegisterEvent("sample1","SampleEvent1",timeout=>180);
   $self->RegisterEvent("timeoutcheck","TimeOutError",timeout=>5);
   $self->RegisterEvent("sample2","SampleEvent2");
   $self->RegisterEvent("sample3","SampleEvent3");
   $self->RegisterEvent("MyTime","SampleEvent2");
   $self->RegisterEvent("long","base::event::sample::SampleEvent1");
   $self->RegisterEvent("long","SampleEvent3");
   $self->RegisterEvent("ft","ft");
   $self->RegisterEvent("LongRunner","LongRunner");
   $self->RegisterEvent("loadsys","loadsys");
   $self->RegisterEvent("testmail1","TestMail1");
   $self->RegisterEvent("testmail2","TestMail2");
   $self->CreateIntervalEvent("MyTime",10);
   return(1);
}

sub ft
{
   my $self=shift;

   use kernel::FileTransfer;

   my $ft=new kernel::FileTransfer($self,"tsft");

   my ($st,$errstr)=$ft->Connect();


   if ($st){
      printf STDERR (" -- Connect OK to  $ft\n");
      if ($ft->Put("sample.pm","tmp/sample1.pm")){
         printf STDERR (" -- Put sample.pm to tmp/sample1.pm OK\n");
         if (defined(my $s=$ft->Exists("tmp/sample1.pm"))){
            printf STDERR (" -- Exists on sample1.pm =$s\n");
         }
         if (defined(my $s=$ft->Exists("tmp/sample2.pm"))){
            printf STDERR (" -- Exists on sample2.pm =$s\n");
         }
         if ($ft->Cd("tmp")){
            printf STDERR (" -- Cd tmp OK\n");
            if ($ft->Get("sample1.pm","x.pmx")){
               printf STDERR (" -- get sample1.pm x.pmx OK\n");
            }
            else{
               printf STDERR (" -- get sample1.pm x.pmx fail\n");
            }
         }
         else{
            printf STDERR (" -- Cd tmp fail\n");
         }
      }
      else{
         printf STDERR (" -- Put sample.pm to tmp/sample.pm failed\n");
      }
      if ($ft->Disconnect()){
         printf STDERR (" -- Disconnect OK\n");
      }
      else{
         printf STDERR (" -- Disconnect failed\n");
      }
   }
   else{
      printf("connect failed - $errstr\n");
   }



   return({exitcode=>0,msg=>'ok'});
}


sub LongRunner
{
   my $self=shift;

   for(my $c=0;$c<20;$c++){
      msg(DEBUG,"LonRunner Loop $c");
      last if ($self->ServerGoesDown());
      sleep(1);
   }
   return({exitcode=>0,msg=>'ok'});
}

sub filecheck
{
   my $self=shift;
   if (-f "/tmp/file"){
      return({exitcode=>0,msg=>'ok'});
   }
   return({exitcode=>1,msg=>'file not found'});
   
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

   my @emailto=qw(hartmut.vogler@com);
   for(my $c=0;$c<1640;$c++){
      push(@emailto,"a.abcdefg$c\@de");
   }

   my $wf=getModuleObject($self->Config,"base::workflow");
   if (my $id=$wf->Store(undef,{
          class    =>'base::workflow::mailsend',
          step     =>'base::workflow::mailsend::dataload',
          name     =>'Largeeine Mail vom Testevent1 mit äöüß',
          emailto  =>\@emailto,
          emailfrom=>'"Vogler, Hartmut" <>',
          emailtext=>["Dies ist der\n 1. Text",'dies der 2.','und der d 100 Zeichen: 12345xljkchvjkyxchvkjyxhcvkljyxchvkljyxhcvkjlyxhcvkljhyxckjvhyxkjcvhyxk1234567890ritte'],
          emailhead=>['Head1','Head2 mal ein gaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaanz langer Text1234567345624354357246357832','Head3'],
          emailtstamp=>['01.01.2000 14:14:00',undef,'02.02.2000 01:01:01'],
          emailprefix=>['sued/xxxxxx.hartmut',undef,'nobody'],
         })){
      my $r=$wf->Store($id,step=>'base::workflow::mailsend::waitforspool');
      return({msg=>'versandt'});
   }
   return({msg=>'shit'});
}

sub modWf
{
   my $self=shift;
   my $p=$self;

   my $wf=getModuleObject($self->Config,"base::workflow");
   my $op=$wf->Clone();

   $wf->SetFilter({class=>\'AL_TCom::workflow::businesreq',
                   id=>[qw( )]});
   foreach my $rec ($wf->getHashList(qw(ALL))){
      msg(INFO,"msg=".Dumper($rec));
      $op->CleanupWorkspace($rec->{id});
      $op->ValidatedUpdateRecord($rec,{eventend=>NowStamp("en"),
                                       closedate=>NowStamp("en"),
                                       stateid=>21,
                                       fwdtarget=>undef,
                                       step=>'base::workflow::request::finish',
                                       fwdtargetid=>undef
                                       },{id=>\$rec->{id}});
   }



   return({exitcode=>0});
}

sub SampleEvent1
{
   my $self=shift;
   my $p=$self;

   msg(INFO,"Start(Event1): ... sleep no");
   my $now=NowStamp("en");
   msg(DEBUG,"DATE now=".$now);
   msg(DEBUG,"DATE ExpandTimeExpression (default)=".
             $p->ExpandTimeExpression($now));
   msg(DEBUG,"DATE ExpandTimeExpression (CET)=".
             $p->ExpandTimeExpression($now,undef,"GMT","CET"));
   msg(DEBUG,"DATE ExpandTimeExpression (CET,de)=".
             $p->ExpandTimeExpression($now,"de","GMT","CET"));
   msg(DEBUG,"DATE ExpandTimeExpression (CET,RFC822)=".
             $p->ExpandTimeExpression($now,"RFC822","GMT","CET"));
   msg(DEBUG,"DATE ExpandTimeExpression (UTC,RFC822)=".
             $p->ExpandTimeExpression($now,"RFC822","GMT","UTC"));
   msg(DEBUG,"DATE ExpandTimeExpression (CET,stamp)=".
             $p->ExpandTimeExpression($now,"stamp","GMT","CET"));
   kill(10,$$);




   msg(DEBUG,"End  (Event1):");
   return({msg=>'heinz',exitcode=>0});
}


sub wftest
{
   my $self=shift;

   eval("use Time::HiRes qw( usleep time clock);");
   foreach my  $mod (qw(base::user base::grp base::workflow)){
      my $st=Time::HiRes::time();
      msg(DEBUG,"Start(wftest\@$mod): %lf",$st);
      my $o=getModuleObject($self->Config,$mod);
      if (defined($o)){
         my $en=Time::HiRes::time();
         my $t=$en-$st;
         msg(DEBUG,"End(wftest\@$mod):%lf   = op:%lf",$en,$t);
      }
   }


   return({exitcode=>0});
}


sub memtest
{
   my $self=shift;

   msg(DEBUG,"Start(memtest):");
   eval("use GTop;"); 
   msg(DEBUG,"W5V2::Cache=%s\n",join(",",keys(%{$W5V2::Cache->{w5base2}})));
   msg(DEBUG,"W5V2::Context=%s\n",join(",",keys(%{$W5V2::Context})));
   my $g0=GTop->new->proc_mem($$);
   for(my $cc=0;$cc<50;$cc++){ 
      my $g1=GTop->new->proc_mem($$);
      for(my $c=0;$c<10000;$c++){ 
         my $e=NowStamp("en");
      }
      my $g=GTop->new->proc_mem($$);
      msg(DEBUG,"loop=%02d mem=".$g->vsize." total=%d loopdelta=%d\n",$cc,$g-$g0,$g-$g1);
   }
   msg(DEBUG,"End  (memtest):");
   msg(DEBUG,"W5V2::Context=%s\n",join(",",keys(%{$W5V2::Context})));
   msg(DEBUG,"W5V2::Cache=%s\n",join(",",keys(%{$W5V2::Cache->{w5base2}})));
   return({exitcode=>0});
}


sub SampleEvent2
{
   my $self=shift;

   my $user=getModuleObject($self->Config,"itil::system");
   $user->SetFilter({systemid=>[qw(S06705023 S19907575)]});
   my @l=$user->getHashList(qw(systemname applications customer));

   $user->Log(WARN,'backlog',"SampleEvent2 just for fun and test");

   for my $rec (@l){
      print STDERR hash2xml({'struct'=>{'entry'=>$rec->{customer}}});

   }
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

   my $sys=getModuleObject($self->Config,"itil::system");
   if (!$sys->Ping()){
      return({msg=>'ping failed to dataobject '.$sys->Self(),exitcode=>1});
   }



   $sys->SetFilter({name=>$name});
   my @l=$sys->getHashList(qw(systemid assetassetid systemname));
printf STDERR ("res=%s\n",Dumper(\@l));
   $res=$l[0]->{assetassetid};


   return($res); 
}





1;
