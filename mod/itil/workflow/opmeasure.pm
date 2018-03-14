package itil::workflow::opmeasure;
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
use base::workflow::request;
use itil::workflow::base;
@ISA=qw(base::workflow::request itil::workflow::base);

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
   $self->AddGroup("customerdata",translation=>'itil::workflow::opmeasure');
   $self->AddGroup("extdesc",translation=>'itil::workflow::opmeasure');
   $self->itil::workflow::base::Init();
   my $bk=$self->SUPER::Init(@_);
   return($bk);
}

sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;

   my @bk=($self->InitFields(
   #   new kernel::Field::Text(    name          =>'reqdesdate',
   #                               label         =>'desired date',
   #                               group         =>'default',
   #                               container     =>'headref'),

    ),$self->SUPER::getDynamicFields(%param));

   $self->getField("implementedto")->{uivisible}=0;
   $self->getField("implementationeffort")->{uivisible}=0;
   $self->getField("initiatorcomments")->{uivisible}=0;
   $self->getField("affectedcontract")->{htmldetail}=0;
   $self->getField("affectedsystem")->{htmldetail}=0;
   $self->getField("affectedproject")->{htmldetail}=0;
   return(@bk);

}

sub getPosibleWorkflowDerivations
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my @l;

   if ($WfRec->{stateid}<16){
      push(@l,
         {label=>$self->T('Initiate operation measure'),
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
                  WorkflowClass=>'itil::workflow::opmeasure'
                }
             });
          },
          name=>'initiateopmeasure'
         },
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
         {label=>$self->T('Initiate request to businessteam'),
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
                  WorkflowClass=>'itil::workflow::businesreq'
                }
             });
          },
          name=>'businesreq'
         }
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

sub handleFollowupExtended  # hock to handel additional parameters in followup
{
   my $self=shift;
   my $WfRec=shift;
   my $h=shift;
   my $param=shift;

   my %wr;
   my %w;
   foreach my $k (%$h){
      if ($k=~m/^extdesc/ || $k eq "reqdesdate"){
         $wr{$k}=$h->{$k};
         $w{$k}=$h->{$k};
      }
   }
   if ($self->StoreRecord($WfRec,$WfRec->{step},\%wr)){
      $param->{additional}->{followupparam}=join(",",sort(keys(%w)));
      return(1);
   }
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

   my $templ="";
   return($templ);
}


sub isWorkflowManager
{
   my $self=shift;
   my $WfRec=shift;

   if (defined($WfRec->{id}) &&   # only if a workflow exists, a workflow
       $WfRec->{stateid}<16){     # manager can be calculated
      my $userid=$self->getParent->getCurrentUserId();
      if (!($WfRec->{fwdtarget} eq "base::user" && # check if i have already
            $WfRec->{fwdtargetid} eq $userid) &&   # the workflow
          !($WfRec->{owner} eq $userid &&          # check if i was the last
            $WfRec->{stateid} eq "2")){            # worker
         my $affectedapplicationid=$WfRec->{affectedapplicationid};
         if (ref($affectedapplicationid) ne "ARRAY"){
            $affectedapplicationid=[$affectedapplicationid];
         }
         my @roleidfields=qw(applmgrid tsmid tsm2id opmid opm2id);
         my $appl=getModuleObject($self->Config,"itil::appl");
         $appl->SetFilter({id=>$affectedapplicationid});
         foreach my $apprec ($appl->getHashList(@roleidfields)){
            foreach my $r (@roleidfields){
               if (exists($apprec->{$r}) &&
                   $apprec->{$r} ne "" &&
                   $apprec->{$r} eq $userid){
                  return(1);
               }
            }
         }
      }
   }
   return(0);
}


sub getDefaultContractor
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $target;
   my $flt;

   if (exists($WfRec->{target}) && exists($WfRec->{targetid})){
      return(undef,$WfRec->{target},$WfRec->{targetid});
   }
   return();
}

sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;
   my @l=$self->SUPER::getPosibleActions($WfRec);

   if (!$self->getParent->isDataInputFromUserFrontend()){
      if ($WfRec->{stateid}>=16){
         push(@l,"wfforcerevise");
      }
   }

   # Genehmigungsanforderung herausnehmen
   @l=grep(!/^wfapprovalreq$/,@l);
   
   return(@l);
}


sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   if ($shortname eq "dataload"){
      return("itil::workflow::opmeasure::".$shortname);
   }
   return($self->SUPER::getStepByShortname($shortname,$WfRec));
}

sub isViewValid
{
   my $self=shift;
   return($self->SUPER::isViewValid(@_),
          "affected","customerdata","extdesc");
}

sub isWriteValid
{
   my $self=shift;
   my @l=$self->SUPER::isWriteValid(@_);
   push(@l,"extdesc") if (!defined($_[0]));
   if (grep(/^default$/,@l)){
      push(@l,"customerdata");
      push(@l,"extdesc");
   }
   @l=grep(!/^init$/,@l);
   return(@l);
}

sub getDetailBlockPriority            # posibility to change the block order
{
   return("header","default","extdesc","affected","customerdata","init","flow");
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/workflow_appl.jpg?".$cgi->query_string());
}

sub getPosibleRelations
{
   my $self=shift;
   my $WfRec=shift;
   return("itil::workflow::opmeasure"=>'relchange'); 
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
   }


   return($self->SUPER::WSDLaddNativFieldList($uri,$ns,$fp,$class,$mode,
                              $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes));
}


