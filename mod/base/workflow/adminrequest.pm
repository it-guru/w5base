package base::workflow::adminrequest;
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
@ISA=qw(base::workflow::request);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{ITIL_installed}=0;

   my $i=getModuleObject($self->Config,"itil::appl");
   if (defined($i)){
      $self->{ITIL_installed}=1;
      $self->AddFrontendFields(
         new kernel::Field::TextDrop(
                   name          =>'newaffectedapplication',
                   label         =>'Application name',
                   htmldetail    =>0,
                   translation   =>'itil::appl',
                   group         =>'init',
                   vjointo       =>'itil::appl',
                   vjoineditbase =>{'cistatusid'=>[3,4]},
                   vjoinon       =>['newaffectedapplicationid'=>'id'],
                   vjoindisp     =>'name'),
     
         new kernel::Field::Link (
                   name          =>'newaffectedapplicationid',
                   container     =>'headref'),
       );
   }

   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (!defined($oldrec) && length($newrec->{detaildescription})<10){
      $self->LastMsg(ERROR,"invalid request description");
      return(0); 
   }
   return($self->SUPER::Validate($oldrec,$newrec,$origrec));
}




sub IsModuleSelectable
{
   my $self=shift;
   my %env=@_;

   return(1);
}

sub getDefaultContractor
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   return('admin','base::grp','1');
}

sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;
   my $app=$self->getParent;
   my $userid=$self->getParent->getCurrentUserId();
   my $isadmin=$self->getParent->IsMemberOf("admin");
   my $stateid=$WfRec->{stateid};

   my @actions=$self->SUPER::getPosibleActions($WfRec);
   if ($isadmin){
      push(@actions,"wftrans2devreq");
   }

   return(@actions);
}


sub getPosibleWorkflowDerivations
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my @l;

   if ($WfRec->{stateid}<16 && $self->isCurrentForward($WfRec)){
      push(@l,
         {label=>$self->T('Initiate quotation request to developer'),
          actor=>sub{
             my $self=shift;
             my $WfRec=shift;

             return({
                targeturl=>'New',
                targetparam=>{
                  Formated_name=>$WfRec->{name},
                  Formated_quotationdetaildescription=>
                                 $WfRec->{detaildescription},
                  Formated_reqnature=>'RAppl.developer',
                  Formated_affectedapplication=>"w5base",
                  WorkflowClass=>'itil::workflow::quotation'
                }
             });
          },
          name=>'invoicerequest'
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
                  Formated_affectedapplication=>"w5base",
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






sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   if ($shortname eq "dataload"){
      return("base::workflow::adminrequest::".$shortname);
   }
   if ($shortname eq "main"){
      return("base::workflow::adminrequest::".$shortname);
   }
   return("base::workflow::request::".$shortname);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/workflow_admin.jpg?".$cgi->query_string());
}


#######################################################################
package base::workflow::adminrequest::dataload;
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
   my $d="<select name=Formated_prio>";
   my @l=("high"=>3,"normal"=>5,"low"=>8);
   while(my $n=shift(@l)){
      my $i=shift(@l);
      $d.="<option value=\"$i\"";
      $d.=" selected" if ($i==$oldval);
      $d.=">".$self->T($n,"base::workflow")."</option>";
   }
   $d.="</select>";


   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width="100%">
<tr>
<td class=fname width=20%>%name(label)%:</td>
<td class=finput>%name(detail)%</td>
</tr>
<tr>
<td class=fname valign=top width=20%>%detaildescription(label)%:</td>
<td class=finput>%detaildescription(detail)%</td>
</tr>
<tr>
<td class=fname width=20%>%prio(label)%:</td>
<td class=finput>$d</td>
</tr>
</table>
EOF
   return($templ);
}

sub addInitialParameters
{
   my $self=shift;
   my $newrec=shift;
   my $conumber=$self->getParent->Config->Param("W5BASEADMINCONUMBER");
   if ($conumber ne ""){
      my $co=getModuleObject($self->getParent->Config,"finance::costcenter");
      if (defined($co)){
         $co->SetFilter({name=>\$conumber,cistatusid=>\'4'});
         my ($corec)=$co->getOnlyFirst(qw(id));
         if (!defined($corec)){
            $self->getParent->LastMsg(ERROR,
             "invalid CO-Number for admin requests - please contact the admin");
            return(0);
         }
         $newrec->{conumber}=$conumber;
      }
   }
   return(1);
}




sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("200");
}


#######################################################################
package base::workflow::adminrequest::main;
use vars qw(@ISA);
use kernel;
@ISA=qw(base::workflow::request::main);


