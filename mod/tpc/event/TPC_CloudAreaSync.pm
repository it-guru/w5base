package tpc::event::TPC_CloudAreaSync;
#  W5Base Framework
#  Copyright (C) 2020  Hartmut Vogler (it@guru.de)
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



sub TPC_CloudAreaSync
{
   my $self=shift;
   my $queryparam=shift;

   my $inscnt=0;

   my @a;
   my %itcloud;

   my $pro=getModuleObject($self->Config,"tpc::project");
   my $dep=getModuleObject($self->Config,"tpc::deployment");
   my $itcloudobj=getModuleObject($self->Config,"itil::itcloud");

   if (!($pro->Ping()) ||
       !($dep->Ping()) ||
       !($itcloudobj->Ping())){
      msg(ERROR,"not all dataobjects available");
      return(undef);
   }

   my $StreamDataobj="tssiem::secscan";


   my $joblog=getModuleObject($self->Config,"base::joblog");
   my $eventlabel='IncStreamAnalyse::'.$dep->Self;
   my $method=(caller(0))[3];

   $joblog->SetFilter({name=>\$method,
                       exitcode=>\'0',
                       exitmsg=>'last:*',
                       cdate=>">now-4d",
                       event=>\$eventlabel});
   $joblog->SetCurrentOrder('-cdate');

   $joblog->Limit(1);
   my ($firstrec,$msg)=$joblog->getOnlyFirst(qw(ALL));

   my %jobrec=( name=>$method, event=>$eventlabel, pid=>$$);
   my $exitmsg="done";
   my $ncnt=0;
   my $lastid="undefined";
   my $jobid=$joblog->ValidatedInsertRecord(\%jobrec);
   msg(DEBUG,"jobid=$jobid");

   my %flt=('status'=>'CREATE_SUCCESSFUL');
   {    
      $flt{cdate}=">now-14d";
      if (defined($firstrec)){
         my $lastmsg=$firstrec->{exitmsg};
         my $laststamp;
         if (($laststamp,$lastid)=
             $lastmsg=~m/^last:(\d+-\d+-\d+ \d+:\d+:\d+)\s+(\S+)$/){
            $flt{cdate}=">=\"$laststamp GMT\"";
            $exitmsg=$lastmsg;
         }
      }
   }

   {
      $dep->ResetFilter();
      $dep->SetFilter(\%flt);
      $dep->Limit(1000,0,0);
      $dep->SetCurrentOrder(qw(cdate id));
      foreach my $deprec ($dep->getHashList(qw(ALL))){
         if ($deprec->{id} eq $lastid){
            msg(INFO,"skip $deprec->{cdate} with $deprec->{id}");
            next;
         }
         $ncnt++;
         #msg(INFO,"$ncnt) op:".$deprec->{opname});
         #msg(INFO,"cdate:".$deprec->{cdate});
         #msg(INFO,"project:".$deprec->{projectid}."\n--\n");
         # print STDERR Dumper($deprec);
         printf STDERR ("$deprec->{cdate} ".
                        "TPC: $deprec->{opname} \@ $deprec->{project}\n");
         $exitmsg="last:".$deprec->{cdate}." ".$deprec->{id};
         last if ($ncnt>50);
      }
   }
   #printf STDERR ("lastmsg:$exitmsg\n");

   $joblog->ValidatedUpdateRecord({id=>$jobid},
                                 {exitcode=>"0",
                                  exitmsg=>$exitmsg,
                                  exitstate=>"ok - $ncnt messages"},
                                 {id=>\$jobid});

   return({exitcode=>0,exitmsg=>'ok'});
}






1;
