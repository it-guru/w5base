package base::event::wfschedule;
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


   $self->RegisterEvent("wfschedule","wfschedule");
   return(1);
}

sub wfschedule
{
   my $self=shift;
   my @target=@_;

   my $wf=getModuleObject($self->Config,"base::workflow");
   my $wfop=$wf->Clone();
   $wf->SetFilter([
                   {
                    stateid=>\'1',
                    autocopymode=>\'week',
                    autocopydate=>"[EMPTY]"
                   },
                   {
                    stateid=>\'1',
                    autocopymode=>\'week',
                    autocopydate=>"<=now-7d"
                   },
                   {
                    stateid=>\'1',
                    autocopymode=>\'month',
                    autocopydate=>"[EMPTY]"
                   },
                   {
                    stateid=>\'1',
                    autocopymode=>\'month',
                    autocopydate=>"<=now-1M"
                   }
                  ]);
   $wf->SetCurrentView(qw(ALL));
   my ($WfRec,$msg)=$wf->getFirst();
   if (defined($WfRec)){
      do{
         msg(DEBUG,"copy wfheadid=%s",$WfRec->{id});
         #msg(DEBUG,"WfRec=%s",Dumper($WfRec));
         my @copyfields=qw(name class step detaildescription 
                          stateid prio openuser openusername
                          additional headref kh);
         my %newrec;
         foreach my $fld (@copyfields){
            $newrec{$fld}=$WfRec->{$fld};
         }
         msg(DEBUG,"newrec=%s",Dumper(\%newrec));
         delete($newrec{id});
         if (ref($newrec{additional}) eq "HASH"){
            $newrec{additional}=Hash2Datafield(%{$newrec{additional}});
         }
         if (ref($newrec{headref}) eq "HASH"){
            $newrec{headref}=Hash2Datafield(%{$newrec{headref}});
         }
         $newrec{createdate}=NowStamp("en");
         $newrec{mdate}=NowStamp("en");
         my $newautocopydate=$WfRec->{autocopydate};
         if ($WfRec->{autocopydate} eq ""){
            $newautocopydate=$wf->ExpandTimeExpression("today","en",
                                                       "GMT","GMT");
         }
         else{
            my $now=NowStamp("en");
            my $dlt=CalcDateDuration($newautocopydate,$now);
            while($dlt->{totalseconds}>0){
               my $add="+1d";
               if ($WfRec->{autocopymode} eq "month"){
                  $add="+1M";
               }
               elsif($WfRec->{autocopymode} eq "week"){
                  $add="+7d";
               }
               my $chknewautocopydate=
                  $wf->ExpandTimeExpression($newautocopydate.$add,
                                            "en","GMT","GMT");
               $dlt=CalcDateDuration($chknewautocopydate,$now);
               if ($dlt->{totalseconds}<0){
                  last;
               }
               else{
                  $newautocopydate=$chknewautocopydate;
               }
            }
         }

         my $newid=$wfop->InsertRecord(\%newrec);
         msg(DEBUG,"new id=%s",$newid);
         if ($newid ne ""){
            $wfop->SetFilter({id=>\$newid});
            my ($newWfRec,$msg)=$wfop->getOnlyFirst(qw(ALL));
            if (defined($newWfRec)){
               if ($wfop->nativProcess("wfactivate",{},$newWfRec->{id})){
                  msg(DEBUG,"workflow activated ".$newid);
                  $wfop->UpdateRecord({autocopydate=>$newautocopydate,
                                       mdate=>$WfRec->{mdate}},
                                      {id=>$WfRec->{id}});
                  
               }
            }
         }
         ($WfRec,$msg)=$wf->getNext();
      }until(!defined($WfRec));
   }

   return({msg=>'OK',exitcode=>0});
}


1;
