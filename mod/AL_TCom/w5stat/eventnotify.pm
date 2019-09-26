package AL_TCom::w5stat::eventnotify;
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
      if ($team ne "" && 
          ($rec->{eventstatclass}==1 || $rec->{eventstatclass}==2)){
         msg(INFO,"wfheadid=$rec->{id} ".
                  "eventstart=$eventstart evenend=$eventend ".
                  "team=$rec->{involvedbusinessteam}");

         $self->getParent->storeStatVar("Group",[$team],{},
                                    "ITIL.Workflow.AL_TCom.Eventinfo.Count",1);
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
                         "ITIL.Workflow.AL_TCom.Eventinfo.IdList",$rec->{id});
               my $ss=DateTime::SpanSet->from_spans(spans=>[$span]);
               $ss=$ss->intersection($param{basespan});
               my $tsum=0;
               foreach my $span ($ss->as_list()){
                  my $d=CalcDateDuration($span->start,$span->end);
                  $tsum+=$d->{totalseconds};
               }
               $self->getParent->storeStatVar("Group",[$team],{},
                       "ITIL.Workflow.AL_TCom.Eventinfo.EventDuration",$tsum);
            }
            else{
               msg(ERROR,"no basespan defined");
            }
         }
      }
   }
}


1;
