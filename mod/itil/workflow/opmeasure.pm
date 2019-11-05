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
   $self->AddGroup("extopmeadesc",translation=>'itil::workflow::opmeasure');
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
      new kernel::Field::Link(    name          =>'subtyp',
                                  label         =>'subtyp',
                                  container     =>'headref'),
      new kernel::Field::Date(    name          =>'plannedstart',
                                  label         =>'planned start',
                                  htmleditwidth =>'100%',
                                  group         =>'extopmeadesc',
                                  container     =>'headref'),
      new kernel::Field::Date(    name          =>'plannedend',
                                  htmleditwidth =>'100%',
                                  label         =>'planned end',
                                  group         =>'extopmeadesc',
                                  container     =>'headref'),
    ),$self->SUPER::getDynamicFields(%param));

   $self->getField("implementedto")->{uivisible}=0;
   $self->getField("implementationeffort")->{uivisible}=0;
   $self->getField("initiatorcomments")->{uivisible}=0;
   $self->getField("affectedcontract")->{htmldetail}=0;
   $self->getField("affectedsystem")->{htmldetail}="NotEmpty";
   $self->getField("affectedproject")->{htmldetail}=0;
   return(@bk);

}


sub PostponeMaxDays   # postpone max days after WfStart
{
   my $self=shift;
   my $WfRec=shift;
   if ($WfRec->{subtyp} eq "riskmeasure"){
      return((365*3)+5);
   }
   return(365*1);
}





sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (!defined($oldrec)){
      if (length($newrec->{detaildescription})<10){
         $self->LastMsg(ERROR,"invalid detail description for measure");
         return(0);
      }
   }

   if (exists($newrec->{plannedstart}) || exists($newrec->{plannedend})){
      my $plannedstart=effVal($oldrec,$newrec,"plannedstart"); 
      my $plannedend=effVal($oldrec,$newrec,"plannedend"); 
      if ($plannedstart ne "" && $plannedend ne ""){
         my $d=CalcDateDuration($plannedstart,$plannedend);
         if (!defined($d) || $d->{totalminutes}<=0){
            $self->LastMsg(ERROR,"planned end must be behind planned start");
            return(0);
         }
      }
      my $eventstart=effVal($oldrec,$newrec,"eventstart"); 
      my $eventend=effVal($oldrec,$newrec,"eventend"); 
      if ($plannedstart ne "" && $eventstart ne $plannedstart){
         $newrec->{eventstart}=$plannedstart;
      }
      if ($plannedend ne "" && $eventend ne $plannedend){
         $newrec->{eventend}=$plannedend;
      }
   }
   if (exists($newrec->{plannedstart}) && $newrec->{plannedstart} ne ""){
      my $plannedstart=effVal($oldrec,$newrec,"plannedstart"); 
      my $createdate=effVal($oldrec,$newrec,"createdate"); 
      my $d=CalcDateDuration($plannedstart,$createdate);
      my $subtyp=effVal($oldrec,$newrec,"subtyp");
      my $maxoffset=10.0;
      if ($subtyp eq "riskmeasure"){
         $maxoffset=365*24*60*2;
         $maxoffset=365*24*60*100;  # temporär for migration dataload
      }
      if (!defined($d) || $d->{totalminutes}>$maxoffset){
         $self->LastMsg(ERROR,"planned start to far in the past");
         return(0);
      }
   }
   if (exists($newrec->{plannedend}) && $newrec->{plannedend} ne ""){
      my $plannedend=effVal($oldrec,$newrec,"plannedend"); 
      my $d=CalcDateDuration(NowStamp("en"),$plannedend);
      my $subtyp=effVal($oldrec,$newrec,"subtyp");
      my $maxoffset=365*24*60;
      if ($subtyp eq "riskmeasure"){
         $maxoffset=365*24*60*5;
      }
      if (!defined($d) || $d->{totalminutes}>$maxoffset){
         $self->LastMsg(ERROR,"planned end to far in the future");
         return(0);
      }
   }
   if (effChanged($oldrec,$newrec,"stateid")){
      if (defined($oldrec) && $oldrec->{stateid}<21 && $newrec->{stateid}>20){
         $newrec->{eventend}=NowStamp("en");
      }
   }



   
   foreach my $fld (qw(plannedstart plannedend)){
      if (defined($oldrec) &&
          $oldrec->{$fld} ne ""){
         if (exists($newrec->{$fld}) && $newrec->{$fld} eq ""){
            $self->LastMsg(ERROR,"it is not allowed to delete this entry");
            return(0);
         }
      }
   }

   return(1);
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
   my $iscurrent=$self->isCurrentForward($WfRec);
 
   my @l=$self->SUPER::getPosibleActions($WfRec);

   if (!$self->getParent->isDataInputFromUserFrontend()){
      if ($WfRec->{stateid}>=16){
         push(@l,"wfforcerevise");
      }
   }
   if ($iscurrent && 
       in_array([3,4],$WfRec->{stateid})){
      my $allow=1;
      if (ref($WfRec->{shortactionlog}) eq "ARRAY"){
         foreach my $arec (@{$WfRec->{shortactionlog}}){
            if ($arec->{name} eq "wfaddnote"){
               $allow=0;
            }
         }
      }
      # wenn schon was gemacht, dann darf die Liste der Systeme
      # nicht mehr verändert werden
      if ($allow){
         push(@l,"wfmodaffectedsystem");
      }
   }

   # Genehmigungsanforderung herausnehmen
   @l=grep(!/^wfapprovalreq$/,@l);

   if ($WfRec->{stateid}<16){
      if ($#l==-1){ # aktueller User darf nix
         if ($#{$WfRec->{relations}}!=-1){
            foreach my $rel (@{$WfRec->{relations}}){
               if ($rel->{name} eq "riskmesure"){
                  my $wfid=$rel->{srcwfid};
                  if ($wfid ne ""){
                     my $wf=$self->getParent->Clone();
                     $wf->SetFilter({id=>\$wfid});
                     my ($wfrec,$msg)=$wf->getOnlyFirst(qw(ALL));
                     if (defined($wfrec)){
                        my $a=$wfrec->{posibleactions};
                        if (ref($a) eq "ARRAY"){
                           if (in_array($a,["wfhardtake","wfforward"])){
                              push(@l,"wfhardtake");
                           }
                        }
                     }
                  }
               }
            }
         }
      }
   }
   
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
   if ($shortname eq "main"){
      return("itil::workflow::opmeasure::".$shortname);
   }
   return($self->SUPER::getStepByShortname($shortname,$WfRec));
}

