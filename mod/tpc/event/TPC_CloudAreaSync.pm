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
use kernel::QRule;
@ISA=qw(kernel::Event);



sub TPC_CloudAreaSync
{
   my $self=shift;
   my $queryparam=shift;

   my $tpcname="TEL-IT_PrivateCloud";
   my $tpccode="TPC";

   my $inscnt=0;

   my @a;
   my %itcloud;

   my $pro=getModuleObject($self->Config,"tpc::project");
   my $dep=getModuleObject($self->Config,"tpc::deployment");
   my $itcloudobj=getModuleObject($self->Config,"itil::itcloud");
   my $appl=getModuleObject($self->Config,"itil::appl");
   my $itcloudarea=getModuleObject($self->Config,"itil::itcloudarea");

   if ($pro->isSuspended() ||
       $dep->isSuspended()){
      return({exitcode=>0,exitmsg=>'ok'});
   }


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
   my $laststamp;
   my $lastid="undefined";
   my @msg;
   my $jobid=$joblog->ValidatedInsertRecord(\%jobrec);
   msg(DEBUG,"jobid=$jobid");

   my %flt=('status'=>'CREATE_SUCCESSFUL');
   {    
      $flt{cdate}=">now-14d";
      if (defined($firstrec)){
         my $lastmsg=$firstrec->{exitmsg};
         if (($laststamp,$lastid)=
             $lastmsg=~m/^last:(\d+-\d+-\d+ \d+:\d+:\d+)\s+(\S+)$/){
            $flt{cdate}=">=\"$laststamp GMT\"";
            $exitmsg=$lastmsg;
         }
      }
   }
   if (1){
      $pro->ResetFilter();
      $pro->SetFilter({});
      my @ss=$pro->getHashList(qw(id name applid));
      my @s;
      foreach my $rec (@ss){
         #next if ($rec->{name}=~m/test/i);
         if ($rec->{applid}=~m/^[0-9]{3,20}$/){
          #  printf STDERR ("process: %s\n",$rec->{id});
          #  printf STDERR ("   name: %s\n",$rec->{name});
          #  printf STDERR (" applid: %s\n",$rec->{applid});
          #  printf STDERR ("\n");
            push(@s,{
               id=>$rec->{id},
               name=>$rec->{name},
               applid=>$rec->{applid}
            });
         }
      }
      $itcloudarea->ResetFilter();
      $itcloudarea->SetFilter({srcsys=>\$tpccode});
      my @c=$itcloudarea->getHashList(qw(name itcloud srcsys srcid cistatusid));

      my @opList;


      #printf STDERR ("fifi c=%s\n",Dumper(\@c));
      #printf STDERR ("fifi s=%s\n",Dumper(\@s));

      my $res=OpAnalyse(
         sub{  # comperator
            my ($a,$b)=@_;   # a=lnkadditionalci b=aus AM
            my $eq;          # undef= nicht gleich
            if ( $a->{srcid} eq $b->{id}){
               $eq=0;  # rec found - aber u.U. update notwendig
               my $aname=$a->{name};
               $aname=~s/\[.*\]$//;
               if ($aname eq $b->{name} &&
                   $a->{cistatusid}<6){
                  $eq=1;   # alles gleich - da braucht man nix machen
               }
            }
            return($eq);
         },
         sub{  # oprec generator
            my ($mode,$oldrec,$newrec,%p)=@_;
            if ($mode eq "insert" || $mode eq "update"){
               my $oprec={
                  OP=>$mode,
                  DATAOBJ=>'itil::itcloudarea',
                  DATA=>{
                     name    =>$newrec->{name},
                     applid  =>$newrec->{applid},
                     cloud   =>$tpcname,
                     srcsys  =>$tpccode,
                     srcid   =>$newrec->{id}
                  }
               };
               if ($mode eq "insert"){
                  $oprec->{DATA}->{cistatusid}="3";
               }
               if ($mode eq "update"){
                  if ($oldrec->{cistatusid}==6){
                     $oprec->{DATA}->{cistatusid}="3";
                  }
                  $oprec->{IDENTIFYBY}=$oldrec->{id};
               }
               return($oprec);
            }
            elsif ($mode eq "delete"){
               my $oprec={
                  OP=>"update",
                  DATAOBJ=>'itil::itcloudarea',
                  IDENTIFYBY=>$oldrec->{id},
                  DATA=>{
                     cistatusid  =>6
                  }
               };
               return($oprec);
            }
            return(undef);
         },
         \@c,\@s,\@opList
      );

      for(my $c=0;$c<=$#opList;$c++){
         if ($opList[$c]->{OP} eq "insert"){
            $appl->ResetFilter();
            $appl->SetFilter({id=>\$opList[$c]->{DATA}->{applid}});
            my ($arec,$msg)=$appl->getOnlyFirst(qw(id cistatusid));
            if (!defined($arec)){
               $opList[$c]->{OP}="invalid";
               push(@msg,"ERROR: invalid application (W5BaseID) in project ".
                         $opList[$c]->{DATA}->{name});
            }
            else{
               if ($arec->{cistatusid} ne "3" &&
                   $arec->{cistatusid} ne "4"){
                  $opList[$c]->{OP}="invalid";
                  push(@msg,"ERROR: invalid cistatus for application ".
                            $arec->{name}.
                            " in project ".$opList[$c]->{DATA}->{name});
               }
            }
         }
      }
      if (!$res){
         my $opres=ProcessOpList($itcloudarea,\@opList);
      }
   }

   my ($dlast)=$laststamp=~m/^(\S+)\s/;
   my ($dnow)=NowStamp("en")=~m/^(\S+)\s/;

   if ($dlast eq $dnow){
      @msg=();     # project sync messages only on daychange
   }


   if (1){
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
         #printf STDERR ("$deprec->{cdate} ".
         #               "TPC: $deprec->{opname} \@ $deprec->{project}\n");
         #
         # Wenn das Deployment ein logisches System (machine) betrifft,
         # dann muss system importiert werden bzw. aktualisiert werden.
         #
         #
         $exitmsg="last:".$deprec->{cdate}." ".$deprec->{id};
         last if ($ncnt>50);
      }
   }

   if ($#msg!=-1){
      $itcloudobj->ResetFilter();
      $itcloudobj->SetFilter({name=>\$tpcname});
      my ($tpccloudrec,$msg)=$itcloudobj->getOnlyFirst(qw(ALL));
      if (defined($tpccloudrec)){
         my %notifyParam=();
         $itcloudobj->NotifyWriteAuthorizedContacts(
                      $tpccloudrec,{},
                      \%notifyParam,{},sub{
            my ($subject,$ntext);
            my $subject="TPC CloudArea Sync";
            my $tmpl=join("\n",@msg);
            return($subject,$tmpl);
         });
      }
      else{
         msg(ERROR,"invalid to find cloud $tpcname in cloud list");
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