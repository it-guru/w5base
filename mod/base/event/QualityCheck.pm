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
                        timeout=>$self->{qualitycheckduration}+600); 
   return(1);
}

sub QualityCheck
{
   my $self=shift;
   my $dataobj=shift;
   my $dataobjid=shift;     # for debugging, it is posible to specify a id
   msg(DEBUG,"starting QualityCheck");
   my $lnkq=getModuleObject($self->Config,"base::lnkqrulemandator");

   my %dataobjtocheck=$lnkq->LoadQualityActivationLinks();
   #msg(INFO,Dumper(\%dataobjtocheck));
   if ($dataobj eq ""){
      my $n=keys(%dataobjtocheck);
      my $doSleep=($self->{qualitycheckduration}+600-10)/$n;
      $doSleep=10 if ($doSleep<10);
      $doSleep=300 if ($doSleep>300);
      foreach my $dataobj (sort(keys(%dataobjtocheck))){
         msg(INFO,"calling QualityCheck for '$dataobj'");
         my $bk=$self->W5ServerCall("rpcCallEvent","QualityCheck",$dataobj);
         if (!defined($bk->{AsyncID})){
            msg(ERROR,"can't call QualityCheck for ".
                      "dataobj '$dataobj' Event");
         }
         sleep($doSleep);
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
                                             '>='.$mdate->{dataobjattr}.')')
               )
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
               #printf STDERR ("fifi x %s\n\n",join("\n",@l));
               if (grep(/error/i,@l)){
                  msg(ERROR,"error messages while check of ".
                            $stateparam->{idname}."='".$curid."' in ".
                            $dataobj->Self());
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
