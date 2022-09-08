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
   my $imode=Query->Param("IMODE");
   my $interviewcatid=Query->Param("interviewcatid");
   my $archiv=Query->Param("archiv");
   $self->ResetFilter();
   $self->SetFilter({$idname=>\$id});
   my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));
   if (defined($rec)){
      if ($interviewcatid eq ""){ 
         print $self->HttpHeader();
         print $self->HtmlHeader(body=>1,
                                 js=>['toolbox.js',
                                      'jquery.js',
                                      'jquery.ui.js',
                                      'jquery.ui.widget.js',
                                      'jquery.ui.dataCube.js',
                                     # 'firebug-lite.js',
                                      'jquery.locale.js'],
                                 style=>['default.css','work.css',
                                         'Output.HtmlDetail.css',
                                         'kernel.App.Web.css',
                                         'kernel.App.Web.Interview.css',
                                         'jquery.ui.css']);
         print $self->InterviewMainForm($rec,$idname,$id);
         print $self->HtmlBottom(body=>1);
      }
      else{
         $self->InterviewSubForm("xml",$rec,$interviewcatid,$imode);
      }
   }
}

sub InterviewSubForm
{
   my $self=shift;
   my $format=shift;
   my $rec=shift;
   my $interviewcatid=shift;
   my $imode=shift;
   my $state=$rec->{interviewst};

   my $lastquestclust;
   my @q;
   my $HTMLjs;
   my $commenttxt=$self->T("add comments to your answer","base::interanswer");
   foreach my $qrec (@{$state->{TotalActiveQuestions}}){
      my $d;
      if ($imode eq "open"){
         if (exists($state->{AnsweredQuestions}->
                    {interviewid}->{$qrec->{id}}) &&
             $state->{AnsweredQuestions}->
                   {interviewid}->{$qrec->{id}}->{answer} ne ""){
            next;
         }
      }
      if ($imode eq "outdated"){
         if (!exists($qrec->{needverify}) || !$qrec->{needverify}){
            next;
         }
      }
      if ($qrec->{AnswerViewable}){
         if ($interviewcatid eq $qrec->{interviewcatid}){
            if (!defined($lastquestclust) ||
                $lastquestclust ne $qrec->{questclust}){
               $d.="<div class=\"InterviewQuestClust\">".
                   $qrec->{questclust}."</div>";
               $d.="\n<div class=InterviewQuestHead>".
                   "<table border=0 class=InterviewQuestHead width=95%>".
                   "<tr><td class=InterviewQuestHead></td>".
                   "<td class=InterviewQuestHead width=55 align=center>".
                   "relevant</td>".
                   "<td class=InterviewQuestHead width=180 ".
                   "align=center valign=top>".
                   $self->T("answer","base::interanswer").
                   "</td><td width=1%>".
                   "<img border=0 ".
                   "src=\"../../../public/base/load/confirm_space.gif\">".
                   "</td>".
                   "<td width=1%><img border=0 width=8 height=12 ".
                   "src=\"../../../public/base/load/empty.gif\"></td>".
                   "</tr></table></div>";
            }
            $d.="\n<div class=InterviewQuest>".
                "<form onsubmit=\"return(false);\" name=\"F$qrec->{id}\">".
                "<table border=0 class=InterviewQuest width=95% 
                  border=0 >".
                "<tr><td><div onclick=switchExt($qrec->{id})>".
                "<span class=InterviewQuestion>".
                $qrec->{name}."</span></div>".
                "</td><td width=55 nowrap valign=top>".
                "<div id=relevant$qrec->{id}>$qrec->{HTMLrelevant}</div></td>".
                "<td width=180 nowrap valign=top>".
                "<div class=InterviewQuestAnswer ".
                "id=answer$qrec->{id}>$qrec->{HTMLanswer}</div></td>".
                "<td width=1% align=center valign=top nowrap>".
                "<span class=qhelp onclick=switchExt($qrec->{id})>".
                "<img border=0 id='COMMENTINDICATOR_$qrec->{id}' ".
                "title=\"$commenttxt\" ".
                "src=\"../../../public/base/load/nocomment.gif\">".
                "</span>".
                "</td>".
                "<td width=1% align=center valign=top>".
                "<div class=qhelp onclick=qhelp($qrec->{id})>".
                "<img border=0 ".
                "src=\"../../../public/base/load/questionmark.gif\">".
                "</div>".
                "</td>".
                "<td width=18 nowrap valign=top>".
                "<span id=verify$qrec->{id}>$qrec->{HTMLverify}</span>".
                "</td>".
                "</tr>".
                "<tr><td colspan=5>".
                "<div id=EXT$qrec->{id} ".
                "style=\"display:none;visibility:hidden\">".
                "<div id=comments$qrec->{id}>$qrec->{HTMLcomments}</div>".
                "</div></td>".
                "</tr></table></form></div>";
            push(@q,$d);
            $HTMLjs.=$qrec->{HTMLjs};
            $lastquestclust=$qrec->{questclust};
            $lastquestclust="" if (!defined($lastquestclust));
         }
      }
   }
   if ($format eq "xml"){
      print $self->HttpHeader("text/xml");
      if ($HTMLjs ne ""){
         $HTMLjs="function Init$interviewcatid(){$HTMLjs} ".
                 "Init$interviewcatid(0)";
      }
      else{
         $HTMLjs="function Init$interviewcatid(){}";
      }
      my $res=hash2xml({document=>{result=>'ok',q=>\@q,js=>$HTMLjs,
                                   exitcode=>0}},{header=>1});
      print $res;
   }
   else{
      return(join("",@q));
   }
}


