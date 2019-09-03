package secscan::workflow::FindingHndl;
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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

@ISA=qw(kernel::WfClass);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->{history}=[qw(insert modify delete)];
   $self->{tester}=[qw(11634961950007 11634966030005 11817228080001 
                       12260596620002 13643853890000 13790292430004)];
   return($self);
}


sub PostponeMaxDays   # postpone max days after WfStart
{
   my $self=shift;
   my $WfRec=shift;

   return(365*3);
}



sub IsModuleSelectable
{
   my $self=shift;
   my $acl;

   $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
                          "base::workflow",
                          func=>'New',
                          param=>'WorkflowClass=secscan::workflow::FindingHndl');
   if (defined($acl)){
      return(1) if (grep(/^read$/,@$acl));
   }
   return(0);
}


sub checkAllowCreateWorkflow
{
   my $self=shift;
   my $h=shift;
   my $arec=shift;

   return(1);
}



sub IsModuleSelectable
{
   my $self=shift;
   return(1) if ($self->IsMemberOf("admin"));
   return(0);
}


sub Init
{
   my $self=shift;
   my $parent=$self->getParent();

#   $parent->AddFields(
#      new kernel::Field::KeyText(
#                name          =>'xxo21',
#                htmldetail =>0,
#                container     =>'headref',
#                keyhandler    =>'kh',
#                label         =>'BusinessprocessID'),
#
#   );
   $self->AddGroup("secinternal",translation=>'secscan::workflow::FindingHndl');
   #$self->AddGroup("affected",translation=>'itil::workflow::base');

   return(1);
}





sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;

   my @l=($self->InitFields(
      new kernel::Field::Select(  name          =>'secfindingitem',
                                  label         =>'Security Finding Item',
                                  vjointo       =>'secscan::item',
                                  htmldetail    =>0,
                                  vjoinon      =>['secfindingitemname'=>'name'],
                                  vjoineditbase =>{cistatusid=>'4'},
                                  vjoindisp     =>'name'),

      new kernel::Field::Link(    name          =>'secfindingitemname',
                                  label         =>'Security Finding Item Name',
                                  container     =>'headref'),

      new kernel::Field::Textarea(name          =>'secfindingitemrawdesc',
                                  label         =>'Security Finding Item Desc',
                                  readonly      =>1,
                                  htmldetail    =>0,
                                  uivisible     =>sub{
                                     my $self=shift;
                                     my $app=$self->getParent;
                                     my $mode=shift;
                                     my %param=@_;
                                     return(0) if (ref($param{current}) ne
                                                   "HASH");
                                     return($app->isAuthorized("view",
                                            $param{current}));
                                  },
                                  vjointo       =>'secscan::item',
                                  vjoinon      =>['secfindingitemname'=>'name'],
                                  vjoindisp     =>'description'),

      new kernel::Field::Text(    name          =>'secfindingipaddrref',
                                  label         =>'IP-Address reference',
                                  uivisible     =>sub{
                                     my $self=shift;
                                     my $app=$self->getParent;
                                     my $mode=shift;
                                     my %param=@_;
                                     return(0) if (ref($param{current}) ne
                                                   "HASH");
                                     return($app->isAuthorized("view",
                                            $param{current}));
                                  },
                                  container     =>'headref'),

      new kernel::Field::Interface(name         =>'secfindingreponsibleid',
                                  label         =>'responsible id',
                                  container     =>'headref'),

      new kernel::Field::Interface(name         =>'secfindingaltreponsibleid',
                                  label         =>'alternate responsible id',
                                  container     =>'headref'),

      new kernel::Field::Contact( name          =>'secfindingreponsible',
                                  label         =>'responsible person',
                                  vjoinon       =>'secfindingreponsibleid'),

      new kernel::Field::Select(  name          =>'secfindingtreattarget',
                                  label         =>'treating target in days',
                                  group         =>'secinternal',
                                  value         =>['7',
                                                   '14',
                                                   '28',
                                                   '90',
                                                  ],
                                  htmleditwidth =>'60px',
                                  default       =>'28',
                                  container     =>'headref'),

      new kernel::Field::Boolean( name          =>'secfindingaskdsgvo',
                                  group         =>'secinternal',
                                  label         =>'ask DSGVO compromised',
                                  container     =>'headref'),

      new kernel::Field::Boolean( name          =>'secfindingenforceremove',
                                  group         =>'secinternal',
                                  label         =>'request enforce remove',
                                  container     =>'headref'),

      new kernel::Field::Boolean( name          =>'secfindingaskstatement',
                                  group         =>'secinternal',
                                  label         =>'ask statement',
                                  container     =>'headref'),

      new kernel::Field::Textarea(name          =>'secfindinggendebug',
                                  group         =>'secinternal',
                                  label         =>'generation debug log',
                                  container     =>'headref'),

      new kernel::Field::Textarea(name          =>'secfindingdesc',
                                  label         =>'Description of finding',
                                  uivisible     =>sub{
                                     my $self=shift;
                                     my $app=$self->getParent;
                                     my $mode=shift;
                                     my %param=@_;
                                     return(0) if (ref($param{current}) ne
                                                   "HASH");
                                     return($app->isAuthorized("view",
                                            $param{current}));
                                  },
                                  depend        =>[qw(secfindingitemname
                                                      secfindingitemrawdesc
                                                      detaildescription)],
                                  onRawValue    =>sub{
                                     my $self   =shift;
                                     my $current=shift;
                                     my $i=$self->getParent->getField(
                                           "secfindingitemrawdesc");
                                     my $dsc=$i->RawValue($current);
                                     my $lang=$self->getParent->Lang();
                                     $dsc=extractLangEntry($dsc,
                                                           $lang,65535,65535); 
                                     my $d=$self->getParent->getField(
                                           "detaildescription");
                                     my $detaildescription=
                                           $d->RawValue($current);
                                     return($dsc.
                                            "\n".
                                            $detaildescription);
                                  }),

      new kernel::Field::Textarea(name          =>'secfindingdsgvostatement',
                                  label         =>'DSGVO Statement',
                                  readonly      =>1,
                                  uivisible     =>sub{
                                     my $self=shift;
                                     my $app=$self->getParent;
                                     my $mode=shift;
                                     my %param=@_;
                                     return(0) if (ref($param{current}) ne
                                                   "HASH");
                                     return($app->isAuthorized("view",
                                            $param{current}));
                                  },
                                  htmldetail    =>'NotEmpty',
                                  container     =>'headref'),

      new kernel::Field::Textarea(name          =>'secfindingreasontatement',
                                  label         =>'Reasons for finding',
                                  readonly      =>1,
                                  uivisible     =>sub{
                                     my $self=shift;
                                     my $app=$self->getParent;
                                     my $mode=shift;
                                     my %param=@_;
                                     return(0) if (ref($param{current}) ne
                                                   "HASH");
                                     return($app->isAuthorized("view",
                                            $param{current}));
                                  },
                                  htmldetail    =>'NotEmpty',
                                  container     =>'headref'),

      new kernel::Field::Textarea(name          =>'secfindingnonremstatement',
                                  label         =>'Reasons for non-removal',
                                  readonly      =>1,
                                  uivisible     =>sub{
                                     my $self=shift;
                                     my $app=$self->getParent;
                                     my $mode=shift;
                                     my %param=@_;
                                     return(0) if (ref($param{current}) ne
                                                   "HASH");
                                     return($app->isAuthorized("view",
                                            $param{current}));
                                  },
                                  htmldetail    =>'NotEmpty',
                                  container     =>'headref'),

      new kernel::Field::Select(  name          =>'secfindingstate',
                                  label         =>'state of Secuirty Finding',
                                  group         =>'state',
                                  readonly      =>1,
                                  default       =>'INANALYSE',
                                  value         =>['INANALYSE',
                                                   'CLOSEDRESOLVED',
                                                   'CLOSEDCNTEXIST'
                                                  ],
                                  container     =>'headref'),

   ),$self->SUPER::getDynamicFields(%param));
   $self->getField("affectedapplication")->{htmldetail}=0;
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






sub checkextdescdesstart
{
   my $self=shift;
   my $current=shift;
   my %FOpt=@_;


   return("<img border=1 src=\"../../base/load/attention.gif\">");

}


sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   return("secscan::workflow::FindingHndl::".$shortname);
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
#      if (!$self->isRiskWfAuthorized("view",$current)){
#         if (length($d)>3){
#            $d=substr($d,0,3)."...";
#         }
#      }
   }

   return($d);
}




sub isOptionalFieldVisible
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   my $name=$param{field}->Name();

   return(0) if ($name eq "relations");
   return(0) if ($name eq "prio");
   return(1) if ($name eq "name");
   return(1) if ($name eq "shortactionlog");
   return(0);
}


