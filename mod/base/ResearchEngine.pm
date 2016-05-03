package base::ResearchEngine;
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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
use CGI;
@ISA=qw(kernel::App::Web);

#
#  lib/kernel/App/Web/Listedit.pm
#  static/springy
#  mod/base/Research
#  mod/base/ResearchEngine.pm
#  lib/javascript/moment.min.js
#  lib/javascript/moment-with-locales.min.js
#  lib/javascript/springy.js
#  lib/javascript/excanvas.js
#  lib/javascript/jquery.enterKey.js
#  lib/javascript/jquery.mousewheel.js
#  skin/default/base/lang/base.ResearchEngine

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->LoadSubObjs("Research","Research");
   return($self);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(Main StartWith ClassLib));
}

sub ClassLib
{
   my $self=shift;
   my $lang=$self->Lang();


   print $self->HttpHeader("text/javascript",charset=>'UTF-8');
   my $d=<<EOF;
function W5Base(){
   return(W5BaseConfig);
}
// Base Class definition for all DataObjects

var DataObjectBaseClass=function(dataobj,dataobjid){
   this.dataobj=dataobj;
   this.dataobjid=dataobjid;
   return(this);
};

DataObjectBaseClass.prototype.onStartWith=function(){
   // Research Start with this object
};

DataObjectBaseClass.prototype.onSetObjectFocus=function(){
   console.log("on Select",this);
   var d="<div class=ObjectWindow>";

   d+="<div class=ObjectWindowTitle>";
   d+="<div align=right>"+
      "<img id=ObjectWindowClose border=0 "+
      "src='../../../public/base/load/subModClose.gif'>"+
      "</div>";
   d+="</div>";
   d+=this.renderDetailData();
   d+=this.renderDetailActions();
   d+="</div>";
   \$("#con").html(d);
   \$("#ObjectWindowClose").click(function(e){
        selected=null;
        nearest=null;
        showMain();
   });




   \$(".callAction").click(function(e){
     var name=\$(this).attr("name");
     var dataobj=\$(this).attr("dataobj");
     var dataobjid=\$(this).attr("dataobjid");
     var k=dataobj+'::'+dataobjid;
     var node;
     if (node=W5App.graph.NodeExists(k)){
        node.data.w5obj.onAction(name);
     }
   });
};

DataObjectBaseClass.prototype.renderDetailData=function(){
   var d="<div class=DetailData style='height:100px;overflow:auto'>";
   d+="Object:"+this.dataobj+"<br>";
   d+="ObjectID:"+this.dataobjid+"<br><hr>";
   d+="</div>";
   return(d);
};

DataObjectBaseClass.prototype.handleSearch=function(){
   alert("no search defined");
   return;
};

DataObjectBaseClass.prototype.renderDetailActions=function(){
   var d="<div class=DetailActions style='height:100px;overflow:auto'>";
   var l=this.getPosibleActions();
   for(var c=0;c<l.length;c++){
      var e="<div>"+
            "<input class='callAction' "+
            "name='"+l[c].name+"' style='text-align:left' "+
            "dataobj='"+this.dataobj+"' "+
            "dataobjid='"+this.dataobjid+
            "' type=button value='"+l[c].label+"' style='width:100%'>"+
            "</div>";
      d+=e;
   }
   d+="</div>";
   return(d);
};

DataObjectBaseClass.prototype.getPosibleActions=function(){
   return([{name:'xxx',label:'Hallo Welt'},
           {name:'sdfs',label:'This is it'}]);
   return([]);
};

DataObjectBaseClass.prototype.onAction=function(name){
   console.log('process Action '+name+' on '+this.dataobjid);
   return;
};


DataObjectBaseClass.prototype.displayname=function(){
   return("unkown");
};

DataObjectBaseClass.prototype.getAvatarImage=function(){
   var i = new Image();
   i.src = '../../../public/base/load/world.jpg'+
           '?HTTP_ACCEPT_LANGUAGE=$lang';
   return(i);
};


var DataObject=new Object();

//
// Class Defitions and Stor in DataObjectClass as attributes, to allow
// call by standard w5base object notations ( ... :: ... )
//

EOF
   print($d);
   foreach my $sobj (values(%{$self->{Research}})){
      if ($sobj->can("getJSObjectClass")){
         my $d=$sobj->getJSObjectClass($self,$lang);
         printf("%s\n",$d);
      }
   }
}

#
# Research Bootstrap call
#
sub StartWith
{
   my ($self)=@_;
   my $dataobj;
   my $dataobjid;
   my $val;
   if (defined(Query->Param("FunctionPath"))){
      $val=Query->Param("FunctionPath");
   }
   $val=~s/^\///;
   my @v=split(/\//,$val);
   if ($v[0] ne "" && ($v[0]=~m/^\S+::\S+$/) && $v[1] ne ""){
      $dataobj=$v[0];
      $dataobjid=$v[1];
   }
   $self->HtmlGoto("../../Main",post=>{
      dataobj=>$dataobj,
      dataobjid=>$dataobjid
   });
}

#
# Resarch Engine
#

sub Main
{
   my ($self)=@_;

   print $self->HttpHeader("text/html",charset=>'UTF-8');

   my $getAppTitleBar=$self->getAppTitleBar();

   my $dataobj=Query->Param("dataobj");
   my $dataobjid=Query->Param("dataobjid");
   my $lang=$self->Lang();
   my $objlist="var objlist=";
   my @objlist;
   foreach my $sobj (values(%{$self->{Research}})){
      my $d;
      if ($sobj->can("getObjectInfo")){
         $d=$sobj->getObjectInfo($self,$lang);
      }
      if (defined($d)){
         push(@objlist,"{name:'$d->{name}',label:'$d->{label}',".
                       "prio:'$d->{prio}'}");
      }
   }
   $objlist=$objlist."[".join(",\n",@objlist)."];";
   my $opt={
      static=>{
          LANG      => $lang,
          DATAOBJ   => $dataobj,
          DATAOBJID => $dataobjid,
          OBJLIST   => $objlist,
          TITLEBAR  => $getAppTitleBar
      }
   };

   my $prog=$self->getParsedTemplate("tmpl/base.ResearchEngineMain",$opt);
   utf8::encode($prog);
   print($prog);
}


1;
