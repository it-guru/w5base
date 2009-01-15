package itil::workflow::businesreq;
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

sub Init
{
   my $self=shift;
   $self->AddGroup("customerdata",translation=>'itil::workflow::businesreq');
   return($self->SUPER::Init(@_));
}

sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;

   return($self->InitFields(
      new kernel::Field::Select(  name       =>'reqnature',
                                  label      =>'Request nature',
                                  group      =>'customerdata',
                                  htmleditwidth=>'60%',
                                  getPostibleValues=>\&XgetRequestNatureOptions,
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
      new kernel::Field::Text(    name       =>'customerrefno',
                                  htmleditwidth=>'100px',
                                  group      =>'customerdata',
                                  translation=>'itil::workflow::businesreq',
                                  searchable =>0,
                                  container  =>'headref',
                                  label      =>'Reference'),
    ),$self->SUPER::getDynamicFields(%param));
}

sub XgetRequestNatureOptions
{
   my $self=shift;
   return($self->getParent->getRequestNatureOptions());
}
sub getRequestNatureOptions
{
   my $self=shift;
   my $vv=['operation','project','modification','other'];
   my @l;
   foreach my $v (@$vv){
      push(@l,$v,$v);
   }
   return(@l);
}


sub getDefaultContractor
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $target;
   my $flt;

   if (defined($WfRec->{affectedapplication})){
      my $applname=$WfRec->{affectedapplication};
      if (ref($applname) eq "ARRAY"){
         $flt={name=>\$applname->[0]};
      } 
      else{
         $flt={name=>\$applname};
      }
   }
   if (defined($WfRec->{affectedapplicationid})){
      my $applid=$WfRec->{affectedapplicationid};
      if (ref($applid) eq "ARRAY"){
         $flt={id=>\$applid->[0]};
      } 
      else{
         $flt={id=>\$applid};
      }
   }
   my @devcon;
   if (defined($flt)){
      my $appl=getModuleObject($self->getParent->Config,"itil::appl");
      $appl->SetFilter($flt);
      my ($cur,$msg)=$appl->getOnlyFirst(qw(allowbusinesreq contacts id name));
      if (defined($cur) && defined($cur->{contacts})){
         if (!defined($WfRec->{affectedapplicationid})){
            $WfRec->{affectedapplicationid}=$cur->{id};
         }
         if (!defined($WfRec->{affectedapplication})){
            $WfRec->{affectedapplication}=$cur->{name};
         }
         my $c=$cur->{contacts};
         if (ref($c) eq "ARRAY"){
            foreach my $con (@$c){
               my $roles=$con->{roles};
               $roles=[$roles] if (ref($roles) ne "ARRAY");
               if (grep(/^orderin1$/,@$roles)){
                  unshift(@devcon,{target=>$con->{target},
                                   targetid=>$con->{targetid}});
               } 
               if (grep(/^orderin2$/,@$roles) ||
                   grep(/^businessemployee$/,@$roles)){
                  push(@devcon,{target=>$con->{target},
                                targetid=>$con->{targetid}});
               } 
            }
         }
         if (!$cur->{allowbusinesreq}){
            $self->LastMsg(ERROR,"business requests are disabled ".
                                 "for the desired application");
            return(undef);
         }
      }
   }
   else{
      $self->LastMsg(ERROR,"no reference to related application specified");
      return(undef);
   }
   if ($#devcon==-1){
      $self->LastMsg(ERROR,"no orderin found");
      return(undef);
   }
   return(undef,map({$_->{target},$_->{targetid}} @devcon));
}


sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   if ($shortname eq "dataload"){
      return("itil::workflow::businesreq::".$shortname);
   }
   return($self->SUPER::getStepByShortname($shortname,$WfRec));
}

sub isViewValid
{
   my $self=shift;
   return($self->SUPER::isViewValid(@_),"customerdata");
}

sub getDetailBlockPriority            # posibility to change the block order
{
   return("customerdata","init","flow");
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/workflow_appl.jpg?".$cgi->query_string());
}





#######################################################################
package itil::workflow::businesreq::dataload;
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
   my $checknoautoassign;
   if (Query->Param("Formated_noautoassign") ne ""){
      $checknoautoassign="checked";
   }

   my $nextstart=$self->getParent->getParent->T("NEXTSTART","base::workflow");
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
<tr>
<td class=fname>%reqnature(label)%:</td>
<td colspan=3 class=finput>%reqnature(detail)%</td>
</tr>
<script language="JavaScript">
setFocus("Formated_name");
setEnterSubmit(document.forms[0],"NextStep");
</script>
<tr>
<td class=fname width=20%>%prio(label)%:</td>
<td width=80 class=finput>$d</td>
<td class=fname width=20%>Workflow NICHT automatisch der Bearbeitung zuführen</td>
<td class=finput><input $checknoautoassign name=Formated_noautoassign type=checkbox></td>
</tr>
<tr>
<td class=fname>%customerrefno(label)%:</td>
<td colspan=3 class=finput>%customerrefno(detail)%</td>
</tr>
<tr>
<td class=fname>%forceinitiatorgroupid(label)%:</td>
<td colspan=3 class=finput>%forceinitiatorgroupid(detail)%</td>
</tr>
<tr>
<td colspan=4 align=center><br>$nextstart</td>
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
      my $appl=getModuleObject($self->Config,"itil::appl");
      $appl->SetFilter({id=>$aid});
      my %conumber;
      foreach my $arec ($appl->getHashList(qw(conumber))){
         $conumber{$arec->{conumber}}++ if ($arec->{conumber} ne "");
         $found++;
      }
      if (keys(%conumber)){
         $newrec->{conumber}=[keys(%conumber)];
      }
   }
   if ($found!=1){
      $self->LastMsg(ERROR,"no application found in request");
      return(0);
   }
   
   return($self->SUPER::Validate(@_));

}







sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("320");
}

1;
