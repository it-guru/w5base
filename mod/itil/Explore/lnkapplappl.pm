package itil::Explore::lnkapplappl;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
use kernel::ExploreApplet;
@ISA=qw(kernel::ExploreApplet);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub getJSObjectClass
{
   my $self=shift;
   my $app=shift;
   my $lang=shift;
   my $selfname=$self->Self();

 #   my $addGroups=quoteHtml($self->getParent->T("add all related groups"));
 #   my $addOrgs=quoteHtml($self->getParent->T("add organisation groups"));
 #   my $orgRoles=join(" ",orgRoles());

   my $d=<<EOF;
(function(window, document, undefined) {
   var applet='${selfname}';
   ClassAppletLib[applet].class=function(app){
      ClassApplet.call(this,app);
   };
   \$.extend(ClassAppletLib[applet].class.prototype,ClassApplet.prototype);


   ClassAppletLib[applet].class.prototype.loadItemList=function(){
     var app=this.app;
     return(
        new Promise(function(ok,reject){
           app.Config().then(function(cfg){
              var w5obj=getModuleObject(cfg,'itil::lnkapplappl');
                w5obj.SetFilter({
                   cistatusid:"4",
                   fromapplcistatus:'4',
                   fromapplopmode:'prod',
                   toapplcistatus:'4'
                });
                w5obj.findRecord("fromappl,fromapplid,toappl,toapplid",
                                 function(data){
                   // detect all objects need to be preloaded
                   var cnt=data.length;
                   if (cnt>2000){
                      cnt=2000;
                   }
                   var preLoad=[W5Explore.loadDataObjClass("itil::appl")];
                   app.console.log("INFO","found "+data.length+
                                          " interface records");
                   Promise.all(preLoad).then(function(preload){
                      var promlst=new Array();
                      var edges=new Array();
                      for(c=0;c<cnt;c++){
                         promlst.push(
                            app.addNode("itil::appl",data[c].fromapplid,
                                                     data[c].fromappl));
                         promlst.push(
                            app.addNode("itil::appl",data[c].toapplid,
                                                     data[c].toappl));
                         edges.push({
                            fromid:app.toObjKey('itil::appl',
                                                data[c].fromapplid),
                            toid:app.toObjKey('itil::appl',
                                                data[c].toapplid)
                         });
                      } 
                      app.console.log("INFO","start resolving promise objects");
                      Promise.all(promlst).then(function(){
                         for(c=0;c<edges.length;c++){
                            app.addEdge(edges[c].fromid,edges[c].toid,{});
                         }
                         console.log("OK, all loaded");
                      }).catch(function(e){
                         console.log("not good - in ",e);
                      });
                   }).catch(function(e){
                      console.log("not good2 - in ",e);
                   });
                   ok("OK");
                },function(exception){
                   app.console.log("got error from call");
                   reject(exception);
                });
             }).catch(function(e){
                console.log("get config failed",e);
                app.console.log("can not get config");
                reject(e); 
             });
          })
       )
   };



   ClassAppletLib[applet].class.prototype.run=function(){
      var appletobj=this;
      this.app.ShowNetworkMap({
         physics: {
            barnesHut:{
               gravitationalConstant:-4100
            },
            enabled: true
         }
      });
      this.app.console.log("INFO","loading scenario ...");
      this.loadItemList().then(function(d){
          appletobj.app.console.log("INFO","scenario is loaded");
      }).catch(function(e){
          \$(".spinner").hide();
      });



//      this.app.showDialog(function(){
//         var d="this is $self , $app,  $lang";
//         return(d);
//      },function(){
//         appletobj.exit();
//      });




   };
})(this,document);
EOF
   return($d);
}

sub getObjectInfo
{
   my $self=shift;
   my $app=shift;
   my $lang=shift;

   return({
      label=>"Application Interfaces",
      description=>"Build a map of all technical interfaces of productive Applications",
      sublabel=>"IT-Inventar",
      prio=>'500'
   });
}



1;
