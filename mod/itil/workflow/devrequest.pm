package itil::workflow::devrequest;
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
   return($self);
}

sub IsModuleSelectable
{
   my $self=shift;
   my %env=@_;

   return(1);
}

sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;

   return($self->InitFields(
      new kernel::Field::Select(  name       =>'reqnature',
                                  label      =>'Request nature',
                                  htmleditwidth=>'60%',
                                  value      =>['feature request',
                                                'bugfix',
                                                'functional modification',
                                                'other'],
                                  container  =>'headref'),

      new kernel::Field::KeyText( name       =>'affectedapplication',
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
                                  label      =>'Affected Application'),
      new kernel::Field::KeyText( name       =>'affectedapplicationid',
                                  htmldetail =>0,
                                  translation=>'itil::workflow::base',
                                  searchable =>0,
                                  keyhandler =>'kh',
                                  container  =>'headref',
                                  label      =>'Affected Application ID'),
    ),$self->SUPER::getDynamicFields(%param));
}


sub getDefaultContractor
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $applid;
   my $target;
   if (defined($WfRec->{affectedapplicationid})){
      $applid=$WfRec->{affectedapplicationid};
      $applid=$applid->[0] if (ref($applid) eq "ARRAY");
   }
   my @devcon;
   if (defined($applid)){
      my $appl=getModuleObject($self->getParent->Config,"itil::appl");
      $appl->SetFilter({id=>\$applid});
      my ($cur,$msg)=$appl->getOnlyFirst(qw(allowdevrequest contacts));
      if (defined($cur) && defined($cur->{contacts})){
         my $c=$cur->{contacts};
         if (ref($c) eq "ARRAY"){
            foreach my $con (@$c){
               my $roles=$con->{roles};
               $roles=[$roles] if (ref($roles) ne "ARRAY");
               if (grep(/^developerboss$/,@$roles)){
                  unshift(@devcon,{target=>$con->{target},
                                   targetid=>$con->{targetid}});
               }
               if (grep(/^developer$/,@$roles)){
                  push(@devcon,{target=>$con->{target},
                                targetid=>$con->{targetid}});
               } 
            }
         }
         if (!$cur->{allowdevrequest}){
            $self->LastMsg(ERROR,"developer requests are disabled ".
                                 "for the desired application");
            return(undef);
         }
      }
   }
   if ($#devcon==-1){
      $self->LastMsg(ERROR,"no developer found");
      return(undef);
   }
   return(undef,$devcon[0]->{target},$devcon[0]->{targetid},
                $devcon[1]->{target},$devcon[1]->{targetid});
}


sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   if ($shortname eq "dataload"){
      return("itil::workflow::devrequest::".$shortname);
   }
   return($self->SUPER::getStepByShortname($shortname,$WfRec));
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/workflow_dev.jpg?".$cgi->query_string());
}



#######################################################################
package itil::workflow::devrequest::dataload;
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

   my $nextstart=$self->getParent->getParent->T("NEXTSTART","base::workflow");
   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr>
<td class=fname width=20%>%name(label)%:</td>
<td class=finput>%name(detail)%</td>
</tr>
<tr>
<td class=fname valign=top width=20%>%detaildescription(label)%:</td>
<td class=finput>%detaildescription(detail)%</td>
</tr>
<tr>
<td class=fname>%affectedapplication(label)%:</td>
<td class=finput>%affectedapplication(detail)%</td>
</tr>
<tr>
<td class=fname>%reqnature(label)%:</td>
<td class=finput>%reqnature(detail)%</td>
</tr>
<script language="JavaScript">
setFocus("Formated_name");
setEnterSubmit(document.forms[0],"NextStep");
</script>
<tr>
<td class=fname width=20%>%prio(label)%:</td>
<td class=finput>$d</td>
</tr>
<tr>
<td class=fname>%forceinitiatorgroupid(label)%:</td>
<td class=finput>%forceinitiatorgroupid(detail)%</td>
</tr>
<tr>
<td colspan=2 align=center><br>$nextstart</td>
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
   }
   return($self->SUPER::Process($action,$WfRec,$actions));
}







sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("300");
}

1;
