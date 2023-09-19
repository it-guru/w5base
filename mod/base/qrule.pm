package base::qrule;
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
use Time::HiRes qw(gettimeofday);
use Class::ISA;
use kernel;
use kernel::Field;
use kernel::QRule;
use kernel::DataObj::Static;
use kernel::App::Web::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::Static);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                align         =>'left',
                label         =>'QRule ID'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'full QRule Name',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $id=$current->{id};
                   return("(".$id.") ".
                          $self->getParent->{qrule}->{$id}->getName());
                }),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'QRule Name',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $id=$current->{id};
                   if (exists($self->getParent->{qrule}->{$id})){
                      return($self->getParent->{qrule}->{$id}->getName());
                   }
                   return("NotExistingQRule:".$id);
                }),

      new kernel::Field::Text(
                name          =>'target',
                label         =>'posible Target'),

      new kernel::Field::Htmlarea(
                name          =>'longdescription',
                label         =>'Description',
                searchable    =>0,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $id=$current->{id};
                   return($self->getParent->{qrule}->{$id}->getDescription());
                }),

      new kernel::Field::Textarea(
                name          =>'hints',
                label         =>'Hints',
                searchable    =>0,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $id=$current->{id};
                   return($self->getParent->{qrule}->{$id}->getHints());
                }),

      new kernel::Field::Textarea(
                name          =>'code',
                label         =>'Programmcode',
                searchable    =>0,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $id=$current->{id};
                   my $instdir=$self->getParent->Config->Param("INSTDIR");
                   $id=~s/::/\//g;
                   my $d="?";
                   my $file="$instdir/mod/$id.pm";
                   if (-f $file){
                      if (open(F,"<$file")){
                         $d=join("",<F>);
                         close(F);
                      }
                   }
                   return($d);
                }),

   );
   $self->LoadSubObjs("qrule","qrule");
   $self->{'data'}=[];
   my @dl=$self->getInstalledDataObjNames();
  
   foreach my $obj (values(%{$self->{qrule}})){
      my $ctrl=$obj->getPosibleTargets();
      my $name=$obj->Self();
      $ctrl=[$ctrl] if (ref($ctrl) ne "ARRAY");
      my %t;
      foreach my $ct (@$ctrl){
         if ($ct=~m/[\.\^\*]/){
            foreach my $m (@dl){
               if ($m=~m/$ct/){
                  $t{$m}++;
               }
            }
         }
         else{
            $t{$ct}++;
         }
      }
      my $r={id=>$obj->Self,target=>[keys(%t)]};
      push(@{$self->{'data'}},$r);
   }
   $self->setDefaultView(qw(linenumber id name target));
   return($self);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/qmgmt.jpg?".$cgi->query_string());
}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}  

sub isQruleApplicable
{
   my $self=shift;
   my $do=shift;
   my $objlist=shift;
   my $lnkrec=shift;
   my $rec=shift;

   return(0) if (!defined($do));
   my $dataobjparent=$do->SelfAsParentObject();
   my @objlist=@$objlist;
   push(@objlist,Class::ISA::self_and_super_path($objlist->[0]));
   if (defined($self->{qrule}->{$lnkrec->{qruleid}})){
      my $qrule=$self->{qrule}->{$lnkrec->{qruleid}};
      my $postargets=$qrule->getPosibleTargets();
      return() if (!defined($postargets)); 
      $postargets=[$postargets] if (ref($postargets) ne "ARRAY");
      my $found=0;
      foreach my $target (@$postargets){
         if (grep(/^$target$/,@objlist)){
            my $qdataobj=quotemeta($lnkrec->{dataobj});
            my $qdataobjparent=quotemeta($dataobjparent);
            if (grep(/^$qdataobj$/,@objlist) ||
                grep(/^$dataobjparent$/,@objlist)){
               $found=1;
               last;
            }
         }
      }
      if (($lnkrec->{dataobj}=~m/::workflow::/) &&
          $lnkrec->{dataobj} ne $rec->{class}){
         $found=0;
      }
      return($qrule) if ($found);
   }
   return();
}

sub calcParentAndObjlist
{
   my $self=shift;
   my $parent=shift;
   my $objlist=shift;
   my $mandator=shift;
   my $calledRec=shift;
   my $potentialRuleList=shift;
   my $orgParentName=$parent->Self();

   my $rec=$$calledRec;

   my $cache=$self->Cache();
   my $cachekey=$parent->Self."-".join(",",@$mandator);
   $cache->{QualityRuleCompat}={} if (!exists($cache->{QualityRuleCompat}));
   $cache=$cache->{QualityRuleCompat};

   my $parentTransformationCount=0;
   my $nonAnyRules=0;
   if ($parent->Self() ne "base::workflow"){
      my $cache_identifier=$orgParentName.'::'.$rec->{mandatorid};
      if (!exists($cache->{$cache_identifier})){
         my @ruleorder=sort({
            $b->{mandatorid}<=>$a->{mandatorid}  # Every Any Regel must be
                                                 # processed at the end!
         } @$potentialRuleList);
         foreach my $lnkrec (@ruleorder){
            my $do=$self->getPersistentModuleObject($lnkrec->{dataobj});
            if (my $qrule=$self->isQruleApplicable($do,$objlist,$lnkrec,$rec)){
               if ($lnkrec->{mandatorid}!=0){
                  $nonAnyRules++;
               }
               if ($parent->Self() ne $do->Self()){
                  if (($lnkrec->{mandatorid}==0 && $nonAnyRules==0) ||
                      ($lnkrec->{mandatorid}!=0)){
                     # any rules are only allowed to do parentTransformation
                     # if no other rules are exists
                     if ($parentTransformationCount==0){
                        # rec muß neu gelesen werden!
                        my $reloadedRec=$self->reloadRec($do,$rec);
                        if (!defined($reloadedRec)){
                           msg(ERROR,"parent transformation error ".
                                     "while reread rec");
                           msg(ERROR,"rec=".Dumper($rec));
                           return();
                        }
                        ${$calledRec}=$reloadedRec; # return new rec to caller
                        $rec=$reloadedRec;
                        $objlist=$do->getQualityCheckCompat($rec); 
                        msg(INFO,"qrule parent transformation ".
                                 "from %s to %s done",
                                 $parent->Self(),$do->Self());
                        $parent=$do;
                     }
                     else{
                        msg(ERROR,"mulitple parent transformation detected ".
                                  "in ".$lnkrec->{dataobj});
                     }
                  }
               }
            }
         }
         $cache->{$cache_identifier}={parent=>$parent->Self,objlist=>$objlist};
      }
      else{
         if ($parent->Self() ne $cache->{$cache_identifier}->{parent}){
            my $do=getModuleObject($self->Config,
                                    $cache->{$cache_identifier}->{parent});
            my $reloadedRec=$self->reloadRec($do,$rec);
            if (!defined($reloadedRec)){
               msg(ERROR,"parent transformation error ".
                         "while reread rec - Cached");
               return();
            }
            ${$calledRec}=$reloadedRec; # return new rec to caller
            $rec=$reloadedRec;
            $objlist=$do->getQualityCheckCompat($rec); 
            msg(INFO,"qrule parent transformation ".
                     "from %s to %s done - Cached",
                     $parent->Self(),$do->Self());
            $parent=$do;
          
         }
      }
   }
   return($parent,$objlist);

}


