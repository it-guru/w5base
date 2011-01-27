package itil::workflow::itquotation;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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
use base::workflow::quotation;
use itil::workflow::base;
@ISA=qw(base::workflow::quotation itil::workflow::base);

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
   $self->AddGroup("customerdata",translation=>'itil::workflow::itquotation');
   $self->itil::workflow::base::Init();
   return($self->SUPER::Init(@_));
}

sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;

   return($self->InitFields(
      new kernel::Field::Select(
                name          =>'reqnature',
                label         =>'Request nature',
                translateion  =>'itil::workflow::itquotation',
                value         =>['RUserGroup',
                                 'RAppl.developer',
                                 'RAppl.businessteam',
                                 'RAppl.opm',
                                 'RAppl.tsm'],
                container     =>'headref'),

      new kernel::Field::Link(
                name          =>'originalfwdtarget1',
                label         =>'original forward',
                container     =>'headref'),

      new kernel::Field::Link(
                name          =>'originalfwdtarget2',
                label         =>'original forward',
                container     =>'headref'),

    ),$self->SUPER::getDynamicFields(%param));



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




sub isWorkflowManager
{
   my $self=shift;
   my $WfRec=shift;

#   if (defined($WfRec->{id}) &&   # only if a workflow exists, a workflow
#       $WfRec->{stateid}<16){     # manager can be calculated
#      my $userid=$self->getParent->getCurrentUserId();
#     
#      my @devcon=$self->getDefaultContractor($WfRec);
#     
#      my $msg=shift(@devcon);
#     
#      while(my $target=shift(@devcon)){
#         my $targetid=shift(@devcon);
#         if ($target eq "base::user" && $targetid eq $userid){
#            return(1);
#         }
#         if ($target eq "base::grp" && $targetid ne ""){
#            if ($self->getParent->IsMemberOf($targetid,"RMember","direct")){
#               return(1);
#            }
#         }
#      }
#   }
   return(0);
}


sub getDefaultProvider
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   return();
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

sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   if ($shortname eq "dataload"){
      return("itil::workflow::itquotation::".$shortname);
   }
   return($self->SUPER::getStepByShortname($shortname,$WfRec));
}




sub isViewValid
{
   my $self=shift;
   my $rec=$_[0];
   my $fo=$self->getField("reqnature");
   my $d=$fo->RawValue($rec);
printf STDERR ("fifi d=$d rec=%s\n",Dumper($rec));
   if ($d=~m/^RAppl\..*/){
      return($self->SUPER::isViewValid(@_),"affected");
   }
   return($self->SUPER::isViewValid(@_),"customerdata");
}

sub isWriteValid
{
   my $self=shift;
   my @l=$self->SUPER::isWriteValid(@_);
   if (grep(/^default$/,@l)){
      push(@l,"customerdata");
   }
   return(@l);
}


sub getPosibleRelations
{
   my $self=shift;
   my $WfRec=shift;
   return("itil::workflow::itquotation"=>'relbuisreq',
          "itil::workflow::itquotation"=>'reldevreq'); 
}









#######################################################################
package itil::workflow::itquotation::dataload;
use vars qw(@ISA);
use kernel;
@ISA=qw(base::workflow::quotation::dataload);

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
<td class=fname>%reqnature(label)%:</td>
<td colspan=3 class=finput>%reqnature(detail)%</td>
</tr>
<tr>
<td colspan=4>

<div id=app style="height:60px;padding:5px;margin:15px;border-style:solid;border-width:2px;border-color:black">
<table width=100% border=1>
<tr>
<td class=fname width=1% nowrap>%affectedapplication(label)%:</td>
<td class=finput>%affectedapplication(detail)%</td>
</tr>
</table>
</div>

<div id=fwd style="height:60px;padding:5px;margin:15px;border-style:solid;border-width:2px;border-color:black">
<table width=100% border=1>
<tr>
<td class=fname width=1% nowrap>%fwdtargetname(label)%:</td>
<td class=finput>%fwdtargetname(detail)%</td>
</tr>
</table>
</div>




</td>
</tr>
<tr>
<td class=fname>%forceinitiatorgroupid(label)%:</td>
<td colspan=3 class=finput>%forceinitiatorgroupid(detail)%</td>
</tr>
</table>
<script language="JavaScript">
setFocus("Formated_name");
setEnterSubmit(document.forms[0],"NextStep");
function setInitFormLayout(reqnature){
  var fdiv=document.getElementById("fwd");
  var adiv=document.getElementById("app");
  if (reqnature.match(/^RAppl\\./)){
     adiv.style.visibility='visible';
     adiv.style.display='block';
     fdiv.style.visibility='hidden';
     fdiv.style.display='none';
  } 
  else{
     fdiv.style.visibility='visible';
     fdiv.style.display='block';
     adiv.style.visibility='hidden';
     adiv.style.display='none';
  }
}
window.onload = function() {
    document.forms[0].elements['Formated_reqnature'].onchange=function(){
      setInitFormLayout(document.forms[0].elements['Formated_reqnature'].value);
    };
    setInitFormLayout(document.forms[0].elements['Formated_reqnature'].value);
}
</script>
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

   if ($action eq "NextStep" || $action eq "create"){
      $action="NextStep";
      my $reqnature=$h->{reqnature};
      if ($reqnature eq "RUserGroup"){
         if ($h->{fwdtargetname} eq ""){
            $self->LastMsg(ERROR,"invalid quotation target specified");
            return(0);
         }
         $h->{originalfwdtarget1}=$h->{fwdtargetname};
      }
      elsif ($reqnature=~m/^RAppl\./){
         my $appl=getModuleObject($self->getParent->Config,"itil::appl");
         if ($h->{affectedapplication} ne ""){
            $appl->SetFilter({name=>\$h->{affectedapplication}});
         }
         elsif ($h->{affectedapplicationid} ne ""){
            $appl->SetFilter({id=>\$h->{affectedapplicationid}});
         }
         else{
            $self->LastMsg(ERROR,"invalid application request");
            return(0);
         }
         my ($arec,$msg)=$appl->getOnlyFirst(qw(id conumber name));
         if (defined($arec)){
            $h->{affectedapplicationid}=$arec->{id};
            $h->{affectedapplication}=$arec->{name};
            if ($arec->{conumber} ne ""){
               $h->{involvedcostcenter}=$arec->{conumber};
            }
         }
         if ($h->{affectedapplicationid} eq ""){
            $self->LastMsg(ERROR,"invalid application specified");
            return(0);
         }
         
         print STDERR Dumper($h);
      }
      else{
         $self->LastMsg(ERROR,"invalid request nature");
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
      my $rfo=$self->getField("reqnature");
      my $reqnature=Query->Param("Formated_".$rfo->Name());
      printf STDERR ("fifi requestnature=%s\n",$reqnature); 
      if ($reqnature eq "RUserGroup"){
         my $fo=$self->getField("fwdtargetname");
         my $foval=Query->Param("Formated_".$fo->Name());
         if ($foval=~m/^\s*$/){
            $self->LastMsg(ERROR,"no target specified");
            return(0);
         }
         if (!$fo->Validate($WfRec,{$fo->Name=>$foval})){
            $self->LastMsg(ERROR,"unknown error") if (!$self->LastMsg());
            return(0);
         }
      }
      elsif ($reqnature=~m/^RAppl\./){
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
      
   }
   return($self->SUPER::Process($action,$WfRec));
}

sub addInitialParameters
{
   my $self=shift;
   my $newrec=shift;

   return(1);
}











sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("340");
}

1;
