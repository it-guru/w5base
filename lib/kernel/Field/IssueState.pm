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
        #    my $link="<span onclick=alert(\"onclick=openwin('$url','_blank',".
        #             "'height=480,width=640,toolbar=no,status=no,".
        #             "resizable=yes,scrollbars=auto');\")>";
            my $link="<a href=\"$url\" target=_blank>";


#            $response->{document}->{HtmlDetail}="<div ".
#                     "style=\"left:-40px;top:-45px;position:relative\">".
#                     $link."<img border=0 ".
#                  "title=\"$title\" ".
#                  "style=\"position:absolute;width:40px;height:40px;".
#                  "padding-right:5px\" src=\"../../base/load/attention.gif\">".
#                  "</a></div>";

            $response->{document}->{HtmlDetail}="<div id=fixedload ".
                     "style=\"display:none;visible:hidden\">".
                     $link."<img border=0 ".
                  "title=\"$title\" ".
                  "style=\"width:30px;height:30px;".
                  "padding-right:5px\" src=\"../../base/load/attention.gif\">".
                  "</a></div>";



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
         sleep(3);
         $response->{document}->{HtmlV01}="ERROR: State only in Detail view";
         $response->{document}->{HtmlDetail}="
<div id=fixedload style='display:none;visible:hidden'>
<img border=0 style='position:absolute;width:30px;height:30px;
     padding-right:5px' src='../../base/load/attention.gif'>
</div>";
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
addEvent(window,"load",onLoadViewProcessor_$self->{name}_$id);
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
