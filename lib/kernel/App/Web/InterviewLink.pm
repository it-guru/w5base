package kernel::App::Web::InterviewLink;
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

sub HtmlInterviewLink
{
   my ($self)=@_;
   my $idname=$self->IdField()->Name();
   my $id=Query->Param($idname);
   my $queryblock=Query->Param("queryblock");
   my $archiv=Query->Param("archiv");
   $self->ResetFilter();
   $self->SetFilter({$idname=>\$id});
   my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));
   if (defined($rec)){
      if ($queryblock eq ""){ 
         print $self->HttpHeader();
         print $self->HtmlHeader(body=>1,
                                 js=>'toolbox.js',
                                 style=>['default.css','work.css',
                                         'Output.HtmlDetail.css',
                                         'kernel.App.Web.css',
                                         'kernel.App.Web.Interview.css']);
         printf("<input type=hidden name=$idname value=\"%s\">",$id);
         printf("<input type=hidden id=parentid value=\"%s\">",$id);
         printf("<input type=hidden id=parentobj value=\"%s\">",
                $self->SelfAsParentObject);
         print $self->InterviewMainForm($rec,$idname,$id);
         print $self->HtmlBottom(body=>1);
      }
      else{
         $self->InterviewSubForm($rec,$queryblock);
      }
   }
}

sub InterviewSubForm
{
   my $self=shift;
   my $rec=shift;
   my $queryblock=shift;
   my $state=$rec->{interviewst};

   my $lastquestclust;
   my @q;
   foreach my $qrec (@{$state->{TotalActiveQuestions}}){
      my $d;
      if ($queryblock eq $qrec->{queryblock}){
         if ($lastquestclust ne $qrec->{questclust}){
            $d.="<div class=InterviewQuestClust>$qrec->{questclust}</div>";
            $d.="\n<div class=InterviewQuestHead>".
                "<table border=0 class=InterviewQuestHead width=95%>".
                "<tr><td class=InterviewQuestHead></td>".
                "<td class=InterviewQuestHead width=50 align=center>".
                "relevant</td>".
                "<td class=InterviewQuestHead width=180 ".
                "align=center>".$self->T("answer","base::interanswer")."</td>".
                "</tr></table></div>";
         }
         $d.="\n<div class=InterviewQuest><form name=\"F$qrec->{id}\">".
             "<table class=InterviewQuest width=95% 
               border=0 cellspacing=0 cellpadding=0>".
             "<tr><td><div onclick=switchExt($qrec->{id})>$qrec->{name}</div>".
             "</td><td width=50>".
             "<div id=relevant$qrec->{id}>$qrec->{HTMLrelevant}</div></td>".
             "<td width=180 nowrap>".
             "<div class=InterviewQuestAnswer ".
             "id=answer$qrec->{id}>$qrec->{HTMLanswer}</div></td>".
             "<td width=1% align=center valign=center>".
             "<div class=qhelp onclick=qhelp($qrec->{id})><img border=0 ".
             "src=\"../../../public/base/load/questionmark.gif\"></div></td>".
             "</tr>".
             "<tr><td colspan=4>".
             "<div id=EXT$qrec->{id} style=\"display:none;visibility:hidden\">".
             "<div id=comments$qrec->{id}>$qrec->{HTMLcomments}</div>".
             "</div></td>".
             "</tr></table></form></div>";
         push(@q,$d);
         $lastquestclust=$qrec->{questclust};
      }
   }
   print $self->HttpHeader("text/xml");
   my $res=hash2xml({document=>{result=>'ok',q=>\@q,exitcode=>0}},{header=>1});
   print $res;
   #print STDERR $res;
}


