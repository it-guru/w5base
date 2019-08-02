package itil::workflow::riskmgmt;
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
use kernel::WfClass;

@ISA=qw(kernel::WfClass itil::workflow::base);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->{history}=[qw(insert modify delete)];
   return($self);
}

sub Init
{
   my $self=shift;
   $self->AddGroup("riskdesc",translation=>'itil::workflow::riskmgmt');
   $self->AddGroup("riskrating",translation=>'itil::workflow::riskmgmt');
   $self->AddGroup("riskbase",translation=>'itil::workflow::riskmgmt');
   $self->itil::workflow::base::Init();
   return($self->SUPER::Init(@_));
}

sub storedParamHandler
{
   my $self=shift;
   my $d=shift;
   my $current=shift;
   my $name=$self->Name();

   if ($current->{stateid}<20){
      return($d);  # normal resolution
   }
   else{
      return("?") if (ref($current->{headref}) ne "HASH");
      my $headref=$current->{headref};
      return("??") if (ref($headref->{"stored_".$name}) ne "ARRAY");
      return($headref->{"stored_".$name}->[0]);
   }
}


sub PostponeMaxDays   # postpone max days after WfStart
{
   my $self=shift;
   my $WfRec=shift;

   return((365*3)+5);
}



sub IsModuleSelectable
{
   my $self=shift;
   my $acl;

   $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
                          "base::workflow",
                          func=>'New',
                          param=>'WorkflowClass=itil::workflow::riskmgmt');
   if (defined($acl)){
      return(1) if (grep(/^read$/,@$acl));
   }
   return(0);
}


sub getcachedArec
{
   my $self=shift;
   my $rec=shift;
   my $cachedArec;
   my $applid=$rec->{affectedapplicationid};
   my $appl=getModuleObject($self->Config,"itil::appl");
   $appl->SetFilter({id=>$applid});
   my ($arec,$msg)=$appl->getOnlyFirst(qw(applmgrid databossid mandatorid));
   if (defined($arec)){
      $cachedArec=$arec;
   }
   return($cachedArec);
}



sub isCurrentApplMgr
{
   my $self=shift;
   my $rec=shift;
   my $cachedArec=shift;

   if (!defined($cachedArec)){
      $cachedArec=$self->getcachedArec($rec);
   }
   my $userid=$self->getParent->getCurrentUserId();
   if (!defined($cachedArec)){
      return(0);
   }
   if ($userid eq $cachedArec->{applmgrid}){
      return(1);
   }
   return(0);
}


sub isRiskWfAuthorized
{
   my $self=shift;
   my $mode=shift;
   my $rec=shift;
   my $cachedArec=shift;

   if (!defined($cachedArec)){
      $cachedArec=$self->getcachedArec($rec);
   }
   my $userid=$self->getParent->getCurrentUserId();
   if (!defined($cachedArec)){
      return(0);
   }
   if ($mode eq "create" || $mode eq "view"){
      if ($userid eq $cachedArec->{applmgrid}){
         return(1);
      }
      if ($userid eq $cachedArec->{databossid}){
         return(1);
      }
   }
   if ($mode eq "modify" || $mode eq "view"){
      my $userid=$self->getParent->getCurrentUserId();
      if ($rec->{fwdtarget} eq "base::user" &&
          $rec->{fwdtargetid} eq $userid){
         return(1);
      }
   }
   my @mandatorid=($cachedArec->{mandatorid});
   if (defined($rec) && ref($rec->{mandatorid}) eq "ARRAY"){
      push(@mandatorid,@{$rec->{mandatorid}});
   }

   if ($self->IsMemberOf(\@mandatorid,[qw(RSKCoord RSKManager 
                                          RSKPManager RSKPManager2)],"down")){
      return(1);
   }
   if ($mode eq "view"){
      return(1) if ($self->IsMemberOf("admin"));
   }
   return(0);
}


sub checkAllowCreateWorkflow
{
   my $self=shift;
   my $h=shift;
   my $arec=shift;

   if (!$self->isRiskWfAuthorized("create",$h,$arec)){
      $self->LastMsg(ERROR,
         "no authorisation to create risk workflow for selected application");
      return(0);
   }
   return(1);
}


sub getResponsibleRiskRole
{
   my $self=shift;
   my $rec=shift;
   my $cachedArec=shift;

   if (!defined($cachedArec)){
      my $appl=getModuleObject($self->Config,"itil::appl");
      my $flt={id=>$rec->{affectedapplicationid}};
      $appl->SetFilter($flt);
      my ($arec,$msg)=$appl->getOnlyFirst(qw(mandatorid));
      if (defined($arec)){
         $cachedArec=$arec;
      }
   }
   if (!defined($cachedArec)){
      return;
   }
   my @rskmgr;

   @rskmgr=$self->getParent->getMembersOf($cachedArec->{mandatorid},
                                          ['RSKCoord'],'firstup');
   if ($#rskmgr==-1){
      @rskmgr=$self->getParent->getMembersOf($cachedArec->{mandatorid},
                                          [qw(RSKManager 
                                              RSKPManager 
                                              RSKPManager2)],'firstup');
   }
   return(@rskmgr);
}




sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;

   my @l=($self->InitFields(
      new kernel::Field::Select(  name          =>'riskbasetype',
                                  label         =>'Risk base type',
                                  value         =>['personal',
                                                   'response',
                                                   'software',
                                                   'hardware',
                                                   'infrastructure',
                                                   'drbackup',
                                                   'performance',
                                                   'budget',
                                                   'thiredparty',
                                                   'privacy',
                                                   'OTHER'],
                                  transprefix   =>'RISKBASE.',
                                  group         =>'riskbase',
                                  container     =>'headref'),

      new kernel::Field::Textarea(name          =>'extdescriskimpact',
                                  label         =>'Description of the impact '.
                                                  'on the occurrence of the '.
                                                  'risk',
                                  group         =>'riskdesc',
                                  container     =>'headref'),

      new kernel::Field::Select(  name          =>'extdescriskdowntimedays',
                                  label         =>'Estimate downtime '.
                                                  'in case the risk '.
                                                  'occurs',
                                  htmleditwidth =>'120',
                                  value         =>[ 0..30 ],
                                  transprefix   =>'RISKDAYS.',
                                  group         =>'riskdesc',
                                  container     =>'headref'),

      new kernel::Field::Select(  name          =>'extdescriskoccurrency',
                                  label         =>'Probability of occurrence '.
                                                  'Risk',
                                  htmleditwidth =>'120',
                                  value         =>['0','1','2','3','4','5',
                                                   '6','7','8','9','10','11'],
                                  default       =>'0',
                                  transprefix   =>'RISKPCT.',
                                  group         =>'riskdesc',
                                  container     =>'headref'),


      new kernel::Field::Date(    name          =>'extdescarisedate',
                                  label         =>'When can the risk arise?',
                                  dayonly       =>2,
                                  group         =>'riskdesc',
                                  container     =>'headref'),



      new kernel::Field::Text(    name          =>'riskmgmtcolor',
                                  label         =>'Risk value color',
                                  htmldetail    =>0,
                                  group         =>'riskrating',
                                  onRawValue    =>\&getCalculatedRiskState),

      new kernel::Field::Text(    name          =>'riskmgmtpoints',
                                  background    =>sub{
                                     my $self=shift;
                                     my $mode=shift;
                                     my $current=shift;
                                     my $fld=$self->getParent->getField(
                                             "riskmgmtcolor",$current);
                                     my $color=$fld->RawValue($current);
                                     return($color);
                                  },
                                  label         =>'Risk value',
                                  group         =>'riskrating',
                                  onRawValue    =>\&getCalculatedRiskState),

      new kernel::Field::Textarea(name          =>'riskmgmtcalclog',
                                  label         =>'Risiko calculation log',
                                  htmlwidth     =>'300',
                                  nowrap        =>1,
                                  htmldetail    =>sub{
                                     my $self=shift;
                                     my $mode=shift;
                                     my %param=@_;
                                     my $current=$param{current};
                                     my @mandatorid=@{$current->{mandatorid}}; 
                                     if ($self->getParent->IsMemberOf(
                                         \@mandatorid,
                                         [qw(RSKCoord RSKManager
                                             RSKPManager RSKPManager2)],"up")){
                                        return(1);
                                     }
                                     return(0);
                                  },
                                  vjoinconcat   =>"\n",
                                  group         =>'riskrating',
                                  onRawValue    =>\&getCalculatedRiskState),

      new kernel::Field::Textarea(name          =>'riskmgmtestimation',
                                  label         =>'Risiko processual estimation',
                                  htmlwidth     =>'300',
                                  nowrap        =>1,
                                  htmldetail    =>0,
                                  vjoinconcat   =>"\n",
                                  htmldetail    =>sub{
                                     my $self=shift;
                                     my $mode=shift;
                                     my %param=@_;
                                     my $current=$param{current};
                                     my @mandatorid=@{$current->{mandatorid}}; 
                                     if ($self->getParent->IsMemberOf(
                                         \@mandatorid,
                                         [qw(RSKCoord RSKManager
                                             RSKPManager RSKPManager2)],"up")){
                                        return(1);
                                     }
                                     return(0);
                                  },
                                  group         =>'riskrating',
                                  onRawValue    =>\&getRiskEstimation),

      new kernel::Field::Htmlarea(name          =>'riskmgmtcondition',
                                  label         =>'Risiko machining condition',
                                  htmlwidth     =>'300',
                                  xnowrap        =>1,
                                  htmldetail    =>0,
                                  vjoinconcat   =>"\n",
                                  group         =>'riskrating',
                                  onRawValue    =>\&getRiskEstimation),

      new kernel::Field::TextDrop(name          =>'applicationbase',
                                  label         =>'risk base data application',
                                  group         =>'riskbase',
                                  vjointo       =>'itil::riskmgmtbase',
                                  vjoindisp     =>'name',
                                  vjoinon       =>['affectedapplicationid'=>
                                                   'id']),

      new kernel::Field::TextDrop(name          =>'solutionopt',
                                  label         =>'Solution OPT',
                                  translation   =>'itil::riskmgmtbase',
                                  group         =>'riskbase',
                                  weblinkto     =>'none',
                                  vjointo       =>'itil::riskmgmtbase',
                                  vjoindisp     =>'solutionopt',
                                  vjoinon       =>['affectedapplicationid'=>'id'],
                                  prepRawValue  =>\&storedParamHandler),

      new kernel::Field::Link(    name          =>'stored_solutionopt',
                                  label         =>'stored solutionopt',
                                  group         =>'riskbase',
                                  container     =>'headref'),

      new kernel::Field::TextDrop(name          =>'itrmcriticality',
                                  label         =>'ITRM criticality',
                                  translation   =>'itil::riskmgmtbase',
                                  group         =>'riskbase',
                                  weblinkto     =>'none',
                                  vjointo       =>'itil::riskmgmtbase',
                                  vjoindisp     =>'itrmcriticality',
                                  vjoinon       =>['affectedapplicationid'=>'id'],
                                  prepRawValue  =>\&storedParamHandler),

      new kernel::Field::Link(    name          =>'stored_itrmcriticality',
                                  label         =>'stored itrmcriticality',
                                  group         =>'riskbase',
                                  container     =>'headref'),

      new kernel::Field::TextDrop(name          =>'ibipoints',
                                  label         =>'IBI Points',
                                  translation   =>'itil::riskmgmtbase',
                                  group         =>'riskbase',
                                  weblinkto     =>'none',
                                  vjointo       =>'itil::riskmgmtbase',
                                  vjoindisp     =>'ibipoints',
                                  vjoinon       =>['affectedapplicationid'=>'id'],
                                  prepRawValue  =>\&storedParamHandler),

      new kernel::Field::Link(    name          =>'stored_ibipoints',
                                  label         =>'stored ibipoints',
                                  group         =>'riskbase',
                                  container     =>'headref'),

      new kernel::Field::TextDrop(name          =>'ibiprice',
                                  label         =>'IBI EURO',
                                  translation   =>'itil::riskmgmtbase',
                                  group         =>'riskbase',
                                  weblinkto     =>'none',
                                  vjointo       =>'itil::riskmgmtbase',
                                  vjoindisp     =>'ibiprice',
                                  vjoinon       =>['affectedapplicationid'=>'id'],
                                  prepRawValue  =>\&storedParamHandler),

      new kernel::Field::Link(    name          =>'stored_ibiprice',
                                  label         =>'stored ibiprice',
                                  group         =>'riskbase',
                                  container     =>'headref'),

    ),$self->SUPER::getDynamicFields(%param));
   $self->getField("affectedcontract")->{htmldetail}=0;
   $self->getField("affectedsystem")->{htmldetail}=0;
   $self->getField("affectedproject")->{htmldetail}=0;

    return(@l);
}