sub isViewValid
{
   my $self=shift;
   return($self->SUPER::isViewValid(@_),
          "affected","customerdata","extopmeadesc");
}

sub isWriteValid
{
   my $self=shift;
   my @l=$self->SUPER::isWriteValid(@_);
   my $WfRec=shift;

   push(@l,"extopmeadesc") if (!defined($WfRec));
   if (grep(/^default$/,@l)){
      push(@l,"customerdata");
      push(@l,"extopmeadesc");
   }
   my $userid=$self->getParent->getCurrentUserId();
   if ($WfRec->{fwdtarget} eq 'base::user' &&
       $userid==$WfRec->{fwdtargetid} &&
       ($WfRec->{stateid}==4 || $WfRec->{stateid}==3)){
      push(@l,"relations");
   }

   @l=grep(!/^init$/,@l);
   return(@l);
}

sub getDetailBlockPriority            # posibility to change the block order
{
   return("header","default","extopmeadesc","affected","customerdata",
          "init","flow");
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/workflow_opmeasure.jpg?".
          $cgi->query_string());
}

sub getPosibleRelations
{
   my $self=shift;
   my $WfRec=shift;
   return("itil::workflow::opmeasure"=>'info'); 
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
   my %g;

   if (ref($c) eq "ARRAY"){
      if ($fwd->{fwdtarget} eq "base::user"){
         if (in_array([$fwd->{fwdtargetid}],[
                   $arec->{tsmid},$arec->{tsm2id},
                   $arec->{opmid},$arec->{opm2id},
                   $arec->{applmgrid}])){
            return(1);
         }
         %g=$self->getGroupsOf($fwd->{fwdtargetid},["RMember"],"direct");
         if (($arec->{itsemteamid} ne "" && exists($g{$arec->{itsemteamid}}))||
             ($arec->{responseteamid} ne "" && 
              exists($g{$arec->{responseteamid}}))||
             ($arec->{businessteamid} ne "" && 
              exists($g{$arec->{businessteamid}}))){
            return(1);
         }
         foreach my $con (@$c){# if target is registered in a group in contacts
            if ($fwd->{fwdtarget} eq "base::user" &&
                $con->{target} eq "base::grp"){
               # check if $fwd->{fwdtargetid} is in $con->{targetid} group
               if (exists($g{$con->{targetid}})){
                  return(1);
               }
            } 
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
      foreach my $con (@$c){  # if target is registered in contacts, it's ok
         if ($con->{target} eq $fwd->{fwdtarget} &&
             $con->{targetid} eq $fwd->{fwdtargetid}){
            return(1);
         }
      }
      if (ref($arec->{swinstances}) eq "ARRAY"){
         my @swiid;
         foreach my $swirec (@{$arec->{swinstances}}){
            push(@swiid,$swirec->{id}) if ($swirec->{id} ne "");
         }
         if ($#swiid!=-1){
            my $swi=getModuleObject($self->Config,"itil::swinstance");
            $swi->SetFilter({id=>\@swiid});
            foreach my $swirec ($swi->getHashList(qw(fullname
                                                 admid adm2id swteamid))){
                if ($fwd->{fwdtarget} eq "base::user"){
                   if (in_array([$fwd->{fwdtargetid}],[
                             $swirec->{admid},
                             $swirec->{adm2id}])){
                      return(1);
                   }
                   if (($swirec->{swteamid} ne "" && 
                       exists($g{$swirec->{swteamid}}))){
                      return(1);
                   }
                }
                if ($fwd->{fwdtarget} eq "base::grp"){
                   if (in_array([$fwd->{fwdtargetid}],[
                             $swirec->{swteamid}])){
                      return(1);
                   }
                }
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

   if (!Query->Param("Formated_plannedstart")){
      Query->Param("Formated_plannedstart"=>$self->T("now"));
   }


   my $nextstart=$self->getParent->getParent->T("NEXTSTART","base::workflow");
   my $t1=$self->getParent->getParent->T("planned timerange",
                $self->getParent->Self);
   my $assignlabel=$self->getParent->getParent->T("assign measure to",
                   $self->getParent->Self);
   my $secial=$self->getParent->getSpecificDataloadForm();
   my $templ=<<EOF;
<style>

</style>
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
<td>
<table border=0 cellspacing=0 cellpadding=0>
<tr>
<td class=finput>$d</td>
<td class=fname>${t1}:</td>
<td class=finput>%plannedstart(detail)%</td>
<td>-</td>
<td class=finput>%plannedend(detail)%</td>
</tr>
</table>
</td>
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
                                           systems
                                           itsemteamid 
                                           responseteamid 
                                           businessteamid
                                           swinstances 
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
            if (ref($arec->{systems}) eq "ARRAY"){
               my %systemid;
               my %system;
               foreach my $rec (@{$arec->{systems}}){
                  if (defined($rec->{systemid})){
                     $systemid{$rec->{systemid}}=1;
                  }
                  if (defined($rec->{system})){
                     $system{$rec->{system}}=1;
                  }
               }
               if (keys(%systemid)){
                  $h->{affectedsystemid}=[keys(%systemid)];
               }
               if (keys(%system)){
                  $h->{affectedsystem}=[keys(%system)];
               }
            }
            #
            # Check if current user is allowed to create a business measure 
            #
            #
            my $userid=$self->getParent->getParent->getCurrentUserId();
            if ($userid eq "" ||
                (!in_array([$userid],[
                   $arec->{tsmid},$arec->{tsm2id},
                   $arec->{opmid},$arec->{opm2id},
                   $arec->{applmgrid}
                 ]) &&
                (!$self->getParent->IsMemberOf("admin")) &&
                ($arec->{businessteamid} ne "" && 
                 !$self->getParent->IsMemberOf($arec->{businessteamid})))){
                # ok, now we should check the contacts
               my $found=0;
               foreach my $crec (@{$arec->{contacts}}){
                  my $r=$crec->{roles};
                  if (in_array(['businessemployee','applmgr2'],$r)){
                     if ($crec->{target} eq "base::user"){
                        if ($crec->{targetid} eq $userid){
                           $found++;
                           last;
                        }
                     }
                     if ($crec->{target} eq "base::grp"){
                        if ($self->getParent->IsMemberOf($crec->{targetid})){
                           $found++;
                           last;
                        }
                     }
                  }

               }
               if (!$found){
                  $self->LastMsg(ERROR,"You are not authorised to create ".
                                       "measures for the desired application");
                  return(0);
               }
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
   
   return($self->SUPER::Validate(@_));

}




sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("250");
}

#######################################################################
package itil::workflow::opmeasure::main;
use vars qw(@ISA);
use kernel;
@ISA=qw(base::workflow::request::main);


sub getSystemBase
{
   my $self=shift;
   my $curapplid=shift;
   my $max=shift;

   my $appl=getModuleObject($self->Config,"itil::appl");
   $appl->SetFilter({id=>$curapplid});
   my @l=$appl->getHashList(qw(id systems));
   my %s; 
   $max->{system}=5;
   $max->{systemsystemid}=5;
   $max->{shortdesc}=5;
   foreach my $arec (@l){
      if (ref($arec->{systems}) eq "ARRAY"){
         foreach my $srec (@{$arec->{systems}}){
            if (!exists($s{$srec->{systemid}})){
               $s{$srec->{systemid}}={
                 shortdesc=>$srec->{shortdesc},
                 system=>$srec->{system},
                 systemsystemid=>$srec->{systemsystemid}
               };
               if (length($srec->{shortdesc})>$max->{shortdesc}){
                  $max->{shortdesc}=length($srec->{shortdesc});
               }
               if (length($srec->{system})>$max->{system}){
                  $max->{system}=length($srec->{system});
               }
               if (length($srec->{systemsystemid})>$max->{systemsystemid}){
                  $max->{systemsystemid}=length($srec->{systemsystemid});
               }
            }
         }
      }
   }
   $max->{system}++;
   $max->{systemsystemid}++;
   return(\%s);
}


sub generateWorkspacePages
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $divset=shift;
   my $selopt=shift;
   my $tr="itil::workflow::opmeasure::main";
   my $class="display:none;visibility:hidden";

   my $defop;
   if (grep(/^wfmodaffectedsystem$/,@$actions)){
      $$selopt.="<option value=\"wfmodaffectedsystem\">".
                $self->getParent->T("wfmodaffectedsystem",$tr).
                "</option>\n";
      my $sel="<select size=9 style=\"width:100%\" ".
              "name=affectedsystemid multiple>";
      my $cursystemid=$WfRec->{affectedsystemid};
      if (ref($cursystemid) ne "ARRAY"){
         $cursystemid=[$cursystemid];
      }
      if (Query->Param("OP") eq "wfmodaffectedsystem"){
         my @affectedsystemid=Query->Param("affectedsystemid");
         $cursystemid=\@affectedsystemid;
      }
      my $curapplid=$WfRec->{affectedapplicationid};
      if (ref($curapplid) ne "ARRAY"){
         $curapplid=[$curapplid];
      }
      my %max=();
      my $s=$self->getSystemBase($curapplid,\%max);

      foreach my $systemid (sort({
                              my $asel=in_array($cursystemid,$a) ? "0" : "1";
                              my $bsel=in_array($cursystemid,$b) ? "0" : "1";
                              my $ak=$asel.$s->{$a}->{system};
                              my $bk=$bsel.$s->{$b}->{system};
                              $ak cmp $bk;
                            } keys(%$s))){
         my $srec=$s->{$systemid};
         my $form="%-$max{system}s ".
                  "%-$max{systemsystemid}s ".
                  "%-$max{shortdesc}s";
         my $label=sprintf($form,
                           $srec->{system},
                           $srec->{systemsystemid},
                           $srec->{shortdesc});
         my $selected="";
         if (in_array($cursystemid,$systemid)){
            $selected=" selected";
         }
         $label=~s/ /&nbsp;/g;
         $sel.="<option${selected} value=\"$systemid\">".$label."</option>\n";
      }
      $sel.="</select>";
      $$divset.="<div id=OPwfmodaffectedsystem class=\"$class\">".
                $sel."</div>";
   }
   return(
      $self->SUPER::generateWorkspacePages($WfRec,$actions,$divset,$selopt)
   );
}


sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $userid=$self->getParent->getParent->getCurrentUserId();


   if ($action eq "BreakWorkflow"){
      my $h=$self->getWriteRequestHash("web");
      return($self->nativProcess("wfbreak",$h,$WfRec,$actions));
   }

   if ($action eq "SaveStep"){
      my $op=Query->Param("OP");
      if ($action ne "" && !grep(/^$op$/,@{$actions})){
         $self->LastMsg(ERROR,"invalid disalloed action requested");
         return(0);
      }
      if ($op eq "wfmodaffectedsystem"){
         my @affectedsystemid=Query->Param("affectedsystemid");
         my $h={"affectedsystemid"=>\@affectedsystemid}; 
         return($self->nativProcess("wfmodaffectedsystem",$h,$WfRec,$actions));
      }
   }
   return($self->SUPER::Process($action,$WfRec,$actions));
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

   if ($op eq "wfmodaffectedsystem"){
      if (ref($h->{affectedsystemid}) eq "ARRAY"){
         my $curapplid=$WfRec->{affectedapplicationid};
         if (ref($curapplid) ne "ARRAY"){
            $curapplid=[$curapplid];
         }
         my %max=();
         my $s=$self->getSystemBase($curapplid,\%max);
         my $fh={
            affectedsystemid=>[],
            affectedsystem=>[]
         };
         if ($#{$h->{affectedsystemid}}==-1){
            $self->LastMsg(ERROR,"empty system list not allowed to store");
            return(0);
         }
         foreach my $sid (@{$h->{affectedsystemid}}){
            if (in_array([keys(%$s)],$sid)){
               push(@{$fh->{affectedsystemid}},$sid);
               push(@{$fh->{affectedsystem}},$s->{$sid}->{system});
            }
         }
         if ($#{$fh->{affectedsystemid}}==-1){
            $self->LastMsg(ERROR,"empty system list not allowed to store");
            return(0);
         }
         if ($self->StoreRecord($WfRec,$fh)){
            Query->Delete("OP");
            return(1);
         }
      }
      #print STDERR ("fifi h=%s\n",Dumper($h));
      return(1);
   }
   return($self->SUPER::nativProcess($op,$h,$WfRec,$actions));
}

1;