sub InterviewMainForm
{
   my $self=shift;
   my $rec=shift;
   my $idname=shift;
   my $id=shift;
   my $state=$rec->{interviewst};
   my $label=$self->getRecordHeader($rec);
   my $d="<div class=Interview><div style=\"padding:2px\">";
   my $srelevant="<select name=relevant onchange=submitChange(this) >".
                 "<option value=\"1\">Ja</option>".
                 "<option value=\"0\">Nein</option>".
                 "</select>";
   my $scomments="<textarea name=comments onchange=submitChange(this) ".
                 "rows=2 style=\"width:100%\"></textarea>";

   $d.=<<EOF;
<script language="JavaScript">

function qhelp(id)
{
   openwin("../../base/interview/Detail?ModeSelectCurrentMode=Question&id="+id,"_blank",
          "height=400,width=600,toolbar=no,status=no,"+
          "resizable=yes,scrollbars=auto");
}

function switchExt(id)
{
   var e=document.getElementById("EXT"+id);
   if (e.style.display=="none" || e.style.display==""){
      e.style.display="block";
      e.style.visibility="visible";
   }
   else{
      e.style.display="none";
      e.style.visibility="hidden";
   }
}
function switchQueryBlock(o,id)
{
   var e=document.getElementById("BLK"+id);
   if (e.style.display=="none" || e.style.display==""){
      e.innerHTML='<center><img src="../../base/load/ajaxloader.gif"></center>';
      e.style.display="block";
      e.style.visibility="visible";
      var o=document.getElementById("BLKON"+id);
      o.style.display="block";
      o.style.visibility="visible";
      var o=document.getElementById("BLKOFF"+id);
      o.style.display="none";
      o.style.visibility="hidden";

      var xmlhttp=getXMLHttpRequest();
      var path='HtmlInterviewLink';
      xmlhttp.open("POST",path);
      xmlhttp.onreadystatechange=function() {
       if (xmlhttp.readyState==4 && 
           (xmlhttp.status==200 || xmlhttp.status==304)){
          var xmlobject = xmlhttp.responseXML;
          var result=xmlobject.getElementsByTagName("q");
          var d="";
          for (var i = 0; i < result.length; ++i){
              var childNode=result[i].childNodes[0];
              if (childNode){
                 d+=childNode.nodeValue;
              }
          }
          e.innerHTML=d;
       }
      }
      var q="$idname=$id&queryblock="+Url.encode(e.getAttribute("name"));
      //alert("q= "+q);
      xmlhttp.setRequestHeader("Content-type","application/x-www-form-urlencoded");
      var r=xmlhttp.send(q);
   }
   else{
      e.style.display="none";
      e.style.visibility="hidden";
      var o=document.getElementById("BLKOFF"+id);
      o.style.display="block";
      o.style.visibility="visible";
      var o=document.getElementById("BLKON"+id);
      o.style.display="none";
      o.style.visibility="hidden";
   }
}
function loadForm(id,xmlobject)
{
   var v=new Array('answer','comments','relevant');

   for (var i = 0; i < v.length; ++i){
      var a=document.getElementById(v[i]+id);
      var result=xmlobject.getElementsByTagName("HTML"+v[i])[0];
      var childNode=result.childNodes[0];
      if (childNode){
         a.innerHTML=childNode.nodeValue;
      }
   }
}
function submitChange(o)
{
   var vname=o.name;
   var vval=o.value;
   var qid=o.form.name;
   qid=qid.substring(1,qid.length); // F am Anfang abscheinden
   var parentid=document.getElementById("parentid").value;
   var parentobj=document.getElementById("parentobj").value;

   var xmlhttp=getXMLHttpRequest();
   var path='../../base/interanswer/Store';
   xmlhttp.open("POST",path);
   xmlhttp.onreadystatechange=function() {
    if (xmlhttp.readyState==4 && 
        (xmlhttp.status==200 || xmlhttp.status==304)){
       loadForm(qid,xmlhttp.responseXML);
    }
   }
   var q="vname="+vname+"&vval="+Url.encode(vval)+"&"+"parentid="+parentid+"&"+
         "parentobj="+parentobj+"&"+"qid="+qid;
   xmlhttp.setRequestHeader("Content-type","application/x-www-form-urlencoded");
   var r=xmlhttp.send(q);

  // alert("changed "+vname+" newval="+vval+" in question "+qid+" parentid="+parentid+" parentobj="+parentobj);
}

function setA(formid,val)
{
   if (document.forms['F'+formid]){
      if (document.forms['F'+formid].elements['answer']){
         document.forms['F'+formid].elements['answer'].value=val;
         submitChange(document.forms['F'+formid].elements['answer']);
      }
      else{
         alert("ERROR: can not identify answer element");
      }
   }
   else{
      alert("ERROR: can not identify form");
   }
}

</script>
EOF
   my $s;     
   $d.="<div class=header>";
   $d.="<table width=95%><tr><td></td>";
   $d.="<td align=left>".$label."</td>";
   $d.="<td align=right>";
   $d.="<select name=archiv style=\"width:200px\">";
   $d.="<option value=\"\">aktueller Fragenkatalog</option>";
   $d.="</select>";
   $d.="</td></tr></table>";
   $d.="</div>";

   my $lastquestclust;
   my $lastqblock;
   my $blknum=0;

   my @blklist;

   foreach my $qrec (@{$state->{TotalActiveQuestions}}){
      if ($lastqblock ne $qrec->{queryblock}){
         push(@blklist,$qrec->{queryblock});
      }
      $lastqblock=$qrec->{queryblock};
   }
   $d.="</div>" if ($lastqblock ne "");
  # push(@blklist,"open");
   $lastqblock=undef;
   foreach my $blk (@blklist){
      $d.="\n</div>\n" if ($lastqblock ne "");
      $d.="<div class=InterviewQuestBlockFancyHead>$blk - $label</div>";
      $d.="\n<div onclick=\"switchQueryBlock(this,'${blknum}');\" ".
          "class=InterviewQuestBlockHead>".
          "\n<div id=BLKON${blknum} class=OnOfSwitch ".
          "style=\"visible:hidden;display:none\">".
          "<img border=0 src=\"../../../public/base/load/minus.gif\"></div>".
          "<div id=BLKOFF${blknum} class=OnOfSwitch ".
          "style=\"visible:visible;display:block\">".
          "<img border=0 src=\"../../../public/base/load/plus.gif\"></div>".
          "<div style=\"float:none\">$blk</div></div>";
      $d.="\n<div id=BLK${blknum} name=\"$blk\" class=InterviewQuestBlock>";
      $blknum++;
      $lastqblock=$blk;
   }
   $d.="</div>" if ($lastqblock ne "");



   $d.="</div></div>";
   $d.=<<EOF;
<script language="JavaScript">
function loadAllForms()
{
   $s
}
addEvent(window, "load", loadAllForms);
</script>

EOF

}


######################################################################

1;