sub isContactInRelationToApp
{
   my $self=shift;
   my $fwd=shift;
   my $arec=shift;

   my $c=$arec->{contacts};

   if (ref($c) eq "ARRAY"){
      if ($fwd->{fwdtarget} eq "base::user"){
         if (in_array([$fwd->{fwdtargetid}],[
                   $arec->{tsmid},$arec->{tsm2id},
                   $arec->{opmid},$arec->{opm2id},
                   $arec->{applmgrid}])){
            return(1);
         }
      }
      if ($fwd->{fwdtarget} eq "base::grp"){
         if (in_array([$fwd->{fwdtargetid}],[
                   $arec->{itsemteamid},
                   $arec->{responseteamid},
                   $arec->{businessteamid}])){
            return(1);
         }
      }
      foreach my $con (@$c){
         my $roles=$con->{roles};
         $roles=[$roles] if (ref($roles) ne "ARRAY");
         #if (grep(/^orderin1$/,@$roles)){
         if ($#{$roles}!=-1){
            if ($con->{target} eq $fwd->{fwdtarget} &&
                $con->{targetid} eq $fwd->{fwdtargetid}){
               return(1);
            }
         } 
      }
   }
   return(0);

}









#######################################################################
package itil::workflow::opmeasure::dataload;
use vars qw(@ISA);
use kernel;
@ISA=qw(base::workflow::request::dataload);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $oldval=Query->Param("Formated_prio");
   $oldval="5" if (!defined($oldval));
   my $d="<select name=Formated_prio style=\"width:100px\">";
   my @l=("high"=>3,"normal"=>5,"low"=>8);
   while(my $n=shift(@l)){
      my $i=shift(@l);
      $d.="<option value=\"$i\"";
      $d.=" selected" if ($i==$oldval);
      $d.=">".$self->T($n,"base::workflow")."</option>";
   }
   $d.="</select>";


   my $nextstart=$self->getParent->getParent->T("NEXTSTART","base::workflow");
   my $assignlabel=$self->getParent->getParent->T("assign measure to",
                   $self->getParent->Self);
   my $secial=$self->getParent->getSpecificDataloadForm();
   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr>
<td class=fname width=20%>%name(label)%:</td>
<td colspan=3 class=finput>%name(detail)%</td>
</tr>
<tr>
<td class=fname valign=top width=20%>%detaildescription(label)%:</td>
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
<tr>
<td class=fname width=20%>%prio(label)%:</td>
<td width=80 class=finput>$d</td>
</tr>
$secial
<tr>
<td class=fname>%forceinitiatorgroupid(label)%:</td>
<td colspan=3 class=finput>%forceinitiatorgroupid(detail)%</td>
</tr>
<tr>
<td class=fname>$assignlabel:</td>
<td colspan=3 class=finput>%fwdtargetname(detail)%</td>
</tr>
<!--
<tr>
<td colspan=4 align=center><br>$nextstart</td>
</tr>
-->
</table>
EOF
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
      #if ($h->{reqdesdate} eq ""){
      #   $h->{reqdesdate}="as soon as posible / baldmöglichst";
      #}

      my $flt;
      if ($h->{affectedapplication} ne ""){
         $flt={name=>\$h->{affectedapplication}}; 
      }
      if ($h->{affectedapplicationid} ne ""){
         $flt={id=>\$h->{affectedapplicationid}}; 
      }
      if (defined($flt)){
         my $appl=getModuleObject($self->getParent->Config,"itil::appl");
         $appl->SetFilter($flt);
         my ($arec)=$appl->getOnlyFirst(qw(mandator mandatorid conumber
                                           custcontracts 
                                           contacts
                                           customer customerid
                                           tsmid tsm2id
                                           opmid opm2id
                                           applmgrid
                                           itsemteamid 
                                           responseteamid 
                                           businessteamid
                                        ));
         if (defined($arec)){
            $h->{mandatorid}=[$arec->{mandatorid}];
            $h->{mandator}=[$arec->{mandator}];
            $h->{involvedcustomer}=[$arec->{customer}];
            $h->{involvedcostcenter}=[$arec->{conumber}];
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
            #
            # Check if current user is allowed to create a business measure 
            #
            #
            my $userid=$self->getParent->getParent->getCurrentUserId();
            if ($userid eq "" ||
                !in_array([$userid],[
                   $arec->{tsmid},$arec->{tsm2id},
                   $arec->{opmid},$arec->{opm2id},
                   $arec->{applmgrid}
                 ])){
               $self->LastMsg(ERROR,"you are no authorised to create ".
                                    "measure for the desired application");
               return(0);
            }
            my $fo=$self->getField("fwdtargetname");
            my $fwdres=$fo->Validate($WfRec,{$fo->Name=>$h->{$fo->Name}});
            $self->LastMsg(""); # reset last msg if exists
            if (!$self->getParent->isContactInRelationToApp($fwdres,$arec)){
               $self->LastMsg(ERROR,"selected target forward is not in ".
                                    "relation to desired application");
               return(0);
            }
            else{
              foreach my $k (keys(%$fwdres)){
                 $h->{$k}=$fwdres->{$k};
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
      {
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
      }

      {
         my $fo=$self->getField("fwdtargetname");
         my $foval=Query->Param("Formated_".$fo->Name());
         if ($foval=~m/^\s*$/){
            $self->LastMsg(ERROR,"no forward specified");
            return(0);
         }
         if (!$fo->Validate($WfRec,{$fo->Name=>$foval})){
            $self->LastMsg(ERROR,"unknown error") if (!$self->LastMsg());
            return(0);
         }
      }
   }
   return($self->SUPER::Process($action,$WfRec));
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
   
   return($self->SUPER::Validate(@_));

}







sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("250");
}

1;
