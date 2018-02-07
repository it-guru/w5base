package kernel::Field::Boolean;
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
use kernel::Field::Select;

@ISA    = qw(kernel::Field::Select);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{value}=[0,1]            if (!defined($self->{value}));
   # Boolean unterstützt auch andere Werte für 0,1 wenn diese
   # bei der initialisierung als value mitgegeben werden. Erstes
   # value=false, zweites value=true (zumindest ist es so geplant)
   $self->{transprefix}="boolean." if (!defined($self->{transprefix}));
   $self->{allowempty}=0           if (!defined($self->{allowempty}));
   if (!defined($self->{default})){
      $self->{default}=$self->{allowempty} ? "": "0";
   }
   $self->{htmleditwidth}="60px"   if (!defined($self->{htmleditwidth}));
   $self->{WSDLfieldType}="xsd:boolean" if (!defined($self->{WSDLfieldType}));
   if ($self->{markempty}){
      $self->{default}=undef;
   }
  # if ($self->{allowempty} && !grep(/^$/,@{$self->{value}})){
  #    unshift(@{$self->{value}},"");
  # }
   return($self);
}


sub ViewProcessor                           # same handling as in
{                                           # TextDrop fields!!!
   my $self=shift;
   my $mode=shift;
   my $refid=shift;
   if ($mode eq "XML" && $refid ne ""){
      my $response={document=>{}};

      my $obj=$self->getParent();
      my $idfield=$obj->IdField();
      if (defined($idfield)){
         $obj->ResetFilter();
         $obj->SetFilter({$idfield->Name()=>\$refid});
         $obj->SetCurrentOrder("NONE");
         my ($rec,$msg)=$obj->getOnlyFirst(qw(ALL));
         if ($obj->Ping()){
            my $fo=$obj->getField($self->Name(),$rec);
            if (defined($fo) && defined($rec)){
               my $d=$self->SUPER::FormatedResult($rec,$mode);
               $d=[$d] if (ref($d) ne "ARRAY");
               $response->{document}->{value}=$d;
            }
            else{
               $response->{document}->{value}="";
            }
         }
         else{
            $response->{document}->{value}=
               "[ERROR: layer 1 information temporarily unavailable]";
         }
      }
      print $self->getParent->HttpHeader("text/xml");
      print hash2xml($response,{header=>1});
      #msg(INFO,hash2xml($response,{header=>1})); # only for debug
      return;
   }
   return;
}



sub FormatedResult
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);


   if ($self->{async} && $mode eq "HtmlDetail"){   # same handling as in 
      my $idfield=$self->getParent->IdField();     # TextDrop fields!!!
      if (defined($idfield)){
         my $id=$idfield->RawValue($current);
         my $divid="ViewProcessor_$self->{name}";
         my $XMLUrl="$ENV{SCRIPT_URI}";
         $XMLUrl=~s/^[a-z]+?://; # rm protocol to prevent reverse proxy issues
         $XMLUrl.="/../ViewProcessor/XML/$self->{name}/$id";
         my $d="<div id=\"$divid\"><font color=silver>init ...</font></div>";
         $d=$self->addWebLinkToFacility($d,$current);
         return(<<EOF);
$d
<script language="JavaScript">
function onLoadViewProcessor_$self->{name}(timedout)
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
         if (xmlhttp.readyState<4){
            var t="<font color=silver>Loading ...</font>";
            if (r.innerHTML!=t){
               r.innerHTML=t;
            }
         }
         if (xmlhttp.readyState==4 && 
             (xmlhttp.status==200||xmlhttp.status==304)){
            var xmlobject = xmlhttp.responseXML;
            var result=xmlobject.getElementsByTagName("value");
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



//   ResContainer.innerHTML="<font color=silver>"+
//                          "- Informations isn't avalilable at now -"+
//                          "</font>";
}
addEvent(window,"load",onLoadViewProcessor_$self->{name});
</script>
EOF
      }
      return("- ERROR - no idfield - ");
   }


   
   if ($mode eq "SOAP"){
      return("true") if ($d);
      return("false");
   }
   if ($mode eq "JSON"){
      return(undef) if (!defined($d));
      return(\'1') if ($d);
      return(\'0');
   }
   if ($mode=~m/Html/i){
      return("?") if ($d eq "" && $self->{'markempty'});
   }

   return($d) if ($mode eq "XMLV01");
   return($self->SUPER::FormatedResult($current,$mode));
}


1;