sub  recalcResponsiblegrp
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $secfindingreponsibleid=effVal($oldrec,$newrec,"secfindingreponsibleid");
   if ($secfindingreponsibleid ne ""){
      my $user=getModuleObject($self->getParent->Config,"base::user");
      $user->SetFilter({userid=>\$secfindingreponsibleid});
      my ($usrrec)=$user->getOnlyFirst(qw(groups usertyp));
      if (defined($usrrec) && ref($usrrec->{groups}) eq "ARRAY"){
         my %grp;
         my %grpid;
         my @chkroles=orgRoles();
         if ($usrrec->{usertyp} eq "service"){
            push(@chkroles,"RMember"); # for Service-Users stats goes to RMember
         }
         foreach my $grec (@{$usrrec->{groups}}){
            if (ref($grec->{roles}) eq "ARRAY"){
               if (in_array($grec->{roles},\@chkroles)){
                  $grp{$grec->{group}}++;
                  $grpid{$grec->{grpid}}++;
               }
            }
         }
         if (keys(%grp)){
            $newrec->{responsiblegrp}=[keys(%grp)];
            $newrec->{responsiblegrpid}=[keys(%grpid)];
         }
      }
   }
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

   if (!$iscurrent){
      if ($self->isCurrentWorkspace($WfRec)){
         $iscurrent=1;
      }
   }
   if (!$iscurrent){
      if ($isadmin){
         $iscurrent=1;
      }
   }


   my @l=$self->SUPER::getPosibleActions($WfRec);
   if ($WfRec->{stateid} > 1 && $WfRec->{stateid} <17){
      if ( (!($WfRec->{secfindingaskdsgvo}) || 
           ($WfRec->{secfindingdsgvostatement} ne ""))  &&
           (!($WfRec->{secfindingaskstatement}) ||
           ($WfRec->{secfindingreasontatement} ne ""))){
         if (($iscurrent)){
            push(@l,"wfclose");   # als beseitigt abschließen
         }
      }
   }
   if ($WfRec->{stateid} > 1 && $WfRec->{stateid} <17){
      if ($WfRec->{step} eq "secscan::workflow::FindingHndl::main"){
         if ($WfRec->{secfindingaskdsgvo}){
            if (($iscurrent)){
               push(@l,"wfaskdsgvo");
            }
         }
      }
   }
   if ($WfRec->{stateid} > 1 && $WfRec->{stateid} <17){
      if ($WfRec->{step} eq "secscan::workflow::FindingHndl::main"){
         if ($WfRec->{secfindingaskstatement}){
            if (($iscurrent)){
               push(@l,"wfaskreason");
            }
         }
      }
   }
   if ($WfRec->{stateid} > 1 && $WfRec->{stateid} <17){
      if (!($WfRec->{secfindingenforceremove})){
         if ( (!($WfRec->{secfindingaskdsgvo}) || 
              ($WfRec->{secfindingdsgvostatement} ne ""))  &&
              (!($WfRec->{secfindingaskstatement}) ||
              ($WfRec->{secfindingreasontatement} ne ""))){
            if (($iscurrent)){ # als NICHT beseitigt abschließen
               push(@l,"wfsecsetwrkasdes");   
            }
         }
      }
   }
   if ($W5V2::OperationContext eq "W5Server"){
      if ($WfRec->{step} ne "secscan::workflow::FindingHndl::finish"){
         push(@l,"wfforceobsolete");
      }
      if ($WfRec->{stateid}>15){
         push(@l,"wfreactivate");
      }
   }
   if ($WfRec->{stateid} > 1 && $WfRec->{stateid} <17){
      if ($WfRec->{step} eq "secscan::workflow::FindingHndl::main"){
         if (($iscurrent)){
            push(@l,"wfrejectresp");   # Verantwortung ablehnen
         }
      }
   }

   if ($WfRec->{step} eq "secscan::workflow::FindingHndl::approve"){
      if ($WfRec->{stateid} > 1 && $WfRec->{stateid} <17){
         if (($iscurrent)){
            push(@l,"wfsetnewresp");   # neuen Verantwortlichen setzen
         }
      }
   }
   if ($iscurrent){
      push(@l,"iscurrent");
   }
   return(@l);
}


sub isAuthorized
{
   my $self=shift;
   my $mode=shift;
   my $rec=shift;

   if ($mode eq "modify" || $mode eq "view"){
      my $userid=$self->getParent->getCurrentUserId();
      if ($rec->{fwdtarget} eq "base::user" &&
          $rec->{fwdtargetid} eq $userid){
         return(1);
      }
      if ($rec->{secfindingreponsibleid} eq $userid){
         return(1);
      }
      if ($self->isCurrentWorkspace($rec)){
         return(1);
      }
      if ($self->IsMemberOf("admin")){
         return(1);
      }
   }
   return(0);
}


