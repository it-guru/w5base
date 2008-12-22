package AL_TCom::workflow::fastdiary;
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
use AL_TCom::workflow::diary;
use AL_TCom::lib::workflow;
@ISA=qw(AL_TCom::workflow::diary);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFrontendFields(
      new kernel::Field::TextDrop(name       =>'affectedapplication',
                                  translation=>'itil::workflow::base',

                                  readonly   =>sub {
                                      my $self=shift;
                                      my $current=shift;
                                      return(0) if (!defined($current));
                                      return(1);
                                   },
                                   vjointo    =>'itil::appl',
                                   vjoinon    =>['affectedapplicationid'=>'id'],
                                   vjoindisp  =>'name',

                                   keyhandler =>'kh',
                                   container  =>'headref',
                                   uivisible  =>0,
                                   group      =>'affected',
                                   label      =>'Affected Application'),
   );

   return($self);
}

sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my @l=();
   
   return($self->SUPER::getDynamicFields(%param),
          $self->InitFields(
           new kernel::Field::Select(    name       =>'tcomcodrelevant',
                                         label      =>'P800 Relevant',
                                         htmleditwidth=>'20%',
                                         value      =>[qw(yes no)],
                                         default    =>'yes',
                                         group      =>'tcomcod',
                                         container  =>'headref'),

           new kernel::Field::Select(    name       =>'tcomcodcause',
                                         label      =>'Activity',
                                         htmleditwidth=>'80%',
                                         translation=>'AL_TCom::lib::workflow',
                                         value      =>
                             [AL_TCom::lib::workflow::tcomcodcause()],
                                         default    =>'undef',
                                         group      =>'tcomcod',
                                         container  =>'headref'),
   ));
}




sub IsModuleSelectable
{
   my $self=shift;
   my $acl;

   $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
                          "base::workflow",
                          func=>'New',
                          param=>'WorkflowClass=AL_TCom::workflow::fastdiary');
   if (defined($acl)){
      return(1) if (grep(/^read$/,@$acl));
   }
   return(0);
}

sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   if ($shortname eq "fastdataload" ||
       $shortname eq "dataloadok"){
      return("AL_TCom::workflow::fastdiary::".$shortname);
   }

   return($self->SUPER::getStepByShortname($shortname,$WfRec));
}

sub getNextStep
{
   my $self=shift;
   my $currentstep=shift;
   my $WfRec=shift;

   if($currentstep eq ""){
      return($self->getStepByShortname("fastdataload",$WfRec));
   }
   elsif($currentstep=~m/::fastdataload$/){
      return($self->getStepByShortname("dataloadok",$WfRec));
   }
   elsif($currentstep=~m/::dataloadok$/){
      return($self->getStepByShortname("fastdataload",$WfRec));
   }
   return($self->SUPER::getNextStep($currentstep,$WfRec));
}


#######################################################################
package AL_TCom::workflow::fastdiary::fastdataload;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(base::workflow::diary::dataload);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $l2=$self->T("Worktime");
   my $l1=$self->T("Worktime");
   my $m1=$self->T("MSG");
   $m1="" if ($m1 eq "MSG");
   my $oldval=Query->Param("Formated_effort");
   my $e="<select name=Formated_effort>";
   for(my $ef=5;$ef<=480;$ef+=5){
      $e.="<option value=\"$ef\"";
      $e.=" selected" if ($ef==$oldval);
      my $hnum=$ef/60.0;
      my $h="";
      if ($hnum==int($hnum)){
         $h=" = ${hnum}h";
      }
      $e.=">$ef$h</option>";

   }
   $e.="</select>";

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr>
<td class=fname colspan=2>
%name(label)%:<br>
%name(detail)%</td>
</tr>
<td class=fname colspan=2>
%detaildescription(label)%:<br>
%detaildescription(detail)%</td>
</tr>
<tr>
<td class=fname width=20%>%tcomcodrelevant(label)%:</td>
<td class=finput>%tcomcodrelevant(detail)%</td>
</tr>
<tr>
<td class=fname width=20%>%tcomcodcause(label)%:</td>
<td class=finput>%tcomcodcause(detail)%</td>
</tr>
<tr>
<td class=fname width=20%>$l1:</td>
<td class=finput>${e} min
<input type=button value="1,0h" onclick="seteffort(60);" style="width:35px">
<input type=button value="1,5h" onclick="seteffort(90);" style="width:35px">
<input type=button value="2,0h" onclick="seteffort(120);" style="width:35px">
<input type=button value="2,5h" onclick="seteffort(150);" style="width:35px">
<input type=button value="3h" onclick="seteffort(180);" style="width:25px">
<input type=button value="4h" onclick="seteffort(240);" style="width:25px">
<input type=button value="5h" onclick="seteffort(300);" style="width:25px">
<input type=button value="6h" onclick="seteffort(360);" style="width:25px">
<input type=button value="7h" onclick="seteffort(420);" style="width:25px">
<input type=button value="8h" onclick="seteffort(480);" style="width:25px">
</td>
</tr>
<tr>
<td class=fname width=20%>%affectedapplication(label)%:</td>
<td class=finput>%affectedapplication(detail)%</td>
</tr>
<tr>
<td colspan=2 style="padding-left:5px">
$m1
</tr>
</table>
<script language="JavaScript">
function seteffort(min)
{
   var o=document.forms[0].elements["Formated_effort"];
   if (o){
      for(i=0;i<o.options.length;i++){
         if (o.options[i].value==min){
            o.options[i].selected=true;
         }
         else{
            o.options[i].selected=false;
         }
      }
   }
}
setFocus("Formated_fwdtargetname");
setEnterSubmit(document.forms[0],"NextStep");
</script>
EOF
   return($templ);
}

