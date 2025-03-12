package base::event::QualityCheck;
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
use List::Util qw/shuffle/;
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

   my $qualitycheckduration=$self->Config->Param("QualityCheckDuration");
   $qualitycheckduration="600" if ($qualitycheckduration eq "");
   $self->{qualitycheckduration}=$qualitycheckduration;



   $self->RegisterEvent("QualityCheck","QualityCheck",
                        timeout=>$self->{qualitycheckduration}*2); 
   return(1);
}

sub QualityCheck
{
   my $self=shift;
   my $dataobj=shift;
   my $qualitytask;
   my $qualitytasktasknum;
   my $qualitytasktaskcnt;

   if ($_[0]=~m/^T/){
      $qualitytask=shift;
      if (my ($num,$cnt)=$qualitytask=~m/^T([0-9]+)\/([0-9]+)$/){
         $qualitytasktasknum=$num;
         $qualitytasktaskcnt=$cnt;
      }
      else{
         die("invalid Task specification");
      }
      if ($qualitytasktasknum<1 || $qualitytasktasknum>10){
         die("invalid Task num");
      }
      if ($qualitytasktaskcnt<1 || $qualitytasktaskcnt>10){
         die("invalid Task cnt");
      }
      if ($qualitytasktasknum>$qualitytasktaskcnt){
         die("invalid Task run num");
      }
   }

   my $dataobjid=shift;     # for debugging, it is posible to specify a id
   msg(DEBUG,"starting QualityCheck");
   my $lnkq=getModuleObject($self->Config,"base::lnkqrulemandator");

   my %dataobjtocheck=$lnkq->LoadQualityActivationLinks();
   #msg(INFO,Dumper(\%dataobjtocheck));
   my $LimitTasks=int($self->Config->Param("QualityCheckLimitParallelTasks"));
   if ($LimitTasks<1){
      $LimitTasks=1;
   }
   if ($LimitTasks>10){
      $LimitTasks=10;
   }
   if ($dataobj eq ""){
      my $startt=time();
      my $n=keys(%dataobjtocheck);
      my $doSleep=($self->{qualitycheckduration}-600-30)/$n;
      $doSleep=20 if ($doSleep<20);
      $doSleep=120 if ($doSleep>120);
      foreach my $dataobj (shuffle(keys(%dataobjtocheck))){
         msg(INFO,"calling QualityCheck for '$dataobj'");
         my $o=getModuleObject($self->Config,$dataobj);
         if (defined($o)){
            my $cnt=$o->CountRecords();
            my $taskcnt=int($cnt/50000);

            $taskcnt=1 if ($dataobj eq "base::workflow" || $taskcnt<1);
            $taskcnt=$LimitTasks  if ($taskcnt>$LimitTasks);

            if ($taskcnt==1){
               my $bk=$self->W5ServerCall("rpcCallEvent",
                                          "QualityCheck",$dataobj);
               if (!defined($bk->{AsyncID})){
                  msg(ERROR,"can't call QualityCheck for ".
                            "dataobj '$dataobj' Event");
               }
            }
            else{
               my @tasks;
               for(my $c=1;$c<=$taskcnt;$c++){
                  push(@tasks,$c);
               }
               foreach my $t (@tasks){
                  my $bk=$self->W5ServerCall("rpcCallEvent",
                                             "QualityCheck",$dataobj,
                                             "T".$t."/".$taskcnt);
                  if (!defined($bk->{AsyncID})){
                     msg(ERROR,"can't call QualityCheck for ".
                               "dataobj '$dataobj' Event");
                  }
               }
            }
            sleep($doSleep);
         }
      }
      my $laststart=time();
      while((time()-$laststart)<$self->{qualitycheckduration}){
         sleep(1);
      }
   }
   else{
      my $obj=getModuleObject($self->Config,$dataobj);
      if (defined($obj)){
         #
         # lastqcheckoutofdate is needed, to ensure (new) edited records are
         # prior handeled in QualityCHeck
         #
         my $lastqcheckoutofdate=$obj->getField("lastqcheckoutofdate");
         if (!defined($lastqcheckoutofdate)){
            my $mdate=$obj->getField("mdate");
            my $lastqcheck=$obj->getField("lastqcheck");
            if (defined($mdate) && defined($lastqcheck) &&
                $mdate->{dataobjattr} ne "" &&
                $lastqcheck->{dataobjattr} ne ""){
               $obj->AddFields(
                   new kernel::Field::Boolean(
                             name          =>'lastqcheckoutofdate',
                             label         =>'last QualityCheck out of Date',
                             uivisible     =>0,
                             noselect      =>1,
                             dataobjattr   =>'('.$lastqcheck->{dataobjattr}.
                                             ' is not null OR '.
                                             $lastqcheck->{dataobjattr}.
                                             '>='.$mdate->{dataobjattr}.')')
               )
            }
         }
         if ($qualitytask ne ""){
            my $qchecktask=$obj->getField("qchecktask");
            if (!defined($qchecktask)){
               my $idfield=$obj->IdField();
               if (defined($idfield)){
                  my $idfielddataobjattr=$idfield->{dataobjattr};
                  if ($idfielddataobjattr ne ""){
                     $obj->AddFields(
                         new kernel::Field::Number(
                                   name          =>'qchecktask',
                                   label         =>'qcheck TaskID',
                                   uivisible     =>0,
                                   precision     =>0,
                                   noselect      =>1,
                                   dataobjattr   =>'mod('.
                                                    $idfielddataobjattr.
                                                   ',11)')
                     );
                     $qchecktask=$obj->getField("qchecktask");
                  }
               }
            }
         }

         my $basefilter;
         if ($obj->getField("mandatorid")){
            my @mandators=keys(%{$dataobjtocheck{$dataobj}});
            @mandators=grep({$_ ne "0"} @mandators);
            if ($#mandators!=-1              # use mandator filter if not only 
                && $dataobj ne "base::workflow"){  # "ANY" rules exists
               msg(INFO,"set (basefilter) mandatorid filter='%s'",
                        join(",",@mandators));
               $basefilter={mandatorid=>\@mandators};
            }
         }
         if ($dataobjid ne ""){
            my $idfield=$obj->IdField();
            if (defined($idfield)){
               my $idname=$idfield->Name();
               if ($idname ne ""){
                  if (ref($basefilter) eq "HASH"){
                     $basefilter->{$idname}=\$dataobjid;
                  }
                  else{
                     $basefilter={$idname=>\$dataobjid};
                  }
               }
            }
         }
         if ($qualitytask ne ""){
            my @tasks=(0..100);
            for(my $c=0;$c<=$#tasks;$c++){
               my $mod=($c % $qualitytasktaskcnt)+1;
               if ($mod!=$qualitytasktasknum){
                  $tasks[$c]=undef;
               }
            }
            @tasks=grep({defined($_)} @tasks);
            if (ref($basefilter) ne "HASH"){
               $basefilter={};
            }
            $basefilter->{qchecktask}=\@tasks;
         }
         
         return($self->doQualityCheck($basefilter,$obj));
      }
      else{
         return({exitcode=>1,msg=>"invalid dataobject '$dataobj' specified"});
      }
   }
   
   return({exitcode=>0,msg=>'ok'});
}

