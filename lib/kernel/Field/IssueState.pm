package kernel::Field::IssueState;
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
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{readonly}=1;
   $self->{history}=0;
   $self->{htmldetail}=0;
   $self->{searchable}=0;
   $self->{group}="qc";
   $self->{name}="dataissuestate";
   $self->{label}="DataIssue state";
   return($self);
}


sub getWorkflowRec
{
   my $self=shift;
   my $obj=shift;
   my $refid=shift;


   my $wf=$self->getParent->getPersistentModuleObject("base::workflow");
   $wf->SetFilter({directlnktype=>\$obj,
                   stateid=>"<17",
                   directlnkid=>\$refid,
                   directlnkmode=>\'DataIssue'});
   my ($issuerec)=$wf->getOnlyFirst(qw(id eventstart name 
                                       urlofcurrentrec
                                       fwdtargetname));
   return($issuerec);
}

sub ViewProcessor
{
   my $self=shift;
   my $mode=shift;
   my $refid=shift;
   if ($mode eq "XML" && $refid ne ""){
      my $response={document=>{value=>'ok',HtmlDetail=>'',HtmlV01=>'OK'}};
      my $obj=$self->getParent()->SelfAsParentObject();
      if ($obj ne "base::workflow"){
         my $issuerec=$self->getWorkflowRec($obj,$refid);
         my $title="OK";
         if (defined($issuerec)){
            $response->{document}->{value}="DataIssue \@ ".
                                         $issuerec->{fwdtargetname};
            $title=$self->getParent->T(
                       'There is an unprocessed DataIssue for %s!'.
                       ' - Not all data seems to be correct!');
            $title=sprintf($title,$issuerec->{fwdtargetname});
            my $url="../../base/workflow/ById/$issuerec->{id}";
            my $link="<a href=\"$url\" target=_blank>";
            my $dispmsg="<div id=qmsg style='position:absolute;left:15px;top:20px;background-color:yellow;height:100px;overflow:auto;width:450px;border-style:solid;border-color:black;border-width:1px;text-align:left;visibility:hidden;display:none'>".$title."</div>";
            $response->{document}->{HtmlDetail}="
<div onclick='openwin(\"$url\",\"_blank\",\"height=480,width=640,toolbar=no,status=no,resizeable=yes,scrollbars=no\");' onmouseout='var e=document.getElementById(\"qmsg\");e.style.visibility=\"hidden\";e.style.display=\"none\";' onmouseover='var e=document.getElementById(\"qmsg\");e.style.visibility=\"visible\";e.style.display=\"block\";' style='cursor:pointer' >
<table cellspacing=0 cellpadding=0 border=0>
<tr>
<td>
<img style=\"margin:2px\" src=\"../../base/load/attention.gif\"></td>
<td valign=center><font color=red><b>DataIssue</b></font></td>
</tr></table>

$dispmsg
</div>";
            $response->{document}->{HtmlV01}="$link<img border=0 ".
                  "title=\"$title\" ".
                  "src=\"../../base/load/fail.gif\"></a>";
         }
         else{
            $response->{document}->{HtmlV01}="<img title=\"$title\" ".
                                             "src=\"../../base/load/ok.gif\">";
         }
      }
      else{
         my $pobj=$self->getParent();
         $pobj->ResetFilter();
         $pobj->SetFilter({id=>\$refid});
         my ($wfrec)=$pobj->getOnlyFirst(qw(ALL));
         if (defined($wfrec)){
            my $qr=getModuleObject($pobj->Config,"base::qrule");
            $qr->setParent($pobj);
            my $res=$qr->nativQualityCheck($wfrec->{class},$wfrec);
            if (defined($res) && ref($res) eq "HASH"){
               $res->{exitcode}=0;
               my $dispmsg="";
               if (ref($res->{rule}) eq "ARRAY"){
                  foreach my $r (@{$res->{rule}}){
                     if ($r->{exitcode}>$res->{exitcode}){
                        $res->{exitcode}=$r->{exitcode};
                     }
                     if (ref($r->{qmsg}) eq "ARRAY"){
                        $dispmsg.="<ul>".
                            join("",map({"<li>".$_."</li>"} @{$r->{qmsg}})).
                            "</ul>";
                     }
                  }
               }
               #$dispmsg=Dumper($res);
               #print STDERR "qcheckresupt=".Dumper($res);
               if ($res->{exitcode}>0){
                  my $color="green";
                  my $bgcolor="white";
                  if ($res->{exitcode}==1){
                     $response->{document}->{HtmlV01}="INFO";
                     $color="black";
                  }
                  elsif ($res->{exitcode}==2){
                     $response->{document}->{HtmlV01}="WARN";
                     $color="orange";
                     $bgcolor="#F6FACE";
                  }
                  else{
                     $response->{document}->{HtmlV01}="FAIL";
                     $color="red";
                     $bgcolor="#F6E7DC";
                  }
                  if ($dispmsg ne ""){
                     $dispmsg="<div id=qmsg style='position:absolute;left:15px;top:20px;background-color:$bgcolor;height:100px;overflow:auto;width:450px;border-style:solid;border-color:black;border-width:1px;text-align:left;visibility:hidden;display:none'>".
                     $dispmsg."</div>";
                  }
                  
                  $response->{document}->{HtmlDetail}="
<div onmouseout='var e=document.getElementById(\"qmsg\");e.style.visibility=\"hidden\";e.style.display=\"none\";' onmouseover='var e=document.getElementById(\"qmsg\");e.style.visibility=\"visible\";e.style.display=\"block\";' style='cursor:pointer' >
<table cellspacing=0 cellpadding=0 border=0>
<tr>
<td>
<img style=\"margin:2px\" src=\"../../base/load/attention.gif\"></td>
<td valign=center><font color=\"$color\"><b>DataIssue</b></font></td>
</tr></table>

$dispmsg
</div>";
               }
               else{
                  $response->{document}->{HtmlV01}="OK";
                  $response->{document}->{HtmlDetail}="";
               }
            }
            else{
               $response->{document}->{HtmlV01}="";
               $response->{document}->{HtmlDetail}="";
            }

         }
      }

      print $self->getParent->HttpHeader("text/xml");
      print hash2xml($response,{header=>1});
      #msg(INFO,hash2xml($response,{header=>1})); # only for debug
      return;
   }
   return;
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $idfield=$self->getParent->IdField();

   if (!$self->getParent->isQualityCheckValid($current)){
      return("");
   }

   if ($mode eq "HtmlDetail" || $mode eq "HtmlV01"){
      if (defined($idfield)){
         my $id=$idfield->RawValue($current,$mode);
         my $divid="ViewProcessor_$self->{name}_$id";
         my $XMLUrl="";
        # my $XMLUrl="$ENV{SCRIPT_URI}";
        # $XMLUrl=~s/^[a-z]+?://; # rm protocol to prevent reverse proxy issues
         my $parent=$self->getParent->Self;
         $parent=~s/::/\//g;
 
         $XMLUrl.="/../../../$parent/ViewProcessor/XML/$self->{name}/$id";
         my $d="<div id=\"$divid\"></div>";
         $d=$self->addWebLinkToFacility($d,$current);
         my $activator='addEvent(window,"load",onLoadViewProcessor_'.
                       $self->{name}.'_'.$id.');';
         if ($self->getParent->Self eq "base::workflow"){ # wf check with 2 sec
            $activator='addEvent(window,"load",'.         # latency
                       'function (){ window.setTimeout("onLoadViewProcessor_'.
                       $self->{name}.'_'.$id.'();",2000);});';
         }
         my $issueboxpath="if (window.parent){".
                          "IssueBox=window.parent.document.".
                          "getElementById(\"IssueState\");}";
         if ($mode eq "HtmlV01"){
            $issueboxpath="IssueBox=document.".
                          "getElementById(\"$divid\");";
            
         }
 
         return(<<EOF);
$d
<script language="JavaScript">
function onLoadViewProcessor_$self->{name}_$id(timedout)
{
   var ResContainer=document.getElementById("$divid");
   if (ResContainer && timedout==1){
      ResContainer.innerHTML="ERROR: XML request timed out";
      return;
   }
   var IssueBox;
   $issueboxpath;
   if (IssueBox){
      IssueBox.innerHTML="Checking DataIssue ...";
      // window.setTimeout("onLoadViewProcessor_$self->{name}(1);",10000);
      // timeout handling ist noch bugy!
      var reqTarget=document.location.pathname+"$XMLUrl";
      var xmlhttp=getXMLHttpRequest();
      xmlhttp.open("POST",reqTarget,true);
      xmlhttp.onreadystatechange=function() {
         var r=document.getElementById("$divid");
         var r=IssueBox;
         if (r){
            if (xmlhttp.readyState==4 && 
                (xmlhttp.status==200||xmlhttp.status==304)){
               var xmlobject = xmlhttp.responseXML;
               var result=xmlobject.getElementsByTagName("$mode");
               if (result){
                  r.innerHTML="";
                  for(rid=0;rid<result.length;rid++){
                     if (r.innerHTML!=""){
                        r.innerHTML+=", ";
                     }
                     if (result[rid].childNodes[0]){
                        r.innerHTML+=result[rid].childNodes[0].nodeValue;
                     }
                  }
               }
               else{
                  r.innerHTML="ERROR: XML error";
               }
            }
         }
      };
      xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded');
      var r=xmlhttp.send('Mode=XML');
   }
}
$activator
</script>
EOF
      }
      return("- ERROR - no idfield - ");
   }

   return($self->SUPER::FormatedDetail($current,$mode));
}