sub preValidate                 # das muß in preValidate behandelt werden,
{                               # da später noch die KeyHandler beeinflußt
   my $self=shift;              # werden
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   return($self->SUPER::Validate($oldrec,$newrec,$origrec));
}


sub ProcessNext                
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   #
   # check application
   #
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
   ########################################################################

   #
   # check effort
   #
   my $effort=Query->Param("Formated_effort");
   if ($effort<=0 || $effort>480){
      $self->LastMsg(ERROR,"invalid effort");
      return(0);
   }
   #
   # check description
   #
   my $description=Query->Param("Formated_detaildescription");
   if ($description=~m/^\s*$/ || length($description)<10){
      $self->LastMsg(ERROR,"invalid or to short description");
      return(0);
   }
   #
   # check tcomcodcause
   #
   my $tcomcodcause=Query->Param("Formated_tcomcodcause");
   my $tcomcodrelevant=Query->Param("Formated_tcomcodrelevant");
   if ($tcomcodcause=~m/^\s*$/ ||
       ($tcomcodrelevant eq "yes" && $tcomcodcause eq "undef")){
      $self->LastMsg(ERROR,"invalid activity selected");
      return(0);
   }



   #
   # create or update workflow
   #
   my $wf=$self->getParent->getParent();
   my $h=$self->getWriteRequestHash("web");
   if (ref($h->{affectedapplication}) eq "ARRAY" && 
       $#{$h->{affectedapplication}}==0){
      $h->{affectedapplication}=$h->{affectedapplication}->[0];
      $h->{stateid}=4;
      $h->{class}="AL_TCom::workflow::diary";
      $h->{step}="AL_TCom::workflow::diary::dataload";
      my $entrytime=$self->getParent->getParent->ExpandTimeExpression("now");
      #my ($year,$month)=$entrytime=~m/^(\d+)-(\d+)-/;
      #my $mstr="$month/$year";
      #my $evstart=$self->getParent->getParent->ExpandTimeExpression($mstr);
      #my $evend=$self->getParent->getParent->ExpandTimeExpression($mstr.
      #                                                            "+1M-1s");
      $h->{eventstart}=$entrytime;
      $h->{eventend}=$entrytime;
      my $applrec={};
      {
         my $applobj=getModuleObject($self->Config,"itil::appl");
         $applobj->SetFilter({cistatusid=>"<=4",
                              name=>\$h->{affectedapplication}});
         my $msg;
         ($applrec,$msg)=$applobj->getOnlyFirst(qw(id tsmid tsm2id 
                                                         semid sem2id));
      }
      my ($oldrec,$msg);
      if (defined($applrec)){
         my $id=$wf->Store(undef,$h);
         if (defined($id) && $id ne ""){
            $wf->SetFilter({id=>\$id});
            ($oldrec,$msg)=$wf->getOnlyFirst(qw(ALL));
         }
      }

      if (defined($oldrec)){
         my $tcomworktime=$oldrec->{tcomworktime};
         $tcomworktime+=$effort;
         if ($self->getParent->getParent->Action->StoreRecord(
             $oldrec->{id},"note",
             {translation=>'base::workflow::diary'},$description,$effort)){
            my $id=$wf->Store($oldrec,{
                            step=>"AL_TCom::workflow::diary::wfclose",
                            tcomworktime=>$tcomworktime,
                            stateid=>17});
            my $c=$self->getParent->Context();
            $c->{InsertId}=$oldrec->{id};
            my $userid=$self->getParent->getParent->getCurrentUserId();
            if ($userid==$applrec->{tsmid}  ||
                $userid==$applrec->{tsm2id} ||
                $userid==$applrec->{semid}  ||
                $userid==$applrec->{sem2id} ){
               my $id=$wf->Store($oldrec,{
                               step=>"base::workflow::diary::wffinish",
                               fwdtarget=>undef,
                               fwdtargetid=>undef,
                               fwddebtarget=>undef,
                               fwddebtargetid=>undef,
                               stateid=>21});
            }
         }
      }
      else{
         $self->LastMsg(ERROR,"can't create workflow");
         return(0);
      }
   }
   else{
      $self->LastMsg(ERROR,"unexpected data request");
      return(0);
   }

   my $nextstep=$self->getParent->getNextStep($self->Self(),$WfRec);
   if (defined($nextstep)){
      Query->Param("WorkflowStep"=>$nextstep);
      return(0);
   }
   return(0);
}



sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(330);
}


#######################################################################
package AL_TCom::workflow::fastdiary::dataloadok;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my @steplist=Query->Param("WorkflowStep");
   pop(@steplist);
   my $StoredWorkspace=$self->SUPER::generateStoredWorkspace($WfRec,@steplist);
   my $l1=$self->T("Worktime");
   my $m1=$self->T("MSG");
   $m1="" if ($m1 eq "MSG");

   my $c=$self->getParent->Context();
   my $id=$c->{InsertId};

   my $templ="<br><center><b>".$self->T("OK entry appended")."</b>";
   if (defined($id)){
      my $dest="../../base/workflow/ById/$id";
      my $detailx=$self->getParent->getParent->DetailX();
      my $detaily=$self->getParent->getParent->DetailY();

      $templ.=" (<a href=\"$dest\" target=WF$id>$id</a>)";
   }
   $templ.="</center>";
   return($templ);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   return($self->SUPER::Validate($oldrec,$newrec,$origrec));
}

sub ProcessNext                
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $nextstep=$self->getParent->getNextStep($self->Self(),$WfRec);
   if (defined($nextstep)){
      Query->Param("WorkflowStep"=>$nextstep);
      return(0);
   }
   return($self->SUPER::ProcessNext($action,$WfRec,$actions));
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(70);
}

sub CreateSubTip
{
   my $self=shift;
   return("");
}





1;