sub calculateRiskState
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $st=shift;

}


sub getMandatoryParamFields
{
   my $self=shift;

   return(qw(extdescriskdowntimedays extdescriskoccurrency extdescarisedate));
}


sub getCalculatedRiskState
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $name=$self->Name();

   my $id=$current->{id};

   if (!defined($self->getParent->Context->{CalcRiskState}->{$id})){
      my $st={
         raw=>{
            riskmgmtpoints=>'',
            riskmgmtcalclog=>[],
            riskmgmtcolor=>''
         }
      };
      $self->getParent->calculateRiskState($current,$mode,$st);
      $self->getParent->Context->{CalcRiskState}->{$id}=$st;
   }
   return($self->getParent->Context->{CalcRiskState}->{$id}->{raw}->{$name});
}


sub RiskEstimation
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $st=shift;



}


sub getRiskEstimation
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $name=$self->Name();

   my $id=$current->{id};

   if (!defined($self->getParent->Context->{RiskEstimation}->{$id})){
      my $st={
         raw=>{
            riskmgmtestimation=>[],
            riskmgmtcondition=>[]
         }
      };
      $self->getParent->RiskEstimation($current,$mode,$st);
      $self->getParent->Context->{RiskEstimation}->{$id}=$st;
   }
   return($self->getParent->Context->{RiskEstimation}->{$id}->{raw}->{$name});
}






sub getPosibleWorkflowDerivations
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my @l;

   if ($WfRec->{stateid}<17){
      push(@l,
         {label=>$self->T('Initiate developer request'),
          actor=>sub{
             my $self=shift;
             my $WfRec=shift;

             return({
                targeturl=>'New',
                targetparam=>{
                  Formated_name=>$WfRec->{name},
                  Formated_detaildescription=>
                                 $WfRec->{detaildescription},
                  Formated_affectedapplication=>$WfRec->{affectedapplication},
                  WorkflowClass=>'itil::workflow::devrequest'
                }
             });
          },
          name=>'initiatedevrequest'
         },
         );
   }

   return(@l);
}



sub checkextdescdesstart
{
   my $self=shift;
   my $current=shift;
   my %FOpt=@_;


   return("<img border=1 src=\"../../base/load/attention.gif\">");

}

sub  recalcResponsiblegrp
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   $self->SUPER::recalcResponsiblegrp($oldrec,$newrec);
   if (!defined($newrec->{responsiblegrp}) ||
       $#{$newrec->{responsiblegrp}}==-1){
      my $applid=effVal($oldrec,$newrec,"affectedapplicationid");
      my $appl=getModuleObject($self->Config,"itil::appl");
      $appl->SetFilter({id=>$applid});
      my ($arec,$msg)=$appl->getOnlyFirst(qw(businessteam businessteamid));
      if (defined($arec) && $arec->{businessteam} ne ""){
         $newrec->{responsiblegrp}=[$arec->{businessteam}];
         $newrec->{responsiblegrpid}=[$arec->{businessteamid}];
      }
   }
}



sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   return("itil::workflow::riskmgmt::".$shortname);
}




sub getNextStep
{
   my $self=shift;
   my $currentstep=shift;
   my $WfRec=shift;

   if($currentstep eq ""){
      return($self->getStepByShortname("dataload",$WfRec));
   }
   if($currentstep=~m/::dataload$/){
      return($self->getStepByShortname("paramload",$WfRec));
   }
   if($currentstep=~m/::paramload$/){
      return($self->getStepByShortname("main",$WfRec));
   }
   return(undef);
}


sub camuflageOptionalField
{
   my $self=shift;
   my $fld=shift;
   my $d=shift;
   my $current=shift;
   if ($fld->Name() eq "name"){
      if (!$self->isRiskWfAuthorized("view",$current)){
         if (length($d)>3){
            $d=substr($d,0,3)."...";
         }
      }
   }

   return($d);
}




sub isOptionalFieldVisible
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   my $name=$param{field}->Name();

   my $fld=$self->getField("wffields.riskbasetype",$param{current});
   my $riskbasetype=$fld->RawValue($param{current});

   if ($mode eq "HtmlDetail"){
      if ($name eq "detaildescription"){
         if ($riskbasetype ne "OTHER"){
            return(0);
         }
         else{
            return(1);
         }
      }
   }
   return(1) if ($name eq "relations");
   return(0) if ($name eq "prio");
   return(1) if ($name eq "name");
   return(1) if ($name eq "shortactionlog");
   return(0);
}







sub expandVar
{
   my $self=shift;
   my $var=shift;
   my $current=shift;

   if ($var eq "W5BaseID"){
      return($current->{id});
   }

   return("?");
}

sub getSpecificDataloadForm
{
   my $self=shift;

   my $templ=<<EOF;
<tr>
<td class=fname>%customerrefno(label)%:</td>
<td colspan=3 class=finput>%customerrefno(detail)%</td>
</tr>
EOF
   return($templ);
}


sub XgetRequestNatureOptions
{
   my $self=shift;
   return($self->getParent->getRequestNatureOptions());
}
sub getRequestNatureOptions
{
   my $self=shift;
   my $vv=['operation','project','modification','inquiry','other'];
   my @l;
   foreach my $v (@$vv){
      push(@l,$v,$self->T($v));
   }
   return(@l);
}


sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;
   my $userid=$self->getParent->getCurrentUserId();
   my $isadmin=$self->getParent->IsMemberOf("admin");
   my $iscurrent=$self->isCurrentForward($WfRec);
   my $lastworker=$WfRec->{owner};
   my $creator=$WfRec->{openuser};
   my $initiatorid=$WfRec->{initiatorid};
   my $isRiskWfAuthorized=$self->isRiskWfAuthorized("modify",$WfRec);
   my $isCurrentApplMgr=$self->isCurrentApplMgr($WfRec);


   my $openSubWf=0;
   my $haveSubWf=0;
   my $notDeferedWf=0;

   foreach my $relrec (@{$WfRec->{relations}}){
      $haveSubWf++;
      if ($relrec->{dststate}<20){
         $openSubWf=1;
         if ($relrec->{dststate}!=5){
            $notDeferedWf++;
         }
      }
   }


   my $isworkspace=0;
   if (!$iscurrent){  # check Workspace only if not current
      $isworkspace=$self->isCurrentWorkspace($WfRec);
   }

   my @l=$self->SUPER::getPosibleActions($WfRec);

   if (!$self->getParent->isDataInputFromUserFrontend()){
      if ($WfRec->{stateid}>=17){
         push(@l,"wfforcerevise");
      }
   }
   if ($WfRec->{stateid}<16 && 
       $WfRec->{stateid}==4){
      if ($iscurrent){
         push(@l,"wfaddopmeasure");
         if ($haveSubWf){ # Zurückstellen erst möglich, wenn Maßnahmen existsi.
            if ($notDeferedWf==0){
               push(@l,"wfdefer");
            }
         }
      }
   }
   if ($WfRec->{stateid}<17){  # noch nicht geschlossen
      if ($iscurrent){
         push(@l,"wfmailsend");
         push(@l,"wfforward");
      }
      else{
         if ($self->isRiskWfAuthorized("view",$WfRec)){
            push(@l,"wfmailsend");
         }
      }
   }
   if ($WfRec->{stateid}<20){  # noch nicht beendet
      if ($isRiskWfAuthorized){
         push(@l,"wfforward");
      }
      if ($isCurrentApplMgr && !$iscurrent){
         push(@l,"wfhardtake");
      }
   }
   if ($WfRec->{stateid} eq "17"){
      if ($iscurrent && $isRiskWfAuthorized){
         push(@l,"wffine");
      }
   }
   if ($WfRec->{stateid} > 1 && $WfRec->{stateid} ne "17"){
      if ($haveSubWf){   # schliesen nur dann, wenn min. eine Maßnahme
         if (($iscurrent || $isadmin) && !$openSubWf){
            push(@l,"wfclose");
         }
      }
   }
   if ($WfRec->{stateid} eq "1"){  
      if ($iscurrent || $userid==$creator || $isadmin){
         push(@l,"wfbreak");
      }
   }
   if ($iscurrent){
      push(@l,"wfaddnote");
      push(@l,"iscurrent");
   }
   if ($WfRec->{stateid}>=20){  # ab beendet ist nichts mehr machbar
      @l=();
   }
   
   #msg(INFO,"posible Actions in riskmgmt workflow=".join(",",@l));
   return(@l);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   my @l=("default","header");


   if ($self->isRiskWfAuthorized("view",$rec)){
      push(@l,"riskdesc","riskrating","relations","state",
              "history","flow","affected","riskbase");
   }

   return(@l);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my @l=$self->SUPER::isWriteValid(@_);
   push(@l,"extdesc") if (!defined($_[0]));

   if ($rec->{stateid} <16){
      if ($self->isRiskWfAuthorized("modify",$rec)){
         push(@l,"riskdesc");
      }
   }
   return(@l);
}

sub getDetailBlockPriority            # posibility to change the block order
{
   return("header","default","riskdesc","riskrating",
          "riskbase","affected","customerdata","init","flow");
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/workflow_riskmgmt.jpg?".
          $cgi->query_string());
}

sub getPosibleRelations
{
   my $self=shift;
   my $WfRec=shift;
   return("itil::workflow::riskmgmt"=>'relchange'); 
}

sub WSDLaddNativFieldList
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $class=shift;
   my $mode=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;

   if ($mode eq "store"){
      $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
                  "name=\"affectedapplication\" type=\"xsd:string\" />";
#      $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
#                  "name=\"extdescdesstart\" type=\"xsd:date\" />";
#      $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
#                  "name=\"extdescdesend\" type=\"xsd:date\" />";
#      $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
#                  "name=\"extdescurgency\" type=\"xsd:string\" />";
#      $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
#                  "name=\"extdescdependencies\" type=\"xsd:string\" />";
#      $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
#                  "name=\"extdescpreparation\" type=\"xsd:string\" />";
#      $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
#                  "name=\"extdescfallback\" type=\"xsd:string\" />";
   }


   return($self->SUPER::WSDLaddNativFieldList($uri,$ns,$fp,$class,$mode,
                              $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes));
}


sub isRiskParameterComplete
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (effVal($oldrec,$newrec,"extdescarisedate") eq ""){
      return(0);
   }
   return(1);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $allok=$self->isRiskParameterComplete($oldrec,$newrec);

   if ($allok){
      if (effVal($oldrec,$newrec,"stateid")<4){
         $newrec->{stateid}=4;
      }
   }  
   else{
      if (effVal($oldrec,$newrec,"stateid") eq "4"){
         $newrec->{stateid}=1;
      }
   }
   return(1);
}









#######################################################################
package itil::workflow::riskmgmt::dataload;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   #my $oldval=Query->Param("Formated_prio");
   #$oldval="5" if (!defined($oldval));
   #my $d="<select name=Formated_prio style=\"width:100px\">";
   #my @l=("high"=>3,"normal"=>5,"low"=>8);
   #while(my $n=shift(@l)){
   #   my $i=shift(@l);
   #   $d.="<option value=\"$i\"";
   #   $d.=" selected" if ($i==$oldval);
   #   $d.=">".$self->T($n,"base::workflow")."</option>";
   #}
   #$d.="</select>";
   #my $checknoautoassign;
   #if (Query->Param("Formated_noautoassign") ne ""){
   #   $checknoautoassign="checked";
   #}

   my $nextstart=$self->getParent->getParent->T("NEXTSTART","base::workflow");
   my $secial=$self->getParent->getSpecificDataloadForm();
   my $t1=$self->getParent->T("What kind of risk do you have?","itil::workflow::riskmgmt");
   my $t2=$self->getParent->T("Please describe the risk","itil::workflow::riskmgmt");
   my $t3=$self->getParent->T("(only needed in risk of type \"other\")","itil::workflow::riskmgmt");




   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr>