sub camuflageOptionalField
{
   my $self=shift;
   my $fld=shift;
   my $d=shift;
   my $current=shift;
   if ($fld->Name() eq "name"){
      if (!$self->isAuthorized("view",$current)){
         if (length($d)>15){
            $d=substr($d,0,15)."...";
         }
      }
   }

   return($d);
}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   my @l=("default");

   if ($self->isAuthorized("view",$rec)){
      push(@l,"relations","state",
              "history","flow","affected","source");
   }
   #if ($self->IsMemberOf("admin")){
   #   push(@l,"secinternal");
   #}
   return(@l);
}



sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my @l=$self->SUPER::isWriteValid(@_);
#   push(@l,"extdesc") if (!defined($_[0]));
#
#   if ($rec->{stateid} <16){
#      if ($self->isRiskWfAuthorized("modify",$rec)){
#         push(@l,"riskdesc");
#      }
#   }
   return(@l);
}

sub getDetailBlockPriority            # posibility to change the block order
{
   return("header","default","flow","state","source","relations","secinternal");
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/secscan/load/workflow_FindingHndl.jpg?".
          $cgi->query_string());
}

sub getPosibleRelations
{
   my $self=shift;
   my $WfRec=shift;
   return("secscan::workflow::FindingHndl"=>'relchange'); 
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
                  "name=\"secfindingipaddrref\" type=\"xsd:string\" />";
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



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}



sub NotifySecurityFindingForward
{
   my $self=shift;
   my $WfRec=shift;
   my $note=shift;
   my $id=$WfRec->{id};
   my $aobj=$self->getParent->Action();
   my $workflowname=$self->getWorkflowMailName();

   my $wf=$self->getParent->Clone();
   $wf->ResetFilter();
   $wf->SetFilter({id=>\$WfRec->{id}});
   my ($WfRec,$msg)=$wf->getOnlyFirst(qw(id 
                                      fwdtarget fwdtargetid fwdtargetname)); 


   my $lastlang=$ENV{HTTP_FORCE_LANGUAGE};
   my $uobj=getModuleObject($self->Config,'base::user');
   $uobj->SetFilter({userid=>\$WfRec->{fwdtargetid},cistatusid=>4});
   my ($u,$msg)=$uobj->getOnlyFirst(qw(lastlang lang));

   if (defined($u->{lastlang}) && $u->{lastlang} ne "") {
      $ENV{HTTP_FORCE_LANGUAGE}=$u->{lastlang};
   }
   else{
      if (defined($u->{lang}) && $u->{lang} ne ""){
         $ENV{HTTP_FORCE_LANGUAGE}=$u->{lang};
      }
   }

   if ($note eq ""){
      $note=$self->T(
            "The automaticly decteded security-finding has been forwared ".
            "to you. Please handle the referenced workflow as fast es ".
            "posible to reduce the security risk for your application.");
   }
   my %cc;
   my $ws=$self->getParent->getPersistentModuleObject("base::workflowws");
   if (defined($ws)){
      $ws->SetFilter({wfheadid=>\$id,fwdtarget=>'base::user'});
      my @l=$ws->getHashList(qw(ALL));
      foreach my $wsrec (@l){
         $cc{$wsrec->{fwdtargetid}}++;
      }
   }


   $aobj->NotifyForward($id,
                        $WfRec->{fwdtarget},
                        $WfRec->{fwdtargetid},
                        $WfRec->{fwdtargetname},
                        $note,
                        emailfrom=>"\"T-Security\" <>",
                        workflowname=>$workflowname,
                        addcctarget=>[keys(%cc)]);

   if ($lastlang ne ""){
      $ENV{HTTP_FORCE_LANGUAGE}=$lastlang;
   }
   else{
      delete($ENV{HTTP_FORCE_LANGUAGE});
   }
}


