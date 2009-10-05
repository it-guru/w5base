package tssc::mgr;
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
use kernel::App::Web;
use kernel::App::Web::Listedit;
use kernel::Field;
use kernel::TemplateParsing;
use tssc::lib::io;
@ISA=qw(kernel::App::Web  kernel::TemplateParsing tssc::lib::io);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}


sub getValidWebFunctions
{
   my $self=shift;
   return("Main","addAttach",
          $self->SUPER::getValidWebFunctions());
}

sub addAttach
{
   my $self=shift;
   return($self->kernel::App::Web::Listedit::addAttach());
}



sub Main
{
   my $self=shift;

   my $userid=$self->getCurrentUserId();
   my $user=getModuleObject($self->Config,"base::user");
   $user->SetFilter({userid=>\$userid});
   my ($urec,$msg)=$user->getOnlyFirst(qw(posix));
   my $posix=uc($urec->{posix});


   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css',],
                           title=>'W5Base ServiceCenter Manager',
                           submodal=>1,
                           js=>[qw( toolbox.js)],
                           body=>1,form=>1);
   print $self->HtmlSubModalDiv();
   my $appline=sprintf("<tr><td height=1%% style=\"padding:1px\" ".
                       "valign=top>%s</td></tr>",$self->getAppTitleBar());

   my %opNames=('NewApplIncident'=>{url=>'../inm/Process?'},
                'MyIncidentMgr'  =>{url=>'../inm/Manager?'},
                'MyIncidentList' =>{url=>"../inm/NativResult?".
                                         "search_openedby=$posix&".
                                         "search_status=!closed&".
                                         "AutoSearch=1&"});
   my $jsOPlocator="";
   foreach my $k (keys(%opNames)){
      my $url=$opNames{$k}->{url};
      $jsOPlocator.="if (e.id=='$k' || e=='$k'){\n".
                    "   frames['work'].document.location.href=\"$url\";\n".
                    "   directLink.href=\"Main?OP=$k\";\n".
                    "   document.forms[0].elements['OP'].value='$k';".
                    "}\n";
   }

   print <<EOF;
<style>
body{
   overflow:hidden;
}
</style>
<script language="JavaScript">
function showWork(e)
{
   var directLink=document.getElementById("directLink");
   if (e.id=='Restart' || e=='Restart'){
      if (document.forms[0].elements['OP'].value==''){
         document.forms[0].elements['OP'].value='MyIncidentMgr';
      }
      document.forms[0].submit();
   }
   $jsOPlocator
}


function doOP(o,op,form,e)
{
   var param="";
   var l=document.getElementById("loading");


   if (e.running==1){
      alert("ERROR: other SC operation already running");
      return;
   }
   e.running=1;
   o.disabled="disabled";

   e.innerHTML=l.innerHTML;
   param+="&SCUsername="+encodeURI(document.getElementById("SCUsername").value);
   param+="&SCPassword="+encodeURI(document.getElementById("SCPassword").value);
   param+="&OP="+encodeURI(op);
   if (op!="Login"){
      if (form){
         for(c=0;c<form.elements.length;c++){
            if (form.elements[c].name!="OP"){
               param+="&"+form.elements[c].name+"="+
               encodeURIComponent(form.elements[c].value);
            }
         }
      }
   }
   var xmlhttp=getXMLHttpRequest();
   xmlhttp.open("POST","../inm/Process",true);
   xmlhttp.onreadystatechange=function() {
    if (xmlhttp.readyState==4 && 
        (xmlhttp.status==200 || xmlhttp.status==304)){
       var xmlobject = xmlhttp.responseXML;
       var result=xmlobject.getElementsByTagName("htmlresult");

       var d="";
       for (var i = 0; i < result.length; ++i){
           var childNode=result[i].childNodes[0];
           if (childNode){
              d+=childNode.nodeValue;
           }
       }
       e.innerHTML=d;
       o.disabled="";
       var result=xmlobject.getElementsByTagName("javascript");

       var d="";
       for (var i = 0; i < result.length; ++i){
           var childNode=result[i].childNodes[0];
           if (childNode){
              d+=childNode.nodeValue;
           }
       }
       eval(d);
       e.running=0;
    }
   }
   xmlhttp.setRequestHeader("Content-type","application/x-www-form-urlencoded");
   xmlhttp.setRequestHeader("Content-length",param.length);
   xmlhttp.setRequestHeader("Connection","close");

   var r=xmlhttp.send(param);
}
</script>
EOF
   my $SCUsername=Query->Param("SCUsername");
   my $SCPassword=Query->Param("SCPassword");
   my $showWork="../inm/Manager";
   if (my $k=Query->Param("showWork")){
      Query->Delete("showWork");
      $showWork=$opNames{$k}->{'url'};
   }
   if (my $k=Query->Param("OP")){
      Query->Delete("OP");
      $showWork=$opNames{$k}->{'url'};
   }
   my %cgi;
   foreach my $k (Query->Param()){
      $cgi{$k}=[Query->Param($k)] if (uc($k) ne $k);
   }
   my $q=new kernel::cgi(\%cgi);
   my $urlparam=$q->QueryString();

   $showWork.=$urlparam;
   print <<EOF;
<table width=100% height=100% border=0 cellspacing=0 cellpadding=0>
$appline
<tr height=1%><td>
<div id=loading style=\"width:0px;height:0px;padding:0px;margin:0px;overflow:hidden;postion:absolute;visibility:hidden;display:none">
<center><img src="../../base/load/ajaxloader.gif"></center>
</div>
<div style="margin-left:5px;margin-right:5px;padding-bottom:4px;border-bottom-style:solid;border-width:1px;border-color:darkblue">
<table border=0 cellspacing=0 cellpadding=0>
<tr>
<td width=1% nowrap>ServiceCenter SCUsername:</td>
<td width=1%><input type=text id=SCUsername name=SCUsername
                    value="$SCUsername"></td>
<td width=1% nowrap>SCPassword:</td>
<td width=1%><input type=password id=SCPassword name=SCPassword
                    value="$SCPassword"></td>
<td>&nbsp;</td>
<td width=1% align=right><input type=button onclick="showWork(this);" 
                    id=Restart name=Restart value="Restart"></td>
<td width=20 align=right>
<a id=directLink href="Main" target=_blank><img border=0 style="margin:4px;margin-left:8px" src="../../../public/base/load/listweblink.gif"></a>
</td>
</tr>
</table>
</div>
</td></tr>
<tr height=1%><td>
<div style="margin:5px">
<input id=NewApplIncident class=opbutton type=button onclick="showWork(this);"
       value="New Application Incident">
<input id=MyIncidentList  class=opbutton type=button onclick="showWork(this);"
       value="list Incidents created by me">
<input id=MyIncidentMgr  class=opbutton type=button onclick="showWork(this);"
       value="Incident Manager">
</div>
</td></tr>
<tr><td align=center><iframe name=work class=subframe src="$showWork"></iframe></td></tr>
<tr height=1%><td>
<div style="padding:5px;height:50px;overflow:auto" id=result>
W5Base/Darwin stellt ein Kern-Set an Funktionen zur Bedienung von
ServiceCenter zur Verfügung. Sollten Sie Transaktionen in ServiceCenter
durchführen wollen, die über die W5Base/Darwin Oberfläche nicht möglich
sind, so nutzen Sie bitte dafür dann den "normalen" ServiceCenter Client!
</div>
</td></tr>
</table>
<input type=hidden name=OP>
EOF
   print $self->HtmlBottom(body=>1,form=>1);
}


1;