<td class=fname>$t1</td>
<td colspan=3 class=finput>%riskbasetype(detail)%</td>
</tr>
<tr>
<td class=fname width=20%>%name(label)%:</td>
<td colspan=3 class=finput>%name(detail)%</td>
</tr>
<tr>
<td class=fname valign=top width=20%>$t2:<br><font color=gray>$t3</font></td>
<td colspan=3 class=finput>%detaildescription(detail)%</td>
</tr>
<tr>
<td class=fname>%affectedapplication(label)%:</td>
<td colspan=3 class=finput>%affectedapplication(detail)%</td>
</tr>
<script language="JavaScript">
setFocus("Formated_name");
setEnterSubmit(document.forms[0],"NextStep");
</script>
</table>
<script language="JavaScript">
setFocus("Formated_name");
setEnterSubmit(document.forms[0],"NextStep");
function setInitFormLayout(reqnature){
  var desc=document.getElementById("detaildescription");
  if (reqnature.match(/^OTHER.*/)){
     desc.style.visibility='visible';
     desc.style.display='block';
  }
  else{
     desc.style.display='none';
     desc.style.visibility='hidden';
  }
}
function handleFieldLayout(){
  var sel=document.forms[0].elements['Formated_riskbasetype'];
  var val=sel.options[sel.selectedIndex].value;
  console.log("val=",val);
  setInitFormLayout(val);

}
window.onload = function() {
    document.forms[0].elements['Formated_riskbasetype'].onchange=handleFieldLayout;
    handleFieldLayout();
}
</script>

EOF
   return($templ);
}


sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      my $fo=$self->getField("affectedapplication");
      my $foval=Query->Param("Formated_".$fo->Name());
      if ($foval=~m/^\s*$/){
         $self->LastMsg(ERROR,"no application specified");
         return(0);
      }
      my $apphash;
      if (!($apphash=$fo->Validate($WfRec,{$fo->Name=>$foval}))){
         $self->LastMsg(ERROR,"unknown error") if (!$self->LastMsg());
         return(0);
      }
      if (!$self->getParent->checkAllowCreateWorkflow($apphash)){
         return(0);
      }

      my @rskmgr=$self->getParent->getResponsibleRiskRole($apphash);
      if ($#rskmgr==-1){
         $self->LastMsg(ERROR,
             "no riskcoordinator for application");
         return(0);
      }

      if (Query->Param("Formated_name") eq ""){
         $self->LastMsg(ERROR,"no short description specified");
         return(0);
      }
   }
   return($self->SUPER::Process($action,$WfRec,$actions));
}



sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   return("340");
}


#######################################################################
package itil::workflow::riskmgmt::paramload;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);


sub generateStoredWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my @steplist=@_;

   my $d=<<EOF;
<tr>
<td class=fname width=30%>%affectedapplication(label)%:</td>
<td class=finput>%affectedapplication(storedworkspace)%</td>
</tr>
EOF
   my $appid=Query->Param("Formated_affectedapplicationid");
   if ($appid ne ""){
      my $t1=$self->T("current Riskcoordinator");
      my @rskmgr=$self->getParent->getResponsibleRiskRole({
         affectedapplicationid=>\$appid
      });
      if ($#rskmgr!=-1){
         my $user=getModuleObject($self->getParent->Config,"base::user");
         $user->SetFilter({userid=>\$rskmgr[0]});
         my ($urec)=$user->getOnlyFirst(qw(fullname));
         if (defined($urec)){
            $d.=<<EOF;
<tr>
<td class=fname width=30%>$t1:</td>
<td class=finput>$urec->{fullname}</td>
</tr>
EOF
         }
      }
   }
 

   return($self->SUPER::generateStoredWorkspace($WfRec,@steplist).$d);
}


sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my @steplist=Query->Param("WorkflowStep");
   pop(@steplist);
   my $StoredWorkspace=$self->generateStoredWorkspace($WfRec,@steplist);


   my $nextstart=$self->getParent->getParent->T("NEXTSTART","base::workflow");
   my $secial=$self->getParent->getSpecificDataloadForm();
   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
$StoredWorkspace
<tr>
<td class=fname colspan=4>%extdescriskimpact(label)%:</td>
</tr><tr>
<td colspan=4 class=finput>%extdescriskimpact(detail)%</td>
</tr>
EOF
   foreach my $fldname ($self->getParent->getMandatoryParamFields()){
      $templ.="<tr><td class=fname valign=top width=20%>";
      $templ.="%${fldname}(label)%:</td>";
      $templ.="<td colspan=3 class=finput>%${fldname}(detail)%</td>";
      $templ.="</tr>\n";
   }
   $templ.=<<EOF;
<script language="JavaScript">
//setFocus("Formated_name");
setEnterSubmit(document.forms[0],"NextStep");
</script>
<tr>
<td colspan=4 align=center><br>$nextstart</td>
</tr>
</table>
EOF
   $templ.=$self->getParent->getParent->HtmlPersistentVariables(qw( 
      Formated_affectedapplication
      Formated_detaildescription
      Formated_name
      Formated_riskbasetype
   ));

   return($templ);
}

