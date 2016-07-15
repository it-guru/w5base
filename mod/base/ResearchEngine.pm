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

DataObjectBaseClass.prototype.loadRec=function(view){
   var dst=this;
   if (dst.rec==undefined){
      dst.rec={
         name:'????',
         fullname:'????'
      };  
   }
   var w5obj=getModuleObject(W5App.Config(),this.dataobj);
   w5obj.SetFilter({id:this.dataobjid});
   W5App.setLoading(1,"loading "+this.dataobj+" "+this.dataobjid);
   w5obj.findRecord(view,function(data){
      if (data[0]){
         dst.rec=data[0];
      }
      W5App.setLoading(-1);
   });
};


DataObjectBaseClass.prototype.onSetObjectFocus=function(){
   var curthis=this;
   var disp=function(){
      var d="<div class=ObjectWindow>";

      d+="<div class=ObjectWindowTitle>";
      d+="<div class=ObjectWindowTitleText>";
      d+=DataObject[curthis.dataobj].label;
      d+="</div>";
      d+="<div class=ObjectWindowTitleButton>"+
         "<img id=ObjectWindowClose border=0 "+
         "src='../../../public/base/load/subModClose.gif'>"+
         "</div>";
      d+="</div>";
      d+=curthis.renderDetailData();
      d+=curthis.renderDetailActions();
      d+="</div>";
      \$("#ObjectDetail").html(d);
      \$(".jqellipsis").ellipsis();  // ... anzeigen bei Bedarf
      \$("#ObjectWindowClose").click(function(e){
           W5App.showMain();
      });


      \$(".callAction").click(function(e){
         var name=\$(this).attr("name");
         var dataobj=\$(this).attr("dataobj");
         var dataobjid=\$(this).attr("dataobjid");
         var k=dataobj+'::'+dataobjid;
         var node;
        
         // Resultset definition
         var resultSet=new Object({
             addObject:function(o){
                 if (o.rec.dataobj && o.rec.dataobjid){
                    W5App.addObject(o.rec.dataobj,o.rec.dataobjid);
                 }
                 else{
                    console.log("error in addObject",o);
                 }
             },
             addConnector:function(skey,dkey,mode){
                 W5App.addConnectorKK(skey,dkey,mode);
             },
             display:function(){
             }
         });

         if (node=W5App.graph.NodeExists(k)){
            node.data.w5obj.onAction(name,resultSet);
         }
      });
   };
   disp();
   if (W5App.isLoading()){
      W5App.pushLoadingStack(function(){
         disp();
         W5App.Renderer.start();
      });
   }
};

DataObjectBaseClass.prototype.renderDetailData=function(){
   var d="<div class=DetailData style='height:100px;overflow:auto'>";
   var data=this.gatherDetailData();
   d+="<table border=1 width=100%>";
   for(var c=0;c<data.length;c++){
      var rec=data[c];
      if (rec.type=='h1'){
         d+="<tr><td colspan=2><div class='jqellipsis' "+
            "style='font-weight:bold'>"+
            rec.label+"</div></td></tr>";
      }
      else if (rec.type=='h2'){
         d+="<tr><td colspan=2><div class='jqellipsis'>"+
            rec.label+"</div></td></tr>";
      }
      else{
         d+="<tr><td width=10 nowrap style='font-weight:bold'>"+
            rec.label+":</td>";
         d+="<td><div class='jqellipsis'>"+rec.value.text+
            "</div></td></td></tr>";
      }
   }
   d+="</table>";
   d+="</div>";
   return(d);
};

DataObjectBaseClass.prototype.gatherDetailData=function(){
   var l=new Array();
   l.push({
      label:this.fullname(),
      type:'h1',
   });
   l.push({
      label:'Type',
      type:'text',
      value:{
         text:this.dataobj
      }
   });
   l.push({
      label:'Name',
      type:'text',
      value:{
         text:this.shortname()
      }
   });
   console.log("gatherDetailData",DataObject);
   return(l);
}




DataObjectBaseClass.prototype.renderDetailActions=function(){
   var d="<div class=DetailActions style='height:100%;overflow:auto'>";
   var currentObject=this;
   var l=this.getPosibleActions();
   d+="<table width=100%>";
   for(var c=0;c<l.length;c++){
      var logo="action_op.gif";
      if (l[c].name.match(/^add/i)) logo="action_add.gif";
      if (l[c].name.match(/^del/i)) logo="action_del.gif";
      var e="<tr class='callAction' "+
            "name='"+l[c].name+"' style='text-align:left' "+
            "dataobj='"+this.dataobj+"' "+
            "dataobjid='"+this.dataobjid+
            "'><td valign=top width=10>"+
            "<img border=0 src='../../../public/base/load/"+logo+"'>"+
            "</td><td valign=top>"+l[c].label+"</td></tr>";
      d+=e;
   }
   d+="</table>";
   d+="</div>";
   return(d);
};

DataObjectBaseClass.prototype.getPosibleActions=function(){
   return([
           {name:'delThis',label:'delete Object'}
          // ,{name:'anyOp',label:'MachNix'}
          ]);
};

DataObjectBaseClass.prototype.onAction=function(name,resultSet){
   if (name=='delThis'){
      W5App.delObject(this.dataobj,this.dataobjid);
      W5App.showMain();
   }
   if (name=='dataobj'){
      // var dkey=W5App.toObjKey(this.dataobj,this.dataobjid);
      resultSet.addObject({
         k:this.dataobj,
         rec:{
            name:this.dataobj,
            dataobj:this.dataobj,
            dataobjid:this.dataobjid
         }
      }); 
      return(1);
   }
   if (name=='dataobjid'){
      var dkey=W5App.toObjKey(this.dataobj,this.dataobjid);
      resultSet.addObject({
         k:dkey,
         rec:{
            name:this.dataobjid,
            dataobj:this.dataobj,
            dataobjid:this.dataobjid
         }
      }); 
   }
   return(0);
};


DataObjectBaseClass.prototype.fullname=function(){
   return("unkown");
};

DataObjectBaseClass.prototype.shortname=function(){
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
   my $fullname=$self->T("Fullname");
   my $name=$self->T("Name");
   my $objecttype=$self->T("ObjectType");
   my $opt={
      static=>{
          LANG      => $lang,
          DATAOBJ   => $dataobj,
          DATAOBJID => $dataobjid,
          OBJLIST   => $objlist,
          TITLEBAR  => $getAppTitleBar,
          NAME      => $name,
          FULLNAME  => $fullname,
          OBJECTTYPE=> $objecttype,
      }
   };

   my $prog=$self->getParsedTemplate("tmpl/base.ResearchEngineMain",$opt);
   utf8::encode($prog);
   print($prog);
}


1;