sub InterviewPartners
{
   my $self=shift;
   my $rec=shift;


   return(''=>$self->T("Databoss",$self->Self)) if (!defined($rec));
   return(''=>[$rec->{'databossid'}]) if (exists($rec->{'databossid'}));
   return(''=>[]);
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
   $label=~s/['<>]//g;

   $d.=<<EOF;
<script language="JavaScript">

parent.document.title='Interview: $label';

function qhelp(id)
{
   openwin("../../base/interview/Detail?ModeSelectCurrentMode=Question&id="+id,"_blank",
          "height=400,width=600,toolbar=no,status=no,"+
          "resizable=yes,scrollbars=auto");
}

function qverify(qid)
{
   var parentid=document.getElementById("parentid").value;
   var parentobj=document.getElementById("parentobj").value;

   doStoreValue(qid,parentobj,parentid,"lastverify","1");
}

function expandall(){
   var c=0;
   \$(".InterviewQuestBlockHead").each(function(){
      var o=this;
      setTimeout(function(){
         switchQueryBlockOn(o);
      },c);
      c=c+800;    // wait some time
   });
}
function collapseall(){
   \$(".InterviewQuestBlockHead").each(function(){
      switchQueryBlockOff(this);
   });
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
function switchQueryBlockOn(o)
{
   var id=\$(o).attr("blkid");
   var imode=\$(o).attr("imode");
   var e=document.getElementById("BLK"+id);
   var Q=document.getElementById("QST"+id);

   if (id>0){
      Q.innerHTML='<center><img src="../../base/load/ajaxloader.gif">'+
                  '</center>';
   }
   e.style.display="block";
   e.style.visibility="visible";
   var o=document.getElementById("BLKON"+id);
   o.style.display="block";
   o.style.visibility="visible";
   var o=document.getElementById("BLKOFF"+id);
   o.style.display="none";
   o.style.visibility="hidden";
   if (id==0){
      return;
   }
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
       if (d!=""){
          Q.innerHTML=d;
          var jso=xmlobject.getElementsByTagName("js");
          for (var i = 0; i < jso.length; ++i){
              var childNode=jso[i].childNodes[0];
              if (childNode){
                 eval(childNode.nodeValue);
              }
          }
       }
       else{
          Q.innerHTML="<br>";
       }
    }
   }
   var q="$idname=$id&interviewcatid="+id+"&IMODE="+imode;
   xmlhttp.setRequestHeader("Content-type","application/x-www-form-urlencoded");
   var r=xmlhttp.send(q);
}

function switchQueryBlockOff(o)
{
   var id=\$(o).attr("blkid");
   var imode=\$(o).attr("imode");
   var e=document.getElementById("BLK"+id);
   var Q=document.getElementById("QST"+id);

   e.style.display="none";
   e.style.visibility="hidden";
   var o=document.getElementById("BLKOFF"+id);
   o.style.display="block";
   o.style.visibility="visible";
   var o=document.getElementById("BLKON"+id);
   o.style.display="none";
   o.style.visibility="hidden";

}


function switchQueryBlock(o)
{
   var id=\$(o).attr("blkid");
   var imode=\$(o).attr("imode");
   var e=document.getElementById("BLK"+id);
   var Q=document.getElementById("QST"+id);
   if (e.style.display=="none" || e.style.display==""){
      switchQueryBlockOn(o);
   }
   else{
      switchQueryBlockOff(o);
   }
}
function loadForm(id,xmlobject)
{
   var v=new Array('answer','comments','relevant','verify','js');
   var js="";

   for (var i = 0; i < v.length; ++i){
      var a=document.getElementById(v[i]+id);
      var result=xmlobject.getElementsByTagName("HTML"+v[i])[0];
      var childNode=result.childNodes[0];
      if (childNode){
         if (v[i]=="js"){
            js+=childNode.nodeValue;
         }
         else{
            a.innerHTML=childNode.nodeValue;
         }
      }
   }
   if (js!=""){
      eval(js);
   }
}

function updateCommentIndicator(qid)
{
   var indic=\$('#COMMENTINDICATOR_'+qid);
   var comments=\$('#COMMENTS_'+qid);
   if (indic && comments){
      var imgsrc=indic.attr('src');
      var newsrc=imgsrc;
      if (comments.val()!=""){
         newsrc=newsrc.replace(/\\/[^/]+\$/,'/comment.gif');
     
      }
      else{
         newsrc=newsrc.replace(/\\/[^/]+\$/,'/nocomment.gif');
      }
      if (newsrc!=imgsrc){
         indic.attr('src',newsrc);
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

   updateCommentIndicator(qid);
   doStoreValue(qid,parentobj,parentid,vname,vval);
}


function doStoreValue(qid,parentobj,parentid,vname,vval)
{

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
   my @sl=('current'=>$self->T("current questions"),
           'open'=>$self->T("not answered questions"),
           'outdated'=>$self->T("outdated answers"),
           'analyses'=>$self->T("analyses"));
   my $s="<select name=IMODE onchange=\"document.forms['control'].submit();\" ".
         "style=\"width:200px\">";
   my $imode=Query->Param("IMODE");
   $imode="current" if ($imode eq "");
   while(my $k=shift(@sl)){
      my $v=shift(@sl);
      $s.="<option value=\"$k\"";
      $s.=" selected" if ($imode eq $k);
      $s.=">$v</option>";
   }
   $s.="</select>";

   my $help=$self->findtemplvar({},"GLOBALHELP","article",
                 "W5Base ".$self->SelfAsParentObject." Config-Item-Interview|".
                 "W5Base Config-Item-Interview");
   $d.="<form name=\"control\">";
   $d.="<div class=header>";
   $d.="<table border=0 width=97%><tr><td width=5>&nbsp;</td>";
   $d.="<td align=left>".$label."</td>";
   $d.="<td align=right width=1%>".$s."</td><td width=10>".
       $help."</td>".
       "<td width=10 nowrap>".
       "<img style=\"cursor:pointer\" onclick=\"document.forms[0].submit();\" ".
       "src=\"../../../public/base/load/reload.gif\"></td>".
       "<td width=10 nowrap>".
       "<img style=\"cursor:pointer\" onclick=\"expandall();\" ".
       "src=\"../../../public/base/load/expandall.gif\"></td>".
       "<td width=10 nowrap>".
       "<img style=\"cursor:pointer\" onclick=\"collapseall();\" ".
       "src=\"../../../public/base/load/collapseall.gif\"></td>".
       "</tr></table>";
   $d.="</div>";
   $d.=sprintf("<input type=hidden name=$idname value=\"%s\">",$id);
   $d.=sprintf("<input type=hidden id=parentid value=\"%s\">",$id);
   $d.=sprintf("<input type=hidden id=parentobj value=\"%s\">",
               $self->SelfAsParentObject);
   $d.="</form>";

   if ($imode eq "analyses"){
      $d.="<script language=\"JavaScript\">";
      my $parentobj=$self->SelfAsParentObject();
      my $interview=getModuleObject($self->Config,"base::interview");
      $interview->SetFilter({parentobj=>\$parentobj});

      my $output=new kernel::Output($interview);
      if ($output->setFormat("JSON",charset=>"latin1")){
         $interview->SetCurrentView(qw(name id questclust queryblock rawprio));
         $d.=$output->WriteToScalar(HttpHeader=>0);
      }
      #
      # send Interview State
      #
      $self->ResetFilter();
      $self->SetFilter({$idname=>\$id});

      my $output=new kernel::Output($self);
      if ($output->setFormat("JSON",charset=>"latin1")){
         $self->SetCurrentView("interviewst");
         $d.=$output->WriteToScalar(HttpHeader=>0);
      }
      $d.="</script>";
      $d.="<script language=\"JavaScript\">";
      $d.=<<EOF;
var Cube;
\$(document).ready(function (parentid){
   Cube=new Array();
   for (id in document.W5Base.base.interview){
     var notrelevant=document.W5Base.last['$id'].interviewst.qStat.notrelevant;
     var a=document.W5Base.last['$id'].interviewst.qStat.questStat[id];
     var w=3-document.W5Base.base.interview[id].rawprio;
     if (w<1){
        w=1;
     }
     if (a!=undefined){  
       if (jQuery.inArray(id,notrelevant)<0){
          var qn=document.W5Base.base.interview[id].name;
          qn=qn.replace(".","_");
         
          var qc=document.W5Base.base.interview[id].queryblock+".- "+qn;
          var o=new Object({qb:qc,
                            qg:document.W5Base.base.interview[id].questclust,
                            weight:w,
                            value:a});
          Cube.push(o);
        }
      //  else{
      //    alert("id "+id+" not relevant");
      //  }
     }
   }
   var c={value:Cube,
          currentFilter:0,
          unit:'%',
          filter:[{key:'qb',
                   label:'Kategorie',
                   levelSeperator:'.',
                   dyncss:[{range:[0,30],  cssclass:'interview-analyse-red'},
                           {range:[90,100],cssclass:'interview-analyse-green'}],
                   currentKey:''
                  },
                  {key:'qg',
                   label:'Fragegruppe',
                   dyncss:[{range:[0,30],  cssclass:'interview-analyse-red'},
                           {range:[90,100],cssclass:'interview-analyse-green'}],
                   currentKey:''}
                 ]
   };





   \$("#out").dataCube(c);

});
EOF
      $d.="</script>";
      $d.="<div id=\"out\"></div>";
   }
   else{
      my $lastquestclust;
      my $lastqblock;
      my $blknum=0;
    
      my @blklist;
      my @blkid;
   
      my %queryblocklabel; 

    #  my $ic=getModuleObject($self->Config,"base::interviewcat");
    #  $ic->SetCurrentView(qw(id fulllabel));
    #  my $icat=$ic->getHashIndexed(qw(id));  # cache categorie labels


      foreach my $qrec (@{$state->{TotalActiveQuestions}}){
         if ($imode eq "open"){
            if (exists($state->{AnsweredQuestions}->
                       {interviewid}->{$qrec->{id}}) &&
                ($state->{AnsweredQuestions}->
                      {interviewid}->{$qrec->{id}}->{answer} ne "" ||
                 $state->{AnsweredQuestions}->
                      {interviewid}->{$qrec->{id}}->{relevant} eq "0" )){
               next;
            }
         }
         if ($lastqblock ne $qrec->{queryblock}){
            push(@blklist,$qrec->{queryblock});
            $queryblocklabel{$qrec->{queryblock}}=$qrec->{queryblocklabel};
            push(@blkid,$qrec->{interviewcatid});
         }
         $lastqblock=$qrec->{queryblock};
      }
      $d.="</div>" if ($lastqblock ne "");
      my @openlevel;
      my $vsequence=0;
      for(my $c=0;$c<=$#blklist;$c++){
         #my $blk=$blklist[$c];
         my $blk=$queryblocklabel{$blklist[$c]};
         my $blkid=$blkid[$c];
         my @curlevel=split(/\./,$blk);
         $self->switchToLevel(\$d,$rec,\@openlevel,\@curlevel,
                              \$vsequence,$blkid,$imode);
      }
      $self->switchToLevel(\$d,$rec,\@openlevel,[],\$vsequence);
    
      $d.="</div></div>";
   }
   return($d);
}

sub switchToLevel
{
   my $self=shift;
   my $d=shift;
   my $rec=shift;
   my $from=shift;
   my $to=shift;
   my $vsequence=shift;
   my $last_blkid=shift;
   my $imode=shift;

   my $blk=join(".",@{$to});

   my $complevel=$#{$to}<$#{$from} ? $#{$from} : $#{$to};
   my $eqlevel=0;

   for(my $i=0;$i<=$complevel;$i++){
      if (!defined($to->[$i]) ||
          !defined($from->[$i]) ||
          $from->[$i] ne $to->[$i]){
         $eqlevel=$i;
         last;
      }
   }
   $eqlevel=0 if ($eqlevel<0);
   for(my $i=$#{$from};$i>=$eqlevel;$i--){
       $$d.="</div>";
   }
   my $plusstyle ="visible:visible;display:block";
   my $minusstyle="visible:hidden;display:none";
   my $blkstyle="visible:hidden;display:none";
   if ($imode eq "outdated"){
      $minusstyle="visible:visible;display:block";
      $plusstyle="visible:hidden;display:none";
      $blkstyle="visible:visible;display:block";
   }
   if ($#{$to}>=$eqlevel){
      for(my $i=$eqlevel;$i<=$#{$to};$i++){
         $blk=$to->[$i];
         my $blkid=$last_blkid;
         if ($i!=$#{$to}){
            $blkid="VIRTUAL".$$vsequence;
            $$vsequence++;
         }
         my $blkvalue="<br>"; 
         if ($imode eq "outdated"){
            $blkvalue=$self->InterviewSubForm("html",$rec,$blkid,$imode);
         }
         if ($blkvalue ne ""){
            $$d.="\n<div blkid=\"${blkid}\" imode=\"${imode}\" ".
                "onclick=\"switchQueryBlock(this);\" ".
                "class=InterviewQuestBlockHead>".
                "\n<div id=BLKON${blkid} class=OnOfSwitch ".
                "style=\"$minusstyle\">".
                "<img border=0 src=\"../../../public/base/load/minus.gif\">".
                "</div>".
                "<div id=BLKOFF${blkid} class=OnOfSwitch ".
                "style=\"$plusstyle\">".
                "<img border=0 src=\"../../../public/base/load/plus.gif\">".
                "</div>".
                "<div style=\"float:none\">$blk</div></div>";
            $$d.="\n<div id=BLK${blkid} name=\"$blk\" ".
                 "class=InterviewQuestBlock style=\"$blkstyle\">";
            $$d.="\n<div id=QST${blkid} ".
                 "style=\"border-style-left:solid;border-color:black\" >".
                 "$blkvalue</div>";
         }
         else{
            $$d.="<div>"; # create a dummy div for structure consistence
         }
      }
   }
   @{$from}=(@{$to});
}


######################################################################

1;