sub nativProcess
{
   my $classobj=shift;
   my $self=shift;
   my $action=shift;
   my $h=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "wfforceobsolete"){
      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"wffine",
          {translation=>'base::workflow::request'},"",undef)){
         my $nextstep=$self->getParent->getStepByShortname("finish");
         my $store={stateid=>25,
                    step=>$nextstep,
                    fwdtargetid=>undef,
                    fwdtarget=>undef,
                    closedate=>NowStamp("en"),
                    fwddebtarget=>undef,
                    fwddebtargetid=>undef};
         if ($WfRec->{eventend} eq ""){
            $store->{eventend}=NowStamp("en");
         }
         $self->StoreRecord($WfRec,$store);
         $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
         return(1);
      }

      return(1);
   }
   if ($action eq "wfreactivate"){
      $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"wfreactivate",
          {translation=>'secscan::workflow::FindingHndl'},"",undef)){
         my $nextstep=$self->getParent->getStepByShortname("main");
         my $store={stateid=>2,
                    step=>$nextstep,
                    secfindingstate=>'INANALYSE',
                    closedate=>undef,
                    fwddebtarget=>undef,
                    fwddebtargetid=>undef};
         msg(WARN,"reactivate SecFinding $WfRec->{id}");
         if (!in_array($self->getParent->{tester},
                       $WfRec->{fwdtargetid})){
            $store->{fwdtargetid}=15632883160001;
            $store->{fwdtarget}="base::user";
         }
         $self->StoreRecord($WfRec,$store);
         return(1);
      }
      return(1);
   }
   return(0);
}







#######################################################################
package secscan::workflow::FindingHndl::dataload;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $nextstart=$self->getParent->getParent->T("NEXTSTART","base::workflow");
   my $secial=$self->getParent->getSpecificDataloadForm();
   my $t1=$self->getParent->T("IP-Address","secscan::workflow::FindingHndl");
   my $t2=$self->getParent->T("Security Item","secscan::workflow::FindingHndl");
   my $t3=$self->getParent->T("responsible person","secscan::workflow::FindingHndl");




   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr>
<td class=fname width=20%>%secfindingitem(label)%:</td>
<td colspan=3 class=finput>%secfindingitem(detail)%</td>
</tr>
<tr>
<td class=fname width=20%>%secfindingipaddrref(label)%:</td>
<td colspan=3 class=finput>%secfindingipaddrref(detail)%</td>
</tr>
<tr>
<td class=fname width=20%>%secfindingreponsible(label)%:</td>
<td colspan=3 class=finput>%secfindingreponsible(detail)%</td>
</tr>
<tr>
<td class=fname width=20%>%secfindingaskdsgvo(label)%:</td>
<td class=finput>%secfindingaskdsgvo(detail)%</td>
<td class=fname width=20%>%secfindingenforceremove(label)%:</td>
<td class=finput>%secfindingenforceremove(detail)%</td>
</tr>
<tr>
<td class=fname width=20%>%secfindingaskstatement(label)%:</td>
<td class=finput>%secfindingaskstatement(detail)%</td>
<td class=fname width=20%>%secfindingtreattarget(label)%:</td>
<td class=finput>%secfindingtreattarget(detail)%</td>
</tr>
<tr>
<td class=fname width=20%>%detaildescription(label)%:</td>
<td colspan=3 class=finput>%detaildescription(detail)%</td>
</tr>
</table>
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
      my $fo=$self->getField("secfindingipaddrref");
      my $foval=Query->Param("Formated_".$fo->Name());
      if ($foval=~m/^\s*$/){
         $self->LastMsg(ERROR,"no ipaddr specified");
         return(0);
      }

      my $fo=$self->getField("secfindingreponsible");
      my $foval=Query->Param("Formated_".$fo->Name());
      if ($foval=~m/^\s*$/){
         $self->LastMsg(ERROR,"no responsible specified");
         return(0);
      }
      my $resphash;
      if (!($resphash=$fo->Validate($WfRec,{$fo->Name=>$foval}))){
         $self->LastMsg(ERROR,"unknown error") if (!$self->LastMsg());
         return(0);
      }

      if (Query->Param("Formated_secfindingitem") eq ""){
         $self->LastMsg(ERROR,"no item specified");
         return(0);
      }
      my $h=$self->getWriteRequestHash("web");
      $h->{secfindingreponsibleid}=$resphash->{secfindingreponsibleid};
      return($self->nativProcess($action,$h,$WfRec,$actions));
   }
   return($self->SUPER::Process($action,$WfRec,$actions));
}



sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   return("260");
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
      $h->{step}=$self->getNextStep();
      $h->{name}="SecurityFinding @ ".$h->{secfindingipaddrref};
      $h->{stateid}=2;

      if ($h->{secfindingreponsibleid} ne ""){
      #   my @mandators=$self->getParent->getMandatorsOf(
      #                   $h->{secfindingreponsibleid},"direct");
         my @mandators;
         if ($#mandators!=-1){
            my $m=getModuleObject($self->Config,"base::mandator");
            $m->SetFilter({grpid=>$mandators[0]});
            my %mnames=();
            my %mid=();
            foreach my $mrec ($m->getHashList(qw(name grpid))){
               $mnames{$mrec->{name}}++;
               $mid{$mrec->{grpid}}++;
            }
            $h->{mandator}=[sort(keys(%mnames))];
            $h->{mandatorid}=[sort(keys(%mid))];
         }
      }


      $h->{fwdtargetid}=$h->{secfindingreponsibleid};
      $h->{fwdtarget}="base::user";

      if (!in_array($self->getParent->{tester},
                    $h->{fwdtargetid})){
         $h->{fwdtargetid}=15632883160001; # security_issue test contact
         $h->{fwdtarget}="base::user";
         delete($h->{secfindingaltreponsibleid});  # no tsms
      }

      $h->{secfindingstate}="INANALYSE";
      my $secfindingaltreponsibleid=$h->{secfindingaltreponsibleid};
      if (my $id=$self->StoreRecord($WfRec,$h)){
         my $aobj=$self->getParent->getParent->Action();

         if (defined($h->{secfindingaltreponsibleid})){
            my $wsref=$h->{secfindingaltreponsibleid};
            $wsref=[$wsref] if (ref($wsref) ne "ARRAY");
            foreach my $a (@{$wsref}){
               $self->getParent->getParent->AddToWorkspace($id,"base::user",$a);
            }
         }
         $self->getParent->NotifySecurityFindingForward({id=>$id});
         $self->PostProcess($action,$h,$actions);
         return($id);
      }
      else{
         return(0);
      }
   }
   if ($action eq "wfforceobsolete"){
      return($self->getParent->nativProcess($self,$action,$h,$WfRec,$actions));
   }

   return($self->SUPER::nativProcess($action,$h,$WfRec,$actions));
}