sub reloadRec
{
   my $self=shift;
   my $do=shift;
   my $rec=shift;

   $do->ResetFilter();
   my $idobj=$do->IdField();
   if (defined($idobj)){
      my $idname=$do->IdField()->Name();
      $do->SetFilter({$idname=>\$rec->{$idname}});
      ($rec)=$do->getOnlyFirst(qw(ALL)); 
      if (!defined($rec)){
         return(undef);
      }
      else{
         return($rec);
      }
   }
   else{
      msg(ERROR,"qrule.pm can not detect ".
                "idfield in ".$do->Self());
   }
   return();
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




sub calcFinalQruleList
{
   my $self=shift;
   my $parent=shift;
   my $objlist=shift;
   my $rec=shift;
   my $mandator=[];

   my @qrulelist=();

   #
   # Berechnung der möglichen QualityRules anhand des Mandaten
   #
   $mandator=$$rec->{mandatorid} if (exists($$rec->{mandatorid}));
   $mandator=[$mandator] if (ref($mandator) ne "ARRAY");
   push(@$mandator,0);  # for rules on any mandator
   @$mandator=sort(@$mandator);
   $objlist=[$objlist] if (ref($objlist) ne "ARRAY");
   my $lnkr=getModuleObject($self->Config,"base::lnkqrulemandator");
   if ($self->getParent->Self() eq "base::workflow"){
      $lnkr->SetFilter({mandatorid=>$mandator,
                        cistatusid=>\'4',
                        dataobj=>$$rec->{class}});
   }
   else{
      $lnkr->SetFilter({mandatorid=>$mandator,
                        cistatusid=>\'4'});
   }
   #######################################################################

   my @potentialRuleList=$lnkr->getHashList(qw(mdate qruleid mandatorid dataobj));

   #######################################################################
   # Notwendige Parent-Transformation prüfen
   # Hier kommt es wohlmöglich zu einer Änderung des zu verwendenden Parent,
   # da der Mandant u.U. mit einer Ableitung des aktuellen Objektes laut
   # QualityRule zu prüfen ist. Auch die objlist kann sich dabei verändern.
   ($parent,$objlist)=$self->calcParentAndObjlist($parent,$objlist,
                                                  $mandator,$rec,
                                                  \@potentialRuleList);
   my %qruledone;
   foreach my $lnkrec (@potentialRuleList){
      my $qrulename=$lnkrec->{qruleid};
      next if ($qruledone{$qrulename}); # doppelte behandlung verhindern
      my $do=getModuleObject($self->Config,$lnkrec->{dataobj});
      if (my $qrule=$self->isQruleApplicable($do,$objlist,$lnkrec,$$rec)){
         $qruledone{$qrulename}++;
         push(@qrulelist,$qrulename);
      }
   }
   return($parent,$objlist,\@qrulelist);
}




sub nativDatacareAssistant
{
   my $self=shift;
   my $objlist=shift;
   my $rec=shift;
   my @param=@_;
   my $parent=$self->getParent->Clone;
   my $mandator=[];
   my $checkStart=NowStamp("en");

   $mandator=$rec->{mandatorid} if (exists($rec->{mandatorid}));
   $mandator=[$mandator] if (ref($mandator) ne "ARRAY");
   push(@$mandator,0);  # for rules on any mandator
   $objlist=[$objlist] if (ref($objlist) ne "ARRAY");
   my $lnkr=getModuleObject($self->Config,"base::lnkqrulemandator");
   if ($self->getParent->Self() eq "base::workflow"){
      $lnkr->SetFilter({mandatorid=>$mandator,
                        dataobj=>\$rec->{class}});
   }
   else{
      $lnkr->SetFilter({mandatorid=>$mandator});
   }
   my %qruledone;
   my $parentTransformationCount=0;

   #######################################################################
   # from nativeQualityCheck
   #######################################################################
   if ($parent->Self() ne "base::workflow"){
      foreach my $lnkrec ($lnkr->getHashList(qw(mdate qruleid dataobj))){
         my $do=getModuleObject($self->Config,$lnkrec->{dataobj});
         if (my $qrule=$self->isQruleApplicable($do,$objlist,$lnkrec,$rec)){
            if ($parent->Self() ne $do->Self()){
               if ($parentTransformationCount==0){
                  # rec muß neu gelesen werden!
                  $do->ResetFilter();
                  my $idobj=$do->IdField();
                  if (defined($idobj)){
                     my $idname=$do->IdField()->Name();
                     my $idval=$rec->{$idname};
                     $do->SetFilter({$idname=>\$idval});
                     ($rec)=$do->getOnlyFirst(qw(ALL)); 
                     if (!defined($rec)){
                        msg(ERROR,"parent transformation error ".
                                  "while reread rec on refid='".$idval."'");
                        return;
                     }
                      # recreate compat list
                     $objlist=$do->getQualityCheckCompat($rec); 
                     msg(INFO,"qrule parent transformation from %s to %s done",
                              $parent->Self(),$do->Self());
                     $parent=$do;
                  }
                  else{
                     msg(ERROR,"qrule.pm can not detect idfield in ".
                         $do->Self());
                  }
               }
               else{
                  msg(ERROR,"mulitple parent transformation detected");
               }
            }
         }
      }
   }
   #######################################################################

   $param[0]->{autocorrect}=0 if (!exists($param[0]->{autocorrect}));;

   $param[0]->{ruleno}=0 if (!exists($param[0]->{ruleno}));;
   foreach my $lnkrec ($lnkr->getHashList(qw(mdate qruleid dataobj))){
      my $qrulename=$lnkrec->{qruleid};
      next if ($qruledone{$qrulename});
      my $do=getModuleObject($self->Config,$lnkrec->{dataobj});
      my $qrule=$self->isQruleApplicable($do,$objlist,$lnkrec,$rec);
      if (defined($qrule) && $qrule->can("datacareRecord")){
         $qruledone{$qrulename}++;
         $param[0]->{ruleno}++;
         my ($qresult,$control)=$qrule->datacareRecord($parent,$rec,@param);
      }
   }


   return({fifi=>'xx'});
}



sub nativQualityCheck
{
   my $self=shift;
   my $objlist=shift;
   my $rec=shift;
   my @param=@_;
   my $parent=$self->getParent->Clone;
   my $result;
   my %alldataissuemsg;
   my $dataissueactiverulecount;
   my $dataissuerulecount;
   my %dataupdate;
   my $checkStart=NowStamp("en");

   if (ref($param[0]) ne "HASH"){
      $param[0]={}; # this is the checksession!
   }

   $param[0]->{autocorrect}=0 if (!exists($param[0]->{autocorrect}));;
   $param[0]->{ruleno}=0 if (!exists($param[0]->{ruleno}));;
   delete($param[0]->{abortSession});


   my ($parent,$objlist,$finalQruleList)=
       $self->calcFinalQruleList($parent,$objlist,\$rec);

   #######################################################################
   # Generelle Operationen im parent durchführen, die IMMER vor dem 
   # QualityCheck durchgeführt werden müssen (z.B. laden von AutoDiscovery
   # Daten)
   $parent->preQualityCheckRecord($rec,@param);


   my $interviewst=$parent->getField("interviewst",$rec);
   my $idfield=$parent->IdField();
   my $objname=$parent->SelfAsParentObject();
   my $itodo=getModuleObject($self->Config,"base::interviewtodocache");

   if (defined($idfield) && 
       defined($interviewst)){ # handle interview state cache
      my $sseconds=Time::HiRes::time();
      my $id=$rec->{$idfield->Name()};
      #
      #  Current cache for id+objname load
      #
      $itodo->SetFilter({dataobject=>\$objname,dataobjectid=>\$id});
      my @currIToDo=$itodo->getHashList(qw(dataobject dataobjectid userid id));
      my @tobeIToDo=();

      my $d=$interviewst->RawValue($rec);
      if ($d->{todo}>0 || $d->{outdated}>0){

         my %ipartner=$parent->InterviewPartners($rec);
         my @pendingInterviewPartner=(''); # always add default (databoss)
         if (ref($d->{pendingInterviewPartner}) eq "HASH"){
            push(@pendingInterviewPartner,
                 keys(%{$d->{pendingInterviewPartner}}));
         }
         my %uids;
         foreach my $ipname (@pendingInterviewPartner){
            if (exists($ipartner{$ipname})){
               my $u=$ipartner{$ipname};
               $u=[$u] if (ref($u) ne "ARRAY");
               foreach my $id (@$u){
                  if ($id ne ""){
                     $uids{$id}++;
                  }
               }
            }
         }
         if (keys(%uids)){
            my $uobj=getModuleObject($self->Config,"base::user");
            foreach my $uid (keys(%uids)){
               $uobj->ResetFilter();
               $uobj->SetFilter({cistatusid=>"<6 AND >3",userid=>\$uid});
               my ($urec,$msg)=$uobj->getOnlyFirst(qw(userid));
               if (defined($urec)){
                  msg(INFO,"OpenInterview: $objname - $id ask uid=$uid");
                  push(@tobeIToDo,{
                     dataobject=>$objname,
                     dataobjectid=>$id,
                     userid=>$uid
                  });
               }
            }
         }
      }
      #######################################################################
      # do corrections in Cache table
      my @opList=();
      my $res=kernel::QRule::OpAnalyse(
         sub{  # comperator
            my ($a,$b)=@_;   
            my $eq;          # undef= nicht gleich
            if ( $a->{dataobject} eq $b->{dataobject} &&
                 $a->{dataobjectid} eq $b->{dataobjectid} &&
                 $a->{userid} eq $b->{userid}){
               $eq=1;  # rec found und keine Update notwendig (update not sup)
            }
            return($eq);
         },
         sub{  # oprec generator
            my ($mode,$oldrec,$newrec,%p)=@_;
            if ($mode eq "insert" || $mode eq "update"){
               my $oprec={
                  OP=>$mode,
                  DATAOBJ=>'base::interviewtodocache',
                  DATA=>{
                     dataobject=>$newrec->{dataobject},
                     dataobjectid=>$newrec->{dataobjectid},
                     userid=>$newrec->{userid},
                  }
               };
               if ($mode eq "update"){
                  $oprec->{IDENTIFYBY}=$oldrec->{id};
               }
               return($oprec);
            }
            elsif ($mode eq "delete"){
               my $oprec={
                  OP=>$mode,
                  DATAOBJ=>'base::interviewtodocache',
                  IDENTIFYBY=>$oldrec->{id}
               };
               return($oprec);
            }
            return(undef);
         },
         \@currIToDo,\@tobeIToDo,\@opList
      );
      if (!$res){
         my $opres=ProcessOpList($itodo,\@opList);
      }
      my $eseconds=Time::HiRes::time();
      msg(INFO,sprintf("interview cache calculation time = %.2lf\n",
                       $eseconds-$sseconds));
   }
   else{
      ####################################################################
      # BulkDelete cache for objname (ensure no cache entries, if iterview
      # is undeployed for objname
      $itodo->BulkDeleteRecord({
          dataobject=>[$self->SelfAsParentObject()],
      });
   }



   #
   # Das Enrichment Verfahren kann vorraussichtlich NICHT den
   # preQualityCheckRecord ersetzen.
   # Enrichment wird asyncron ablaufen müssen und IMMER ohne User-Interaktion
   # ablaufen, d.h. der User kann das Enrichment (stand 07/2014) 
   # vorraussichtlich nicht selbst anstoßen.
   #
   # foreach my $qrulename (@$finalQruleList){
   #    my $qrule=$self->{qrule}->{$qrulename};
   #    my $oldcontext=$W5V2::OperationContext;
   #    $W5V2::OperationContext="Enrichment";
   #    my $dataModified=0;
   #    $param[0]->{ruleno}++;
   #    if ($qrule->can("enrichRecord")){
   #      $dataModified=$qrule->enrichRecord($parent,$rec,@param);
   #    }
   #    $W5V2::OperationContext=$oldcontext;
   #    if ($dataModified){ # reload rec is a ToDo
   #       my $reloadedRec=$self->reloadRec($parent,$rec);
   #       if (!defined($reloadedRec)){
   #          msg(ERROR,"reloadRec error after enrichment");
   #          return();
   #       }
   #       $rec=$reloadedRec;
   #    }
   #  }
   #  $param[0]->{ruleno}=0;

   CIRCQC: for(my $circQC=0;$circQC<3;$circQC++){
      %alldataissuemsg=(); # a new circulaer pass resets the old messages
      $dataissueactiverulecount=0;
      $dataissuerulecount=0;
      $param[0]->{EssentialsChangedCnt}=0;
      $param[0]->{EssentialsChanged}={};
      foreach my $qrulename (@$finalQruleList){
         my $sseconds=Time::HiRes::time();
         if ($self->Config->Param("W5BaseOperationMode") eq "dev"){
            msg(INFO,"start rule $qrulename ...");
         }
         my $qrule=$self->{qrule}->{$qrulename};
         my $oldcontext=$W5V2::OperationContext;
         $W5V2::OperationContext="QualityCheck";
         my $acorrect=0;  # vorgesehen für auto correct modeA
         $param[0]->{ruleno}++;
         if ($qrule->can("qcheckRecord")){
            my $oldHistComments=$W5V2::HistoryComments;
            $W5V2::HistoryComments="QualityRule=$qrulename";
            my ($qresult,$control)=$qrule->qcheckRecord($parent,$rec,@param);
            $W5V2::OperationContext=$oldcontext;
            $W5V2::HistoryComments=$oldHistComments; 
            if (defined($control) && defined($control->{dataissue})){
               my $dataissuemsg=$control->{dataissue};
               $dataissuemsg=[$dataissuemsg] if (ref($dataissuemsg) ne "ARRAY");
               if ($#{$dataissuemsg}!=-1){
                  my $qrulename=$qrule->Self();
                  if (!defined($alldataissuemsg{$qrulename})){
                     $alldataissuemsg{$qrulename}=[];
                  }
                  push(@{$alldataissuemsg{$qrulename}},@{$dataissuemsg});
               }
            }
            if (defined($control) && defined($control->{dataupdate})){
            }
            my $resulttext="OK";
            $resulttext="fail"      if (defined($qresult) && $qresult!=0);
            $resulttext="note"      if ($qresult==1);
            $resulttext="warn"      if ($qresult==2);
            if (!defined($qresult)){
               $resulttext="disabled";
            }
            else{
               $dataissueactiverulecount++;
            }
            $dataissuerulecount++;
            my $qrulelongname=$qrule->getName();
            my $hints=$qrule->getHints();
            my $havehints=$hints eq "" ? 0 : 1;
            my $res={ 
               rulelabel=>"$qrulelongname",
               ruleid=>$qrule->Self,
               pass=>($circQC+1),
               havehints=>$havehints,
               result=>$self->T($resulttext),
               exitcode=>$qresult
            };
            if ($circQC>0){
               $res->{rulelabel}="(Pass:".($circQC+1).") ".$res->{rulelabel};
            }
            if (defined($control->{qmsg})){
               $self->translate_qmsg($control,$res,$qrulename);
            }
            push(@{$result->{rule}},$res);
            if (exists($param[0]->{abortSession}) &&
                $param[0]->{abortSession} ne ""){
               last CIRCQC;
            }
         }
         $W5V2::OperationContext=$oldcontext;
         if ($self->Config->Param("W5BaseOperationMode") eq "dev"){
            my $eseconds=Time::HiRes::time();
            my $t=sprintf("%.3lf",$eseconds-$sseconds); 
            msg(INFO,"... end rule $qrulename (duration=$t sec)");
            msg(INFO,"-------------------------------------------------\n");
         }
      }
      {
         # reload is needed, to enscure to get correct current values
         # from database - this is needed for a posible pass2 or for
         # for write accesss to record to get correct oldrec
         my $reloadedRec=$self->reloadRec($parent,$rec);
         if (!defined($reloadedRec)){
            # record does not exists after QualityCheck. This only can meen,
            # any qrule in check has delete the check-record (f.e. for 
            # cleanup
            last CIRCQC;
           # return();
         }
         $rec=$reloadedRec;
      }
      if ($param[0]->{EssentialsChangedCnt}==0){ 
         last CIRCQC;
      }
   }
   if (exists($param[0]->{abortSession}) &&     # if abortSession, no handling
              $param[0]->{abortSession} ne ""){ # for DataIssue Wf is allowed
      return($result);
   }
   if ($parent->Self() ne "base::workflow"){ # only DataIssues for nonworkflows!
      my $wf=getModuleObject($parent->Config,"base::workflow");
      my $dataobj=$parent;
      my $affectedobject=$dataobj->SelfAsParentObject();
      my $affectedobjectinstance=$dataobj->Self(); # new version of affected calc
      my $idfield=$dataobj->IdField();
      my $affectedobjectid=$idfield->RawValue($rec);
      msg(INFO,"QualityRule Level1");
      if (keys(%alldataissuemsg)){
         msg(INFO,"QualityRule Level2");
         my $directlnkmode="DataIssueMsg";
         my $detaildescription;
         foreach my $qrule (keys(%alldataissuemsg)){
            $detaildescription.="\n" if ($detaildescription ne "");
            $detaildescription.="[W5TRANSLATIONBASE=$qrule]\n";
            $detaildescription.=$qrule."\n";
            foreach my $msg (@{$alldataissuemsg{$qrule}}){
               if ($msg=~m/^\[\S+::\S+\]$/){
                  $detaildescription.=$msg."\n";
               }
               else{
                  $detaildescription.=" - ".$msg."\n";
               }
            }
         }
         msg(INFO,"QualityRule Level3");
         my $oldforce=$ENV{HTTP_FORCE_LANGUAGE};
         $ENV{HTTP_FORCE_LANGUAGE}="en";
         my $objectname=$dataobj->getRecordHeader($rec);
         if (my $headerfield=$dataobj->getRecordHeaderField($rec)){
            $objectname=$headerfield->RawValue($rec);
         }
     
         my $name="DataIssue: ".$dataobj->T($affectedobject,$affectedobject).": ".
                  $objectname;
         $ENV{HTTP_FORCE_LANGUAGE}=$oldforce;
         delete($ENV{HTTP_FORCE_LANGUAGE}) if ($ENV{HTTP_FORCE_LANGUAGE} eq "");
         $wf->ResetFilter();
         $wf->SetFilter({stateid=>"<20",class=>\"base::workflow::DataIssue",
                        # directlnktype=>\$affectedobject,
                         directlnktype=>[$affectedobject,
                                         $dataobj->SelfAsParentObject()],
                         directlnkid=>\$affectedobjectid});
         #msg(INFO,"QualityRule Level4");
         my ($WfRec,$msg)=$wf->getOnlyFirst(qw(ALL));
         my $oldcontext=$W5V2::OperationContext;
         $W5V2::OperationContext="QualityCheck";
         #msg(INFO,"QualityRule Level5");
         if (!defined($WfRec)){
            #msg(INFO,"QualityCheck: ".
            #         "an old record does not exists - so i create a new one");
            my $newrec={name=>$name,
                        detaildescription=>$detaildescription,
                        class=>"base::workflow::DataIssue",
                        step=>"base::workflow::DataIssue::dataload",
                        affectedobject=>$affectedobject,
                        affectedobjectinstance=>$affectedobjectinstance,
                        affectedobjectid=>$affectedobjectid,
                        altaffectedobjectname=>$objectname,
                        directlnkmode=>$directlnkmode,
                        eventend=>undef,
                        eventstart=>NowStamp("en"),
                        srcload=>NowStamp("en"),
                        srcsys=>$affectedobject,
                        dataissuemetric=>[sort(keys(%alldataissuemsg))],
                        dataissuerulecount=>$dataissuerulecount,
                        dataissueactiverulecount=>$dataissueactiverulecount,
                        DATAISSUEOPERATIONSRC=>$directlnkmode};
            my $bk=$wf->Store(undef,$newrec);
            $result->{wfheadid}=$bk;
         }
         else{
            msg(INFO,"QualityCheck: ".
                     "an old record exists - so i update the record");
            my $newrec={name=>$name,
                        mdate=>$WfRec->{mdate},
                        owner=>$WfRec->{owner},
                        affectedobjectinstance=>$affectedobjectinstance,
                        srcsys=>$affectedobject,
                        editor=>$WfRec->{editor},
                        realeditor=>$WfRec->{realeditor},
                        srcload=>NowStamp("en"),
                        dataissuemetric=>[sort(keys(%alldataissuemsg))],
                        dataissuerulecount=>$dataissuerulecount,
                        dataissueactiverulecount=>$dataissueactiverulecount,
                        detaildescription=>$detaildescription};
            my $bk=$wf->Store($WfRec,$newrec);
            $result->{wfheadid}=$WfRec->{id};
         }
     
         $W5V2::OperationContext=$oldcontext;
      }
      my $oldcontext=$W5V2::OperationContext;
      $W5V2::OperationContext="QualityCheck";
      #
      # cleanup deprecated DataIssues for current object
      #
      $wf->ResetFilter();
      my $cleanupfilter={stateid=>"<20",class=>\"base::workflow::DataIssue",
                      srcload=>"<\"$checkStart GMT\"",
                      directlnktype=>[$affectedobject,
                                      $dataobj->SelfAsParentObject()],
                      directlnkid=>\$affectedobjectid};
      if (!keys(%alldataissuemsg)){       # ensure that all open workflows
         delete($cleanupfilter->{srcload})# are closed, if currently no open
      }                                   # messages

      $wf->SetFilter($cleanupfilter);
      $wf->SetCurrentView(qw(ALL));
      $wf->ForeachFilteredRecord(sub{
                         $wf->Store($_,{stateid=>'21',
                                        fwddebtarget=>undef,
                                        fwddebtargetid=>undef,
                                        fwdtarget=>undef,
                                        fwdtarget=>undef});
                      });
      if (my $qclast=$parent->getField("lastqcheck")){
         my $idfield=$parent->IdField();
         if (defined($idfield)){
            my $id=$idfield->RawValue($rec);
            if ($id ne ""){
               my $updrec={
                   lastqcheck=>NowStamp("en"),
                   mdate=>$rec->{mdate}         # don't change mdate, because
               };                               # lastqcheck is not a "real"
                                                # record data
               $parent->ValidatedUpdateRecord($rec,$updrec,
                   {$idfield->Name()=>\$id}
               );
            }                               
         }
      }
      $parent->postQualityCheckRecord($rec,@param);
      $W5V2::OperationContext=$oldcontext;
   }

   return($result);

}

sub translate_qmsg
{
   my $self=shift;
   my $control=shift;
   my $res=shift;
   my $qrulename=shift;
 

   $res->{qmsg}=$control->{qmsg};
   if (ref($res->{qmsg}) eq "ARRAY"){
      for(my $c=0;$c<=$#{$res->{qmsg}};$c++){
         if (my ($pr,$po)=$res->{qmsg}->[$c]=~m/^(.*?)\s*:\s*(.*)$/){
            $res->{qmsg}->[$c]=$self->T($pr,
                                         $qrulename).": ".$po;
         }
         else{
            $res->{qmsg}->[$c]=$self->T($res->{qmsg}->[$c],
                                         $qrulename);
         }
      }
   }
   else{
      if (my ($pr,$po)=$res->{qmsg}=~m/^(.*)\s*:\s+(.*)$/){
         $res->{qmsg}=$self->T($pr,$qrulename).": ".$po;
      }
      else{
         $res->{qmsg}=$self->T($res->{qmsg},$qrulename);
      }
   }
   return($res);
}

sub WinHandleQualityCheck
{
   my $self=shift;
   my $objlist=shift;
   my $rec=shift;
   my $dataobj=$self->getParent();
   my $CurrentIdToEdit=Query->Param("CurrentIdToEdit");
   my $mode=Query->Param("Mode");
   if (defined($mode) && $mode eq "process" && $CurrentIdToEdit ne ""){
      my $reqautocorret=Query->Param("ForceAutoCorrectSession");
      $reqautocorret=1 if ($reqautocorret ne "");
      #printf STDERR ("fifi env=%s\n",Dumper(\%ENV));
      #printf STDERR ("fifi query=%s\n",Query->Dumper());
      #printf STDERR ("fifi rec=%s\n",Dumper($rec));
      print $self->HttpHeader("text/xml");
      my $res=hash2xml({},{header=>1});
      print $res."<document>";
      my %checksession=(checkstart=>time(),checkmode=>'web');
      if (exists($rec->{allowifupdate}) && $rec->{allowifupdate}==1){
         $checksession{autocorrect}=1;
      }
      if ($reqautocorret && !$checksession{autocorrect}){
         # check if write is allowed
         my @write=$dataobj->isWriteValid($rec);
         my $wr=0;
         if (in_array(\@write,[qw(ALL default)])){
            $wr++;
         }
         if ($wr){
            $checksession{autocorrect}=1;
         }
      }
      my $checkresult=$self->nativQualityCheck($objlist,$rec,\%checksession);
      #print STDERR Dumper($checkresult);
      foreach my $ruleres (@{$checkresult->{rule}}){
         my $res=hash2xml({rule=>$ruleres},{});
         print $res;
         #printf STDERR ($res."\n");
      }
      if ($checkresult->{wfheadid} ne ""){
         my $res=hash2xml({wfheadid=>$checkresult->{wfheadid}},{});
         print $res;
         #printf STDERR ($res."\n");
      }
      print "</document>";
      return();
   }
   my $d=$self->HttpHeader("text/html");
   my $winlabel;
   $winlabel=$rec->{name}     if (defined($rec->{name}));
   $winlabel=$rec->{fullname} if (defined($rec->{fullname}));
   $d.=$self->HtmlHeader(style=>['default.css','qrule.css'],
                         form=>1,body=>1,
                         js=>['toolbox.js'],
                         title=>$self->T("QC:").$winlabel);
   my $handlermask=$self->getParsedTemplate("tmpl/base.qualitycheck",
                          {static=>{winlabel=>$winlabel}});
   my $msg=$self->findtemplvar({},"LASTMSG"); 
   my $DetailClose=$self->T("DetailClose","kernel::App::Web::Listedit");
   my $DetailPrint=$self->T("DetailPrint","kernel::App::Web::Listedit");
   my $qruleinfo=$self->T("open infos to quality rule");
   my $hintsav=$self->T("hints available");
   my $autoctext=$self->T("autocorrect, if posible",'base::qrule');
   my $act="";

   my @write=$dataobj->isWriteValid($rec);
   my $wr=0;
   if (in_array(\@write,[qw(ALL default)])){
      $wr++;
   }
   if ($wr){
      $act="<input type=checkbox id=ForceAutoCorrectSession>".$autoctext;
   }
   if (exists($rec->{allowifupdate}) && $rec->{allowifupdate}==1){
      $act="";
   }


   $d.=<<EOF;
<table width="100%" height="100%" border=0>
<tr height=50><td>$handlermask</td></tr>
<tr>
<td valign=top>
<div id=reslist class=QualityCheckResultList>
</div>
</td>
</tr>
<tr height=20>
<td>
<table cellspacing=0 cellpadding=0 width="100%">
<tr><td>$msg</td><td align=right><div id=summary></div></td></tr>
</table>
</td>

</tr>
<tr height=1%>
<td>
<table width=100% border=0>
<tr>
<td align="left">$act</td>
<td align="right">
<div class=buttonline>
<input onclick="window.print();" type=button style="width:100px" value="$DetailPrint">
<input onclick="processCheck();" type=button style="width:100px" value="recheck">
<input onclick="window.close();" type=button style="width:100px" value="$DetailClose">
<input type=hidden name=CurrentIdToEdit value="$CurrentIdToEdit">
</div>
</td>
</tr>
</table>
</td>
</tr>
</table>
<script language="JavaScript">

function showLoading()
{
   var r=document.getElementById("reslist");
   if (r){
      var t="<center><br><br>"+
            "<img src='../../base/load/ajaxloader.gif'><br>"+
            "Loading ...</center>";
      if (r.innerHTML!=t){
         r.innerHTML=t;
      }
   }
   else{
      alert("Element reslist not found");
   }
   var r=document.getElementById("summary");
   if (r){
      var t="- working -";
      if (r.innerHTML!=t){
         r.innerHTML=t;
      }
   }
   else{
      alert("Element summary not found");
   }
}

function addToResult(ruleid)
{
   window.setTimeout(showLoading,1);
   var xmlhttp=getXMLHttpRequest();
   xmlhttp.open("POST",document.location.href,true);
   xmlhttp.onreadystatechange=function() {
//    if (xmlhttp.readyState<4){
//       var r=document.getElementById("reslist");
//       if (r){
//          var t="Checking ...";
//          if (r.innerHTML!=t){
//             r.innerHTML=t;
//          }
//       }
//       var r=document.getElementById("summary");
//       if (r){
//          var t="- working -";
//          if (r.innerHTML!=t){
//             r.innerHTML=t;
//          }
//       }
//    }
    if (xmlhttp.readyState==4 && (xmlhttp.status==200 || xmlhttp.status==304)){
       var xmlobject = xmlhttp.responseXML;
       var r=document.getElementById("reslist");
       r.innerHTML="";
       var wfheadidobj=xmlobject.getElementsByTagName("wfheadid");
       var wfheadid;
       if (wfheadidobj && wfheadidobj[0] && wfheadidobj[0].childNodes &&
           wfheadidobj[0].childNodes[0]){
          wfheadid=wfheadidobj[0].childNodes[0].nodeValue;
       }
       var results=xmlobject.getElementsByTagName("rule");
       var ok=0;
       var warn=0;
       var fail=0;
       var passno;
       if (results.length>0){
          for(rid=0;rid<results.length;rid++){
             var ruleres=results[rid];

             var label=ruleres.getElementsByTagName("rulelabel")[0];
             var labelChildNode=label.childNodes[0];
             var labeltext=labelChildNode.nodeValue;

             var ruleid=ruleres.getElementsByTagName("ruleid")[0];
             var ruleidChildNode=ruleid.childNodes[0];
             var ruleidtext=ruleidChildNode.nodeValue;

             var result=ruleres.getElementsByTagName("result")[0];
             var resultChildNode=result.childNodes[0];
             var resulttext=resultChildNode.nodeValue;

             var havehints=ruleres.getElementsByTagName("havehints")[0];
             var havehintsChildNode=havehints.childNodes[0];
             var havehintstext=havehintsChildNode.nodeValue;

             var pass=ruleres.getElementsByTagName("pass")[0];
             var passChildNode=pass.childNodes[0];
             var passtext=passChildNode.nodeValue;
             if (passtext!=passno){
                passno=passtext;
                fail=0;
                ok=0;
                warn=0;
             }

             var exitcode=ruleres.getElementsByTagName("exitcode")[0];
             var exitcodetext="?";
             var color="";
             if (exitcode.childNodes[0]){
                var exitcodeChildNode=exitcode.childNodes[0];
                var exitcodetext=exitcodeChildNode.nodeValue;
                color="<font color=green>";
                if (exitcodetext!=0){
                   color="<font color=red>";
                   fail++;
                }
                else{
                   ok++;
                }
                if (exitcodetext==1){
                   color="<font color=#D7AD08>";
                }
                if (exitcodetext==2){
                   warn++;
                }
             }
             var atitle="$qruleinfo";
             var tabselect="";
             if (havehintstext=="1"){
                labeltext+=" <img alt='hints available' height=10 width=10 "+
                           "border=0 "+
                           "src='../../base/load/info.gif'>";
                atitle+=" - $hintsav";
                tabselect="ModeSelectCurrentMode=FView&";
             }
             r.innerHTML+="<a title='"+atitle+"' class=rulelink href=javascript:openwin('../../base/qrule/Detail?"+tabselect+"id="+ruleidtext+"','_blank','height=480,width=640,toolbar=no,status=no,resizeable=yes,scrollbars=no')>"+labeltext+"</a>"+": "+color+resulttext+"</font><br>";

             var qmsg=ruleres.getElementsByTagName("qmsg");

             if (qmsg.length>0){
                r.innerHTML+="<ul>";
                for(eid=0;eid<qmsg.length;eid++){
                   var qmsgChildNode=qmsg[eid].childNodes[0];
                   var qmsgtext=qmsgChildNode.nodeValue;
                   r.innerHTML+="<li>"+qmsgtext+"</li>";
                  
                }
                r.innerHTML+="</ul>";
             }
             r.innerHTML+="<div style=\\"height:4px\\"></div>";
          }
          var r=document.getElementById("summary");
          if (r){
             var t="R:";
             if (wfheadid){
                t="<a class=rulelink href=javascript:openwin('../../base/workflow/ById/"+wfheadid+"','_blank','height=480,width=640,toolbar=no,status=no,resizeable=yes,scrollbars=no')>"+t+'</a>';
             }
             t=t+results.length+"/<font color=green>"+ok+"</font>";
             if (warn>0){
                 t+="/<font color=orange>"+warn+"</font>";
             }
             if (fail>0){
                 t+="/<font color=red>"+fail+"</font>";
             }
             if (r.innerHTML!=t){
                r.innerHTML=t;
             }
          }
       }
       else{
          r.innerHTML="no rules defined";
          var r=document.getElementById("summary");
          if (r){
             var t="-";
             if (r.innerHTML!=t){
                r.innerHTML=t;
             }
          }
       }
    }
   }
   var forceAutoCorrect=document.getElementById("ForceAutoCorrectSession");
   var ForceAutoCorrectSessionParam="";
   if (forceAutoCorrect){
      if (forceAutoCorrect.checked){
         ForceAutoCorrectSessionParam="&ForceAutoCorrectSession=1";
      }
   }
   xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded');
   var r=xmlhttp.send('Mode=process&CurrentIdToEdit='+'$CurrentIdToEdit'+
                      ForceAutoCorrectSessionParam);
}
function resizeOut()
{
   var r=document.getElementById("reslist");
   var h=getViewportHeight(); 
   r.style.height=(h-140)+"px";  // set height of output fix
}
function processCheck()
{
   var r=document.getElementById("reslist");
   resizeOut();
   r.innerHTML="";
   addToResult(1);
}
addEvent(window,"load",processCheck);
addEvent(window,"resize",resizeOut);

</script>
EOF

   $d.=$self->HtmlBottom(body=>1,form=>1);



   return($d);
}


sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_;

   if (defined($rec)){
      if ($rec->{hints} ne ""){
         if ($ENV{REMOTE_USER} ne "anonymous"){
            return($self->SUPER::getHtmlDetailPages($p,$rec),
                   "FView"=>$self->T("Rule Infos"));
         }
         return("FView"=>$self->T("Rule Infos"));
      }
   }
   return($self->SUPER::getHtmlDetailPages($p,$rec));
}


