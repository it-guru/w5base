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
   my ($issuerec)=$wf->getOnlyFirst(qw(id eventstart name fwdtargetname));
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
            $response->{document}->{HtmlDetail}="<div id=fixedload ".
                     "style=\"display:none;visible:hidden\">".
                     $link."<div align=right style='padding-top:70px'>".
                     "<img border=0 title=\"$title\" ".
                  "style=\"width:30px;height:30px;".
                  "padding-right:5px\" src=\"../../base/load/attention.gif\">".
                  "</a></div></div>";

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
               if ($dispmsg ne ""){
                  $dispmsg="<div id=qmsg style='background-color:yellow;height:100px;overflow:auto;width:380px;border-style:solid;border-color:black;border-width:1px;text-align:left;visibility:hidden;display:none'>".
                           $dispmsg."</div>";
               }
               #print STDERR "qcheckresupt=".Dumper($res);
               if ($res->{exitcode}>0){
                  $response->{document}->{HtmlV01}="FAIL";
                  $response->{document}->{HtmlDetail}="
<div id=fixedload style='display:none;visible:hidden'>
<div style='height:70px'>&nbsp;</div>
<div align=right style='width:100%'>
<div align=right onmouseout='var e=document.getElementById(\"qmsg\");e.style.visibility=\"hidden\";e.style.display=\"none\";' >
<img onmouseover='var e=document.getElementById(\"qmsg\");e.style.visibility=\"visible\";e.style.display=\"block\";' style='margin-bottom:2px;width:30px;height:30px;
     padding-right:5px;cursor:pointer' src='../../base/load/attention.gif'>
$dispmsg
</div></div>
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
   if ($mode eq "HtmlDetail" || $mode eq "HtmlV01"){
      if (defined($idfield)){
         my $id=$idfield->RawValue($current);
         my $divid="ViewProcessor_$self->{name}_$id";
         my $XMLUrl="$ENV{SCRIPT_URI}";
         $XMLUrl.="/../ViewProcessor/XML/$self->{name}/$id";
         my $d="<div id=\"$divid\"></div>";
         $d=$self->addWebLinkToFacility($d,$current);
         my $activator='addEvent(window,"load",onLoadViewProcessor_'.
                       $self->{name}.'_'.$id.');';
         if ($self->getParent->Self eq "base::workflow"){ # wf check with 2 sec
            $activator='addEvent(window,"load",'.         # latency
                       'function (){ window.setTimeout("onLoadViewProcessor_'.
                       $self->{name}.'_'.$id.'();",2000);});';
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
   // window.setTimeout("onLoadViewProcessor_$self->{name}(1);",10000);
   // timeout handling ist noch bugy!
   var xmlhttp=getXMLHttpRequest();
   xmlhttp.open("POST","$XMLUrl",true);
   xmlhttp.onreadystatechange=function() {
      var r=document.getElementById("$divid");
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
   my $d=$self->SUPER::RawValue(@_);
   my $current=shift;
   my $idfield=$self->getParent->IdField();
   if (defined($idfield)){
      my $refid=$idfield->RawValue($current);
      my $obj=$self->getParent()->SelfAsParentObject();
      my $issuerec=$self->getWorkflowRec($obj,$refid);
      if (defined($issuerec)){
         return("DataIssue ".
                $self->getParent->T("since","kernel::Field::IssueState")." ".
                $issuerec->{eventstart}." GMT");
      }
      return("OK");
   }

   return("?");
}





1;
