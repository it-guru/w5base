(function(window, document, undefined) {
   var applet='%SELFNAME%';
   ClassAppletLib[applet].class=function(app){
      ClassApplet.call(this,app);
   };
   $.extend(ClassAppletLib[applet].class.prototype,ClassApplet.prototype);


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
                   conproto:'DB-Client DB-Link ODBC',
                   toapplcistatus:'4'
                });
                w5obj.findRecord("fromappl,fromapplid,toappl,toapplid",
                                 function(data){
                   // detect all objects need to be preloaded
                   var cnt=data.length;
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
      this.app.node.clear();
      this.app.edge.clear();
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
          $(".spinner").hide();
      });



//      this.app.showDialog(function(){
//         var d="this is $self , $app,  $lang";
//         return(d);
//      },function(){
//         appletobj.exit();
//      });




   };
})(this,document);