sub RawValue
{
   my $self=shift;
#   my $d=$self->SUPER::RawValue(@_);
   my $current=shift;
   my $mode=shift;

   my $msg="?";

   my $idfield=$self->getParent->IdField();
   if (defined($idfield)){
      my $refid=$idfield->RawValue($current);
      my $obj=$self->getParent()->SelfAsParentObject();
      my $issuerec=$self->getWorkflowRec($obj,$refid);
      if (defined($issuerec)){
         if ($mode ne "" && $mode ne "JSON"){
            $msg="DataIssue ".
                 $self->getParent->T("since","kernel::Field::IssueState")." ".
                 $issuerec->{eventstart}." GMT";
         }
         else{
            $msg="FAIL";
            # hier muß noch eine Bewertung rein 
            # WARN = eventstart liegt weniger als 8 Wochen in der
            # vergangenheit. Ansonsten FAIL
            # sufix "but OK" wenn der Bearbeitungszeitpunkt kürzer als 8 Wochen 
            # in der Vergangenheit und mdate min. 1h nach eventstart
            my $d=CalcDateDuration($issuerec->{eventstart},
                  NowStamp("en"),"GMT");
            if (defined($d) && exists($d->{totaldays}) && $d->{totaldays}<8*7){
               $msg="WARN";
            }

            my $d=CalcDateDuration($issuerec->{mdate},NowStamp("en"),"GMT");
            if (defined($d) && exists($d->{totaldays}) && $d->{totaldays}<8*7){
               $msg.=" but OK";
            }

            my $usertz=$self->getParent->UserTimezone();
            my $mdate=$issuerec->{mdate};
            my $eventstart=$issuerec->{eventstart};
            if ($mode eq "JSON" || $mode eq "JSONP"){
               $mdate=$self->getParent->ExpandTimeExpression(
                          $mdate,"ISO8601",$usertz,$usertz);
               $eventstart=$self->getParent->ExpandTimeExpression(
                          $eventstart,"ISO8601",$usertz,$usertz);
            }

            $msg={
               dataissuestate=>$msg,
               id=>$issuerec->{id},
               eventstart=>$eventstart,
               mdate=>$mdate,
               dataissue=>$issuerec->{name},
               dataobj=>$self->getParent->SelfAsParentObject(),
               dataobjid=>$refid,
               urlofcurrentrec=>$issuerec->{urlofcurrentrec}
            };
         }
      }
      else{
         if ($mode ne "" && $mode ne "JSON"){
            $msg="OK";
         }
         else{
            $msg="OK";
            $msg={
               dataobj=>$self->getParent->SelfAsParentObject(),
               dataobjid=>$refid,
               dataissuestate=>$msg
            };
         }
      }
   }

   return($msg);
}





1;
