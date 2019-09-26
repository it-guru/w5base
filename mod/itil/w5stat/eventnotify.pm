package itil::w5stat::eventnotify;
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
use DateTime;
use DateTime::Span;
use DateTime::SpanSet;

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

sub processData
{
   my $self=shift;
   my $statstream=shift;
   my $dstrange=shift;
   my %param=@_;
   my $count;

   return() if ($statstream ne "default");

   my $wf=getModuleObject($self->getParent->Config,"base::workflow");
   $wf->SetCurrentView(qw(ALL));
   my %q1;
   $q1{class}=[grep(/^.*::eventnotify$/,keys(%{$wf->{SubDataObj}}))];
   $q1{eventend}=[undef];
   my %q2=%q1;
   $q2{eventend}="($dstrange)";

   $wf->SetFilter([\%q1,\%q2]);
   $wf->SetCurrentOrder("NONE");
   $wf->SetCurrentView(qw(ALL));
   msg(INFO,"starting collect of itil::workflow::eventinfo");$count=0;
   my ($rec,$msg)=$wf->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         $self->getParent->processRecord($statstream,'itil::workflow::eventinfo',
                                         $dstrange,$rec,%param);
         ($rec,$msg)=$wf->getNext();
         $count++;
      } until(!defined($rec));
   }
   msg(INFO,"end itil::workflow::eventinfo count=$count");
}


sub processRecord
{
   my $self=shift;
   my $statstream=shift;
   my $module=shift;
   my $monthstamp=shift;
   my $rec=shift;
   my %param=@_;
   my ($year,$month)=$monthstamp=~m/^(\d{4})(\d{2})$/;

   return() if ($statstream ne "default");

   if ($module eq "itil::workflow::eventinfo"){
      my $eventstart=$rec->{eventstart};
      my $eventend=$rec->{eventend};
      if (!defined($eventend)){
         $eventend=NowStamp("en");
      }
      my $team=$rec->{involvedbusinessteam};
      if ($team ne ""){
         msg(INFO,"eventstart=$eventstart evenend=$eventend ".
                  "team=$rec->{involvedbusinessteam}");

         $self->getParent->storeStatVar("Group",[$team],{},
                                         "ITIL.Workflow.Eventinfo.Count",1);
         if ((my ($Y1,$M1,$D1,$h1,$m1,$s1)=$eventstart=~
              m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/) &&
             (my ($Y2,$M2,$D2,$h2,$m2,$s2)=$eventend=~
              m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/)){
            my $d1=new DateTime(year=>$Y1, month=>$M1, day=>$D1,
                                hour=>$h1, minute=>$m1, second=>$s1);
            my $d2=new DateTime(year=>$Y2, month=>$M2, day=>$D2,
                                hour=>$h2, minute=>$m2, second=>$s2);
            my $span;
            eval('$span=DateTime::Span->from_datetimes(start=>$d1,end=>$d2);');
            if (defined($param{basespan})){
               $self->getParent->storeStatVar("Group",[$team],
                             {method=>'concat'},
                             "ITIL.Workflow.Eventinfo.IdList",$rec->{id});
               my $ss=DateTime::SpanSet->from_spans(spans=>[$span]);
               $ss=$ss->intersection($param{basespan});
               my $tsum=0;
               foreach my $span ($ss->as_list()){
                  my $d=CalcDateDuration($span->start,$span->end);
                  $tsum+=$d->{totalseconds};
               }
               $self->getParent->storeStatVar("Group",[$team],{},
                                "ITIL.Workflow.Eventinfo.EventDuration",$tsum);
            }
         }
      }
   }
}


1;