sub doQualityCheck
{
   my $self=shift;
   my $basefilter=shift;
   my $dataobj=shift;
 
   msg(INFO,"doQualityCheck in Object $dataobj");

   my $stateparam={
      checkProcess=>undef,
      firstid=>undef,
      idname=>undef,
      SelfAsParentObject=>$dataobj->SelfAsParentObject(),
      directlnktype=>[$dataobj->Self,$dataobj->SelfAsParentObject()],
   };
   my @view=("qcok");
   my $idfieldobj=$dataobj->IdField();
   $stateparam->{idname}=$idfieldobj->Name();
   if (my $lastqcheck=$dataobj->getField("lastqcheck")){
      $stateparam->{checkProcess}="lastqcheckBased";
      unshift(@view,"lastqcheck");
      if (defined($idfieldobj)){
         push(@view,$idfieldobj->Name());
      }
      if ($dataobj->getField("lastqcheckoutofdate")){
         unshift(@view,"lastqcheckoutofdate");
      }
   }
   else{
      $stateparam->{checkProcess}="idBased";
      if (defined($idfieldobj)){
         unshift(@view,$stateparam->{idname});
      }
   }
   if ($stateparam->{checkProcess} eq "idBased"){
      $self->loadQualityCheckContext($stateparam);
   }
   my $qualitycheckduration=$self->{qualitycheckduration};
   my $time=time();
   my $total=0;
   my $c=0;
   my $loopmax=50;
   if (0){ # for DEBUG only !!!
      $loopmax=2;
      $qualitycheckduration=5;
   }
   MAINLOOP: do{
      $dataobj->ResetFilter();
      if (defined($basefilter)){
         $dataobj->SetNamedFilter("MANDATORID",$basefilter);
      }
      if (!($dataobj->SetFilterForQualityCheck($stateparam,@view))){
         return({exitcode=>0,msg=>'ok'});
      }
      $dataobj->Limit($loopmax+1,0,0);
      my ($rec,$msg)=$dataobj->getFirst(unbuffered=>1);
      $c=0;
      if (defined($rec)){
         BLOCKLOOP: do{
            msg(DEBUG,"check record start");
            my $curid=$idfieldobj->RawValue($rec);
            if ($stateparam->{checkProcess} eq "idBased"){
               if ($curid eq ""){
                  die("id based QualityCheck process not supported if id=''");
               }
               if (defined($stateparam->{lastid}) &&
                   $stateparam->{lastid} ne ""){
                  # now store the check context and cleanup DataIssue workflows
                  # with id >$stateparam->{lastid} and <$curid
                  $self->storeQualityCheckContextWithWorkflowCleanup(
                      $stateparam,$curid
                  );

               }
            }

            my $qcokobj=$dataobj->getField("qcok");
            if (defined($qcokobj)){
               my $qcok=$qcokobj->RawValue($rec); 
               msg(DEBUG,"qcok=$rec->{qcok}");
            }
            else{
               return({exitcode=>1,msg=>'no qcok field'});
            }
            $total++;
            $c++;
            if ($self->LastMsg()>0){
               my @l=$self->LastMsg();
               my @emsgs=grep(/error/i,@l);  # find out messages with error in
               if ($#emsgs!=-1){
                  @emsgs=grep(!/^ERROR:/,@emsgs); # remove messages, which are
                  #if ($#emsgs==-1 &&              # already printed (or Silent)
                  #    $self->LastErrorMsgCount()>0){
                  #   msg(ERROR,"debug LastErrorMsgCount seems to be wrong");
                  #   my @allErrmsg=$self->LastMsg();
                  #   msg(ERROR,"debug LastMsg=".Dumper(\@allErrmsg));
                  #   msg(ERROR,"maybe WARN Messages silent?");
                  #}
                  if ($#emsgs!=-1 ||              # already printed (or Silent)
                      $self->LastErrorMsgCount()){
                     msg(ERROR,"error messages while check of ".
                               $stateparam->{idname}."='".$curid."' in ".
                               $dataobj->Self());
                     foreach my $emsg (@emsgs){ # print "normal" messages, which
                        msg(ERROR,$emsg);       # have error in it - but not 
                     }                          # starting with ERROR:       
                  }
               }
               $self->LastMsg("");
            }
            msg(DEBUG,"check record end");
            if ( $curid eq $stateparam->{firstid}){ 
               return({exitcode=>0,
                       msg=>'ok '.$total.' records checked = all'});
            }
            if (time()-$time>$qualitycheckduration){ 
               msg(DEBUG,"Quality check end by ".
                         "QualityCheckDuration=$qualitycheckduration");
               return({exitcode=>0,
                       msg=>'ok '.$total.' records checked = partial'});
            }
            if (!defined($stateparam->{firstid})){
               $stateparam->{firstid}=$curid;
            }
            $stateparam->{lastid}=$curid;
            $stateparam->{lasttime}=NowStamp("en");
            ($rec,$msg)=$dataobj->getNext();
         }until(!defined($rec) ||  $c>=$loopmax);

         # store loop state

      }
      if (!defined($rec)){
         msg(DEBUG,"rec not defined - end of loop check");
         return({exitcode=>0,msg=>'ok'});
      }
      sleep(1);
   }until(0);

   return({exitcode=>0,msg=>'ok'});
}

