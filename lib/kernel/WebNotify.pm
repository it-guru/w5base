package kernel::WebNotify;
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
#
use vars qw(@ISA);
use strict;
use kernel;
use kernel::Plugable;

@ISA=qw(kernel::Plugable);

sub new
{
   my $type=shift;
   my $self=bless({@_},$type);
   return($self);
}


sub Validate
{
   my $self=shift;
   my $data=shift;

#   $self->LastMsg(WARN,"Hallo");
   return(1)
}


sub getQueryForm
{
   my $self=shift;
   my $data=shift;

   my $bb;
   $bb="<table width=\"100%\" height=250 border=1>";
   $bb.="<tr height=1%><td>Notify based on:</td></tr>";
   $bb.="<tr height=1%><td><textarea rows=3 name=sendBaseData ".
        "style='width:100%'>".
        $data->{sendBaseData}."</textarea></td></tr>";
   $bb.="<tr height=1%><td><b>Message text:</b></td></tr>";
   $bb.="<tr><td><textarea name=messageText ".
        "style='width:100%;height:100%'>".
        $data->{messageText}."</textarea></td></tr>";
   $bb.="<tr height=1%><td>Bla bla infotext</td></tr>";
   $bb.="</table>";
   return($bb);
}



sub getQueryTemplate
{
   my $self=shift;
   my %data=Query->MultiVars();
   my $valid=0;
   if (Query->Param("ForceLevel")==1){
      $valid=$self->Validate(\%data);
   }
   my ($target,$action)=$self->getParent->getOperationTarget();
   my $lastmsg="&nbsp;";
   my $bb=$self->getQueryForm(\%data);
   if ($self->LastMsg()){
      $lastmsg=$self->getParent->findtemplvar({},"LASTMSG");
   }
   $bb.=<<EOF;
<script language="JavaScript">
function doSend(){
   document.forms[0].elements['ForceLevel'].value='1';
   document.forms[0].target="$target";
   document.forms[0].action="$action";
   document.forms[0].submit();
}
</script>
<input type=hidden name=ForceLevel value="">
<table width="100%"><tr>
<td align=left>$lastmsg</td>
<td align=right width=1%>
<input type=button onclick='doSend();' value='senden'>
</td></tr></table>
EOF
   if ($valid){
      if (Query->Param("ForceLevel")==1){
         $bb.=<<EOF;
<script language="JavaScript">
addEvent(window, "load",function (){
   if (confirm("Sind Sie sicher, dass Sie die eingegebene Benachrichtung versenden möchten?")){
      document.forms[0].elements['ForceLevel'].value='2';
      document.forms[0].target="Result";
      document.forms[0].action="Result";
      document.forms[0].submit();
   }
});

</script>
EOF
      }
   }
   return($bb);
}

sub doAutoSearch
{
   my $self=shift;
   return(0);
}

sub submitOnEnter
{
   my $self=shift;

   return(0);
}


sub preResult
{
   my $self=shift;
   my $data=shift;

   return(1);
}


sub Result
{
   my $self=shift;
   my $data=shift;

   if ($self->preResult($data)){
      if (Query->Param("ForceLevel")==2){
         my $wfa=getModuleObject($self->Config,"base::workflowaction");
         my %p=(emailfrom=>$data->{messageFrom},
                emailto=>$data->{messageTo},
                emailcc=>$data->{messageCc},
                emailbcc=>$data->{messageBcc});
         if ($data->{messageSMS} ne ""){
            $p{allowsms}=1;
         }
         if ($data->{messageLayout} ne ""){
            $p{emailtemplate}=$data->{messageLayout};
         }
         $wfa->Notify("",$data->{messageSubject},$data->{messageText},%p);
         $self->LastMsg(OK,"your message has been successfully sent");
      }
      $self->sendResultFromLastMsg();
   }

   return(1);
}

sub getDefaultOptionLine
{
   my $self=shift;
   my $data=shift;
   my %param=@_;

   $param{sms}=1 if (!exists($param{sms}));
   $param{layout}=1 if (!exists($param{layout}));
   $param{info}=1 if (!exists($param{info}));

   my $bb;

   $bb.="\n<table width=\"100%\" border=1>\n";
   $bb.="<tr>\n";
   $bb.="<td valign=top>".$self->getParent->T("INFOTEXT",$self->Self)."</td>";


   $bb.="<td nowrap>\n";

   my $sl="<select name='messageLayout'>";
   foreach my $opt (qw(sendmail sendmailnativ)){
      $sl.="<option value='$opt'";
      $sl.=" selected" if ($opt eq $data->{messageLayout});
      $sl.=">".$opt."</option>";
   }
   $sl.="</select>";

   my $sms="<input type=checkbox name=messageSMS";
   my $SMSIfScript=$self->getParent->Config->Param("SMSInterfaceScript");
   msg(INFO,"SMSInterfaceScript=$SMSIfScript");
   if ($SMSIfScript eq ""){
      $sms.=" disabled=true";
   }
   else{
      if ($data->{messageSMS} ne ""){
         $sms.=" checked";
      }
   }
   $sms.=">";

   my $smsact=$self->getParent->T("SMS activate",$self->Self);

   $bb.="<table width=220 border=0 ".
        "style='background-color:silver;padding-left:5px;padding-right:5px;".
        "padding-top:2px;padding-bottom:2px' ".
        "cellspacing=0 cellpadding=0>";
   $bb.="<tr>";
   $bb.="<td nowrap>Mail-Layout:</td>";
   $bb.="<td nowrap>$sl</td>";
   $bb.="</tr>";
   $bb.="<tr>";
   $bb.="<td nowrap>$smsact:</td>";
   $bb.="<td nowrap>$sms</td>";
   $bb.="</tr>";
   $bb.="</table>";

   $bb.="</td></tr>\n";
   $bb.="</table>\n";

   return($bb);
}



1;

