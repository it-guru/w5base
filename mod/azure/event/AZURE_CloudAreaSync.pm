package azure::event::AZURE_CloudAreaSync;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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

sub Init
{
   my $self=shift;

   $self->RegisterEvent("AZURE_CloudAreaSync","AZURE_CloudAreaSync");
   $self->RegisterEvent("AZURE_QualityCheck","AZURE_QualityCheck");
   $self->RegisterEvent("AZURE_CreateNewSecret","AZURE_CreateNewSecret");
   return(1);
}

sub AZURE_CreateNewSecret
{
   my $self=shift;
   my $subsc=getModuleObject($self->Config,"azure::subscription");

   my $newSecrect=$subsc->createNewSecret();
   if ($newSecrect ne "" && !($newSecrect=~m/"/)){
      printf("new secret:\n");
      printf("DATAOBJPASS[AZURE]=\"%s\"\n",$newSecrect);
      return({exitcode=>'0'});
   }
   return({exitcode=>'0',exitmsg=>'Fail to create a new Azure secret'});
}

sub AZURE_QualityCheck
{
   my $self=shift;
   my $cloudareaid=shift;

   my $job=getModuleObject($self->Config,"base::joblog");
   $job->SetFilter({event=>"\"QualityCheck 'itil::itcloudarea'\" ".
                           "\"QualityCheck 'itil::itcloudarea' T*\"",
                    exitstate=>"[EMPTY]",
                    cdate=>">now-6h"});
   my @l=$job->getHashList(qw(mdate id event exitstate));

   if ($#l==-1){
      my $bk=$self->W5ServerCall("rpcCallEvent",
                                 "QualityCheck","itil::itcloudarea",
                                 $cloudareaid);
      return({exitcode=>'0'});
   }
   return({exitcode=>'1'});
}


sub AZURE_CloudAreaSync
{
   my $self=shift;
   my $queryparam=shift;

   my $azurename="Azure_DTIT";
   my $azurecode="AZURE";

   my $inscnt=0;

   my @a;
   my %itcloud;

   my $subsc=getModuleObject($self->Config,"azure::subscription");
   my $itcloudobj=getModuleObject($self->Config,"itil::itcloud");
   my $appl=getModuleObject($self->Config,"itil::appl");
   my $itcloudarea=getModuleObject($self->Config,"itil::itcloudarea");

   if ($subsc->isSuspended()){
      return({exitcode=>0,exitmsg=>'ok'});
   }
   if (!($subsc->Ping()) ||
       !($itcloudobj->Ping())){
      msg(ERROR,"not all dataobjects available");
      return(undef);
   }

   my $joblog=getModuleObject($self->Config,"base::joblog");
   my $eventlabel='IncStreamAnalyse::'.$subsc->Self;
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
   my @msg;
   my $jobid=$joblog->ValidatedInsertRecord(\%jobrec);
   msg(DEBUG,"jobid=$jobid");

   my %flt=('status'=>'CREATE_SUCCESSFUL');
   if (1){    
      $flt{cdate}=">now-14d";
      if (defined($firstrec)){
         my $lastmsg=$firstrec->{exitmsg};
         if (($laststamp)=
             $lastmsg=~m/^last:(\d+-\d+-\d+ \d+:\d+:\d+)$/){
            $flt{cdate}=">=\"$laststamp GMT\"";
            $exitmsg=$lastmsg;
         }
      }
   }
   #   $flt{cdate}=">now-14d";   # for DEBUG: Check last 14 days

   if (1){
      my $d=$joblog->ExpandTimeExpression("now-1h","en","GMT","GMT");
      $exitmsg="last:$d";
   }


   if (1){
      $subsc->ResetFilter();
      $subsc->SetFilter({});
      my @ss=$subsc->getHashList(qw(subscriptionId id name w5baseid
                                    requestor state));
      my @s;
      my $n=$#ss+1;

      $joblog->ValidatedInsertRecord({
         name=>'AzureSubscriptionCount',
         event=>'AZURE_CloudAreaSync',
         pid=>$$,
         exitcode=>0,
         exitmsg=>"OK",
         exitstate=>"ok - got $n subs"
      });

      if ($n<6){
         my $msg="not enough projects (min. 6) found in Azure (got $n) - ".
                 "sync abborted";
         msg(ERROR,$msg);
         foreach my $rec (@ss){
            printf STDERR ("ERROR: got only subscriptionId %s\n",
                   $rec->{subscriptionId})
         }
         msg(ERROR,"ssdump=".Dumper(\@ss));
         return({exitcode=>1,exitmsg=>$msg});
      }

      foreach my $rec (@ss){
         #next if ($rec->{name}=~m/test/i);
         #next if ($rec->{subscriptionId} eq "4bbf1fb2-6316-462f-bac5-0d8d451f3ffd");
         if ($rec->{w5baseid}=~m/^[0-9]{3,20}$/){
          #  printf STDERR ("process: %s\n",$rec->{id});
          #  printf STDERR ("   name: %s\n",$rec->{name});
          #  printf STDERR (" applid: %s\n",$rec->{applid});
          #  printf STDERR ("\n");
            push(@s,{
               subscriptionId=>$rec->{subscriptionId},
               name=>$rec->{name},
               applid=>$rec->{w5baseid},
               state=>lc($rec->{state}),
               requestor=>$rec->{requestor}
            });
         }
      }
      $itcloudarea->ResetFilter();
      $itcloudarea->SetFilter({srcsys=>\$azurecode});
      my @c=$itcloudarea->getHashList(qw(name itcloud applid 
                                         srcsys srcid cistatusid));


      my @opList;


      #printf STDERR ("fifi c=%s\n",Dumper(\@c));
      #printf STDERR ("fifi s=%s\n",Dumper(\@s));

      my $res=OpAnalyse(
         sub{  # comperator
            my ($a,$b)=@_;   # a=lnkadditionalci b=aus AM
            my $eq;          # undef= nicht gleich
            if ( $a->{srcid} eq $b->{subscriptionId}){
               $eq=0;  # rec found - aber u.U. update notwendig
               my $aname=$a->{name};
               $aname=~s/\[.*\]$//;
               my $bname=$b->{name};
               $bname=~s/\[.*\]$//;
               $bname=~s/[\s.]+/_/g;
               my $cistatusuprange=[3,4];
               if (lc($b->{state}) ne "enabled"){
                  $cistatusuprange=[5];
               }
               if ($aname eq $bname &&
                   in_array($cistatusuprange,$a->{cistatusid}) &&
                   $a->{applid} eq $b->{applid}){
                  $eq=1;   # alles gleich - da braucht man nix machen
               }
            }
            return($eq);
         },
         sub{  # oprec generator
            my ($mode,$oldrec,$newrec,%p)=@_;
            if ($mode eq "insert" || $mode eq "update"){
               my $name=$newrec->{name};
               $name=~s/[\s.]+/_/g;
               my $oprec={
                  OP=>$mode,
                  DATAOBJ=>'itil::itcloudarea',
                  DATA=>{
                     name    =>$name,
                     applid  =>$newrec->{applid},
                     cloud   =>$azurename,
                     srcsys  =>$azurecode,
                     srcid   =>$newrec->{subscriptionId}
                  }
               };
               if ($mode eq "insert" && $newrec->{requestor} ne ""){
                  $oprec->{DATA}->{requestoraccount}=lc($newrec->{requestor});
               }
               if (defined($oldrec)){
                  my $oldname=$oldrec->{name};
                  $oldname=~s/\[.*\]$//;
                  if ($oldname eq $name){
                     delete($oprec->{DATA}->{name});
                  }
               }


               if ($mode eq "insert"){
                  $oprec->{DATA}->{cistatusid}="3";
                  if ($newrec->{state} ne "enabled"){  # diabled subscription
                     $oprec->{OP}="invalid";           # will not be new insert
                     $oprec->{DATA}->{cistatusid}="5";
                  }
               }

               if ($mode eq "update"){
                  if ($newrec->{state} ne "enabled" &&
                      $oldrec->{cistatusid}!=5){
                     $oprec->{DATA}->{cistatusid}="5";
                  }
                  if ($newrec->{state} eq "enabled" &&
                      $oldrec->{cistatusid}!=3 &&
                      $oldrec->{cistatusid}!=4){
                     $oprec->{DATA}->{cistatusid}="3";
                  }
                  if ($oldrec->{cistatusid}==6){
                     $oprec->{DATA}->{cistatusid}="3";
                  }
                  if ($oldrec->{cistatusid}!=3 &&
                      $oldrec->{applid} ne $newrec->{applid}){
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
                     cistatusid  =>6,
                     srcid   =>$oldrec->{srcid}
                  }
               };
               return(undef) if ($oldrec->{cistatusid} eq "6");
               return($oprec);
            }
            return(undef);
         },
         \@c,\@s,\@opList
      );

      for(my $c=0;$c<=$#opList;$c++){
         if ($opList[$c]->{OP} eq "insert" ||
             $opList[$c]->{OP} eq "update"){
            if (exists($opList[$c]->{DATA}->{applid})){
               $appl->ResetFilter();
               $appl->SetFilter({id=>\$opList[$c]->{DATA}->{applid}});
               my ($arec,$msg)=$appl->getOnlyFirst(qw(id cistatusid name));
               if (!defined($arec)){
                  $opList[$c]->{OP}="invalid";
                  push(@msg,"ERROR: invalid application (W5BaseID) in ".
                            "project '".
                             $opList[$c]->{DATA}->{name}."' (".
                             $opList[$c]->{DATA}->{srcid}.
                             ")");
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


   if ($#msg!=-1){
      $itcloudobj->ResetFilter();
      $itcloudobj->SetFilter({name=>\$azurename});
      my ($azurecloudrec,$msg)=$itcloudobj->getOnlyFirst(qw(ALL));
      if (defined($azurecloudrec)){
         my %notifyParam=();
         $itcloudobj->NotifyWriteAuthorizedContacts(
                      $azurecloudrec,{},
                      \%notifyParam,{},sub{
            my ($subject,$ntext);
            my $subject="AZURE CloudArea Sync";
            my $tmpl=join("\n",@msg);
            return($subject,$tmpl);
         });
      }
      else{
         msg(ERROR,"invalid to find cloud $azurename in cloud list");
      }
   }

   $joblog->ValidatedUpdateRecord({id=>$jobid},
                                 {exitcode=>"0",
                                  exitmsg=>$exitmsg,
                                  exitstate=>"ok - $ncnt messages"},
                                 {id=>\$jobid});

   return({exitcode=>0,exitmsg=>'ok'});
}









1;