sub loadQualityCheckContext
{
   my $self=shift;
   my $stateparam=shift;

   my $joblog=$self->getPersistentModuleObject("base::joblog");
   $joblog->SetFilter({exitmsg=>'IDPOINT:*',
                       event=>[$self->Self],
                       name=>[$stateparam->{'SelfAsParentObject'}],
                       mdate=>'>now-7d'});
   my @l=$joblog->getHashList(qw(mdate exitmsg));
   if ($#l>-1){
      my ($lastid)=$l[0]->{exitmsg}=~m/^IDPOINT:(.*)$/;
      if ($lastid ne ""){
         $stateparam->{lastid}=$lastid;
         $stateparam->{lasttime}=$l[0]->{mdate};
      }
   }
}

sub storeQualityCheckContextWithWorkflowCleanup
{
   my $self=shift;
   my $stateparam=shift;
   my $curid=shift;    # cleanup >$lastid - <$curid
   my $lasttime=$stateparam->{lasttime}; 
   my $directlnktype=$stateparam->{directlnktype};
   my $lastid=$stateparam->{lastid};   # this id must be stored


   # Abschlieﬂen aller DataIssue Workflows, deren lastload <$lasttime ist
   # und deren dataobjid >$lastid and <$curid ist.
   my $wf=getModuleObject($self->Config,"base::workflow");

   my $cleanupfilter={stateid=>"<20",class=>\"base::workflow::DataIssue",
                   srcload=>"<\"$lasttime GMT\"",
                   directlnktype=>$directlnktype,
                   directlnkid=>">\"$lastid\" AND <\"$curid\""};
   $wf->SetFilter($cleanupfilter);
   $wf->SetCurrentView(qw(ALL));
   $wf->ForeachFilteredRecord(sub{
                      $wf->Store($_,{stateid=>'21',
                                     fwddebtarget=>undef,
                                     fwddebtargetid=>undef,
                                     fwdtarget=>undef,
                                     fwdtarget=>undef});
                   });
   ########################################################################
   my $joblog=$self->getPersistentModuleObject("IdPointStore","base::joblog");
   if (defined($stateparam->{joblogentry})){
      $joblog->ValidatedUpdateRecord({},{
         exitmsg=>'IDPOINT:'.$lastid
      },{id=>[$stateparam->{joblogentry}]});
   }
   else{
      my $id=$joblog->ValidatedInsertRecord({
         event=>$self->Self,
         name=>$stateparam->{'SelfAsParentObject'},
         exitcode=>0,
         pid=>$$,
         exitstate=>'ok',
         exitmsg=>'IDPOINT:'.$lastid
      });
      if (defined($id)){
         $stateparam->{joblogentry}=$id;
      }
   }
}




1;