sub nativProcess
{
   my $self=shift;
   my $action=shift;
   my $h=shift;
   my $WfRec=shift;
   my $actions=shift;


   if ($action eq "NextStep"){
      my @rskmgr;
      my $flt;
      if ($h->{affectedapplication} ne ""){
         $flt={name=>\$h->{affectedapplication}}; 
      }
      if ($h->{affectedapplicationid} ne ""){
         $flt={id=>\$h->{affectedapplicationid}}; 
      }
      if (!defined($h->{stateid}) || $h->{stateid}==0){
         $h->{stateid}=1; # erfassen
      }
      foreach my $fld ($self->getParent->getMandatoryParamFields(),
                       "extdescriskimpact"){
         if ($h->{$fld} eq ""){
            my $t=$self->getParent->T("missing value for");
            $self->LastMsg(ERROR,$t.": ".
                    $self->getParent->getField($fld)->Label());
            return(0);
         }
      }
      $h->{step}=$self->getNextStep();
      if (defined($flt)){
         my $appl=getModuleObject($self->getParent->Config,"itil::appl");
         $appl->SetFilter($flt);
         my ($arec)=$appl->getOnlyFirst(qw(mandator mandatorid conumber
                                           custcontracts 
                                           databoss databossid
                                           applmgr applmgrid
                                           customer customerid));
         if (defined($arec)){
            if ($arec->{applmgrid} eq "" || $arec->{applmgr} eq ""){
               $self->LastMsg(ERROR,"no responsible applicationmanager");
               return(0);
            }
            if ($arec->{mandator} eq "" || $arec->{mandatorid} eq ""){
               $self->LastMsg(ERROR,"can not find mandator");
               return(0);
            }
            @rskmgr=$self->getParent->getResponsibleRiskRole(
               {affectedapplicationid=>$arec->{id}},
               $arec
            );
            if ($#rskmgr==-1){
               $self->LastMsg(ERROR,"no riskcoordinator for application");
               return(0);
            }
            $h->{fwdtarget}='base::user';
            $h->{fwdtargetid}=$arec->{applmgrid};

            $h->{mandatorid}=[$arec->{mandatorid}];
            $h->{mandator}=[$arec->{mandator}];
            $h->{involvedcustomer}=[$arec->{customer}];
            $h->{involvedcostcenter}=[$arec->{conumber}];
            if (!$self->getParent->checkAllowCreateWorkflow($h,$arec)){
               return(0);
            }
            if (ref($arec->{custcontracts}) eq "ARRAY"){
               my %custcontractid;
               my %custcontract;
               foreach my $rec (@{$arec->{custcontracts}}){
                  if (defined($rec->{custcontractid})){
                     $custcontractid{$rec->{custcontractid}}=1;
                  }
                  if (defined($rec->{custcontract})){
                     $custcontract{$rec->{custcontract}}=1;
                  }
               }
               if (keys(%custcontractid)){
                  $h->{affectedcontractid}=[keys(%custcontractid)];
               }
               if (keys(%custcontract)){
                  $h->{affectedcontract}=[keys(%custcontract)];
               }
            }

         }
         else{
            $self->LastMsg(ERROR,"can not find a related mandator");
            return(0);
         }
      }
      else{
         $self->LastMsg(ERROR,"no applicationid findable");
         return(0);
      }
      if (my $id=$self->StoreRecord($WfRec,$h)){
         my $aobj=$self->getParent->getParent->Action();
         $aobj->NotifyForward($id,
                              "base::user",
                              $rskmgr[0],
                              "RiskCoordinator",
                              "",
                              mode=>'newRisk:',
                              workflowname=>$WfRec->{name});
         Query->Delete("Formated_detaildescription");
         Query->Delete("Formated_name");
         $self->PostProcess($action,$h,$actions);
      }
      else{
         return(0);
      }
   }

   return($self->SUPER::nativProcess($action,$h,$WfRec,$actions));
}




sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      my $fo=$self->getField("affectedapplication");
      my $foval=Query->Param("Formated_".$fo->Name());
      if ($foval=~m/^\s*$/){
         $self->LastMsg(ERROR,"no application specified");
         return(0);
      }
      if (!$fo->Validate($WfRec,{$fo->Name=>$foval})){
         $self->LastMsg(ERROR,"unknown error") if (!$self->LastMsg());
         return(0);
      }
      if ((my $applid=Query->Param("Formated_affectedapplicationid")) ne ""){
         my $appl=getModuleObject($self->Config,"itil::appl");
         $appl->SetFilter({id=>\$applid});
         my ($arec,$msg)=$appl->getOnlyFirst(qw(mandator mandatorid));
         if (defined($arec)){
            Query->Param("Formated_mandator"=>$arec->{mandator});
            Query->Param("Formated_mandatorid"=>$arec->{mandatorid});
         }
      }
      my $h=$self->getWriteRequestHash("web");
      return($self->nativProcess($action,$h,$WfRec,$actions));
   }
   return($self->SUPER::Process($action,$WfRec,$actions));
}


sub Validate
{
   my $self=shift;
   my $oldrec=$_[0];
   my $newrec=$_[1];
   my $found=0;


   my $aid=effVal($oldrec,$newrec,"affectedapplicationid");
   if ($aid ne ""){
      $aid=[$aid] if (ref($aid) ne "ARRAY");
      my $co=getModuleObject($self->getParent->Config,"itil::costcenter");
      my $app=getModuleObject($self->getParent->Config,"itil::appl");

      $app->SetFilter({id=>$aid});
      my @l=$app->getHashList(qw(custcontracts mandator 
                                 conumber mandatorid));


      my %custcontract;
      my %custcontractid;
      my %mandator;
      my %mandatorid;
      my %conumber;
      foreach my $apprec (@l){
         if (defined($apprec->{mandator})){
            $mandator{$apprec->{mandator}}=1;
         }
         if (defined($apprec->{mandatorid})){
            $mandatorid{$apprec->{mandatorid}}=1;
         }
         if (defined($apprec->{conumber}) && $apprec->{conumber} ne ""){
            $co->ResetFilter();
            $co->SetFilter({name=>\$apprec->{conumber},cistatusid=>"<=4"});
            my ($corec)=$co->getOnlyFirst("id");
            if (!defined($corec)){
               $self->LastMsg(ERROR,"invalid or inactive costcenter ".
                                    "used in application configuration");
               return(0);
            }
            $conumber{$apprec->{conumber}}=1;
         }
         next if (!defined($apprec->{custcontracts}));
         foreach my $rec (@{$apprec->{custcontracts}}){
            if (defined($rec->{custcontractid})){
               $custcontractid{$rec->{custcontractid}}=1;
            }
            if (defined($rec->{custcontract})){
               $custcontract{$rec->{custcontract}}=1;
            }
         }
      }
      if (keys(%custcontractid)){
         $newrec->{affectedcontractid}=[keys(%custcontractid)];
      }
      if (keys(%custcontract)){
         $newrec->{affectedcontract}=[keys(%custcontract)];
      }
      if (keys(%mandator)){
         $newrec->{mandator}=[keys(%mandator)];
      }
      if (keys(%mandatorid)){
         $newrec->{mandatorid}=[keys(%mandatorid)];
      }
      if (keys(%conumber)){
         $found++;
         $newrec->{involvedcostcenter}=[keys(%conumber)];
      }
   }
   if ($found!=1){
      $self->LastMsg(ERROR,"no valid application found in request");
      return(0);
   }
   else{
      return(1);
   }
   
   return(0);

}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   return("340");
}


#######################################################################
package itil::workflow::riskmgmt::main;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   return(1);
}


sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $op=Query->Param("OP");


   if ($action eq "BreakWorkflow"){
      my $h=$self->getWriteRequestHash("web");
      return($self->nativProcess("wfbreak",$h,$WfRec,$actions));
   }


   if ($action eq "SaveStep"){
      if ($action ne "" && !grep(/^$op$/,@{$actions})){
         $self->LastMsg(ERROR,"invalid disalloed action requested");
         return(0);
      }
      elsif ($op eq "wfaddopmeasure"){
         my $h=$self->getWriteRequestHash("web");
         $h->{plannedstart}=Query->Param("Formated_plannedstart");
         $h->{plannedend}=Query->Param("Formated_plannedend");
         my $bk=$self->nativProcess($op,$h,$WfRec,$actions);
         if ($bk){
            Query->Delete("Formated_plannedstart");
            Query->Delete("Formated_plannedend");
            Query->Delete("Formated_detaildescription");
            Query->Delete("Formated_name");
            return($bk);
         }
         return(!$bk);
      }
      elsif ($op eq "wffine"){
         my $h=$self->getWriteRequestHash("web");
         return($self->nativProcess("wffine",$h,$WfRec,$actions));
      }
      elsif ($op eq "wfbreak"){
         my $h=$self->getWriteRequestHash("web");
         return($self->nativProcess("wfbreak",$h,$WfRec,$actions));
      }
      elsif ($op eq "wfclose"){
         my $note=Query->Param("note");
         my $effort=Query->Param("Formated_effort");
         my $h={};
         $h->{note}=$note                     if ($note ne "");
         $h->{effort}=$effort                 if ($effort ne "");
         return($self->nativProcess($op,$h,$WfRec,$actions));
      }

   }
   return($self->SUPER::Process($action,$WfRec,$actions));
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my @WorkflowStep=Query->Param("WorkflowStep");
   my %b=();
   my @saveables=grep(!/^wfbreak$/,@$actions);
   if ($#saveables!=-1){
      %b=(SaveStep=>$self->T('Save','kernel::WfStep')) if ($#{$actions}!=-1);
   }
   if (defined($WfRec->{id})){
      if (grep(/^wfbreak$/,@$actions)){
         $b{BreakWorkflow}=$self->T('cancel risk workflow',
                                    'itil::workflow::riskmgmt');
      }
   }
   #print STDERR "Buttons:".Dumper(\%b);
   return(%b);
}



sub nativProcess
{
   my $self=shift;
   my $op=shift;
   my $h=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $userid=$self->getParent->getParent->getCurrentUserId();

   if ($op ne "" && !grep(/^$op$/,@{$actions})){
      $self->LastMsg(ERROR,"invalid disalloed action requested");
      msg(ERROR,"invalid requested operation was '$op'");
      return(0);
   }


   if ($op eq "wfbreak"){
      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"wfbreak",
          {translation=>'base::workflow::request'},"",undef)){
         my $openuserid=$WfRec->{openuser};
         my $step=$self->getParent->getStepByShortname("break");
         $self->StoreRecord($WfRec,{stateid=>22,
                                    step=>$step,
                                    eventend=>NowStamp("en"),
                                    closedate=>NowStamp("en"),
                                    fwddebtargetid=>undef,
                                    fwddebtarget=>undef,
                                    fwdtargetid=>undef,
                                    fwdtarget=>undef,
                                   });
         if ($openuserid!=$userid){
            $self->PostProcess($op,$WfRec,$actions,
                               "breaked by $ENV{REMOTE_USER}",
                               fwdtarget=>'base::user',
                               fwdtargetid=>$openuserid,
                               fwdtargetname=>"Requestor");
         }
         return(1);
      }
      return(0);
   }
   elsif($op eq "wfaddopmeasure"){
      print STDERR Dumper($h);
      my $newrec={
         affectedapplicationid=>$WfRec->{affectedapplicationid},
         affectedapplication=>$WfRec->{affectedapplication},
         subtyp=>'riskmeasure',
         mandator=>$WfRec->{mandator},
         mandatorid=>$WfRec->{mandatorid},
         name=>$h->{name},
         stateid=>'2',
         fwdtargetname=>$h->{fwdtargetname},
         detaildescription=>$h->{detaildescription},
         class=>'itil::workflow::opmeasure',
         step =>'base::workflow::request::main'
      };
      if ($h->{plannedstart} eq "" || $h->{plannedend} eq ""){
         $self->LastMsg(ERROR,"planned start or end missing");
         return(0);
      }
      my $tstamp=$self->ExpandTimeExpression($h->{plannedstart},"en",
                               $self->UserTimezone(),"GMT");
      return(0) if (!defined($tstamp));
      $newrec->{plannedstart}=$tstamp;

      my $tstamp=$self->ExpandTimeExpression($h->{plannedend},"en",
                               $self->UserTimezone(),"GMT");
      return(0) if (!defined($tstamp));
      $newrec->{plannedend}=$tstamp;
      print STDERR Dumper($newrec);



      my $id=$self->getParent->getParent->Store(undef,$newrec);
      my $myid=$WfRec->{id};
      if (defined($id)){
         my $wr=getModuleObject($self->getParent->getParent->Config,
                                "base::workflowrelation");
         $wr->ValidatedInsertRecord({
            name=>"riskmesure",
            translation=>"itil::workflow::riskmgmt",
            srcwfid=>$myid,
            dstwfid=>$id,
         });
         Query->Delete("OP");
         Query->Delete("Formated_fwdtargetname");
         return(1);
      }
      return(0);
   }
   elsif($op eq "wfclose"){
      # hier muss noch der Risko-Coordinator berechnet werden!
      my @mem=$self->getParent->getMembersOf($WfRec->{mandatorid},
                                             ['RSKCoord'],'firstup');
      if ($#mem==-1){
         @mem=$self->getParent->getMembersOf($WfRec->{mandatorid},
                                             [qw(RSKManager
                                                 RSKPManager 
                                                 RSKPManager2)],'firstup');
      }
      if ($#mem==-1){
         $self->LastMsg(ERROR,"missing RSKCoord or RSKManager");
         return(0);
      }
      my $riskchef=$mem[0];


      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"wfclosed",
          {translation=>'itil::workflow::riskmgmt'},$h->{note},$h->{effort})){
         my $store={stateid=>17,
                    fwdtargetid=>$riskchef,
                    fwdtarget=>'base::user',
                    eventend=>NowStamp("en"),
                    fwddebtarget=>undef,
                    fwddebtargetid=>undef};
         if ($WfRec->{eventend} eq ""){
            $store->{eventend}=NowStamp("en");
         }
         $self->StoreRecord($WfRec,$store);
         $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
         $self->PostProcess("SaveStep".".".$op,$WfRec,$actions,
                            note=>$h->{note},
                            fwdtarget=>$store->{fwdtarget},
                            fwdtargetid=>$store->{fwdtargetid},
                            fwdtargetname=>'RiskCoordinator');
         return(1);
      }
   }
   elsif($op eq "wffine"){
      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"wffine",
          {translation=>'base::workflow::request'},"",undef)){
         my $nextstep=$self->getParent->getStepByShortname("finish");
         my $store={stateid=>21,
                    step=>$nextstep,
                    fwdtargetid=>undef,
                    fwdtarget=>undef,
                    closedate=>NowStamp("en"),
                    fwddebtarget=>undef,
                    fwddebtargetid=>undef};
         foreach my $v (qw(ibiprice 
                           ibipoints 
                           solutionopt 
                           itrmcriticality)){  # store base parameters
            my $curval=$WfRec->{$v};
            $store->{"stored_".$v}=$curval;
         }
         if ($WfRec->{eventend} eq ""){
            $store->{eventend}=NowStamp("en");
         }
         $self->StoreRecord($WfRec,$store);
         $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
         $self->PostProcess("SaveStep.".$op,$WfRec,$actions);
         return(1);
      }
   }
   return($self->SUPER::nativProcess($op,$h,$WfRec,$actions));
}


