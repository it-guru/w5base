package AL_TCom::event::finishInetworkWf;
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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

   $self->RegisterEvent("finishinwf","finishinwf");
   return(1);
}


sub finishinwf
{
   my $self=shift;
   my %param=@_;

   #return({exitcode=>0}) if (!$param{max});

   my $userid='11697377440001'; # service/inetwork

   my $wf=getModuleObject($self->Config,"base::workflow");
   my $wfop=$wf->Clone();

   my $flt={class=>\'AL_TCom::workflow::businesreq',
            stateid=>\'<21',
            openuser=>\$userid};
   $wf->SetFilter($flt);
   #$wf->Limit($param{max});
   $wf->SetCurrentOrder(qw(NONE));
   $wf->SetCurrentView(qw(id closedate class));

   my $c=0;

   my ($rec,$msg)=$wf->getFirst(unbuffered=>1);
   if (defined($rec)) {
      do {
         msg(INFO,"process $rec->{id} class=$rec->{class}");
            if ($wfop->Action->StoreRecord($rec->{id},"wfautofinish",
                {translation=>'base::workflowaction'},"",undef)) {
               my $closedate=$rec->{closedate};
               $closedate=NowStamp("en") if ($closedate eq "");

               $wfop->UpdateRecord({stateid=>25,
                                    closedate=>$closedate,
                                    fwdtarget=>undef,
                                    fwdtargetid=>undef,
                                    step=>'base::workflow::request::finish'},
                                   {id=>\$rec->{id}});
               $c++;
               $wfop->StoreUpdateDelta({id=>$rec->{id},
                                        stateid=>$rec->{stateid}},
                                       {id=>$rec->{id},
                                        stateid=>25});
            }
         ($rec,$msg)=$wf->getNext();
       } until(!defined($rec));
   }

   return({exitcode=>0,msg=>"$c iNetwork businessrequests finished"});
}



1;