sub generateWorkspacePages
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $divset=shift;
   my $selopt=shift;
   my $tr="base::workflow::adminrequest";
   my $class="display:none;visibility:hidden";

   my $bk=$self->SUPER::generateWorkspacePages($WfRec,$actions,$divset,$selopt);
   if ($self->getParent->{ITIL_installed}){
      if (grep(/^wftrans2devreq$/,@$actions)){
         $$selopt.="<option value=\"wftrans2devreq\">".
                   $self->getParent->T("wftrans2devreq",$tr).
                   "</option>\n";
         my $d="<table width=\"100%\" border=0 cellspacing=0 cellpadding=0>".
               "<tr>".
               "<td colspan=2>Umwandeln in einen Entwickler-Request ".
               "für folgende Anwendung</td>".
               "</tr>".
               "<tr>".
               "<td width=15%>\%newaffectedapplication(label)\%: </td>".
               "<td>\%newaffectedapplication(detail)\%</td>".
               "</tr>".
               "<tr>".
               "<td colspan=2>".
               $self->getDefaultNoteDiv($WfRec,$actions,
                                        mode=>'native',height=>60).
               "</td>".
               "</tr>";
         $d.="</table>";
         $$divset.="<div id=OPwftrans2devreq class=\"$class\">$d</div>";
      }
   }

   return($bk);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $userid=$self->getParent->getParent->getCurrentUserId();

   if ($action eq "SaveStep"){
      my $op=Query->Param("OP");
      if ($op eq "wftrans2devreq"){
         my $fname="newaffectedapplication";
         my $fobj=$self->getParent->getField($fname);
         my $f=Query->Param("Formated_$fname");

         my $new1;
         my $applid;
         if ($new1=$fobj->Validate($WfRec,{$fname=>$f})){
            if (!defined($new1->{"${fname}id"}) ||
                $new1->{"${fname}id"}==0){
               if ($self->LastMsg()==0){
                  $self->LastMsg(ERROR,"invalid application selected");
               }
               return(0);
            }
            $applid=$new1->{"${fname}id"};
         }
         else{
            return(0);
         }
         my $appl=Query->Param("Formated_$fname");
         my $note=Query->Param("note");
         if ($note ne ""){
            $note="==>".$appl."\n\n".$note;
         }
         else{
            $note="==>".$appl;
         }
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"transform",
             {translation=>'base::workflow::request'},$note)){
            my $newWfRec={name                  =>$WfRec->{name},
               class                 =>"itil::workflow::devrequest",
               step                  =>"itil::workflow::devrequest::dataload",
               stateid               =>$WfRec->{stateid},
               reqnature             =>'other',
               affectedapplication   =>$appl,
               openuser              =>$WfRec->{openuser},
               mdate                 =>$WfRec->{mdate},
               openusername          =>$WfRec->{openusername},
               affectedapplicationid =>$applid,
               detaildescription     =>$WfRec->{detaildescription},
               initiatorid           =>$WfRec->{initiatorid},
               initiatorgroupid      =>$WfRec->{initiatorgroupid},
               implementedto         =>$WfRec->{implementedto},
               initiatorcomments     =>$WfRec->{initiatorcomments},
               eventstart            =>$WfRec->{eventstart}};
            my $oldcontext=$W5V2::OperationContext;
            $W5V2::OperationContext="Kernel";
            my $wf=$self->getParent->getParent;
            $wf->nativProcess("NextStep",$newWfRec);
            $W5V2::OperationContext=$oldcontext;
            if (defined($newWfRec->{id})){
               my $wr=$wf->getPersistentModuleObject("base::workflowrelation");
               my $srcid=$WfRec->{id};
               my $dstid=$newWfRec->{id};
               $wr->ValidatedInsertOrUpdateRecord(
                                      {srcwfid=>$srcid,dstwfid=>$dstid},
                                      {srcwfid=>\$srcid,dstwfid=>\$dstid});
               my $store={stateid=>25,
                          step=>"base::workflow::request::break",
                          fwdtargetid=>undef,
                          fwdtarget=>undef,
                          closedate=>NowStamp("en"),
                          eventend=>NowStamp("en"),
                          fwddebtarget=>undef,
                          fwddebtargetid=>undef};
               if ($self->StoreRecord($WfRec,$store)){
                  return(0);
               }
            }
            if ($self->LastMsg()==0){
               $self->LastMsg(ERROR,"problem while tranformation");
            }
            return(0);
         }



         $self->LastMsg(ERROR,"action not implemented");

         return(0);
      }
  }



   return($self->SUPER::Process($action,$WfRec,$actions));
}



1;