sub PostProcess
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;
   my %param=@_;
   my $aobj=$self->getParent->getParent->Action();
   my $workflowname=$self->getParent->getWorkflowMailName();


   if ($action eq "SaveStep.wfclose"){
      if ($param{fwdtargetid} ne ""){
         $aobj->NotifyForward($WfRec->{id},
                              $param{fwdtarget},
                              $param{fwdtargetid},
                              $param{fwdtargetname},
                              $param{note},
                              mode=>'closeRisk:',
                              workflowname=>$workflowname);
      }
   }

   return($self->SUPER::PostProcess($action,$WfRec,$actions,%param));
}






sub generateWorkspacePages
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $divset=shift;
   my $selopt=shift;
   my $height=shift;
   my $tr="itil::workflow::riskmgmt";
   my $class="display:none;visibility:hidden";

   if (grep(/^wfaddopmeasure$/,@$actions)){
      $$selopt.="<option value=\"wfaddopmeasure\">".
                $self->getParent->T("wfaddopmeasure",$tr).
                "</option>\n";
      my $desc=Query->Param("Formated_name");
      my $note=Query->Param("Formated_detaildescription");
      my $pstart=Query->Param("Formated_plannedstart");
      my $pend=Query->Param("Formated_plannedend");
      if (!defined($pstart)){
         $pstart=$self->getParent->T("today");
      }
      if (!defined($pend)){
         $pend=$self->getParent->T("today")."+30d";
      }

      my $plannedstart=$self->T("planned start");
      my $plannedend=$self->T("planned end");

      my $t1=$self->getParent->T("Please describe here the measure ".
         "leading to the elimination/reduction of the risk");
      my $t2=$self->getParent->T("short description measure");

      my $d="<table width=\"100%\" border=0 style='margin-top:6px' ".
          "cellspacing=0 cellpadding=0><tr>".
          "<td nowrap width=1%>${t2}:</td>".
          "<td><input type=text name=Formated_name value='".quoteHtml($desc).
          "' style=\"width:100%\"></td></tr></table>";
      $d.="<table width=\"100%\" border=0 cellspacing=0 cellpadding=0><tr>".
          "<td nowrap width=1%>${plannedstart}: </td>".
          "<td width=20%><input type=text name=Formated_plannedstart ".
          "value='".quoteHtml($pstart).
          "' style=\"width:100%\"></td>".
          "<td nowrap width=1%> &nbsp; ${plannedend}: </td>".
          "<td width=20%><input type=text name=Formated_plannedend ".
          "value='".quoteHtml($pend).
          "' style=\"width:100%\"></td>".
          "</tr></table>";
      $d.="<table width=\"100%\" border=0 style='margin-top:8px' ".
          "cellspacing=0 cellpadding=0><tr>".
          "<td colspan=2>${t1}:<br>".
          "<textarea name=Formated_detaildescription ".
          "style=\"width:100%;resize:none;height:90px\">".
          quoteHtml($note)."</textarea></td></tr>";
      $d.="<tr><td width=1% nowrap>".
          $self->getParent->T("assign to","itil::workflow::riskmgmt").
          ":&nbsp;</td>".
          "<td>\%fwdtargetname(detail)\%".
          "</td></tr>";
      $d.="</table>";
      $$divset.="<div id=OPwfaddopmeasure class=\"$class\">$d</div>";
   }
   if (grep(/^wfclose$/,@$actions)){
      $$selopt.="<option value=\"wfclose\">".
                $self->getParent->T("wfclose",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfclose class=\"$class\">".
                $self->getDefaultNoteDiv($WfRec,$actions).
                "</div>";
   }
   if (grep(/^wffine$/,@$actions)){
      $$selopt.="<option value=\"wffine\">".
                $self->getParent->T("wffine",$tr).
                "</option>\n";
      $$divset.="<div id=OPwffine style=\"$class;margin:15px\"><br>".
                $self->getParent->T("use this action,".
                " to finish this request and mark it as according to ".
                "desire processed")."</div>";
   }
   $self->SUPER::generateWorkspacePages($WfRec,$actions,$divset,$selopt);
   if (grep(/^wfaddopmeasure$/,@$actions)){
      if (!defined($WfRec->{relations}) || $#{$WfRec->{relations}}==-1){
         return("wfaddopmeasure");
      }
   }
   return("wfaddnote");
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   return(0) if (ref($actions) eq "ARRAY" && $#{$actions}==-1);

   return(250);
}






#######################################################################
package itil::workflow::riskmgmt::finish;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub Validate                # make step storeable
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   return(1);
}


sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   return();
   return() if (!$self->getParent->getParent->IsMemberOf("admin"));;
   my %p=$self->SUPER::getPosibleButtons($WfRec);
   delete($p{BreakWorkflow});
   return(%p);
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

#   return("60") if ($self->getParent->getParent->IsMemberOf("admin"));
   return(0);
}


#######################################################################
package itil::workflow::riskmgmt::break;
use vars qw(@ISA);
use kernel;
@ISA=qw(base::workflow::request::finish);





1;