sub getHtmlDetailPageContent
{
   my $self=shift;
   my ($p,$rec)=@_;

   my $page;
   my $idname=$self->IdField->Name();
   my $idval=$rec->{$idname};

   return($self->SUPER::getHtmlDetailPageContent($p,$rec)) if ($p ne "FView");
   $self->HandleLastView("HtmlDetail",$rec) if ($p eq "StandardDetail");

   if ($p eq "FView"){
      Query->Param("$idname"=>$idval);
      $idval="NONE" if ($idval eq "");

      my $q=new kernel::cgi({});
      $q->Param("$idname"=>$idval);
      my $urlparam=$q->QueryString();
      $page="<link rel=\"stylesheet\" ".
            "href=\"../../../static/lytebox/lytebox.css\" ".
            "type=\"text/css\" media=\"screen\" />";

      $page.="<iframe style=\"width:100%;height:100%;border-width:0;".
            "padding:0;margin:0\" class=HtmlDetailPage name=HtmlDetailPage ".
            "src=\"FullView?$urlparam\"></iframe>";
   }
   $page.=$self->HtmlPersistentVariables($idname);
   return($page);
}


sub getValidWebFunctions
{
   my $self=shift;

   return($self->SUPER::getValidWebFunctions(@_),"FullView");
}