#######################################################################
package secscan::workflow::FindingHndl::main;
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
      elsif ($op eq "wfclose" || 
             $op eq "wfrejectresp" ||
             $op eq "wfaskdsgvo" ||
             $op eq "wfaskreason" ||
             $op eq "wfsecsetwrkasdes"){
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
                                    'secscan::workflow::FindingHndl');
      }
   }
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
   elsif($op eq "wfaskdsgvo"){
      my $store={
                 secfindingdsgvostatement=>$h->{note}
      };
      Query->Delete("note");
      Query->Delete("OP");
      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"wfadddsgvo",
          {translation=>'secscan::workflow::FindingHndl'})){
         $self->StoreRecord($WfRec,$store);
      }
      return(1);
   }
   elsif($op eq "wfaskreason"){
      my $store={
                 secfindingreasontatement=>$h->{note}
      };
      Query->Delete("note");
      Query->Delete("OP");
      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"wfaddreason",
          {translation=>'secscan::workflow::FindingHndl'})){
         $self->StoreRecord($WfRec,$store);
      }
      return(1);
   }
   elsif($op eq "wfclose"){
      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"wfclosed",
          {translation=>'secscan::workflow::FindingHndl'},
          $h->{note})){
         my $store={stateid=>21,
                    step=>'secscan::workflow::FindingHndl::finish',
                    fwdtargetid=>undef,
                    fwdtarget=>undef,
                    secfindingstate=>'CLOSEDRESOLVED',
                    eventend=>NowStamp("en"),
                    fwddebtarget=>undef,
                    fwddebtargetid=>undef};
         if ($WfRec->{eventend} eq ""){
            $store->{eventend}=NowStamp("en");
         }
         $self->StoreRecord($WfRec,$store);
         $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
         return(1);
      }
   }
   elsif($op eq "wfrejectresp"){
      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"wfreject",
          {translation=>'secscan::workflow::FindingHndl'},
          $h->{note})){
         Query->Delete("note");
         my $nextstep=$self->getParent->getStepByShortname("approve");
         my $store={stateid=>10,
                    step=>$nextstep,
                    fwdtargetname=>"w5base.secscan.approve",
                    fwddebtarget=>undef,
                    fwddebtargetid=>undef};
         $self->StoreRecord($WfRec,$store);
         $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
         return(1);
      }
   }
   elsif($op eq "wfsecsetwrkasdes"){
      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"wfclosed",
          {translation=>'secscan::workflow::FindingHndl'},
          $h->{note})){
         #
         # Hier müsste u.U. noch eine Prüfung durch die Approve Abteilung
         # rein
         #
         my $store={stateid=>21,
                    step=>'secscan::workflow::FindingHndl::finish',
                    fwdtargetid=>undef,
                    fwdtarget=>undef,
                    secfindingnonremstatement=>$h->{note},
                    secfindingstate=>'CLOSEDCNTEXIST',
                    eventend=>NowStamp("en"),
                    fwddebtarget=>undef,
                    fwddebtargetid=>undef};
         if ($WfRec->{eventend} eq ""){
            $store->{eventend}=NowStamp("en");
         }
         $self->StoreRecord($WfRec,$store);
         $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
        # $self->PostProcess("SaveStep".".".$op,$WfRec,$actions,
        #                    note=>$h->{note},
        #                    fwdtarget=>$store->{fwdtarget},
        #                    fwdtargetid=>$store->{fwdtargetid},
        #                    fwdtargetname=>'RiskCoordinator');
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
         if ($WfRec->{eventend} eq ""){
            $store->{eventend}=NowStamp("en");
         }
         $self->StoreRecord($WfRec,$store);
         $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
         $self->PostProcess("SaveStep.".$op,$WfRec,$actions);
         return(1);
      }
   }
   elsif ($op eq "wfforceobsolete"){
      return($self->getParent->nativProcess($self,$op,$h,$WfRec,$actions));
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
   my $tr="secscan::workflow::FindingHndl";
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
          $self->getParent->T("assign to","secscan::workflow::FindingHndl").
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
                $self->getDefaultNoteDiv($WfRec,$actions,mode=>'simple').
                "</div>";
   }

   if (grep(/^wfsecsetwrkasdes$/,@$actions)){
      $$selopt.="<option value=\"wfsecsetwrkasdes\">".
                $self->getParent->T("wfsecsetwrkasdes",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfsecsetwrkasdes class=\"$class\">".
                "Wenn ein Security-Finding nicht beseitig wird, ist ".
                "eine ausführliche Begründigung notwendig! Sie müssen ".
                "also sehr genau beschreiben, was gegen eine ".
                "Beseitigung spricht.".
                $self->getDefaultNoteDiv($WfRec,$actions,
                                         height=>80,
                                         mode=>'simple').
                "</div>";
   }

   if (grep(/^wfaskdsgvo$/,@$actions)){
      $$selopt.="<option value=\"wfaskdsgvo\">".
                $self->getParent->T("wfaskdsgvo",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfaskdsgvo class=\"$class\">".
                $self->getParent->T("wfaskdsgvo.LABEL",$tr).
                $self->getDefaultNoteDiv($WfRec,$actions,
                                         height=>80,
                                         mode=>'simple').
                "</div>";
   }

   if (grep(/^wfaskreason$/,@$actions)){
      $$selopt.="<option value=\"wfaskreason\">".
                $self->getParent->T("wfaskreason",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfaskreason class=\"$class\">".
                $self->getParent->T("wfaskreason.LABEL",$tr).
                $self->getDefaultNoteDiv($WfRec,$actions,
                                         height=>80,
                                         mode=>'simple').
                "</div>";
   }

   if (grep(/^wfrejectresp$/,@$actions)){
      $$selopt.="<option value=\"wfrejectresp\">".
                $self->getParent->T("wfrejectresp",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfrejectresp class=\"$class\">".
                "Hiermit dokumentieren Sie, dass Sie für das ".
                "Security-Finding nicht zuständig sind. Sie sollten ".
                "in der Begründung möglichst mit angeben, warum es ".
                "aus Ihrer Sicht zu dieser Fehlzuweisung gekommen ist.".
                $self->getDefaultNoteDiv($WfRec,$actions,mode=>'simple').
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
   return("wfclose") if (in_array($actions,"wfclose"));
   return("wfaddnote");
}


#sub getWorkHeight
#{
##   my $self=shift;
#   my $WfRec=shift;
#   my $actions=shift;
#
#   return(0) if (ref($actions) eq "ARRAY" && $#{$actions}==-1);
#
#   return(150);
#}






#######################################################################
package secscan::workflow::FindingHndl::approve;
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


   if ($action eq "SaveStep"){
      if ($action ne "" && !grep(/^$op$/,@{$actions})){
         $self->LastMsg(ERROR,"invalid disalloed action requested");
         return(0);
      }
      elsif ($op eq "wfsetnewresp"){
         my $newrec;
         my $fobj=$self->getParent->getField("secfindingreponsible");
         my $h=$self->getWriteRequestHash("nativweb");
         if ($newrec=$fobj->Validate($WfRec,$h)){
            my $nativH={
               note=>$h->{note},
               secfindingreponsible=>$h->{secfindingreponsible}
            }; 
            return($self->nativProcess($op,$nativH,$WfRec,$actions));
         }
         else{
            return(0);
         }
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
                                    'secscan::workflow::FindingHndl');
      }
   }
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
   elsif($op eq "wfclose"){
      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"wfclosed",
          {translation=>'secscan::workflow::FindingHndl'},
          $h->{note})){
         my $store={stateid=>21,
                    step=>'secscan::workflow::FindingHndl::finish',
                    fwdtargetid=>undef,
                    fwdtarget=>undef,
                    fwddebtarget=>undef,
                    fwddebtargetid=>undef};
         if ($WfRec->{eventend} eq ""){
            $store->{eventend}=NowStamp("en");
         }
         $self->StoreRecord($WfRec,$store);
         $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
         return(1);
      }
   }
   elsif($op eq "wfsetnewresp"){
      my $newrec;
      my $fobj=$self->getParent->getField("secfindingreponsible");
      if ($newrec=$fobj->Validate($WfRec,$h)){
         $newrec->{fwdtarget}="base::user";
         $newrec->{fwdtargetid}=$newrec->{secfindingreponsibleid};
         $newrec->{step}="secscan::workflow::FindingHndl::main";
         $newrec->{stateid}=2;
         if ($WfRec->{eventend} ne ""){
            $newrec->{eventend}=undef;
         }
         $self->getParent->getParent->CleanupWorkspace($WfRec->{id});
         if ($self->StoreRecord($WfRec,$newrec)){
            my $fwdtargetname=$newrec->{secfindingreponsible};
            if ($self->getParent->getParent->Action->StoreRecord(
                $WfRec->{id},"wfforward",
                {translation=>'base::workflow::request'},
                $fwdtargetname."\n".
                $h->{note},undef)){
               $self->PostProcess("SaveStep.".$op,$WfRec,$actions,
                                  note=>$h->{note},
                                  fwdtarget=>$newrec->{fwdtarget},
                                  fwdtargetid=>$newrec->{fwdtargetid},
                                  fwdtargetname=>$fwdtargetname);
            }
         }
         return(0);
      }
      else{
         return(0);
      }
   }
   elsif ($op eq "wfforceobsolete"){
      return($self->getParent->nativProcess($self,$op,$h,$WfRec,$actions));
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


   if ($action eq "SaveStep.wfsetnewresp"){
      $self->getParent->NotifySecurityFindingForward($WfRec,$param{note});
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
   my $tr="secscan::workflow::FindingHndl";
   my $class="display:none;visibility:hidden";

   if (grep(/^wfsetnewresp$/,@$actions)){
      $$selopt.="<option value=\"wfsetnewresp\">".
                $self->getParent->T("wfsetnewresp",$tr).
                "</option>\n";
      my $note=Query->Param("note");

      my $d="<table width=\"100%\" border=0 cellspacing=0 cellpadding=0><tr>".
         "<td colspan=2><textarea name=note ".
         "style=\"width:100%;resize:none;height:100px\">".
         quoteHtml($note)."</textarea></td></tr>";
      $d.="<tr><td width=1% nowrap>".
          $self->getParent->T("new responsible person",
                              "secscan::workflow::FindingHndl").
          ":&nbsp;</td>".
          "<td>\%secfindingreponsible(detail)\%".
          "</td>";
      $d.="</tr></table>";
      $$divset.="<div id=OPwfsetnewresp class=\"$class\">$d</div>";
   }
   if (grep(/^wfclose$/,@$actions)){
      $$selopt.="<option value=\"wfclose\">".
                $self->getParent->T("wfclose",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfclose class=\"$class\">".
                $self->getDefaultNoteDiv($WfRec,$actions,mode=>'simple').
                "</div>";
   }


   $self->SUPER::generateWorkspacePages($WfRec,$actions,$divset,$selopt);
   return("wfaddnote");
}


#sub getWorkHeight
#{
##   my $self=shift;
#   my $WfRec=shift;
#   my $actions=shift;
#
#   return(0) if (ref($actions) eq "ARRAY" && $#{$actions}==-1);
#
#   return(150);
#}






#######################################################################
package secscan::workflow::FindingHndl::finish;
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


   if ($op eq "wfreactivate"){
      return($self->getParent->nativProcess($self,$op,$h,$WfRec,$actions));
   }
   return($self->SUPER::nativProcess($op,$h,$WfRec,$actions));
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

#   return("60") if ($self->getParent->getParent->IsMemberOf("admin"));
   return(0);
}






1;
