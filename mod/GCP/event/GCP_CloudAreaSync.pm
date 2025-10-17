package GCP::event::GCP_CloudAreaSync;
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}



sub GCP_CloudAreaSync
{
   my $self=shift;
   my $queryparam=shift;

   my $gcpcode="GCP";  # tech name
   my $ncnt;

   my $itcloudobj=getModuleObject($self->Config,"itil::itcloud");

   $itcloudobj->SetFilter({shortname=>$gcpcode});
   my @itcloudrec=$itcloudobj->getHashList(qw(ALL));

   if ($#itcloudrec==-1){
      return({exitcode=>1,exitmsg=>'ERROR: no shortname=GCP cloud record'});
   }
   if ($#itcloudrec>0){
      return({exitcode=>1,exitmsg=>'ERROR: only one GCP cloud supported'});
   }
   my $itcloudrec=$itcloudrec[0];

   if ($itcloudrec->{cistatusid}!=4){
      $itcloudobj->ValidatedUpdateRecord($itcloudrec,{cistatusid=>4},{
         id=>\$itcloudrec->{id}
      });
      $itcloudobj->ResetFilter();
      $itcloudobj->SetFilter({id=>\$itcloudrec->{id},cistatusid=>\'4'});
      my ($crec,$msg)=$itcloudobj->getOnlyFirst(qw(ALL));
      $itcloudrec=$crec;
   }
   if (!defined($itcloudrec)){
      return({
         exitcode=>1,
         exitmsg=>'ERROR: unable to find cloudrec shortname=GCP'
      });
   }

   my $gcppro=getModuleObject($self->Config,"GCP::project");
   my $appl=getModuleObject($self->Config,"itil::appl");
   my $itcloudarea=getModuleObject($self->Config,"itil::itcloudarea");


   my $joblog=getModuleObject($self->Config,"base::joblog");
   my $eventlabel='IncStreamAnalyse::'.$gcppro->Self;
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



   msg(INFO,"GCP Cloud record id=$itcloudrec->{id}");



   if ($gcppro->isSuspended()){
      return({exitcode=>0,exitmsg=>'ok - suspended'});
   }
   if (!($gcppro->Ping())){
      msg(ERROR,"not all dataobjects available");
      return(undef);
   }

   my @msg;
   my $gcpname=$itcloudrec->{name};  

   if (1){
      $gcppro->ResetFilter();
      $gcppro->SetFilter({});
      my @pss=$gcppro->getHashList(qw(id name w5baseid state cdate));
      my $n=$#pss+1;
      my @ps;
      foreach my $rec (@pss){
         if ($rec->{w5baseid}=~m/^[0-9]{3,20}$/){
            push(@ps,{
               id=>$rec->{id},
               name=>$rec->{name},
               applid=>$rec->{w5baseid},
               state=>lc($rec->{state})
            #   requestor=>$rec->{requestor}
            });
         }
      }
      #printf STDERR '@ps='.Dumper(\@ps);


      $itcloudarea->ResetFilter();
      $itcloudarea->SetFilter({srcsys=>\$gcpcode});
      my @c=$itcloudarea->getHashList(qw(name itcloud applid 
                                         srcsys srcid cistatusid));
      my @opList;
      my $res=OpAnalyse(
         sub{  # comperator
            my ($a,$b)=@_;   # a=lnkadditionalci b=aus AM
            my $eq;          # undef= nicht gleich
            if ( $a->{srcid} eq $b->{id}){
               $eq=0;  # rec found - aber u.U. update notwendig
               my $aname=$a->{name};
               $aname=~s/\[.*\]$//;
               my $bname=$b->{name};
               $bname=~s/\[.*\]$//;
               $bname=~s/[\s.]+/_/g;
               my $cistatusuprange=[3,4];
               if (lc($b->{state}) ne "active"){
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
                     cloud   =>$gcpname,
                     srcsys  =>$gcpcode,
                     srcid   =>$newrec->{id}
                  }
               };
               #if ($mode eq "insert" && $newrec->{requestor} ne ""){
               #   $oprec->{DATA}->{requestoraccount}=lc($newrec->{requestor});
               #}
               if (defined($oldrec)){
                  my $oldname=$oldrec->{name};
                  $oldname=~s/\[.*\]$//;
                  if ($oldname eq $name){
                     delete($oprec->{DATA}->{name});
                  }
               }


               if ($mode eq "insert"){
                  $oprec->{DATA}->{cistatusid}="3";
                  if ($newrec->{state} ne "active"){  # diabled subscription
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
         \@c,\@ps,\@opList
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
      #print STDERR Dumper(\@opList);
   }

   if ($#msg!=-1){
      $itcloudobj->ResetFilter();
      $itcloudobj->SetFilter({id=>\$itcloudrec->{id}});
      my ($gcpcloudrec,$msg)=$itcloudobj->getOnlyFirst(qw(ALL));
      if (defined($gcpcloudrec)){
         my %notifyParam=();
         $itcloudobj->NotifyWriteAuthorizedContacts(
                      $gcpcloudrec,{},
                      \%notifyParam,{},sub{
            my ($subject,$ntext);
            my $subject="GoogleCloudPlatform CloudArea Sync";
            my $tmpl=join("\n",@msg);
            return($subject,$tmpl);
         });
      }
      else{
         msg(ERROR,"invalid to find cloud $gcpname in cloud list");
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