sub FullView
{
   my $self=shift;
   my $lang=$self->Lang();
   my %flt=$self->getSearchHash();
   $self->ResetFilter();
   $self->SecureSetFilter(\%flt);
   my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));

   print $self->HttpHeader();
   print $self->HtmlHeader(body=>1,
                           js=>'toolbox.js',
                           style=>['default.css',
                                   'kernel.App.Web.css',
                                   'kernel.App.Web.DetailPage.css',
                                   'base.qrule.css']);
   printf("<div style=\"margin-left:5px\">");
   printf("<h1>%s:</h1>",$self->T("Quality Rule"));
   printf("<h2 style=\"margin-top:20px\">%s</h2>",$rec->{name});

   printf("<div style=\"border-width:1px;border-style:solid;".
          "border-color:silver;margin-top:20px;".
          "padding-bottom:10px;margin-right:10px\">");

   my $t=quoteHtml(extractLangEntry($rec->{hints},$lang,undef,1));
   $t=~s/\n/<br>\n/g;
   my $c=FancyLinks($t);
   $c=~s/\n/<br>\n/gs;
   printf("<div style=\"margin:5px;margin-top:5px\">".
          "<b>%s:</b><br>%s</div>",$self->T("Hints"),$c);


   my $contact=$self->findtemplvar({current=>$rec,mode=>"HtmlDetail"},
                                   "contact","formated");
   if ($rec->{contact} ne ""){
      printf("<div style=\"margin:5px;margin-top:20px\">".
             "<b>%s:</b><br>%s</div>",
             $self->findtemplvar({current=>$rec,mode=>"HtmlDetail"},
                                 "contact","label"),$contact);
   }

   my $contact2=$self->findtemplvar({current=>$rec,mode=>"HtmlDetail"},
                                   "contact2","formated");
   if ($rec->{contact2} ne ""){
      printf("<div style=\"margin:5px;margin-top:20px\">".
             "<b>%s:</b><br>%s</div>",
             $self->findtemplvar({current=>$rec,mode=>"HtmlDetail"},
                                 "contact2","label"),$contact2);
   }
   print("</div>");

   if (defined($rec)){
      my $faq=getModuleObject($self->Config(),"faq::article");
      if (defined($faq)){
         my $further=$faq->getFurtherArticles("QualityRule ".$rec->{id});
         if ($further ne ""){
            print($further);
         }
      }
   }



   print $self->HtmlBottom(body=>1);


}




   



1;
